module MartSearch
  module DataSetUtils

    def ikmc_kermits_secondary_sort( search_data )
      
      search_data.each do |key,result_data|
        next if result_data[:'ikmc-kermits'].nil? or result_data[:'ikmc-kermits'].empty?
        next if result_data[:'ikmc-idcc_targ_rep'].nil? or result_data[:'ikmc-idcc_targ_rep'].empty?
        
        # Cache the IKMC Project ID's for clones...
        escell_cache = {}
        result_data[:'ikmc-idcc_targ_rep'].each do |project_name,targ_rep_data|
          [:conditional_clones,:nonconditional_clones].each do |clone_type|
            unless targ_rep_data[clone_type].nil?
              targ_rep_data[clone_type].each do |clone|
                escell_cache[ clone[:escell_clone] ] = clone[:ikmc_project_id]
              end
            end
          end
        end
        
        # Now relate the mice to the cells/projects
        mouse_data = []
        result_data[:'ikmc-kermits'].each do |mouse|
          mouse[:ikmc_project_id]  = escell_cache[ mouse[:escell_clone] ]
          mouse[:mgi_accession_id] = result_data[:index][:mgi_accession_id]
          mouse_data.push(mouse)
        end
        
        result_data[:'ikmc-kermits'] = mouse_data
      end
      
      return search_data
      
    end
    
  end
end
