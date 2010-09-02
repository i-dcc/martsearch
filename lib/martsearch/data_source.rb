module MartSearch
  
  class DataSource
    include MartSearch::Utils
    
    def initialize( conf )
      symbolise_hash_keys(conf)
      @url = conf[:url]
    end
    
    # Abstract method for DataSource based classes - this MUST be overriden 
    # in the child class if this datasource is to be indexed.
    def fetch_all_terms_for_indexing( index_conf={} )
      { :headers => [], :data => [[],[],[]] }
    end
  end
  
  class BiomartDataSource < DataSource
    attr_reader :ds
    
    def initialize( conf )
      super
      @ds = Biomart::Dataset.new( @url, { :name => conf[:dataset] } )
    end
    
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