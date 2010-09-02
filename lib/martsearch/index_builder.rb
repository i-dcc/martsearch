module MartSearch
  class IndexBuilder
    attr_reader :config
    
    include MartSearch
    include MartSearch::Utils
    include MartSearch::IndexBuilderUtils
    
    def initialize()
      @config = MartSearch::ConfigBuilder.instance().config[:index_builder]
      @docs   = {}
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
        
        process_results( ds,results )
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
        
        process_results( ds,results )
        
        puts " - #{ds}: data processing complete"
      end
      
    end
    
    def fetch_datasource( ds )
      conf       = @config[:datasources][ds.to_sym]
      datasource = conf[:datasource]
      index_conf = conf[:indexing]
      
      datasource.fetch_all_terms_for_indexing( index_conf['filters'], all_attributes_to_fetch( index_conf['attribute_map'] ) )
      # ds_to_index = flatten_primary_secondary_datasources( @config[:datasources_to_index] )
      # 
      # Parallel.each( ds_to_index, :in_threads => 10 ) do |ds|
      #   conf       = @config[:datasources][ds.to_sym]
      #   datasource = conf[:datasource]
      #   index_conf = conf[:indexing]
      #   
      #   datasource.fetch_all_terms_for_indexing( index_conf['filters'], all_attributes_to_fetch( index_conf['attribute_map'] ) )
      # end
    end
    
    def process_results( ds, results )
      
    end
    
    
    
    
    
  end
end