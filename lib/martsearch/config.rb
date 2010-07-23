module MartSearch
  
  class Config
    include Singleton
    include MartSearch::Utils
    
    attr_reader :config
    
    def initialize()
      config_dir =  "#{MARTSEARCH_PATH}/../config" 
      
      @config = {
        :datasources   => {},
        :index_builder => nil
      }
      
      # Load the datasource config files...
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.each do |ds_name,ds_conf|
        @config[:datasources][ ds_name.to_sym ] = MartSearch.const_get("#{ds_conf['type']}DataSource").new( ds_conf )
      end
      
      # Load the index building config files...
      index_builder_conf_dir = "#{config_dir}/index_builder/"
      index_builder_conf     = symbolise_hash_keys( JSON.load( File.new( "#{index_builder_conf_dir}/index_builder.json", 'r' ) ) )
      index_builder_conf[:datasets_to_index].each do |ds_name|
        index_builder_conf[:dataset_conf][ds_name.to_sym] = symbolise_hash_keys( 
          JSON.load( File.new( "#{index_builder_conf_dir}/datasets/#{ds_name}.json", 'r' ) ) 
        )
      end
      
    end
    
    
    
    
  end
  
end