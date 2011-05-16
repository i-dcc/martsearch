# encoding: utf-8

module MartSearch
  
  # DataSet class for modelling a search for data.
  #
  # @author Darren Oakley
  class DataSet
    include MartSearch::DataSetUtils
    
    attr_reader :config
    
    # @param [Hash] conf Configuration hash
    def initialize( conf )
      @config = conf
    end
    
    def joined_index_field
      @config[:searching][:joined_index_field]
    end
    
    # Function used to drive a MartSearch::DataSource object to perform 
    # a query for a given dataset. Returns a hash, keyed by the 'joined_attribute' 
    # where the values are an array of results objects associated with this key.
    #
    # i.e.
    #     {
    #       'Cbx1' => [object,object],
    #       'Cbx2' => [object,object]
    #     }
    #
    # @param [Array] query An array of values to query the datasource for
    # @return [Hash] A hash, keyed by the 'joined_attribute' where the values are an array of results objects associated with this key
    def search( query )
      if query.nil?
        # Don't perform a search on empty parameters - this is bad!
        return {}
      else
        results        = datasource.search( query, @config[:searching] )
        sorted_results = sort_results( results )
        return sorted_results
      end
    end
    
    # A secondary sort function that allows a dataset to interact with 
    # the data from all the other datasets prior to going to the templates 
    # or into a cache store.  This can be used to house some cross-dataset 
    # processing that would otherwise be done in the template.
    #
    # This function is empty as it's a placeholder for custom code...
    #
    # @abstract
    # @param [Hash] search_data The current @search_data stash in MartSearch::Controller
    # @return [Hash] The modified copy of @search_data
    def secondary_sort( search_data )
      search_data
    end
    
    # Function used to drive a MartSearch::DataSource object and retieve a 
    # URL to link back to the origin of the data for a given dataset.
    #
    # @param [Array] query An array of values to query the datasource for
    # @return [String] The URL that links to the original datasource
    def data_origin_url( query )
      if query.nil?
        return nil
      else
        return datasource.data_origin_url( query, @config[:searching] )
      end
    end
    
    # Helper function to supply our MartSearch::DataSource instance.
    #
    # @return [MartSearch::DataSource] The DataSource this DataSet drives
    def datasource
      ds = MartSearch::Controller.instance().config[:datasources][ @config[:datasource].to_sym ]
      if ds.nil?
        raise MartSearch::InvalidConfigError, "Unable to find a datasource called '#{@config[:datasource]}' for dataset '#{@config[:internal_name]}'!"
      else
        return ds
      end
    end
    
    private
      
      # Helper function to sort the raw results from the MartSearch::DataSource#search 
      # function and put them into something more suitable for integrating with the 
      # other datasets search returns.
      #
      # @param [Array] results The array of hashes/objects returned from {MartSearch::DataSource#search}
      # @return [Hash] A hash, keyed by the 'joined_attribute' where the values are an array of results objects associated with this key
      def sort_results( results )
        sorted_results = {}
        
        results.each do |result|
          save_this_result = true
          
          unless datasource.is_a?(MartSearch::BiomartDataSource)
            required_attrs   = @config[:searching][:required_attributes]
            unless required_attrs.nil?
              required_attrs.each do |req_attr|
                save_this_result = false if result[req_attr].nil? and result[req_attr.to_sym].nil?
              end
            end
          end
          
          if save_this_result
            attr_to_join_on                   = result[ @config[:searching][:joined_attribute].to_sym ]
            sorted_results[ attr_to_join_on ] = [] unless sorted_results[ attr_to_join_on ]
            sorted_results[ attr_to_join_on ].push( result )
          end
        end
        
        return sorted_results
      end
      
  end
  
end