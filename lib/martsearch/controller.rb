module MartSearch
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigError < Exception; end
  
  # Singleton controller class for MartSearch.  This is the central contoller 
  # for the MartSearch framework - it handles the config file parsing, building 
  # up all of the DataSource and Index objects, and managing the search mechanics.
  # 
  # @author Darren Oakley
  class Controller
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
    
  end
  
end