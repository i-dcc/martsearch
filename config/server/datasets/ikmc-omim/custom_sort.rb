# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def ikmc_omim_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = []
        end
        
        sorted_results[ result[ joined_attribute ] ].push(result)
      end
      
      sorted_results.each do |key,omim_values|
        sorted_results[key] = omim_values.sort{ |a,b| a[:disorder_name] <=> b[:disorder_name] }
      end
      
      return sorted_results
    end
    
  end
end
