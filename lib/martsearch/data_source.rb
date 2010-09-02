module MartSearch
  
  class DataSource
    include MartSearch::Utils
    
    def initialize( conf={} )
      symbolise_hash_keys(conf)
      
      
      @url = conf[:url]
    end
  end
  
  class BiomartDataSource < DataSource
    def initialize( conf={} )
      super
      @ds = Biomart::Dataset.new( @url, { :name => conf[:dataset] } )
    end
    
    def fetch_all_terms_for_indexing( filters={}, attributes=[] )
      sleep 15
      
      puts "filters:"
      ap filters
      puts "attributes:"
      ap attributes
      
      
    end
    
  end
  
end