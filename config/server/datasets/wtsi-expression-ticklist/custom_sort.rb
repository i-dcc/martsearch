sorted_results = {}

##
## Collate all of the info we need from the result data
##

results.each do |result|
  joined_attribute = @config[:searching][:joined_attribute].to_sym
  
  unless sorted_results[ result[ joined_attribute ] ]
    sorted_results[ result[ joined_attribute ] ] = {}
  end
  
  data = sorted_results[ result[ joined_attribute ] ]
  data[ result[ joined_attribute ].to_sym ] = result
  
end

return sorted_results
