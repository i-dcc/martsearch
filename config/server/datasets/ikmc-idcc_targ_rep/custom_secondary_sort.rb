module MartSearch
  module DataSetUtils

    def ikmc_idcc_targ_rep_secondary_sort( search_data )
      
      status_order = {
        "On Hold"                                                 => 1,
        "Transferred to NorCOMM"                                  => 2,
        "Transferred to KOMP"                                     => 3,
        "Withdrawn From Pipeline"                                 => 4,
        "Design Requested"                                        => 5,
        "Alternate Design Requested"                              => 6,
        "VEGA Annotation Requested"                               => 7,
        "Design Not Possible"                                     => 8,
        "Design Completed"                                        => 9,
        "Regeneron Selected"                                      => 10,
        "Design Finished/Oligos Ordered"                          => 11,
        "Parental BAC Obtained"                                   => 12,
        "Vector Construction in Progress"                         => 13,
        "Vector Unsuccessful - Project Terminated"                => 14,
        "Vector Unsuccessful - Alternate Design in Progress"      => 15,
        "Vector - Initial Attempt Unsuccessful"                   => 16,
        "Vector Complete"                                         => 17,
        "Vector - DNA Not Suitable for Electroporation"           => 18,
        "Targeting Vector QC Completed"                           => 19,
        "Vector Electroporated into ES Cells"                     => 20,
        "ES Cells - Electroporation in Progress"                  => 21,
        "ES Cells - Electroporation Unsuccessful"                 => 22,
        "ES Cells - No QC Positives"                              => 23,
        "ES Cells - Targeting  Unsuccessful - Project Terminated" => 24,
        "ES Cells - Targeting Confirmed"                          => 25,
        "ES cell colonies picked"                                 => 26,
        "ES cell colonies screened / QC no positives"             => 27,
        "ES cell colonies screened / QC one positive"             => 28,
        "ES cell colonies screened / QC positives"                => 29,
        "Mice - Microinjection in progress"                       => 30,
        "Mice - Germline transmission"                            => 31,
        "Mice - Genotype confirmed"                               => 32,
        "ES Cell Clone Microinjected"                             => 33,
        "Germline Transmission Achieved"                          => 34
      }
      
      #
      # Sort projects on products availability (mice -> cells -> vectors -> nothing)
      #
      search_data.each do |key,result_data|
        #
        # Sorting on mice, cells and vectors availability
        # (mouse availability is retrieved from 'ikmc-dcc-knockout_attempts')
        #
        projects_with = { :mice => [], :clones => [], :vectors => [], :nothing => [] }
        
        unless result_data[:'ikmc-idcc_targ_rep'].nil?
          result_data[:'ikmc-idcc_targ_rep'].each do |pipeline, pipeline_projects|
            
            pipeline_projects_with = { :mice => [], :clones => [], :vectors => [] }
            
            pipeline_projects.each do |project_key, project|
              
              # Get mice availability
              if result_data[:'ikmc-dcc-knockout_attempts']
                ikmc_projects   = result_data[:'ikmc-dcc-knockout_attempts'][pipeline]
                ikmc_project_id = project[:ikmc_project_id]
          
                if ikmc_projects and ikmc_projects[ikmc_project_id]
                  project[:mouse_available] = ikmc_projects[ikmc_project_id][:mouse_available]
                  project[:ensembl_gene_id] = ikmc_projects[:ensembl_gene_id]
                end
              end
              
              # Sort the projects into the correct baskets...
              if project[:mouse_available] == '1'
                pipeline_projects_with[:mice].push( project )
              elsif project[:escell_available] == '1' # From idcc-targ_rep custom sort
                pipeline_projects_with[:clones].push( project )
              elsif project[:vector_available] == '1' # From idcc-targ_rep custom sort
                pipeline_projects_with[:vectors].push( project )
              end
            end
            
            # Now stamp the most advanced projects with the 'display' flag
            display_stamped = false
            ordered_groups  = [ :mice, :clones, :vectors ]
            ordered_groups.each do |group|
              project_group = pipeline_projects_with[group]
              next if display_stamped
              unless project_group.empty?
                project_group.each do |project|
                  project[:display] = true
                end
                display_stamped = true
              end
            end
            
            ordered_groups.each do |group|
              pipeline_projects_with[group].each do |project|
                projects_with[group].push(project)
              end
            end
            
          end
        end
        
        #
        # Append projects that don't have any distributable products (from 'ikmc-dcc-knockout_attempts')
        #
        unless result_data[:'ikmc-dcc-knockout_attempts'].nil?
          result_data[:'ikmc-dcc-knockout_attempts'].each do |pipeline,pipeline_details|
            next if pipeline == 'TIGM' # Skip if TIGM pipeline (ie. Targeted Trap)
            
            # Skip this pipeline if it's already reported in the targeting repository (ie. has distributable products)
            next if result_data[:'ikmc-idcc_targ_rep'] and result_data[:'ikmc-idcc_targ_rep'].include? pipeline
            
            # Retrieve projects_ids of this pipeline that don't have any product available
            projects_ids      = []
            projects_statuses = []
            
            pipeline_details.values.each do |project|
              if project.is_a? Hash and project.values_at(:vector_available,:escell_available,:mouse_available) == ['0','0','0']
                projects_ids.push( project[:ikmc_project_id] )
                projects_statuses.push( project[:status] )
              end
            end
            next if projects_ids.empty? or projects_statuses.empty?
            
            projects_with[:nothing].push({
              :no_products_available => true,
              :display               => true,
              :pipeline              => pipeline,
              :status                => projects_statuses.sort { |a,b| status_order[a] ? status_order[a] : 0  <=> status_order[b] ? status_order[b] : 0 }.first,
              :mgi_accesion_id       => pipeline_details[:mgi_accession_id],
              :project_ids           => projects_ids
            })
          end
        end
        
        result_data[:'ikmc-idcc_targ_rep'] = (
            projects_with[:mice]    \
          + projects_with[:clones]  \
          + projects_with[:vectors] \
          + projects_with[:nothing]
        )
        
        #
        # Finally, try to associate any microinfection data to es cells.
        #
        if !result_data[:'ikmc-idcc_targ_rep'].empty? and !result_data[:'ikmc-kermits'].nil?
          mi_cache = {}
          
          # Cache the mi and distribution centres from the kermits entries
          result_data[:'ikmc-kermits'].each do |mi|
            unless mi[:escell_clone].nil?
              mi_cache[ mi[:escell_clone] ] = {
                :emma                => mi[:emma],
                :mi_centre           => mi[:mi_centre],
                :distribution_centre => mi[:distribution_centre]
              }
            end
          end
    
          # Now try and stamp this data on the targ_rep entries
          result_data[:'ikmc-idcc_targ_rep'].each do |project|
            mi_data_for_project = []
            [:conditional_clones,:nonconditional_clones].each do |clone_type|
              unless project[clone_type].nil?
                project[clone_type].each do |clone|
                  unless mi_cache[ clone[:escell_clone] ].nil?
                    mi_data_for_project.push( mi_cache[ clone[:escell_clone] ] )
                  end
                end
              end
            end
      
            # Reconcile multiple mi's for a project... Basically, the only rule here 
            # is that:
            #   - for KOMP products, an MI with a distribution centre of 'UCD'
            #     trumps all others.
            #   - for EUCOMM (and all other projects) products we don't care...
            unless mi_data_for_project.empty?
              chosen_mi = mi_data_for_project.first
        
              if mi_data_for_project.size > 1 and project[:pipeline] =~ /KOMP/
                mi_data_for_project.each do |other_mi|
                  if other_mi[:distribution_centre] == 'UCD' and chosen_mi[:distribution_centre] != 'UCD'
                    chosen_mi = other_mi
                  end
                end
              end
              
              project[:mouse_emma]                = chosen_mi[:emma]
              project[:mouse_mi_centre]           = chosen_mi[:mi_centre]
              project[:mouse_distribution_centre] = chosen_mi[:distribution_centre]
            end
          end
        end
        
        if result_data[:'ikmc-idcc_targ_rep'].empty?
          result_data[:'ikmc-idcc_targ_rep'] = nil
        end
      end
      
    end
    
  end
end