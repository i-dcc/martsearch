module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_hom_viability_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = {}
        end
        
        data = sorted_results[ result[ joined_attribute ] ]
        data[ result[ joined_attribute ].to_sym ] = result
        
      end
      
      return sorted_results
    end
    
  end
end
