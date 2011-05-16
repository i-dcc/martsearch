# encoding: utf-8

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
    
    attr_reader :config, :cache, :ontology_cache, :index, :errors, :search_data
    attr_reader :search_results, :datasources, :datasets, :dataviews, :dataviews_by_name
    
    def initialize()
      config_dir = "#{MARTSEARCH_PATH}/config"
      
      @config = {
        :index         => build_index_conf( config_dir ),
        :datasources   => build_datasources( config_dir ),
        :server        => build_server_conf( "#{config_dir}/server" ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder" )
      }
      
      @cache             = initialize_cache( @config[:server][:cache] )
      @ontology_cache    = MartSearch::OntologyTermCache.new()
      @index             = MartSearch::Index.new( @config[:index] )
      @datasources       = @config[:datasources]
      @datasets          = @config[:server][:datasets]
      @dataviews         = @config[:server][:dataviews]
      @dataviews_by_name = @config[:server][:dataviews_by_name]
      
      # Stores for search result data and errors...
      clear_instance_variables
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
    # But returns an ordered list of the results/index docs (@search_results)
    #
    # @param [String] query The query string to pass to the search index
    # @param [Integer] page The page of results to search for/return
    # @param [Boolean] use_index_cache Use cached index data if available
    # @param [Boolean] use_dataset_cache Use cached dataset data if available
    # @param [Boolean] save_index_data Try to save the index return to the cache
    # @return [Array] A list of the search results (primary index fields)
    def search( query, page=1, use_index_cache=true, use_dataset_cache=true, save_index_data=true )
      page = 1 if page == 0
      clear_instance_variables
      
      # Marker.mark("looking up index...") do
      cached_index_data = fetch_from_cache( "index:#{query}-page#{page}" )
      if cached_index_data != nil and use_index_cache
        search_from_cached_index( cached_index_data )
      else
        if search_from_fresh_index( query, page )
          obj_to_cache    = {
            :search_data           => @search_data,
            :search_results        => @search_results,
            :current_page          => @index.current_page,
            :current_results_total => @index.current_results_total,
            :cache_timestamp       => DateTime.now.to_s
          }
          write_to_cache( "index:#{query}-page#{page}", obj_to_cache ) if save_index_data
        end
      end
      # end
      
      # Marker.mark("looking up datasets...") do
      unless @search_data.empty?
        fresh_ds_queries_to_do = []
        
        cached_dataset_data = fetch_from_cache( @search_data.keys.map{ |data_key| "datasets:#{data_key}" } )
        @search_data.keys.each do |data_key|
          if cached_dataset_data["datasets:#{data_key}"].nil?
            fresh_ds_queries_to_do.push(data_key)
          else
            @search_data[data_key] = @search_data[data_key].merge(cached_dataset_data["datasets:#{data_key}"])
          end
        end
        
        unless fresh_ds_queries_to_do.empty?
          grouped_search_terms = prepare_dataset_search_terms( fresh_ds_queries_to_do )
          if search_from_fresh_datasets( fresh_ds_queries_to_do, grouped_search_terms )
            fresh_ds_queries_to_do.each do |data_key|
              unless @search_data[data_key].nil?
                @search_data[data_key][:cache_timestamp] = DateTime.now.to_s
                write_to_cache( "datasets:#{data_key}", @search_data[data_key] )
              end
            end
          end
        end
      end
      # end
      
      # Return paged_results
      return @search_results
    end
    
    # Wrapper around #search.  Get's ALL results possible for a given search.
    # 
    # @param [String] query The query string to pass to the search index
    # @param [Boolean] use_cache Use cached dataset data if available
    # @return [Array] Returns an array of search data keys in the first element, and the search data hash in the second
    def unpaged_search( query, use_cache=true )
      return nil unless battle_station_fully_operational?
      
      # First, reset the 'docs_per_page' configuration
      increased_docs_per_page        = 250
      default_docs_per_page          = config[:index][:docs_per_page]
      config[:index][:docs_per_page] = increased_docs_per_page
      
      # Get on with stuff...
      keys         = []
      data         = {}
      current_page = 1
      total_pages  = ( @index.count( query ) / increased_docs_per_page ).to_i + 1
      
      # Marker.mark("full search...") do
      while current_page <= total_pages
        keys = keys + search( query, current_page, false, use_cache, false ).map{ |elm| elm[ @index.primary_field ].to_sym } 
        data.merge!( @search_data )
        current_page += 1
      end
      # end
      
      ##
      ## TODO:  what would speed things up here is...
      ##         - if we could cut down the amount of data coming back from the index
      ##
      
      # Clean up...
      config[:index][:docs_per_page] = default_docs_per_page
      clear_instance_variables
      
      return keys, data
    end
    
    # Function to let you know if everything (the index and datasources) is up and working as expected.
    #
    # @return [Boolean] true if all ok, false if not
    def battle_station_fully_operational?
      okay = true
      
      okay = false unless @index.is_alive?
      @datasources.each do |name,datasource|
        okay = false unless datasource.is_alive?
      end
      
      return okay
    end
    
    # Function to load in the browsable content config and then query the index 
    # for each term and get a count of items returned...
    #
    # @param [Boolean] use_cache Use cached data if available
    # @return [Hash] A hash of all of the browsable content counts
    def browse_counts( use_cache=true )
      counts = fetch_from_cache( "browse_counts" )
      if counts.nil? || use_cache == false
        all_ok = true
        counts = {}
        @config[:server][:browsable_content].each do |field,field_config|
          counts[field] = {}
          Parallel.each( field_config[:options].keys, :in_threads => 5 ) do |option|
            begin
              option_config         = field_config[:options][option]
              counts[field][option] = @index.count( option_config[:query] )
            rescue MartSearch::IndexSearchError => error
              all_ok                              = false
              counts[field][option] = nil
            end
          end
        end
        
        write_to_cache( "browse_counts", counts ) if all_ok
      end
      
      return counts
    end
    
    # Function to calculate the progress of the WTSI Mouse Genetics Project (MGP).
    # This should return counts for three categories:
    #   - Number of genes with lines with Standard Phenotyping (MGP pipeline) done
    #   - Number of genes with lines with Infection Challenge (Citrobacter & Salmonella) done
    #   - Number of genes with lines with Expression (embryo and adult) done
    # 
    # @param [Boolean] use_cache Use cached data if available
    # @return [Hash] A hash of the status counts that the MGP wants
    def wtsi_phenotyping_progress_counts( use_cache=true )
      heatmap_dataset = self.datasets[:'wtsi-phenotyping-heatmap']
      raise MartSearch::InvalidConfigError, "MartSearch::Controller.wtsi_phenotyping_progress_counts cannot be called if the 'wtsi-phenotyping-heatmap' dataset is inactive" if heatmap_dataset.nil?
      
      counts = fetch_from_cache( "wtsi_phenotyping_progress_counts" )
      if counts.nil? || use_cache == false
        heatmap_test_groups_conf = heatmap_dataset.config[:test_groups]
        heatmap_mart             = heatmap_dataset.datasource.ds
        counts                   = {}
        all_ok                   = true
        
        begin
          counts = {
            :standard_phenotyping => complete_mgp_alleles_count( heatmap_mart, ['haematology_cbc'], ['CompleteInteresting','CompleteNotInteresting'] ),
            :infection_challenge  => complete_mgp_alleles_count( heatmap_mart, ['salmonella_challenge','citrobacter_challenge'], ['CompleteInteresting','CompleteNotInteresting'] ),
            :expression           => complete_mgp_alleles_count( heatmap_mart, ['adult_lac_z_expression','embryo_lac_z_expression'], ['CompleteDataAvailable'] )
          }
        rescue Biomart::BiomartError => error
          all_ok = false
          counts = {
            :standard_phenotyping => counts[:standard_phenotyping]  ? counts[:standard_phenotyping] : '-',
            :infection_challenge  => counts[:infection_challenge]   ? counts[:infection_challenge]  : '-',
            :expression           => counts[:expression]            ? counts[:expression]           : '-',
          }
        end
        
        write_to_cache( "wtsi_phenotyping_progress_counts", counts, { :expires_in => 12.hours } ) if all_ok
      end
      
      return counts
    end
    
    # Cache interaction helper - fetch data from the cache for a given key 
    # or set of keys.
    # 
    # @param [String/Array] names The cache identifer(s) to look up
    # @return [Object/Hash/nil] The deserialized object from the cache, or nil if none found
    def fetch_from_cache( *names )
      sent_string = true
      if names.first.is_a? Array
        names       = names.first
        sent_string = false
      end
      
      cached_data = {}
      cached_data = @cache.read_multi( *names )
      
      cached_data.each do |key,value|
        cached_data[key] = deserialize_cache_entry(value) unless value.nil?
      end
      
      if sent_string && names.size == 1
        return cached_data[names[0]]
      else
        return cached_data
      end
    end
    
    # Cache interaction helper - use this to store data in the cache.
    # 
    # @param [String] key The cache identifer to store 'value' under
    # @param [Object] value The cache 'value' to store
    # @param [Hash] options An options hash (see #{ActiveSupport::Cache} for more info)
    def write_to_cache( key, value, options={} )
      @cache.delete( key )
      if @cache.is_a?(MartSearch::MongoCache)
        @cache.write( key, value, { :expires_in => 36.hours }.merge(options) )
      else
        @cache.write( key, BSON.serialize(value), { :expires_in => 36.hours }.merge(options) )
      end
    end
    
    private
      
      # Helper function for #fetch_from_cache.  Handles the data deserialization for data 
      # coming back from the cache.
      def deserialize_cache_entry( entry )
        entry = BSON.deserialize(entry) unless @cache.is_a?(MartSearch::MongoCache)
        entry = entry.clean_hash if RUBY_VERSION < '1.9'
        entry.recursively_symbolize_keys!
        return entry
      end
      
      # Helper function for #wtsi_phenotyping_progress_counts. This function queries the 
      # MGP mart for a defined set of tests/attributes and computes the number of completed 
      # alleles (by complete, we mean that any of the tests listed have a status defined in the 
      # allowed_values argument passed in).
      # 
      # @param [Biomart::Dataset] mart A Biomart::Dataset object for the MGP mart
      # @param [Array] attributes The list of tests/attributes to check for completeness
      # @param [Array] allowed_values The attribute values to look for to consider a result 'complete'
      # @return [Integer] The count of unique genes that have data on all the tests queried
      def complete_mgp_alleles_count( mart, attributes, allowed_values )
        complete_genes = []
        results        = mart.search(
          :process_results => true,
          :attributes      => attributes.unshift('allele_name'),
          :filters         => {}
        )
        
        results.each do |result|
          pass_count = 0
          result.each do |key,value|
            next if key == 'allele_name'
            pass_count += 1 if allowed_values.include?(value)
          end
          complete_genes.push( result['allele_name'] ) if pass_count == ( attributes.size - 1 )
        end
        
        return complete_genes.uniq.size
      end
      
      # Utility function that drives the index searches.
      #
      # @param [String] query The search term to hit the index with
      # @param [Integer] page The page of results to retrieve
      # @return [Boolean] true/false reporting if the search went without error (actual results are stored in @search_data)
      def search_from_fresh_index( query, page )
        begin
          if @index.is_alive?
            @search_data    = @index.search( query, page )
            @search_results = @index.paginated_results
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
      
      # Utility function to load index data into the instance variables from a 
      # cached object.
      #
      # @param [String] cached_data The marshaled object to load
      def search_from_cached_index( cached_data )
        @search_data                 = cached_data[:search_data]
        @index.current_page          = cached_data[:current_page]
        @index.current_results_total = cached_data[:current_results_total]
        @search_results              = @index.paginate_results(cached_data[:search_results])
      end
      
      # Utility function to prepare the search terms used to drive the dataset searches.
      #
      # @param [Array] search_keys The keys/docs in @search_data to prepare dataset searches for
      # @return [Hash] A hash keyed by the document fields containing all the terms found for the given field
      def prepare_dataset_search_terms( search_keys )
        grouped_terms = {}
        
        search_keys.each do |key|
          doc = @search_data[key][:index]
          doc.each do |field,value|
            grouped_terms_for_field = grouped_terms[field]
            grouped_terms_for_field = [] if grouped_terms_for_field.nil?
            
            if value.is_a?(Array)
              value.each do |val|
                grouped_terms_for_field.push( val )
              end
            else
              grouped_terms_for_field.push( value )
            end
            
            grouped_terms[field] = grouped_terms_for_field
          end
        end
        
        return grouped_terms
      end
      
      # Utility function that performs the dataset searches and 
      # post-search sorting routines
      #
      # @params [Array] terms_to_query An array of @search_data keys that we should be feeding data into here...
      # @param [Hash] grouped_search_terms A hash of terms (grouped by index field) that can be used to drive the dataset searches
      # @return [Boolean] true/false reporting if the searches went without error (actual results are stored in @search_data)
      def search_from_fresh_datasets( terms_to_query, grouped_search_terms )
        success = true
        
        Parallel.each( @datasets.keys, :in_threads => 10 ) do |ds_name|
          begin
            dataset      = @datasets[ds_name]
            search_terms = grouped_search_terms[ dataset.joined_index_field.to_sym ]
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
          rescue Errno::ETIMEDOUT => error
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset did not respond quickly enough for this query.",
              :error => error,
              :type  => 'Errno::ETIMEDOUT'
            }
            success = false
          end
        end
        
        # Run the dataset secondary sorts in serial, BUT only run them on the results we 
        # haven't pulled them from the cache.
        @datasets.each do |dataset_name,dataset|
          if dataset.config[:custom_secondary_sort]
            search_data_copy = @search_data.clone
            search_data_copy.keys.each { |key| search_data_copy.delete(key) unless terms_to_query.include?(key) }
            @search_data.merge( dataset.secondary_sort( search_data_copy ) )
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
          results.symbolize_keys!
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