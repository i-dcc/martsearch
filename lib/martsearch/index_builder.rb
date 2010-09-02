module MartSearch
  class IndexBuilder
    include MartSearch
    include MartSearch::Utils
    include MartSearch::IndexBuilderUtils
    
    attr_reader :config
    
    def initialize()
      @ms_config            = MartSearch::ConfigBuilder.instance().config
      @config               = @ms_config[:index_builder]
      @datasources_config   = @ms_config[:datasources]
      @docs                 = {}
    end
    
    def build_index()
      ds_to_index = @config[:datasources_to_index]
      
      puts "Running Primary DataSource Grabs (in serial)..."
      ds_to_index['primary'].each do |ds|
        puts " - #{ds}"
        puts "   - requesting data"
        
        # results = fetch_datasource( ds )
        # file = File.new( "#{ds}.marshal", "w" )
        # file.write( Marshal.dump(results) )
        # file.close
        
        results = Marshal.load( File.new( "#{ds}.marshal", 'r' ) )
        
        puts "   - #{results[:data].size} rows of data returned"
        puts "   - processing data"
        
        process_results( ds, results )
      end
      
      puts ""
      puts "Running Secondary DataSource Grabs (in parallel)..."
      Parallel.each( ds_to_index['secondary'], :in_threads => 10 ) do |ds|
        puts " - #{ds}: requesting data"
        
        # results = fetch_datasource( ds )
        # file = File.new( "#{ds}.marshal", "w" )
        # file.write( Marshal.dump(results) )
        # file.close
        
        results = Marshal.load( File.new( "#{ds}.marshal", 'r' ) )
        
        puts " - #{ds}: #{results[:data].size} rows of data returned"
        puts " - #{ds}: processing data"
        
        process_results( ds, results )
        
        puts " - #{ds}: data processing complete"
      end
      
    end
    
    def fetch_datasource( ds )
      ds_conf    = @config[:datasources][ds.to_sym]
      datasource = @datasources_config[ ds_conf[:datasource] ]
      
      datasource.fetch_all_terms_for_indexing( ds_conf[:indexing] )
    end
    
    def process_results( ds, results )
      ds_index_conf = @config[:datasources][ds.to_sym][:indexing]
      
      # Extract all of the needed index mapping data from "attribute_map"
      map_data = process_attribute_map( ds_index_conf['attribute_map'] )
      
      # Now loop through the result data...
      results[:data].each do |data_row|
        # First, create a hash out of the data_row and get the primary_attr_value
        data_row_obj       = convert_array_to_hash( results[:headers], data_row )
        primary_attr_value = data_row_obj[ map_data[:primary_attribute] ]
        
        
        
        
      end
    end
    
    
    
    
    
  end
end