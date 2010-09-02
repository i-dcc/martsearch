module MartSearch
  class IndexBuilder
    include MartSearch
    include MartSearch::IndexBuilderUtils
    
    def initialize()
      @config = MartSearch::Config.instance().config[:index_builder]
    end
    
    def fetch_data_for_indexing
      ds_to_index = flatten_primary_secondary_datasources( @config[:datasources_to_index] )
      threads     = []
      
      ds_to_index.each do |ds|
        threads << Thread.new(ds) do |ds_name|
          puts "kick-off #{ds_name}"
          
          conf       = @config[:datasources][ds_name.to_sym]
          datasource = conf[:datasource]
          index_conf = conf[:indexing]
          
          datasource.fetch_all_terms_for_indexing( index_conf['filters'], all_attributes_to_fetch( index_conf['attribute_map'] ) )
        end
      end
      
      threads.each { |thread| thread.join }
    end
    
  end
end