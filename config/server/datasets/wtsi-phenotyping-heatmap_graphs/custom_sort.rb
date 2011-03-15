module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_heatmap_graphs_sort_results( results )
      sorted_results = {}
      
      # remove the 'heatmap_graphs_' prefix from the attributes
      prefix            = /^heatmap_graphs\_/
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
        pipeline          = result[:pipeline]
        colony_prefix     = result[:colony_prefix]
        test_group        = result[:test_group]
        test              = result[:test]
        test_description  = result[:test_description]
        result[:order_by] = result[:order_by].to_i
        
        sorted_results[joined_attribute]                ||= {}
        sorted_results[joined_attribute][colony_prefix] ||= {}
        
        result.delete(:pipeline)
        result.delete(:colony_prefix)
        result.delete(:heatmap_graphs_colony_prefix)
        result.delete(:test_group)
        result.delete(:test)
        result.delete(:test_description)
        
        if test_description.nil?
          # This is a PDF (or collaborator) download - they don't have descriptions in the MIG system
          sorted_results[joined_attribute][colony_prefix][test_group] ||= []
          sorted_results[joined_attribute][colony_prefix][test_group].push(result)
        else
          # 'Regular' published graphs...
          sorted_results[joined_attribute][colony_prefix][test_group]                           ||= {}
          sorted_results[joined_attribute][colony_prefix][test_group][:test_group]                = test_group
          
          sorted_results[joined_attribute][colony_prefix][test_group][test]                     ||= {}
          sorted_results[joined_attribute][colony_prefix][test_group][test][:graphs]            ||= []
          sorted_results[joined_attribute][colony_prefix][test_group][test][:test_description]    = test_description
          sorted_results[joined_attribute][colony_prefix][test_group][test][:pipeline]            = pipeline
          sorted_results[joined_attribute][colony_prefix][test_group][test][:graphs].push(result)
        end
      end
      
      sorted_results.keys.each do |colony_prefix|
        sorted_results[colony_prefix][colony_prefix].each do |test_group,test_group_data|
          next if test_group_data.is_a? Array
          test_group_data.each do |test,test_data|
            next if test == :test_group
            test_data[:graphs].sort!{ |a,b| a[:order_by] <=> b[:order_by] }
          end
        end
        
        sorted_results[colony_prefix].recursively_symbolize_keys!
      end
      
      return sorted_results
    end
    
  end
end
