sorted_results = {}

results.sort{ |a,b| "#{a[:tissue]}-#{a[:gender]}" <=> "#{b[:tissue]}-#{b[:gender]}" }.each do |result|
  joined_attribute = @config[:searching][:joined_attribute].to_sym
  
  unless sorted_results[ result[ joined_attribute ] ]
    sorted_results[ result[ joined_attribute ] ] = {}
  end
  
  unless sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ]
    sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ] = {
      :adult  => [],
      :embryo => []
    }
  end
  
  result_data = sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ]
  
  # work out the thumbnail URL (as the one in the mart can be flakey...)
  result[:thumbnail_url] = result[:url].sub("\.(\w+)$","thumb.\1")
  
  if result[:tissue].match("Embryo")
    result_data[:embryo].push(result)
  else
    result_data[:adult].push(result)
  end
  
end

return sorted_results
