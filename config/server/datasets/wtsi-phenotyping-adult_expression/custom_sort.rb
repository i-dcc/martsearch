# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_adult_expression_sort_results( results )
      sorted_results = {}
      
      # remove the 'adult_expression_' prefix from the attributes
      prefix            = /^adult_expression\_/
      processed_results = []
      results.each do |result|
        processed_result = {}
        result.each do |key,value|
          processed_result[key] = value if key == @config[:searching][:joined_attribute].to_sym
          processed_result[ key.to_s.gsub(prefix,'').to_sym ] = value
        end
        processed_results.push(processed_result)
      end
      results = processed_results
      
      # Collate all of the info we need from the result data
      
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
