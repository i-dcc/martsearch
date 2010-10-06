sorted_results = {}

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
  
  unless result[:url] =~ /^http:/
    result[:url] = "http://img1.sanger.ac.uk/#{result[:url]}"
  end
  
  sorted_results[result[ joined_attribute ]][result[:colony_prefix]][result[:heatmap_group]].push(result)
  
end

sorted_results.each do |colony,data|
  sorted_results[colony][colony].each do |test,images|
    sorted_results[colony][colony][test] = images.sort{ |a,b| a[:order_by] <=> b[:order_by] }
  end
end

return sorted_results
