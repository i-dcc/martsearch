
search_data.each do |key,result_data|
  if result_data[:'ikmc-kermits'] != nil and result_data[:'ikmc-idcc_targ_rep'] != nil
    
    # Cache the IKMC Project ID's for clones...
    escell_cache = {}
    result_data[:'ikmc-idcc_targ_rep'].each do |targ_rep_data|
      [:conditional_clones,:nonconditional_clones].each do |clone_type|
        targ_rep_data[clone_type].each do |clone|
          escell_cache[ clone[:escell_clone] ] = clone[:ikmc_project_id]
        end
      end
    end
    
    # Now relate the mice to the cells/projects
    mouse_data = []
    result_data[:'ikmc-kermits'].each do |mouse|
      mouse[:ikmc_project_id] = escell_cache[ mouse[:escell_clone] ]
      mouse_data.push(mouse)
    end
    
    result_data[:'ikmc-kermits'] = mouse_data
  end
end

return search_data
