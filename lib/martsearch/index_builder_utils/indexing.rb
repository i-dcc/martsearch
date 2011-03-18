module MartSearch
  module IndexBuilderUtils
    
    # Helper module containing all of the functions for carrying out the 
    # preparation and formating of data to be indexed.
    # 
    # @author Darren Oakley
    module Indexing
      
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
              regexp = Regexp.new(ontology_matcher.to_s)
              
              unless test_term.match(regexp).nil?
                cached_data = cache[test_term]
                term_conf   = {
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
                  index_ontology_terms_from_fresh( doc, term_conf, test_term, cache )
                end
              end
            end
          end
        end
      end
      
      private
        
        # Helper function for indexing ontology terms we haven't seen before
        def index_ontology_terms_from_fresh( doc, term_conf, value_to_index, cache )
          ontology_cache = MartSearch::Controller.instance().ontology_cache
          
          begin
            ontolo_term    = ontology_cache.fetch_just_parents( value_to_index )
            terms_to_index = []
            names_to_index = []
            
            unless ontolo_term.parentage.nil?
              terms_to_index = ontolo_term.parentage.map { |term| term.term }
              names_to_index = ontolo_term.parentage.map { |term| term.term_name }
            end
            
            terms_to_index.push( ontolo_term.term )
            names_to_index.push( ontolo_term.term_name )
            
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
              doc[ term_conf[:idx][term_or_name].to_sym ].push( target )
            end
            doc[ term_conf[:idx][:breadcrumb].to_sym ].push( cached_data[term_or_name].join(" | ") )
          end
        end
      
    end
    
  end
end