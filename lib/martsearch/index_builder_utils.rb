module MartSearch
  module IndexBuilderUtils
    
    def flatten_primary_secondary_datasources( pri_sec_hash )
      [ pri_sec_hash['primary'] + pri_sec_hash['secondary'] ].flatten
    end
    
    def all_attributes_to_fetch( attr_map )
      attrs = []
      attr_map.each do |map|
        attrs.push(map["attr"])
      end
      return attrs.uniq
    end
    
    def create_new_download_directory( datasource_name )
      
    end
    
  end
end