sorted_results = {}

results.each do |result|
  joined_attribute = @config[:searching][:joined_attribute].to_sym
  
  unless sorted_results[ result[ joined_attribute ] ]
    sorted_results[ result[ joined_attribute ] ] = {}
  end
  
  result_data = sorted_results[ result[ joined_attribute ] ]
  
  unless result_data[ result[:ass_assay_id_key] ]
    result_data[ result[:ass_assay_id_key] ] = {}
  end
  
  result_data_for_assay = result_data[ result[:ass_assay_id_key] ]
  
  result_data_for_assay[:assay_id]          = result[:ass_assay_id_key]
  result_data_for_assay[:assay_image_count] = result[:assay_image_count]
  
  unless result_data_for_assay[:annotations]
    result_data_for_assay[:annotations] = {}
  end
  
  emap_id = result[:emap_id]
  emap_id = "EMAP:#{emap_id}" unless emap_id =~ /EMAP/
  
  result_data_for_assay[:annotations][emap_id.to_sym] = {
    :ann_pattern  => result[:ann_pattern],
    :ann_strength => result[:ann_strength]
  }
  
end

# Now sort the annotations into order of the ones with more 
# annotations at the top...
results_to_return = {}

sorted_results.each do |id,the_results|
  assays = []
  the_results.each do |assay_id,assay_data|
    assays.push(assay_data)
  end
  results_to_return[id] = assays.sort_by { |a| -1*(a[:annotations].size) }
end

# Then finally calculate the EMAP ontology trees for the annotations...
ontology_cache = MartSearch::Controller.instance().ontology_cache
sorted_results.each do |id,assays|
  assays.each do |assay_id,assay_data|
    emap_ids  = assay_data[:annotations].keys.map { |emap_id| emap_id.to_s }
    emap_tree = ontology_cache.fetch_just_parents( emap_ids.shift )

    emap_ids.each do |emap_id|
      new_tree  = ontology_cache.fetch_just_parents( emap_id )
      emap_tree = emap_tree.merge( new_tree )
    end
    
    assay_data[:emap_tree] = emap_tree.to_json
    assays[assay_id] = assay_data
  end
  
  sorted_results[id] = assays
end

return results_to_return
