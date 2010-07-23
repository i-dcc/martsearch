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
    
    
  end
  
end