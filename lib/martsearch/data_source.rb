# encoding: utf-8

module MartSearch
  
  # Error class raised when there is an error whilst interacting with a DataSource.
  class DataSourceError < StandardError; end
  
  # DataSource class for modelling a source for data.
  #
  # @author Darren Oakley
  # @abstract Subclass and override {#is_alive?, #fetch_all_terms_for_indexing, #search} to implement a custom DataSource class.
  class DataSource
    include MartSearch::Utils
    
    # @param [Hash] conf configuration hash
    def initialize( conf )
      @conf = conf
      @url  = @conf[:url]
    end
    
    # Abstract method - simple heartbeat function to check that the datasource is online.
    #
    # @abstract
    # @return [Boolean] true/false depending on the state of the DataSource
    # @raise [MartSearch::InvalidConfigError] raised as this is an abstract class and sould not be instantiated
    def is_alive?
      raise_error
    end
    
    # Abstract method - Function to query a datasource and return all of the data terms to
    # be indexed.
    #
    # @abstract
    # @param [Hash] conf Configuration hash determining how to query the datasource
    # @return [Hash] a hash containing the :headers (Array) and :data (Array of Arrays) to index - i.e. '{ :headers => [], :data => [[],[],[]] }'
    # @raise [MartSearch::InvalidConfigError] raised as this is an abstract class and sould not be instantiated
    def fetch_all_terms_for_indexing( conf )
      raise_error
    end
    
    # Abstract method - Function to search a datasource given an appropriate configuration.
    # 
    # @abstract
    # @param [Array] query An array of values to query the datasource for
    # @param [Hash] conf Configuration hash determining how to query the datasource
    # @return [Array] An array of objects representing the data retrieved from the datasource
    # @raise [MartSearch::InvalidConfigError] raised as this is an abstract class and sould not be instantiated
    def search( query, conf )
      raise_error
    end
    
    # Abstract method - Function to provide a link URL to the original datasource given a 
    # dataset query.
    #
    # @abstract
    # @param [Array] query An array of values to query the datasource for
    # @param [Hash] conf Configuration hash determining how to query the datasource
    # @return [String] The URL to place in a link
    # @raise [MartSearch::InvalidConfigError] raised as this is an abstract class and sould not be instantiated
    def data_origin_url( query, conf )
      raise_error
    end
    
    private
      
      def raise_error
        raise MartSearch::InvalidConfigError, "There is no 'type' attribute configured for the #{@conf[:internal_name]} datasource.  Please specify the type of datasource."
      end
  end
  
end