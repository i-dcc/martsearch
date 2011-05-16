# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_collaborator_data_sort_results( results )
      sorted_results = {}
      
      # remove the 'collaborator_data_' prefix from the attributes
      prefix            = /^collaborator_data\_/
      processed_results = []
      results.each do |result|
        processed_result = {}
        result.each do |key,value|
          processed_result[key] = value if key == @config[:searching][:joined_attribute].to_sym
          processed_result[key.to_s.gsub(prefix,'').to_sym] = value
        end
        processed_results.push(processed_result)
      end
      
      results = processed_results
      
      results.each do |result|
        joined_attribute  = result[ @config[:searching][:joined_attribute].to_sym ]
        colony_prefix     = result[:colony_prefix].to_sym
        result[:test_key] = result[:test].gsub("[\(\)]","").gsub(" ","_").downcase
        test_key          = result[:test_key].to_sym
        
        sorted_results[joined_attribute]                      ||= {}
        sorted_results[joined_attribute][colony_prefix]       ||= {}
        sorted_results[joined_attribute][colony_prefix][test_key] ||= []
        sorted_results[joined_attribute][colony_prefix][test_key].push(result)
      end
      
      return sorted_results
    end
    
  end
end
