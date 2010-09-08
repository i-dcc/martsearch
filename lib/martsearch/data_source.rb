module MartSearch
  
  # DataSource class for modelling a source for data.
  #
  # @author Darren Oakley
  # @abstract Subclass and override {#fetch_all_terms_for_indexing} to implement a custom DataSource class.
  class DataSource
    include MartSearch::Utils
    
    # @param [Hash] conf configuration hash
    def initialize( conf )
      symbolise_hash_keys(conf)
      @url = conf[:url]
    end
    
    # Abstract method - Function to query a datasource and return all of the data terms to
    # be indexed.
    #
    # @abstract
    # @param [Hash] index_conf configuration hash determining how to query the datasource
    # @return [Hash] a hash containing the :headers (Array) and :data (Array of Arrays) to index
    def fetch_all_terms_for_indexing( index_conf={} )
      { :headers => [], :data => [[],[],[]] }
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
      @ds = Biomart::Dataset.new( @url, { :name => conf[:dataset] } )
    end
    
    # Function to query a biomart datasource and return all of the data ready for indexing.
    #
    # @param [Hash] index_conf configuration hash determining how to query the biomart
    # @return [Hash] a hash containing the :headers (Array) and :data (Array of Arrays) to index
    def fetch_all_terms_for_indexing( index_conf )
      attributes = []
      index_conf['attribute_map'].each do |map|
        attributes.push(map["attr"])
      end
      
      biomart_search_params = {
        :filters => index_conf['filters'],
        :attributes => attributes.uniq,
        :timeout => 240
      }
      
      @ds.search(biomart_search_params)
    end
    
  end
  
end