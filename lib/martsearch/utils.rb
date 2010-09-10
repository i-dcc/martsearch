module MartSearch
  
  # Utility module containing generic helper funcions.
  #
  # @author Darren Oakley
  module Utils
    
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
        
        if dv_conf['enabled']
          dv_conf['internal_name'] = dv_name
          dv_conf['stylesheet']    = get_file_as_string("#{dv_location}/stylesheet.css") if dv_conf['custom_css']
          dv_conf['javascript']    = get_file_as_string("#{dv_location}/javascript.js") if dv_conf['custom_js']
          
          dataviews.push( dv_conf )
          dataviews_by_name[dv_name] = dv_conf
        end
      end
      server_conf['dataviews']         = dataviews
      server_conf['dataviews_by_name'] = dataviews_by_name
      
      server_conf.recursively_symbolize_keys!
      
      return server_conf
    end
    
    # Utility function to convert an array of data to a hash, 
    # given a set of headers to key the hash by (they will be matched
    # by the array index).
    #
    # @param [Array] headers This array will become the hash keys
    # @param [Array] data This array will become the hash values
    # @return [Hash] The resulting converted hash
    def convert_array_to_hash( headers, data )
      converted_data = {}
      headers.each_index do |position|
        if data[position].nil? or data[position] === ""
          converted_data[ headers[position] ] = nil
        else
          converted_data[ headers[position] ] = data[position]
        end

      end
      return converted_data
    end
    
    # Utility function to read in a file and return the files 
    # entire contents as a string.
    #
    # @param [String] filename The name of the file to read
    # @return [String] The contents of the file
    def get_file_as_string(filename)
      data = ''
      f = File.open( filename, "r" ) 
      f.each_line do |line|
        data += line
      end
      return data
    end
    
  end
end