module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_abr_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        matcher = result.match(/(\w{4})\//)
        next if matcher.nil?
        
        colony_prefix = matcher[1].upcase
        sorted_results[colony_prefix]                       = {} unless sorted_results[colony_prefix]
        sorted_results[colony_prefix][colony_prefix.to_sym] = [] unless sorted_results[colony_prefix][colony_prefix.to_sym]
        sorted_results[colony_prefix][colony_prefix.to_sym].push(result)
      end
      
      return sorted_results
    end
    
  end
end
