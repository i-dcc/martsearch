module MartSearch
  module IndexBuilderUtils
    
    def flatten_primary_secondary_datasources( pri_sec_hash )
      [ pri_sec_hash['primary'] + pri_sec_hash['secondary'] ].flatten
    end
    
    def create_new_download_directory( datasource_name )
      
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
            raise StandardError "You have defined more than one attribute to map to the index with! Please check your config..."
          else
            primary_attribute  = mapping_obj["attr"]
            map_to_index_field = mapping_obj["idx"].to_sym
          end
        end

        map[ mapping_obj["attr"] ]        = mapping_obj
        map[ mapping_obj["attr"] ]["idx"] = map[ mapping_obj["attr"] ]["idx"].to_sym
      end

      unless primary_attribute
        raise StandardError "You have not specified an attribute to map to the index with in #{dataset_conf["internal_name"]}!"
      end

      return {
        :attribute_map      => map,
        :primary_attribute  => primary_attribute,
        :map_to_index_field => map_to_index_field
      }
    end
    
  end
end