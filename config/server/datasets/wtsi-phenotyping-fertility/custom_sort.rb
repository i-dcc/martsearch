module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_fertility_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = {}
        end
        
        unless sorted_results[ result[ joined_attribute ] ][ result[ joined_attribute ].to_sym ]
          sorted_results[ result[ joined_attribute ] ][ result[ joined_attribute ].to_sym ] = []
        end
        
        data = sorted_results[ result[ joined_attribute ] ][ result[ joined_attribute ].to_sym ]
        data.push(result)
        
      end
      
      return sorted_results
    end
    
  end
end
