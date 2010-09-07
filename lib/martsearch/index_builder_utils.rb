module MartSearch
  module IndexBuilderUtils

    def setup_and_move_to_work_directory
      index_builder_tmpdir = "#{MARTSEARCH_PATH}/tmp/index_builder"
      
      Dir.mkdir(index_builder_tmpdir) unless File.directory?(index_builder_tmpdir)
      Dir.chdir(index_builder_tmpdir)
      
      ['datasource_dowloads','document_cache','solr_xml'].each do |cache_dir|
        Dir.mkdir(cache_dir) unless File.directory?(cache_dir)
        Dir.chdir(cache_dir)
        
        Dir.mkdir('current')                  unless File.directory?('current')
        Dir.mkdir("daily_#{Date.today.to_s}") unless File.directory?("daily_#{Date.today.to_s}")
        
        # clean up old daily directories
        directories = Dir.glob("daily_*").sort
        while directories.size > 5
          system("/bin/rm -rf '#{directories.shift}'")
        end
        
        Dir.chdir('..')
      end
    end
    
    # Utility function to create a new Lucene/Solr document construct.
    def new_document()
      index_builder_config = MartSearch::ConfigBuilder.instance().config[:index_builder]
      
      # Work out fields to ignore - these will be auto populated by Solr
      copy_fields = []
      index_builder_config[:schema]['copy_fields'].each do |copy_field|
        copy_fields.push( copy_field['dest'] )
      end

      doc = {}
      index_builder_config[:schema]['fields'].each do |key,detail|
        doc[ key.to_sym ] = [] unless copy_fields.include?(key)
      end
      return doc
    end
    
    # Utility function to process the attribute_map configuration into 
    # something we can use to map biomart results to our index configuration.
    def process_attribute_map( attribute_map )
      map                = {}
      primary_attribute  = nil
      map_to_index_field = nil

      # Extract all of the needed index mapping data from the "attribute_map"
      # - The "attribute_map" defines how the biomart attributes relate to the index "fields"
      # - The "primary_attribute" is the biomart attribute used to associate a set of biomart 
      #   results to an index "doc" - using the "map_to_index_field" field as the link.
      attribute_map.each do |mapping_obj|
        if mapping_obj["use_to_map"]
          if primary_attribute
            raise "You have defined more than one attribute to map to the index with! Please check your config..."
          else
            primary_attribute  = mapping_obj["attr"]
            map_to_index_field = mapping_obj["idx"].to_sym
          end
        end

        map[ mapping_obj["attr"] ]        = mapping_obj
        map[ mapping_obj["attr"] ]["idx"] = map[ mapping_obj["attr"] ]["idx"].to_sym
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
    def extract_value_to_index( attr_name, attribute_map, data_row_obj, mart_ds=nil )
      options         = attribute_map[attr_name]
      value_to_index  = data_row_obj[attr_name]

      if options["if_attr_equals"]
        unless options["if_attr_equals"].include?( value_to_index )
          value_to_index = nil
        end
      end

      if options["index_attr_name"] and mart_ds != nil
        if value_to_index
          mart_attributes = mart_ds.attributes()
          if options["index_attr_display_name_only"]
            value_to_index  = mart_attributes[attr_name].display_name
          else
            value_to_index  = [ attr_name, mart_attributes[attr_name].display_name ]
          end
        end
      end

      if options["if_other_attr_indexed"]
        other_attr       = options["if_other_attr_indexed"]
        other_attr_value = data_row_obj[ other_attr ]

        unless extract_value_to_index( other_attr, attribute_map, data_row_obj )
          value_to_index = nil
        end
      end

      unless value_to_index.nil?
        if options["attr_prepend"]
          value_to_index = "#{options["attr_prepend"]}#{value_to_index}"
        end
        if options["attr_append"]
          value_to_index = "#{value_to_index}#{options["attr_append"]}"
        end
      end

      return value_to_index
    end
    
    # Utility function to handle the extraction of metadata from indexed values,
    # (i.e. MP terms in comments)
    def index_extracted_attributes( extract_conf, doc, value_to_index )
      regexp  = Regexp.new( extract_conf["regexp"] )
      matches = false

      if value_to_index.is_a?(Array)
        value_to_index.each do |value|
          matches = regexp.match( value )
          if matches then doc[ extract_conf["idx"].to_sym ].push( matches[0] ) end
        end
      else
        matches = regexp.match( value_to_index )
        if matches then doc[ extract_conf["idx"].to_sym ].push( matches[0] ) end
      end
    end
    
    # Utility function to handle the indexing of grouped attributes
    def index_grouped_attributes( grouped_attr_conf, doc, data_row_obj, map_data )
      grouped_attr_conf.each do |group|
        attrs = []
        group["attrs"].each do |attribute|
          value_to_index = extract_value_to_index( attribute, map_data[:attribute_map], { attribute => data_row_obj[attribute] } )

          # When we have an attribute that we're indexing the attribute NAME 
          # of, we get an array returned...  We can only pick one, so let's pick 
          # the biomart display name...
          if value_to_index.is_a?(Array) then value_to_index = value_to_index.pop() end

          if value_to_index and !value_to_index.gsub(" ","").empty?
            attrs.push(value_to_index)
          end
        end

        # Only index when we have values for ALL the grouped attributes
        if !attrs.empty? and ( attrs.size() === group["attrs"].size() )
          join_str = group["using"] ? group["using"] : "||"
          doc[ group["idx"].to_sym ].push( attrs.join(join_str) )
        end
      end
    end
    
    # Utility function to handle the indexing of ontology terms
    def index_ontology_terms( ontology_term_conf, doc, data_row_obj, map_data, cache )
      ontology_term_conf.each do |term_conf|
        attribute      = term_conf["attr"]
        value_to_index = extract_value_to_index( attribute, map_data[:attribute_map], { attribute => data_row_obj[attribute] } )

        if value_to_index and !value_to_index.gsub(" ","").empty?
          cached_data = cache[value_to_index]
          if cached_data != nil
            index_ontology_terms_from_cache( doc, term_conf, cached_data )
          else
            index_ontology_terms_from_fresh( doc, term_conf, value_to_index, cache )
          end
        end
      end
    end
    
    # Helper function for indexing ontology terms we haven't seen before
    def index_ontology_terms_from_fresh( doc, term_conf, value_to_index, cache )
      begin
        ontolo_term  = MartSearch::OntologyTerm.new( value_to_index )
        parent_terms = ontolo_term.parentage

        terms_to_index = [ ontolo_term.term ]
        names_to_index = [ ontolo_term.term_name ]

        unless parent_terms.nil?
          parent_terms.each do |term|
            terms_to_index.unshift( term.term )
            names_to_index.unshift( term.term_name )
          end
        end

        # Remove the "top-level" ontology name - there's no need to have this 
        # in the search index...
        names_to_index.shift

        # Store these terms to the cache for future use...
        data_to_cache         = { :term => terms_to_index, :term_name => names_to_index }
        cache[value_to_index] = data_to_cache

        # Write the data to the doc...
        index_ontology_terms_from_cache( doc, term_conf, data_to_cache )
      rescue OntologyTermNotFoundError => error
        # The ontology term couldn't be found - no worries, just move on...
      end
    end
    
    # Helper function for indexing ontology terms we have in the cache
    def index_ontology_terms_from_cache( doc, term_conf, cached_data )
      [:term,:term_name].each do |term_or_name|
        cached_data[term_or_name].each do |target|
          doc[ term_conf["idx"][term_or_name.to_s].to_sym ].push( target )
        end
        doc[ term_conf["idx"]["breadcrumb"].to_sym ].push( cached_data[term_or_name].join(" | ") )
      end
    end
    
  end
end