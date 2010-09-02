module MartSearch
  
  class DataSource
    include MartSearch::Utils
    
    def initialize( conf={} )
      symbolise_hash_keys(conf)
      @url = conf[:url]
    end
    
    def fetch_all_terms_for_indexing()
      { :headers => [], :data => [[],[],[]] }
    end
  end
  
  class BiomartDataSource < DataSource
    attr_reader :ds
    
    def initialize( conf={} )
      super
      @ds = Biomart::Dataset.new( @url, { :name => conf[:dataset] } )
    end
    
    def fetch_all_terms_for_indexing( filters={}, attributes=[] )
      biomart_search_params = { :filters => filters, :attributes => attributes, :timeout => 240 }
      @ds.search(biomart_search_params)
    end
    
  end
  
end