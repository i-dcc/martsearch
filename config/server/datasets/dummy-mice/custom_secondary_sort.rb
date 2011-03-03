module MartSearch
  module DataSetUtils

    def dummy_mice_secondary_sort( search_data )
      
      search_data.each do |key,result_data|
        kermits = result_data[:'ikmc-kermits'] ||= []
        emma    = result_data[:'emma-strains'] ||= {}
        
        if kermits.empty? and emma.empty?
          result_data.delete(:'ikmc-kermits')
          result_data.delete(:'emma-strains')
          result_data.delete(:'dummy-mice')
          next
        end
        
        
        
        
      end
      
      return search_data
      
    end
    
  end
end