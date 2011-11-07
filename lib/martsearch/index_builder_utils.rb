# encoding: utf-8

module MartSearch
  
  # Utility module containing helper funcions for the IndexBuilder class.
  #
  # @author Darren Oakley
  module IndexBuilderUtils
    
    # Utility function to setup the expected IndexBuilder cache directory structure.
    def setup_and_move_to_work_directory
      index_builder_tmpdir = "#{MARTSEARCH_PATH}/tmp/index_builder"
      
      Dir.mkdir(index_builder_tmpdir) unless File.directory?(index_builder_tmpdir)
      Dir.chdir(index_builder_tmpdir)
      
      ['dataset_dowloads','document_cache','solr_xml'].each do |cache_dir|
        Dir.mkdir(cache_dir) unless File.directory?(cache_dir)
        if cache_dir == 'dataset_dowloads'
          Dir.chdir(cache_dir)
          Dir.mkdir('current') unless File.directory?('current')
          Dir.chdir('..')
        end
      end
    end
    
    # Utility function to setup and move the current program into a daily cache directory.
    # 
    # @param [String] cache_dir The type of cache_dir to open [dataset_dowloads / document_cache / solr_xml]
    # @param [Boolean] delete Delete an existing daily cache directory?
    def open_daily_directory( cache_dir, delete=true )
      setup_and_move_to_work_directory()
      Dir.chdir("#{MARTSEARCH_PATH}/tmp/index_builder/#{cache_dir}")
      daily_dir = "daily_#{Date.today.to_s}"
      
      system "/bin/rm -r #{daily_dir}" if File.directory?(daily_dir) and delete
      Dir.mkdir(daily_dir) if delete or !File.directory?(daily_dir)

      # clean up old daily directories
      directories = Dir.glob("daily_*").sort
      while directories.size > 5
        system("/bin/rm -rf '#{directories.shift}'")
      end
      
      Dir.chdir(daily_dir)
    end
    
    # Utility function to create a new Lucene/Solr document construct.
    # 
    # @return [Hash] A hash object representing an empty Solr document entry
    def new_document
      index_config = MartSearch::Controller.instance().config[:index]
      
      # Work out fields to ignore - these will be auto populated by Solr
      copy_fields = []
      index_config[:schema][:copy_fields].each do |copy_field|
        copy_fields.push( copy_field[:dest] )
      end

      doc = {}
      index_config[:schema][:fields].each do |key,detail|
        doc[ key.to_sym ] = [] unless copy_fields.include?(key.to_s)
      end
      return doc
    end
    
    # Utility function to process the attribute_map configuration into 
    # something we can use to map dataset results to our index configuration.
    # 
    # @param [Hash] attribute_map The attribute_map configuration for a given dataset
    # @return [Hash] A hash contining the processed :attribute_map, :primary_attribute (of the dataset) and the :map_to_index_field (the index field used to map this data into the index)
    def process_attribute_map( attribute_map )
      map                = {}
      primary_attribute  = nil
      map_to_index_field = nil
      
      # Extract all of the needed index mapping data from the "attribute_map"
      # - The "attribute_map" defines how the biomart attributes relate to the index "fields"
      # - The "primary_attribute" is the biomart attribute used to associate a set of biomart 
      #   results to an index "doc" - using the "map_to_index_field" field as the link.
      attribute_map.each do |mapping_obj|
        if mapping_obj[:use_to_map]
          if primary_attribute
            raise "You have defined more than one attribute to map to the index with! Please check your config..."
          else
            primary_attribute  = mapping_obj[:attr]
            map_to_index_field = mapping_obj[:idx].to_sym
          end
        end

        map[ mapping_obj[:attr] ]       = mapping_obj
        map[ mapping_obj[:attr] ][:idx] = map[ mapping_obj[:attr] ][:idx].to_sym
      end

      unless primary_attribute
        raise "You have not specified an attribute to map to the index with! Please check your config..."
      end

      return {
        :attribute_map      => map,
        :primary_attribute  => primary_attribute,
        :map_to_index_field => map_to_index_field
      }
    end
    
    # Utility function to determine what data values we need to 
    # add to the index given the dataset configuration.
    # 
    # @param [String] attr_name The name of the dataset attribute to process
    # @param [Hash] attribute_map The processed :attribute_map configuration (the value of :attribute_map returned from {#process_attribute_map})
    # @param [Hash] data_row_obj Hash representing the row of dataset data to process
    # @param [Biomart::Dataset] mart_ds A Biomart::Dataset object - required if the attribute_map uses the 'index_attr_name' option
    # @return [nil/String/Array] Can return nil (if there is no data to index), a String (single value to index), or an Array (if there are multiple values to index)
    def extract_value_to_index( attr_name, attribute_map, data_row_obj, mart_ds=nil )
      options         = attribute_map[attr_name]
      value_to_index  = data_row_obj[attr_name]

      if options[:if_attr_equals]
        unless options[:if_attr_equals].include?( value_to_index )
          value_to_index = nil
        end
      end

      if options[:index_attr_name] and mart_ds != nil
        if value_to_index
          mart_attributes = mart_ds.attributes()
          if options[:index_attr_display_name_only]
            value_to_index  = mart_attributes[attr_name].display_name
          else
            value_to_index  = [ attr_name, mart_attributes[attr_name].display_name ]
          end
        end
      end

      if options[:if_other_attr_indexed]
        other_attr       = options[:if_other_attr_indexed]
        other_attr_value = data_row_obj[ other_attr ]

        unless extract_value_to_index( other_attr, attribute_map, data_row_obj )
          value_to_index = nil
        end
      end

      unless value_to_index.nil?
        if options[:attr_prepend]
          value_to_index = "#{options[:attr_prepend]}#{value_to_index}"
        end
        if options[:attr_append]
          value_to_index = "#{value_to_index}#{options[:attr_append]}"
        end
      end
      
      return value_to_index
    end
    
    # Utility function to handle the extraction of metadata from indexed values,
    # (i.e. MP terms in comments).
    # 
    # @param [Hash] extract_conf The configuration object supplying the "regexp" to use and the "idx" field to send our extracted data to
    # @param [Hash] doc The Solr document object to inject any indexable data into
    # @param [String/Array] value_to_index The return from {#extract_value_to_index}
    def index_extracted_attributes( extract_conf, doc, value_to_index )
      regexp  = Regexp.new( extract_conf[:regexp] )
      matches = false

      if value_to_index.is_a?(Array)
        value_to_index.each do |value|
          matches = regexp.match( value )
          if matches then doc[ extract_conf[:idx].to_sym ].push( matches[0] ) end
        end
      else
        matches = regexp.match( value_to_index )
        if matches then doc[ extract_conf[:idx].to_sym ].push( matches[0] ) end
      end
    end
    
    # Utility function to handle the indexing of grouped attributes
    # 
    # @param [Hash] grouped_attr_conf The configuration object supplying the "attrs" to concatenate, the "using" argument (optional), and the "idx" field to send our data to
    # @param [Hash] doc The Solr document object to inject any indexable data into
    # @param [Hash] data_row_obj Hash representing the row of dataset data to process
    # @param [Hash] map_data The complete processed attribute_map config (return from {#process_attribute_map})
    # @param [Biomart::Dataset] mart_ds A Biomart::Dataset object
    def index_grouped_attributes( grouped_attr_conf, doc, data_row_obj, map_data, mart_ds=nil )
      grouped_attr_conf.each do |group|
        attrs = []
        group[:attrs].each do |attribute|
          value_to_index = extract_value_to_index( attribute, map_data[:attribute_map], { attribute => data_row_obj[attribute] }, mart_ds )

          # When we have an attribute that we're indexing the attribute NAME 
          # of, we get an array returned...  We can only pick one, so let's pick 
          # the biomart display name...
          if value_to_index.is_a?(Array) then value_to_index = value_to_index.pop() end

          if value_to_index and !value_to_index.gsub(" ","").empty?
            attrs.push(value_to_index)
          end
        end

        # Only index when we have values for ALL the grouped attributes
        if !attrs.empty? and ( attrs.size() === group[:attrs].size() )
          join_str = group[:using] ? group[:using] : "||"
          doc[ group[:idx].to_sym ].push( attrs.join(join_str) )
        end
      end
    end
    
    # Utility function to handle the indexing of ontology terms.
    # 
    # @param [Hash] ontology_term_conf The configuration object defining how the ontology data should be indexed
    # @param [Hash] doc The Solr document object to inject any indexable data into
    # @param [Hash] data_row_obj Hash representing the row of dataset data to process
    # @param [Hash] map_data The complete processed attribute_map config (return from {#process_attribute_map})
    # @param [Hash] cache A cache object to store data about already retrieved ontology terms (this is for optimization as generating the OntologyTerm objects is expensive)
    def index_ontology_terms( ontology_term_conf, doc, data_row_obj, map_data, cache )
      ontology_term_conf.each do |term_conf|
        attribute      = term_conf[:attr]
        value_to_index = extract_value_to_index( attribute, map_data[:attribute_map], { attribute => data_row_obj[attribute] } )
        
        if value_to_index && !value_to_index.gsub(" ","").empty?
          cached_data = cache[value_to_index]
          if cached_data != nil
            index_ontology_terms_from_cache( doc, term_conf, cached_data )
          else
            index_ontology_terms_from_fresh( doc, term_conf, value_to_index, cache )
          end
        end
      end
    end
    
    # Utility function to split out and index ontology terms concatenated into a single string.
    # 
    # @param [Hash] ontology_term_conf The configuration object defining how the ontology data should be indexed
    # @param [Hash] doc The Solr document object to inject any indexable data into
    # @param [Hash] data_row_obj Hash representing the row of dataset data to process
    # @param [Hash] map_data The complete processed attribute_map config (return from {#process_attribute_map})
    # @param [Hash] cache A cache object to store data about already retrieved ontology terms (this is for optimization as generating the OntologyTerm objects is expensive)
    def index_concatenated_ontology_terms( concat_ont_term_conf, doc, data_row_obj, map_data, cache )
      attribute       = concat_ont_term_conf[:attr]
      split_delimiter = concat_ont_term_conf[:split_on] || ", "
      value_to_index  = extract_value_to_index( attribute, map_data[:attribute_map], { attribute => data_row_obj[attribute] } )
      
      if value_to_index && !value_to_index.gsub(" ","").empty?
        terms_to_test = value_to_index.split(split_delimiter)
        terms_to_test.each do |test_term|
          concat_ont_term_conf[:ontologies].each do |ontology_matcher,ontology_conf|
            regexp  = Regexp.new( ontology_matcher.to_s, Regexp::IGNORECASE )
            matcher = test_term.upcase.match( regexp )
            
            unless matcher.nil?
              matched_term = matcher.to_s
              cached_data  = cache[matched_term]
              term_conf    = {
                :attr => attribute,
                :idx  => {
                  :term       => ontology_conf[:term],
                  :term_name  => ontology_conf[:term_name],
                  :breadcrumb => ontology_conf[:breadcrumb]
                }
              }
              
              if cached_data != nil
                index_ontology_terms_from_cache( doc, term_conf, cached_data )
              else
                index_ontology_terms_from_fresh( doc, term_conf, matched_term, cache )
              end
            end
          end
        end
      end
    end
    
    # Utility function to create the actual XML markup for a collection 
    # of solr document constructs.
    #
    # @param [Array] docs An array of solr document objects
    # @return [String] The constructed XML documents
    def solr_document_xml( docs )
      solr_xml = ""
      xml      = Builder::XmlMarkup.new( :target => solr_xml, :indent => 2 )

      xml.add {
        docs.each do |doc|
          xml.doc {
            doc.each do |field,field_terms|
              field_terms.each do |term|
                xml.field( term, :name => field )
              end
            end
          }
        end
      }

      return solr_xml
    end
    
    private
    
      # Helper function for indexing ontology terms we haven't seen before
      def index_ontology_terms_from_fresh( doc, term_conf, value_to_index, cache )
        begin
          ontolo_term    = OLS.find_by_id( value_to_index )
          terms_to_index = []
          names_to_index = []

          unless ontolo_term.parents.nil?
            terms_to_index = ontolo_term.all_parent_ids
            names_to_index = ontolo_term.all_parent_names
          end
          
          terms_to_index.push( ontolo_term.term_id )
          names_to_index.push( ontolo_term.term_name )
          
          # Remove the "top-level" ontology name - there's no need to have this 
          # in the search index...
          names_to_index.shift

          # Store these terms to the cache for future use...
          data_to_cache         = { :term => terms_to_index, :term_name => names_to_index }
          cache[value_to_index] = data_to_cache

          # Write the data to the doc...
          index_ontology_terms_from_cache( doc, term_conf, data_to_cache )
        rescue OLS::TermNotFoundError => error
          # The ontology term couldn't be found - no worries, just move on...
        end
      end
    
      # Helper function for indexing ontology terms we have in the cache
      def index_ontology_terms_from_cache( doc, term_conf, cached_data )
        [:term,:term_name].each do |term_or_name|
          cached_data[term_or_name].each do |target|
            doc[ term_conf[:idx][term_or_name].to_sym ].push( target )
          end
          doc[ term_conf[:idx][:breadcrumb].to_sym ].push( cached_data[term_or_name].join(" | ") )
        end
      end
      
  end
end