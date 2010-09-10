module MartSearch
  
  # This class is responsible for building and updating of a Solr search 
  # index for use with a MartSearch application.
  #
  # @author Darren Oakley
  class IndexBuilder
    include MartSearch
    include MartSearch::Utils
    include MartSearch::IndexBuilderUtils
    
    attr_reader :config, :document_cache, :log
    
    def initialize()
      ms_config           = MartSearch::Controller.instance().config
      @config             = ms_config[:index_builder]
      @datasources_config = ms_config[:datasources]
      
      @config[:number_of_docs_per_xml_file] = 1000
      
      @log                 = Logger.new(STDOUT)
      @log.level           = Logger::DEBUG
      @log.datetime_format = "%Y-%m-%d %H:%M:%S "
      
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
      setup_and_move_to_work_directory()
      open_daily_directory( 'datasource_dowloads' )
      
      ds_to_index = @config[:datasources_to_index]
      
      @log.info "Running Primary DataSource Grabs (in serial)..."
      ds_to_index[:primary].each do |ds|
        @log.info " - #{ds}"
        @log.info "   - requesting data"
        
        results = fetch_datasource( ds )
        
        @log.info "   - #{results[:data].size} rows of data returned"
        @log.info "   - processing data"
        
        process_results( ds, results )
        clean_document_cache()
      end
      
      @log.info ""
      @log.info "Running Secondary DataSource Grabs (in parallel)..."
      Parallel.each( ds_to_index[:secondary], :in_threads => 10 ) do |ds|
        @log.info " - #{ds}: requesting data"
        
        results = fetch_datasource( ds )
        
        @log.info " - #{ds}: #{results[:data].size} rows of data returned"
        @log.info " - #{ds}: processing data"
        
        process_results( ds, results )
        clean_document_cache()
        
        @log.info " - #{ds}: data processing complete"
      end
      
      @log.info "- #{@document_cache.keys.first}:"
      ap @document_cache[@document_cache.keys.first]
      
    end
    
    # Queries a given datasource for data to index, stores the returned 
    # data to two files, a Marshal.dump (for computer consumption) and 
    # a CSV file (for human consumption).
    #
    # @param [String] ds The name of the datasource to fetch from
    # @param [Boolean] save_to_disk Save cache files to disk?
    # @return [Hash] A hash containing the :headers (Array) and :data (Array of Arrays) to index
    def fetch_datasource( ds, save_to_disk=true )
      ds_conf    = @config[:datasources][ds.to_sym]
      datasource = @datasources_config[ ds_conf[:datasource].to_sym ]
      
      # results = Marshal.load( File.new( "#{ds}.marshal", 'r' ) )
      results = datasource.fetch_all_terms_for_indexing( ds_conf[:indexing] )
      
      if save_to_disk
        file = File.new( "#{ds}.marshal", "w" )
        file.write( Marshal.dump(results) )
        file.close
        
        CSV.open( "#{ds}.csv", "w" ) do |csv|
          csv << results[:headers]
          results[:data].each do |line|
            csv << line
          end
        end
        
        system "/bin/cp #{ds}.marshal ../current/#{ds}.marshal"
        system "/bin/cp #{ds}.csv ../current/#{ds}.csv"
      end
      
      return results
    end
    
    # Function used to process the data returned from a datasource and build 
    # up the @document_cache.
    #
    # @param [String] ds The name of the datasource that the data is from
    # @param [Hash] results The results hash of data (the return from {#fetch_datasource})
    def process_results( ds, results )
      ds_conf       = @config[:datasources][ds.to_sym]
      datasource    = @datasources_config[ ds_conf[:datasource] ]
      ds_index_conf = ds_conf[:indexing]
      
      # Extract all of the needed index mapping data from "attribute_map"
      map_data = process_attribute_map( ds_index_conf[:attribute_map] )
      
      # Do we need to cache lookup data?
      unless map_data[:map_to_index_field].to_sym == @config[:schema][:unique_key].to_sym
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
            if ds_index_conf[:allow_document_creation]
              set_document( value_to_look_up_doc_on, new_document() )
              doc = get_document( value_to_look_up_doc_on )
            end
          end
          
          # Okay, if we have a doc - process the returned attributes
          if doc
            data_row_obj.each do |attr_name,attr_value|
              # Extract and index our initial data return
              value_to_index = extract_value_to_index( attr_name, map_data[:attribute_map], data_row_obj, datasource )

              if value_to_index and doc[ map_data[:attribute_map][attr_name][:idx] ]
                if value_to_index.is_a?(Array)
                  value_to_index.each do |value|
                    doc[ map_data[:attribute_map][attr_name][:idx] ].push( value )
                  end
                else
                  doc[ map_data[:attribute_map][attr_name][:idx] ].push( value_to_index )
                end
              end

              # Any further metadata to be extracted from here?
              if value_to_index and map_data[:attribute_map][attr_name][:extract]
                index_extracted_attributes( map_data[:attribute_map][attr_name][:extract], doc, value_to_index )
              end
            end

            # Do we have any attributes that we need to group together?
            if ds_index_conf[:grouped_attributes]
              index_grouped_attributes( ds_index_conf[:grouped_attributes], doc, data_row_obj, map_data )
            end

            # Any ontology terms to index?
            if ds_index_conf[:ontology_terms]
              index_ontology_terms( ds_index_conf[:ontology_terms], doc, data_row_obj, map_data, @ontology_cache )
            end

            # Finally - save the document to the cache
            doc_primary_key = doc[@config[:schema][:unique_key].to_sym][0]
            set_document( doc_primary_key, doc )
          end
        end
      end
    end
    
    # Helper function to dump the current @document_cache to disk.
    def save_document_cache
      pwd = Dir.pwd
      open_daily_directory( 'document_cache' )
      
      file = File.new( 'document_cache.marshal', 'w' )
      file.write( Marshal.dump( @document_cache ) )
      file.close
      
      Dir.chdir(pwd)
    end
    
    # Function to build and store the XML files needed to update a Solr 
    # index based on the @document_cache store in this current instance.
    def save_solr_document_xmls
      pwd = Dir.pwd
      open_daily_directory( 'solr_xml' )
      
      batch_size = @config[:number_of_docs_per_xml_file]
      @log.info "Creating Solr XML files (#{batch_size} docs per file)..."

      doc_chunks = @document_cache_keys.keys.chunk( batch_size )
      doc_chunks.each_index do |chunk_number|
        @log.info "[ #{chunk_number + 1} / #{doc_chunks.size} ]"

        doc_names = doc_chunks[chunk_number]
        docs = []
        doc_names.each do |name|
          docs.push( get_document( name ) )
        end

        file = File.open( "solr-xml-#{chunk_number+1}.xml", "w" )
        file.print solr_document_xml(docs)
        file.close
      end
      
      Dir.chdir(pwd)
    end
    
    private
    
      # Get a document from the @document_cache.
      #
      # @param [String] key The unique @document_cache key
      def get_document( key )
        @document_cache[key]
      end

      # Save a document to the @document_cache.
      #
      # @param [String] key The unique @document_cache key
      # @param [Object] value The object to store in the @document_cache
      def set_document( key, value )
        @document_cache_keys[key] = true
        @document_cache[key] = value
      end

      # Utility function to find a specific document (i.e. for a gene).
      #
      # @param [Symbol] field The document field upon which to search within
      # @param [String] search_term The term to search with
      # @return A document object if found or nil
      def find_document( field, search_term )
        if field == @config[:schema][:unique_key].to_sym
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
      #
      # @param [Symbol] field The document field to cache the documents by
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
            if !@config[:schema][:fields][index_field][:multi_valued] and index_values.size > 1
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