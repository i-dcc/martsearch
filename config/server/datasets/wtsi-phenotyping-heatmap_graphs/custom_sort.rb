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
          processed_result[ key.to_s.gsub(prefix,'').to_sym ] = value
        end
        processed_results.push(processed_result)
      end
      results = processed_results
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = {}
        end
        
        unless sorted_results[ result[ joined_attribute ] ][result[:colony_prefix]]
          sorted_results[ result[ joined_attribute ] ][result[:colony_prefix]] = {}
        end
        
        unless sorted_results[result[ joined_attribute ]][result[:colony_prefix]][result[:heatmap_group]]
          sorted_results[result[ joined_attribute ]][result[:colony_prefix]][result[:heatmap_group]] = []
        end
        
        sorted_results[result[ joined_attribute ]][result[:colony_prefix]][result[:heatmap_group]].push(result)
        
      end
      
      sorted_results.each do |colony,data|
        sorted_results[colony][colony].each do |test,images|
          sorted_results[colony][colony][test] = images.sort{ |a,b| a[:order_by] <=> b[:order_by] }
        end
        
        sorted_results[colony].recursively_symbolize_keys!
      end
      
      return sorted_results
    end
    
  end
end
