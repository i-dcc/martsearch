module MartSearch
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigBuilderError < Exception; end
  
  # Singleton configuration class for MartSearch.  This class handles all of the 
  # config file parsing and builds up a cache of DataSource objects ready to use 
  # throughout the rest of the MartSearch framework.
  #
  # @author Darren Oakley
  class ConfigBuilder
    include Singleton
    include MartSearch::Utils
    
    attr_reader :config
    
    def initialize()
      config_dir =  "#{MARTSEARCH_PATH}/config"
      
      @config = {
        :http_client   => build_http_client(),
        :datasources   => build_datasources( config_dir ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder" ),
        :server        => build_server_conf( "#{config_dir}/server" )
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
    
    # Helper function to process the MartSearch::DataSource configuration and, build 
    # appropriate DataSource objects based on this configuration.
    #
    # @param [String] config_dir The directory location of the 'datasources.json' config file.
    # @return [Hash] A hash of MartSearch::DataSource objects
    def build_datasources( config_dir )
      datasources     = {}
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.each do |ds_name,ds_conf|
        datasources[ ds_name.to_sym ] = MartSearch.const_get("#{ds_conf['type']}DataSource").new( ds_conf )
      end
      
      return datasources
    end
    
    # Helper function to build up the MartSearch::IndexBuilder configuration object (for 
    # populating/rebuilding) the Solr index.
    #
    # @param [String] config_dir The directory location of the 'index_builder.json' config file. and it's seperate datasources config files.
    # @return [Hash] The configuration hash
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
    
    # Helper funcion to build the MartSearch::Server configuration object.
    #
    # @param [String] config_dir The directory location of the 'server.json' config file.
    # @return [Hash] The configuration hash
    def build_server_conf( config_dir )
      server_conf = symbolise_hash_keys( JSON.load( File.new( "#{config_dir}/server.json", 'r' ) ) )
      
      # Configure the portal uri config
      server_path = URI.parse( server_conf[:portal_url] ).path
      server_path.chop! if server_path =~ /\/$/
      server_conf[:base_uri] = server_path
      
      # Load the configuration for the dataviews
      dataviews         = []
      dataviews_by_name = {}
      server_conf[:dataviews].each do |dv_name|
        dv_location = "#{config_dir}/dataviews/#{dv_name}"
        dv_conf     = symbolise_hash_keys( JSON.load( File.new( "#{dv_location}/config.json", 'r' ) ) )
        
        if dv_conf[:enabled]
          dv_conf[:internal_name] = dv_name
          dv_conf[:stylesheet]    = get_file_as_string("#{dv_location}/stylesheet.css") if dv_conf[:custom_css]
          dv_conf[:javascript]    = get_file_as_string("#{dv_location}/javascript.js") if dv_conf[:custom_js]
          
          dataviews.push( dv_conf )
          dataviews_by_name[dv_name] = dv_conf
        end
      end
      server_conf[:dataviews]         = dataviews
      server_conf[:dataviews_by_name] = symbolise_hash_keys(dataviews_by_name)
      
      return server_conf
    end
    
  end
  
end