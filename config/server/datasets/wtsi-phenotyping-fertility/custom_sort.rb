sorted_results = {}

results.each do |result|
  joined_attribute = @config[:searching][:joined_attribute].to_sym
  
  unless sorted_results[ result[ joined_attribute ] ]
    sorted_results[ result[ joined_attribute ] ] = {}
  end
  
  data = sorted_results[ result[ joined_attribute ] ]
  data[ result[ joined_attribute ] ] = result
  
end

return sorted_results
