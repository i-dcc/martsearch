module MartSearch
  
  # Utility module for the Controller class.
  #
  # @author Darren Oakley
  module ControllerUtils
    
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
      index_builder_conf['datasets_to_index'].each do |index_dataset|
        datasource_conf = JSON.load( File.new( "#{config_dir}/datasets/#{index_dataset}.json", 'r' ) )
        index_builder_conf['datasets'][index_dataset] = datasource_conf
      end
      
      index_builder_conf.recursively_symbolize_keys!
      
      return index_builder_conf
    end
    
    # Helper funcion to build the MartSearch::Server configuration object.
    #
    # @param [String] config_dir The directory location of the 'server.json' config file.
    # @return [Hash] The configuration hash
    def build_server_conf( config_dir )
      server_conf                      = JSON.load( File.new( "#{config_dir}/server.json", 'r' ) )
      dataviews_conf                   = process_dataviews_conf( config_dir, server_conf['dataviews'] )
      server_conf['dataviews']         = dataviews_conf[:dataviews]
      server_conf['dataviews_by_name'] = dataviews_conf[:dataviews_by_name]
      server_conf['datasets']          = process_datasets_conf( config_dir, server_conf['datasets'] )
      server_conf['browsable_content'] = server_conf['browsable_content']
      
      server_conf.recursively_symbolize_keys!
      server_conf
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
        opts[:namespace] = "#{opts[:namespace]}-#{MartSearch::ENVIRONMENT}"
        
        return ActiveSupport::Cache::MemCacheStore.new( servers, opts )
      when /file/
        file_store = "#{MARTSEARCH_PATH}/tmp/cache"
        file_store = config[:file_store] if config[:file_store]
        
        return ActiveSupport::Cache::FileStore.new( file_store )
      when /mongo/
        server     = config[:server]     ? config[:server]     : 'localhost'
        port       = config[:port]       ? config[:port].to_i  : 27017
        db         = config[:db]         ? config[:db]         : 'martsearch'
        mongo      = Mongo::Connection.new( server, port, :pool_size => 5, :timeout => 5 ).db("#{db}-#{MartSearch::ENVIRONMENT}")
        
        return MartSearch::MongoCache.new( :db => mongo, :collection_name => 'martsearch_cache' )
      else
        return ActiveSupport::Cache::MemoryStore.new()
      end
    end
    
    private
      
      ##
      ## Helpers for 'build_server_conf'
      ##
      
      def process_dataviews_conf( config_dir, dataviews_conf )
        dataviews         = []
        dataviews_by_name = {}
        
        dataviews_conf.each do |dv_name|
          dv_location = "#{config_dir}/dataviews/#{dv_name}"
          dv_conf     = JSON.load( File.new( "#{dv_location}/config.json", 'r' ) )

          dv_conf.recursively_symbolize_keys!

          if dv_conf[:enabled]
            dv_conf[:internal_name] = dv_name
            dataview                = MartSearch::DataView.new( dv_conf )

            dataview.stylesheet      = File.read("#{dv_location}/stylesheet.css")     if dv_conf[:custom_css]
            dataview.javascript_head = File.read("#{dv_location}/javascript_head.js") if dv_conf[:custom_head_js]
            dataview.javascript_base = File.read("#{dv_location}/javascript_base.js") if dv_conf[:custom_base_js]

            dataviews.push( dataview )
            dataviews_by_name[dv_name] = dataview
          end
        end
        
        { :dataviews => dataviews, :dataviews_by_name => dataviews_by_name }
      end
      
      def process_datasets_conf( config_dir, datasets_conf )
        datasets = {}
        
        datasets_conf.each do |ds_name|
          ds_location = "#{config_dir}/datasets/#{ds_name}"
          ds_conf     = JSON.load( File.new( "#{ds_location}/config.json", 'r' ) )
          
          ds_conf.recursively_symbolize_keys!
          
          if ds_conf[:enabled]
            ds_conf[:internal_name] = ds_name
            dataset                 = MartSearch::DataSet.new( ds_conf )
            
            if ds_conf[:custom_sort]
              require "#{ds_location}/custom_sort.rb"
              dataset.instance_eval {
                alias :old_sort_results :sort_results
                alias :sort_results :"#{@config[:internal_name].gsub('-','_')}_sort_results"
              }
            end
            
            if ds_conf[:custom_secondary_sort]
              require "#{ds_location}/custom_secondary_sort.rb"
              dataset.instance_eval {
                alias :old_secondary_sort :secondary_sort
                alias :secondary_sort :"#{@config[:internal_name].gsub('-','_')}_secondary_sort"
              }
            end
            
            datasets[ds_name] = dataset
          end
        end
        
        datasets
      end
      
  end
  
end