module MartSearch
  
  class InvalidConfigBuilderError < Exception; end
  
  class ConfigBuilder
    include Singleton
    include MartSearch::Utils
    
    attr_reader :config
    
    def initialize()
      config_dir =  "#{MARTSEARCH_PATH}/config"
      puts  "config_dir = #{config_dir}"
      
      @config = {
        :http_client   => build_http_client(),
        :datasources   => build_datasource_conf( config_dir ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder/" )
      }
    end
    
    private
    
    def build_http_client
      http_client = Net::HTTP
      if ENV['http_proxy'] or ENV['HTTP_PROXY']
        proxy       = URI.parse( ENV['http_proxy'] ) || URI.parse( ENV['HTTP_PROXY'] )
        http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
      end
      return http_client
    end
    
    def build_datasource( conf )
      MartSearch.const_get("#{conf['type']}DataSource").new( conf )
    end
    
    def build_datasource_conf( config_dir )
      datasources     = {}
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.each do |ds_name,ds_conf|
        datasources[ ds_name.to_sym ] = build_datasource( ds_conf )
      end
      
      return datasources
    end
    
    def build_index_builder_conf( config_dir )
      index_builder_conf = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/index_builder.json", 'r' ) ) )
      ['primary','secondary'].each do |pri_sec|
        index_builder_conf[:datasources_to_index][pri_sec].each do |index_dataset|
          datasource_conf              = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/datasources/#{index_dataset}.json", 'r' ) ) )
          datasource_conf[:datasource] = build_datasource( datasource_conf[:datasource] )
          
          index_builder_conf[:datasources][index_dataset.to_sym] = datasource_conf
        end
      end
      
      return index_builder_conf
    end
    
  end
  
end