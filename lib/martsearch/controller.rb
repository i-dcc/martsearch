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
    include MartSearch::ControllerUtils
    
    attr_reader :config, :cache, :index
    
    def initialize()
      config_dir = "#{MARTSEARCH_PATH}/config"
      
      @config = {
        :index         => build_index_conf( config_dir ),
        :datasources   => build_datasources( config_dir ),
        :server        => build_server_conf( "#{config_dir}/server" ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder" )
      }
      
      @cache = initialize_cache( @config[:server][:cache] )
      @index = MartSearch::Index.new( @config[:index] )
    end
    
  end
  
end