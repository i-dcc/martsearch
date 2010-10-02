module MartSearch
  
  # Error class raised when there is an error whilst interacting with a DataSource.
  class DataSourceError < Exception; end
  
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
  
  # Custom DataSource class for interacting with BioMart based datasources.
  #
  # @author Darren Oakley
  class BiomartDataSource < DataSource
    # The Biomart::Dataset object for the BiomartDataSource
    attr_reader :ds
    
    # @param [Hash] conf configuration hash
    def initialize( conf )
      super
      @ds = Biomart::Dataset.new( @url, { :name => @conf[:dataset] } )
    end
    
    # Simple heartbeat function to check that the datasource is online.
    #
    # @see MartSearch::DataSource#is_alive?
    def is_alive?
      @ds.alive?
    end
    
    # Function to query a biomart datasource and return all of the data ready for indexing.
    # 
    # TODO: Merge this function with 'search' - they essentially do the same thing!!!
    # 
    # @see MartSearch::DataSource#fetch_all_terms_for_indexing
    def fetch_all_terms_for_indexing( conf )
      attributes = []
      conf[:attribute_map].each do |map|
        attributes.push(map[:attr])
      end
      
      filters = conf[:filters]
      filters.stringify_keys! unless filters.nil?
      
      biomart_search_params = {
        :filters    => filters,
        :attributes => attributes.uniq,
        :timeout    => 240
      }
      
      @ds.search(biomart_search_params)
    end
    
    # Function to search a biomart datasource given an appropriate configuration.
    #
    # @see MartSearch::DataSource#search
    # @raise [MartSearch::DataSourceError] Raised if an error occurs during the seach process
    def search( query, conf )
      filters = { conf[:joined_filter] => query.join(',') }
      filters.merge!( conf[:filters] ) unless conf[:filters].nil? or conf[:filters].empty?
      filters.stringify_keys!
      
      search_options = {
        :filters         => filters,
        :attributes      => conf[:attributes],
        :process_results => true,
        :timeout         => 20
      }
      
      if conf[:required_attributes]
        search_options[:required_attributes] = conf[:required_attributes]
      end
      
      begin
        results = @ds.search(search_options)
        results.recursively_symbolize_keys!
      rescue Biomart::BiomartError => error
        raise MartSearch::DataSourceError, error
      end
      
      return results
    end
    
    # Function to provide a link URL to the original datasource given a 
    # dataset query.
    #
    # @see MartSearch::DataSource#data_origin_url
    def data_origin_url( query, conf )
      url = @url + "/martview?VIRTUALSCHEMANAME=default&VISIBLEPANEL=resultspanel"

      # Filters...
      filters = []

      filters_to_build = { conf[:joined_filter] => query }
      filters_to_build.merge!( conf[:filters] ) unless conf[:filters].nil?

      filters_to_build.each do |key,value|
        filter = "#{@conf[:dataset]}.default.filters.#{key}.&quot;"

        if value.is_a?(Array) then filter << "#{CGI::escape(value.join(","))}&quot;"
        else                       filter << "#{CGI::escape(value)}&quot;"
        end

        filters.push(filter)
      end

      url << "&FILTERS=#{filters.join("|")}"

      # Attributes...
      attrs = []
      url << "&ATTRIBUTES="

      conf[:attributes].each do |attribute|
        attrs.push("#{@conf[:dataset]}.default.attributes.#{attribute}")
      end

      while ( url.length + attrs.join("|").length ) > 2048
        # This loop ensures that the URL we form is not more than 2048 characters 
        # long - the maximum length that IE can deal with.  We do the shortening by 
        # dropping attributes from the selection, it's a pain, but at least it'll be 
        # easy for the user to add the attribute back in MartView.
        attrs.pop
      end
      url << attrs.join("|")

      return url
    end
    
  end
  
end