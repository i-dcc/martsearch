module MartSearch
  
  # Utility module for the Controller class.
  #
  # @author Darren Oakley
  module ControllerUtils
    include MartSearch::Utils
    
    # Helper function to read in and process the MartSearch::Index configuration.
    #
    # @param [String] config_dir The directory location of the 'index.json' config file.
    # @return [Hash] The configuration hash
    def build_index_conf( config_dir )
      index_conf = JSON.load( File.new( "#{config_dir}/index.json", 'r' ) )
      index_conf.recursively_symbolize_keys!
      return index_conf
    end
    
    # Helper function to process the MartSearch::DataSource configuration and, build 
    # appropriate DataSource objects based on this configuration.
    #
    # @param [String] config_dir The directory location of the 'datasources.json' config file.
    # @return [Hash] A hash of MartSearch::DataSource objects
    def build_datasources( config_dir )
      datasources     = {}
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.recursively_symbolize_keys!
      datasource_conf.each do |ds_name,ds_conf|
        ds_conf[:internal_name] = ds_name
        datasources[ ds_name ]  = MartSearch.const_get("#{ds_conf[:type]}DataSource").new( ds_conf )
      end
      
      return datasources
    end
    
    # Helper function to build up the MartSearch::IndexBuilder configuration object (for 
    # populating/rebuilding) the Solr index.
    #
    # @param [String] config_dir The directory location of the 'index_builder.json' config file. and it's seperate datasources config files.
    # @return [Hash] The configuration hash
    def build_index_builder_conf( config_dir )
      index_builder_conf = JSON.load( File.new( "#{config_dir}/index_builder.json", 'r' ) )
      ['primary','secondary'].each do |pri_sec|
        index_builder_conf['datasources_to_index'][pri_sec].each do |index_dataset|
          datasource_conf = JSON.load( File.new( "#{config_dir}/datasources/#{index_dataset}.json", 'r' ) )
          index_builder_conf['datasources'][index_dataset] = datasource_conf
        end
      end
      
      index_builder_conf.recursively_symbolize_keys!
      
      return index_builder_conf
    end
    
    # Helper funcion to build the MartSearch::Server configuration object.
    #
    # @param [String] config_dir The directory location of the 'server.json' config file.
    # @return [Hash] The configuration hash
    def build_server_conf( config_dir )
      server_conf = JSON.load( File.new( "#{config_dir}/server.json", 'r' ) )
      
      # Configure the portal uri config
      server_path = URI.parse( server_conf['portal_url'] ).path
      server_path.chop! if server_path =~ /\/$/
      server_conf['base_uri'] = server_path
      
      # Load the configuration for the dataviews
      dataviews         = []
      dataviews_by_name = {}
      server_conf['dataviews'].each do |dv_name|
        dv_location = "#{config_dir}/dataviews/#{dv_name}"
        dv_conf     = JSON.load( File.new( "#{dv_location}/config.json", 'r' ) )
        
        dv_conf.recursively_symbolize_keys!
        
        if dv_conf[:enabled]
          dv_conf[:internal_name] = dv_name
          dataview                = MartSearch::DataView.new( dv_conf )
          
          dataview.stylesheet     = get_file_as_string("#{dv_location}/stylesheet.css") if dv_conf[:custom_css]
          dataview.javascript     = get_file_as_string("#{dv_location}/javascript.js")  if dv_conf[:custom_js]
          
          dataviews.push( dataview )
          dataviews_by_name[dv_name] = dataview
        end
      end
      server_conf['dataviews']         = dataviews
      server_conf['dataviews_by_name'] = dataviews_by_name
      
      # Load the configuration for the datasets
      datasets = {}
      server_conf['datasets'].each do |ds_name|
        ds_location = "#{config_dir}/datasets/#{ds_name}"
        ds_conf     = JSON.load( File.new( "#{ds_location}/config.json", 'r' ) )

        ds_conf.recursively_symbolize_keys!
        
        if ds_conf[:enabled]
          ds_conf[:internal_name] = ds_name
          dataset                 = MartSearch::DataSet.new( ds_conf )
          
          if ds_conf[:custom_sort]
            sort    = get_file_as_string( "#{ds_location}/custom_sort.rb" )
            dataset = MartSearch::Mock.method( dataset, :sort_results ) { |results| eval(sort) }
          end
          
          if ds_conf[:custom_secondary_sort]
            secondary_sort = get_file_as_string( "#{ds_location}/custom_secondary_sort.rb" )
            dataset        = MartSearch::Mock.method( dataset, :secondary_sort ) { |search_data| eval(secondary_sort) }
          end
          
          datasets[ds_name] = dataset
        end
      end
      
      server_conf['datasets'] = datasets
      
      server_conf.recursively_symbolize_keys!
      
      return server_conf
    end
    
    # Helper function to initialize the caching system.  Uses ActiveSupport::Cache so 
    # that we can easily support multiple cache backends.
    #
    # @param [String] type Can be either 'memcache' or 'file', if none supplied resorts to a memory-based cache
    # @param [Hash] config Configuration object for the cache store
    # @return [ActiveSupport::Cache Object] either MemCacheStore, FileStore or MemoryStore
    def initialize_cache( config={ :type => 'memory' } )
      case config[:type]
      when /memcache/
        servers = ['localhost']
        opts    = { :namespace => 'martsearch', :no_reply => true }
        
        servers          = config[:servers]   if config[:servers]
        opts[:namespace] = config[:namespace] if config[:namespace]
        
        return ActiveSupport::Cache::MemCacheStore.new( servers, opts )
      when /file/
        file_store = "#{MARTSEARCH_PATH}/tmp/cache"
        file_store = config[:file_store] if config[:file_store]
        
        return ActiveSupport::Cache::FileStore.new( file_store )
      else
        return ActiveSupport::Cache::MemoryStore.new()
      end
    end
    
  end
  
end