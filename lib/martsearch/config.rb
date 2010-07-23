module MartSearch
  
  class Config
    include Singleton
    include MartSearch::Utils
    
    attr_reader :config
    
    def initialize()
      config_dir =  "#{MARTSEARCH_PATH}/../config" 
      
      @config = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/config.json", 'r' ) ) )
      
      @config[:datasources] = {}
      
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.each do |ds_name,ds_conf|
        @config[:datasources][ ds_name.to_sym ] = MartSearch.const_get("#{ds_conf['type']}DataSource").new( ds_conf )
      end
      
      
    end
    
    
    
    
  end
  
end