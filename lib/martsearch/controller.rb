module MartSearch
  
  # Singleton controller class for MartSearch.  This is the central contoller 
  # for the MartSearch framework - it handles the config file parsing, building 
  # up all of the DataSource and Index objects, and managing the search mechanics.
  # 
  # @author Darren Oakley
  class Controller
    include Singleton
    include MartSearch::Utils
    include MartSearch::ControllerUtils
    
    attr_reader :config, :cache, :index, :errors, :search_data, :search_results
    attr_reader :datasources, :datasets, :dataviews, :dataviews_by_name
    
    def initialize()
      config_dir = "#{MARTSEARCH_PATH}/config"
      
      @config = {
        :index         => build_index_conf( config_dir ),
        :datasources   => build_datasources( config_dir ),
        :server        => build_server_conf( "#{config_dir}/server" ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder" )
      }
      
      @cache             = initialize_cache( @config[:server][:cache] )
      @index             = MartSearch::Index.new( @config[:index] )
      @datasources       = @config[:datasources]
      @datasets          = @config[:server][:datasets]
      @dataviews         = @config[:server][:dataviews]
      @dataviews_by_name = @config[:server][:dataviews_by_name]
      
      # Stores for search result data and errors...
      @errors         = { :index => [], :datasets => {} }
      @search_data    = {}
      @search_results = []
    end
    
    # Function to perform the searches against the index and marts.
    #
    # Sets up a results stash (@search_data) holding the data in a structure like:
    #   {
    #     IndexDocUniqueKey => {
    #       "index"         => {}, # index results for this doc
    #       "internal_name" => []/{}, # array/hash of sorted biomart data
    #       "internal_name" => []/{}, # array/hash of sorted biomart data
    #     }
    #   }
    # 
    # But returns an ordered list of the results (@search_results)
    #
    # @param [String] query The query string to pass to the search index
    # @param [Integer] page The page of results to search for/return
    # @return [Array] A list of the search results (primary index fields)
    def search( query, page=1 )
      clear_instance_variables
      
      cached_data = @cache.fetch("query:#{query}-page:#{page}")
      if cached_data
        search_from_cache( cached_data )
      else
        search_from_fresh( query, page )
      end

      # Return paged_results
      return @search_results
    end
    
    private
      
      # Utility function to extract search results from a cached data object
      def search_from_cache( cached_data )
        clear_instance_variables
        
        cached_data_obj              = Marshal.load(cached_data)
        @search_data                 = cached_data_obj[:search_data]
        @search_results              = cached_data_obj[:search_results]
        @index.current_page          = cached_data_obj[:current_page]
        @index.current_results_total = cached_data_obj[:current_results_total]
      end

      # Utility function to control a fresh search off of the index and datasets
      def search_from_fresh( query, page )
        clear_instance_variables
        
        index_search_status   = search_from_fresh_index( query, page )
        dataset_search_status = search_from_fresh_datasets() unless @index.current_results_total == 0
        @search_results       = @index.paginated_results
        
        if index_search_status and dataset_search_status
          obj_to_cache = {
            :search_data           => @search_data,
            :search_results        => @search_results,
            :current_page          => @index.current_page,
            :current_results_total => @index.current_results_total
          }
          @cache.write( "query:#{query}-page:#{page}", Marshal.dump(obj_to_cache), { :expires_in => 12.hours } )
        end
      end
      
      # Utility function that drives the index searches.
      #
      # @param [String] query The search term to hit the index with
      # @param [Integer] page The page of results to retrieve
      # @return [Boolean] true/false reporting if the search went without error (actual results are stored in @search_data)
      def search_from_fresh_index( query, page )
        begin
          if @index.is_alive?
            @search_data = @index.search( query, page )
            return true
          end
        rescue MartSearch::IndexUnavailableError => error
          @errors[:index].push({
            :text  => 'The search index is currently unavailable, please check back again soon.',
            :error => error,
            :type  => 'MartSearch::IndexUnavailableError'
          })
          return false
        rescue MartSearch::IndexSearchError => error
          @errors[:index].push({
            :text  => 'The search term you used has caused an error on the search engine, please try another search term without any special characters in it.',
            :error => error,
            :type  => 'MartSearch::IndexSearchError'
          })
          return false
        end
      end
      
      # Utility function that performs the dataset searches and 
      # post-search sorting routines
      #
      # @return [Boolean] true/false reporting if the searches went without error (actual results are stored in @search_data)
      def search_from_fresh_datasets
        success = true
        
        Parallel.each( @datasets.keys, :in_threads => 10 ) do |ds_name|
          begin
            dataset      = @datasets[ds_name]
            search_terms = @index.grouped_terms[ dataset.joined_index_field.to_sym ]
            results      = dataset.search( search_terms )
            add_dataset_results_to_search_data( dataset.joined_index_field.to_sym, ds_name.to_sym, results )
          rescue MartSearch::DataSourceError => error
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset has returned an error for this query.",
              :error => error,
              :type  => 'MartSearch::DataSourceError'
            }
            success = false
          rescue Timeout::Error => error
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset did not respond quickly enough for this query.",
              :error => error,
              :type  => 'Timeout::Error'
            }
            success = false
          end
        end
        
        @datasets.each do |dataset_name,dataset|
          if dataset.config[:custom_secondary_sort]
            @search_data = dataset.secondary_sort( @search_data )
          end
        end
        
        return success
      end
      
      # Utility function to merge dataset results into the @search_data hash.
      #
      # @param [Symbol] index_field The index field link the results data with (as it's the primary key of the 'results' hash)
      # @param [Symbol] dataset_name The name of the dataset we're working with
      # @param [Hash] results The results that will be merged into @search_data
      def add_dataset_results_to_search_data( index_field, dataset_name, results )
        # First, see if the primary key of the index is the same 
        # as the primary key of our results data, if yes, use 
        # this association as it's easy and bloody fast!
        if @index.primary_field == index_field
          
          @search_data.each do |primary_key,data_value|
            data_value[dataset_name] = results[primary_key]
          end
          
        else
          
          # Create a lookup hash of the 'index_field' values so that 
          # we can easily associate our results back to a primary_key...
          lookup = {}
          
          @search_data.each do |primary_key,data_value|
            joined_index_field_data = data_value[:index][index_field]

            if joined_index_field_data.is_a?(Array)
              joined_index_field_data.each do |lookup_key|
                lookup[lookup_key] = primary_key
              end
            else
              lookup[joined_index_field_data] = primary_key
            end
          end
          
          results.each do |result_key,result_data|
            stash_to_append_to = @search_data[ lookup[result_key] ]

            if stash_to_append_to
              if @datasets[dataset_name].config[:custom_sort]
                current_stash = stash_to_append_to[dataset_name]
                
                if current_stash.nil?
                  current_stash = result_data
                elsif current_stash.is_a?(Array)
                  current_stash.push(result_data)
                elsif current_stash.is_a?(Hash)
                  current_stash.merge!(result_data)
                end
                
                stash_to_append_to[dataset_name] = current_stash
              else
                stash_to_append_to[dataset_name] = [] unless stash_to_append_to[dataset_name.to_sym]

                result_data.each do |data|
                  stash_to_append_to[dataset_name].push(data)
                end
              end
            end
          end
          
        end
      end
      
      # Utility function to clear all instance variables
      def clear_instance_variables
        @errors         = { :index => [], :datasets => {} }
        @search_data    = {}
        @search_results = []
      end
  end
  
end