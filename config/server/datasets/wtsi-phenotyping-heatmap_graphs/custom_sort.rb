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
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        colony_prefix    = result[:colony_prefix]
        heatmap_group    = result[:heatmap_group]
        protocol         = result[:heatmap_group_description]
        
        result.delete(:colony_prefix)
        result.delete(:heatmap_graphs_colony_prefix)
        result.delete(:heatmap_group)
        result.delete(:heatmap_group_description)
        
        sorted_results[joined_attribute]                                         ||= {}
        sorted_results[joined_attribute][colony_prefix]                          ||= {}
        sorted_results[joined_attribute][colony_prefix][heatmap_group]           ||= {}

        sorted_results[joined_attribute][colony_prefix][heatmap_group][:heatmap_group] = heatmap_group
        
        sorted_results[joined_attribute][colony_prefix][heatmap_group][protocol] ||= []
        sorted_results[joined_attribute][colony_prefix][heatmap_group][protocol].push(result)
      end
      
      sorted_results.keys.each do |colony_prefix|
        sorted_results[colony_prefix][colony_prefix].keys.each do |heatmap_group|
          sorted_results[colony_prefix][colony_prefix][heatmap_group].keys.each do |protocol|
            next if protocol == :heatmap_group
            sorted_results[colony_prefix][colony_prefix][heatmap_group][protocol].sort!{ |a,b| a[:order_by] <=> b[:order_by] }
          end
        end
        
        sorted_results[colony_prefix].recursively_symbolize_keys!
      end
      
      return sorted_results
    end
    
  end
end
