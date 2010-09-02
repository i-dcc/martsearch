module MartSearch
  class IndexBuilder
    attr_reader :config
    
    include MartSearch
    include MartSearch::IndexBuilderUtils
    
    def initialize()
      @config = MartSearch::ConfigBuilder.instance().config[:index_builder]
    end
    
    def fetch_data_for_indexing
      ds_to_index = flatten_primary_secondary_datasources( @config[:datasources_to_index] )
      
      Parallel.each( ds_to_index, :in_threads => 10 ) do |ds|
        puts "kick-off #{ds}"
        
        conf       = @config[:datasources][ds.to_sym]
        datasource = conf[:datasource]
        index_conf = conf[:indexing]
        
        datasource.fetch_all_terms_for_indexing( index_conf['filters'], all_attributes_to_fetch( index_conf['attribute_map'] ) )
      end
      
    end
    
  end
end