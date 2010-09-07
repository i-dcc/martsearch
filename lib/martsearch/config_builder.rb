module MartSearch
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigBuilderError < Exception; end
  
  # Singleton configuration class for MartSearch.  This class handles all of the 
  # config file parsing and builds up a cache of DataSource objects ready to use 
  # throughout the rest of the MartSearch framework.
  class ConfigBuilder
    include Singleton
    include MartSearch::Utils
    
    attr_reader :config
    
    def initialize()
      config_dir =  "#{MARTSEARCH_PATH}/config"
      
      @config = {
        :http_client   => build_http_client(),
        :datasources   => build_datasources( config_dir ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder/" )
      }
    end
    
    private
    
    # Sets up a Net::HTTP object
    #
    # @return [Net::HTTP] A Net::HTTP object
    def build_http_client
      http_client = Net::HTTP
      if ENV['http_proxy'] or ENV['HTTP_PROXY']
        proxy       = URI.parse( ENV['http_proxy'] ) || URI.parse( ENV['HTTP_PROXY'] )
        http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
      end
      return http_client
    end
    
    # Helper function to process the DataSource configuration and, build 
    # appropriate DataSource objects based on this configuration.
    #
    # @param [String] config_dir The directory location of the 'datasources.json' config file.
    def build_datasources( config_dir )
      datasources     = {}
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.each do |ds_name,ds_conf|
        datasources[ ds_name.to_sym ] = MartSearch.const_get("#{conf['type']}DataSource").new( ds_conf )
      end
      
      return datasources
    end
    
    # Helper function to build up the IndexBuilder configuration object (for 
    # populating/rebuilding) the Solr index.
    #
    # @param [String] config_dir The directory location of the 'index_builder.json' config file. and it's seperate datasources config files.
    def build_index_builder_conf( config_dir )
      index_builder_conf = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/index_builder.json", 'r' ) ) )
      ['primary','secondary'].each do |pri_sec|
        index_builder_conf[:datasources_to_index][pri_sec].each do |index_dataset|
          datasource_conf = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/datasources/#{index_dataset}.json", 'r' ) ) )
          index_builder_conf[:datasources][index_dataset.to_sym] = datasource_conf
        end
      end
      
      return index_builder_conf
    end
    
  end
  
end