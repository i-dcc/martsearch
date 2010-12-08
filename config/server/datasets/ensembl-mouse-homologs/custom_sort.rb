module MartSearch
  module DataSetUtils
    
    def ensembl_mouse_homologs_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        if sorted_results[ result[ joined_attribute ] ].nil?
          sorted_results[ result[ joined_attribute ] ] = {}
          
          result.keys.each do |key|
            sorted_results[ result[ joined_attribute ] ][key] = []
          end
        end
        
        result_data = sorted_results[ result[ joined_attribute ] ]
        
        result.keys.each do |key|
          result_data[key].push( result[key] )
        end
      end
      
      # Finally, ensure that the data in the arrays is unique
      sorted_results.each do |key,result_data|
        result_data.keys.each do |field|
          if result_data[field].is_a?(Array)
            result_data[field].uniq!
          end
        end
      end
      
      return sorted_results
    end
    
  end
end
