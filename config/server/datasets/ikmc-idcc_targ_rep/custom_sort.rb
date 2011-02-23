module MartSearch
  module DataSetUtils
    
    def ikmc_idcc_targ_rep_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        pipeline         = result[:pipeline]
        cassette         = result[:cassette]
        backbone         = result[:backbone]
        
        result_data      = sorted_results[joined_attribute] ||= {}
        pipeline_store   = result_data[pipeline]            ||= {}
        project_key      = [
          result[:homology_arm_start], result[:homology_arm_end],
          result[:cassette_start],     result[:cassette_end],
          cassette,                    backbone
        ].join('-')
        
        project = pipeline_store[ project_key ] ||= {
          :pipeline                => pipeline,
          :mgi_accession_id        => result[:mgi_accession_id],
          :design_id               => result[:design_id],
          :design_type             => result[:design_type],
          :cassette                => cassette,
          :backbone                => backbone,
          :targeting_vectors       => [],
          :conditional_clones      => [],
          :nonconditional_clones   => [],
          :vector_available        => '0',
          :escell_available        => '0',
          :mouse_available         => '0',
          :display                 => false
        }
        
        # Get the ikmc_project_id
        ikmc_project_id           = result[:ikmc_project_id] || project[:ikmc_project_id]
        project[:ikmc_project_id] = ikmc_project_id if project[:ikmc_project_id].nil?
        
        # Targeting Vectors
        if result[:targeting_vector]
          ikmc_idcc_targ_rep_store_targeting_vector( ikmc_project_id, result, project )
        end
        
        # ES Cells
        if result[:escell_clone]
          ikmc_idcc_targ_rep_store_es_cell( ikmc_project_id, result, project )
        end
      end
      
      return sorted_results
    end
    
    def ikmc_idcc_targ_rep_store_targeting_vector( ikmc_project_id, result, project )
      targ_vec = {
        :ikmc_project_id     => ikmc_project_id,
        :allele_id           => result[:allele_id],
        :targeting_vector    => result[:targeting_vector],
        :intermediate_vector => result[:intermediate_vector]
      }
      
      targ_vec[:gb_file] = case result[:vector_gb_file]
      when 'yes' then true
      when 'no'  then false
      end
      
      unless project[:targeting_vectors].include?( targ_vec )
        project[:vector_available] = '1'
        project[:targeting_vectors].push( targ_vec )
      end
    end
    
    def ikmc_idcc_targ_rep_store_es_cell( ikmc_project_id, result, project )
      es_cell = {
        :ikmc_project_id           => ikmc_project_id,
        :targeting_vector          => result[:targeting_vector],
        :escell_clone              => result[:escell_clone],
        :allele_symbol_superscript => result[:allele_symbol_superscript],
        :parental_cell_line        => result[:parental_cell_line],
        :qc_count                  => 0
      }
      
      # Sort and store the QC metrics for the clones
      qc_metrics = [
        :production_qc_five_prime_screen,
        :production_qc_loxp_screen,
        :production_qc_three_prime_screen,
        :production_qc_loss_of_allele,
        :production_qc_vector_integrity,
        :distribution_qc_karyotype_high,
        :distribution_qc_karyotype_low,
        :distribution_qc_copy_number,
        :distribution_qc_five_prime_lr_pcr,
        :distribution_qc_five_prime_sr_pcr,
        :distribution_qc_three_prime_sr_pcr,
        :distribution_qc_thawing,
        :user_qc_southern_blot,
        :user_qc_map_test,
        :user_qc_karyotype,
        :user_qc_tv_backbone_assay,
        :user_qc_five_prime_lr_pcr,
        :user_qc_loss_of_wt_allele,
        :user_qc_neo_count_qpcr,
        :user_qc_lacz_sr_pcr,
        :user_qc_five_prime_cassette_integrity,
        :user_qc_neo_sr_pcr,
        :user_qc_mutant_specific_sr_pcr,
        :user_qc_loxp_confirmation,
        :user_qc_three_prime_lr_pcr,
        :user_qc_comment
      ]
      
      qc_metrics.each do |metric|
        if result[metric].nil?
          es_cell[metric] = '-'
        else
          es_cell[metric]    = result[metric]
          es_cell[:qc_count] = es_cell[:qc_count] + 1
        end
      end
      
      # gbfile?
      gbfile_available = case result[:allele_gb_file]
      when 'yes' then true
      when 'no'  then false
      end
      
      # Push cells into to the right basket ('conditional' or 'nonconditional')
      if ['targeted_non_conditional', 'deletion'].include?( result[:mutation_subtype] )
        clone_type = :nonconditional_clones
        project[:nonconditional_allele_id]      = result[:allele_id]
        project[:nonconditional_allele_gb_file] = gbfile_available
      else
        clone_type = :conditional_clones
        project[:conditional_allele_id]      = result[:allele_id]
        project[:conditional_allele_gb_file] = gbfile_available
      end
      
      unless project[clone_type].include?( es_cell )
        project[:escell_available] = '1'
        project[clone_type].push( es_cell )
      end
    end
    
  end
end
