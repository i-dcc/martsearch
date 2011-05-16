# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def ensembl_mouse_homologs_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        
        sorted_results[joined_attribute] ||= {}
        result_data                        = sorted_results[joined_attribute]
        
        result.keys.each do |key|
          result_data[key] ||= []
          result_data[key].push( result[key] )
        end
      end
      
      # Finally, ensure that the data in the arrays is unique
      sorted_results.each do |key,result_data|
        result_data.each do |field,field_data|
          field_data.uniq! if field_data.is_a?(Array)
        end
      end
      
      return sorted_results
    end
    
  end
end
