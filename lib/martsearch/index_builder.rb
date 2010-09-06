module MartSearch
  class IndexBuilder
    include MartSearch
    include MartSearch::Utils
    include MartSearch::IndexBuilderUtils
    
    attr_reader :config, :document_cache
    
    def initialize()
      ms_config           = MartSearch::ConfigBuilder.instance().config
      @config             = ms_config[:index_builder]
      @datasources_config = ms_config[:datasources]
      
      # Create a document cache, and a helper lookup variable
      @file_based_cache      = false
      @document_cache        = {}
      @document_cache_keys   = {}
      @document_cache_lookup = {}

      # Create an ontology cache, this will help prevent needless
      # database queries when indexing ontology terms...
      @ontology_cache = {}
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
        clean_document_cache()
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
        clean_document_cache()
        
        puts " - #{ds}: data processing complete"
      end
      
      puts ""
      puts "- #{@document_cache.keys.first}:"
      ap @document_cache[@document_cache.keys.first]
      
    end
    
    def fetch_datasource( ds )
      ds_conf    = @config[:datasources][ds.to_sym]
      datasource = @datasources_config[ ds_conf[:datasource].to_sym ]
      
      datasource.fetch_all_terms_for_indexing( ds_conf[:indexing] )
    end
    
    def process_results( ds, results )
      ds_conf       = @config[:datasources][ds.to_sym]
      datasource    = @datasources_config[ ds_conf[:datasource] ]
      ds_index_conf = ds_conf[:indexing]
      
      # Extract all of the needed index mapping data from "attribute_map"
      map_data = process_attribute_map( ds_index_conf['attribute_map'] )
      
      # Do we need to cache lookup data?
      unless map_data[:map_to_index_field].to_sym == @config[:schema]['unique_key'].to_sym
        cache_documents_by( map_data[:map_to_index_field] )
      end
      
      # Now loop through the result data...
      results[:data].each do |data_row|
        # First, create a hash out of the data_row and get the primary_attr_value
        data_row_obj       = convert_array_to_hash( results[:headers], data_row )
        primary_attr_value = data_row_obj[ map_data[:primary_attribute] ]
        
        # First check we have something to map back to the index with - if not, move along...
        if primary_attr_value
          # Find us a doc object to map to...
          value_to_look_up_doc_on = extract_value_to_index( map_data[:primary_attribute], map_data[:attribute_map], data_row_obj, datasource )
          doc                     = find_document( map_data[:map_to_index_field], value_to_look_up_doc_on )
          
          # If we can't find one - see if we're allowed to create one
          if doc.nil?
            if ds_index_conf['allow_document_creation']
              set_document( value_to_look_up_doc_on, new_document() )
              doc = get_document( value_to_look_up_doc_on )
            end
          end
          
          # Okay, if we have a doc - process the returned attributes
          if doc
            data_row_obj.each do |attr_name,attr_value|
              # Extract and index our initial data return
              value_to_index = extract_value_to_index( attr_name, map_data[:attribute_map], data_row_obj, datasource )

              if value_to_index and doc[ map_data[:attribute_map][attr_name]["idx"] ]
                if value_to_index.is_a?(Array)
                  value_to_index.each do |value|
                    doc[ map_data[:attribute_map][attr_name]["idx"] ].push( value )
                  end
                else
                  doc[ map_data[:attribute_map][attr_name]["idx"] ].push( value_to_index )
                end
              end

              # Any further metadata to be extracted from here?
              if value_to_index and map_data[:attribute_map][attr_name]["extract"]
                index_extracted_attributes( map_data[:attribute_map][attr_name]["extract"], doc, value_to_index )
              end
            end

            # Do we have any attributes that we need to group together?
            if ds_index_conf["grouped_attributes"]
              index_grouped_attributes( ds_index_conf["grouped_attributes"], doc, data_row_obj, map_data )
            end

            # Any ontology terms to index?
            if ds_index_conf["ontology_terms"]
              index_ontology_terms( ds_index_conf["ontology_terms"], doc, data_row_obj, map_data, @ontology_cache )
            end

            # Finally - save the document to the cache
            doc_primary_key = doc[@config[:schema]["unique_key"].to_sym][0]
            set_document( doc_primary_key, doc )
          end
        end
      end
    end
    
    private
    
    ##
    ## Cache handling functions...
    ##

    # Get a document from the @document_cache
    def get_document( key )
      @document_cache[key]
    end

    # Save a document to the @document_cache
    def set_document( key, value )
      @document_cache_keys[key] = true
      @document_cache[key] = value
    end

    # Utility function to find a specific document (i.e. for a gene), arguments 
    # are the field to search on, and the term to find.
    def find_document( field, search_term )
      if field == @config[:schema]['unique_key'].to_sym
        return get_document( search_term )
      else
        map_term = @document_cache_lookup[field][search_term]
        if map_term
          return get_document( map_term )
        else
          return nil
        end
      end
    end

    # Utility function to cache a lookup for the @document_cache by a given field. 
    # This allows a much faster lookup of documents when we are not linking by 
    # the primary field.
    def cache_documents_by( field )
      @document_cache_lookup[field] = {}

      @document_cache_keys.each_key do |cache_key|
        document = get_document(cache_key)
        document[field].each do |lookup_value|
          @document_cache_lookup[field][lookup_value] = cache_key
        end
      end
    end

    # Utility function to remove any duplication from the document cache.
    def clean_document_cache
      @document_cache_keys.each_key do |cache_key|
        document = get_document(cache_key)

        document.each do |index_field,index_values|
          if index_values.size > 0
            document[index_field] = index_values.uniq
          end

          # If we have multiple value entries in what should be a single valued 
          # field, not the best solution, but just arbitrarily pick the first entry.
          if !@config[:schema]['fields'][index_field.to_s]['multi_valued'] and index_values.size > 1
            new_array = []
            new_array.push(index_values[0])
            document[index_field] = new_array
          end
        end

        set_document( cache_key, document )
      end
    end
    
  end
end