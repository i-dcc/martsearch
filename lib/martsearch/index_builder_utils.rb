# encoding: utf-8

module MartSearch
  
  # Utility module containing helper funcions for the IndexBuilder class.
  #
  # @author Darren Oakley
  module IndexBuilderUtils
    
    include MartSearch::IndexBuilderUtils::FileSystem
    include MartSearch::IndexBuilderUtils::DocumentCache
    include MartSearch::IndexBuilderUtils::Indexing
    
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
    
  end
end