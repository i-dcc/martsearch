module MartSearch
  
  # Utility module to house all of the data gathering logic for the IKMC 
  # project page views.
  #
  # @author Sebastien Briois
  # @author Darren Oakley
  # @author Nelo Onyiah
  module ProjectUtils
    
    # Wrapper function to collate all of the data for a given IKMC project.
    #
    # @param [String] project_id The IKMC project ID
    # @return [Hash] A hash containing all the data for the given project
    def get_ikmc_project_page_data( project_id )
      datasources = MartSearch::Controller.instance().datasources
      data        = { :project_id => project_id }
      
      top_level_data = get_top_level_project_info( datasources, project_id )
      if top_level_data.nil?
        return nil
      else
        data.merge!( top_level_data )
        data.merge!( get_human_orthalog( datasources, data[:ensembl_gene_id] ) ) if data[:ensembl_gene_id]
        data.merge!( get_mice( datasources, data[:marker_symbol] ) ) if data[:marker_symbol]
        data.merge!( get_vectors_and_cells( datasources, project_id, data[:mice] ) )
        data.merge!( get_pipeline_stage( data[:status]) ) if data[:status]
      end
      
      return data
    end
    
    private
      
      # This function hits the ikmc-dcc mart for top level information
      # about the IKMC project ID being looked at.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] project_id The IKMC project ID
      # @return [Hash] The data relating to this project
      def get_top_level_project_info( datasources, project_id )
        dcc_mart = datasources[:'ikmc-dcc'].ds
        results  = dcc_mart.search({
          :process_results => true,
          :filters         => {'ikmc_project_id' => project_id },
          :attributes      => [ 
            'marker_symbol',   'mgi_accession_id', 'ensembl_gene_id', 
            'vega_gene_id',    'ikmc_project',     'status', 
            'mouse_available', 'escell_available', 'vector_available'
          ]
        })
        
        if results.empty? or results.nil?
          return nil
        else
          return results[0].symbolize_keys!
        end
      end
      
      # This function hits the Ensembl (mouse) mart and looks for a human orthalog.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] ensembl_gene_id The (mouse) Ensembl ID to look for Human orthalogs of
      # @return [Hash] The data relating to the human orthalog
      def get_human_orthalog( datasources, ensembl_gene_id )
        ens_mart = datasources[:'ensembl-mouse'].ds
        begin
          results  = ens_mart.search({
            :process_results     => true,
            :filters             => { 'ensembl_gene_id' => ensembl_gene_id },
            :attributes          => [ 'human_ensembl_gene' ],
            :required_attributes => [ 'human_ensembl_gene' ]
          })
        rescue Biomart::BiomartError => error
          return {}
        end
      
        results.empty? ? {} : { :human_ensembl_gene => results[0]['human_ensembl_gene'] }
      end
      
      # This function hits the ikmc-kermits mart for data on mice.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] marker_symbol The marker_symbol to search the mart by
      # @return [Hash] The data relating to mice for this project
      def get_mice( datasources, marker_symbol )
        qc_metrics  = [
          'qc_southern_blot',
          'qc_tv_backbone_assay',
          'qc_five_prime_lr_pcr',
          'qc_loa_qpcr',
          'qc_homozygous_loa_sr_pcr',
          'qc_neo_count_qpcr',
          'qc_lacz_sr_pcr',
          'qc_five_prime_cass_integrity',
          'qc_neo_sr_pcr',
          'qc_mutant_specific_sr_pcr',
          'qc_loxp_confirmation',
          'qc_three_prime_lr_pcr'
        ]
      
        kermits_mart = datasources[:'ikmc-kermits'].ds
        results      = kermits_mart.search({
          :process_results => true,
          :filters         => {
            'marker_symbol' => marker_symbol,
            'status'        => 'Genotype Confirmed',
            'emma'          => '1'
          },
          :attributes      => [
              'status', 'allele_name', 'escell_clone', 'emma',
              'escell_strain', 'escell_line', 'mi_centre',
              qc_metrics
          ].flatten,
          :required_attributes => ['status']
        }).recursively_symbolize_keys!

        # Test for QC data - set each empty qc_metric to '-' or count it
        results.each do |result|
          result[:qc_count] = 0
          qc_metrics.each do |metric|
            if result[metric].nil?
              result[metric] = '-'
            else
              result[:qc_count] = result[:qc_count] + 1
            end
          end
        end
      
        results.empty? ? {} : { :mice => results }
      end
      
      # This function hits the ikmc-idcc_targ_rep mart for data on the vectors and cells.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] project_id The IKMC project ID
      # @param [Hash] mouse_data The resulting data from {#get_mice}
      # @return [Hash] The data relating to this project
      def get_vectors_and_cells( datasources, project_id, mouse_data )
        qc_metrics = [
          'production_qc_five_prime_screen',
          'production_qc_loxp_screen',
          'production_qc_three_prime_screen',
          'production_qc_loss_of_allele',
          'production_qc_vector_integrity',
          'distribution_qc_karyotype_high',
          'distribution_qc_karyotype_low',
          'distribution_qc_copy_number',
          'distribution_qc_five_prime_lr_pcr',
          'distribution_qc_five_prime_sr_pcr',
          'distribution_qc_three_prime_sr_pcr',
          'user_qc_southern_blot',
          'user_qc_map_test',
          'user_qc_karyotype',
          'user_qc_tv_backbone_assay',
          'user_qc_five_prime_lr_pcr',
          'user_qc_loss_of_wt_allele',
          'user_qc_neo_count_qpcr',
          'user_qc_lacz_sr_pcr',
          'user_qc_five_prime_cassette_integrity',
          'user_qc_neo_sr_pcr',
          'user_qc_mutant_specific_sr_pcr',
          'user_qc_loxp_confirmation',
          'user_qc_three_prime_lr_pcr'
        ]
        targ_rep_mart = datasources[:'ikmc-idcc_targ_rep'].ds
        results       = targ_rep_mart.search({
          :process_results => true,
          :filters         => { 'ikmc_project_id' => project_id },
          :attributes      => [
            'allele_id',
            'design_id',
            'mutation_subtype',
            'cassette',
            'backbone',
            'intermediate_vector',
            'targeting_vector',
            'allele_symbol_superscript',
            'escell_clone',
            'floxed_start_exon',
            'parental_cell_line',
            qc_metrics
          ].flatten
        })
      
        data = {}
      
        results.each do |result|
          if data.empty?
            data.update({
              'intermediate_vectors' => [],
              'targeting_vectors'    => [],
              'es_cells'             => {
                'conditional'              => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }, 
                'targeted non-conditional' => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }
              },
              'vector_image' => "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/vector-image",
              'vector_gb'    => "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
            })
          end
        
          design_type = case result['mutation_subtype']
            when 'conditional_ready'        then 'Conditional (Frameshift)'
            when 'deletion'                 then 'Deletion'
            when 'targeted_non_conditional' then 'Targeted, Non-Conditional'
            else ''
          end
        
          ##
          ## Intermediate Vectors
          ##
        
          unless result['mutation_subtype'] == 'targeted_non_conditional'
            data['intermediate_vectors'].push(
              'name'        => result['intermediate_vector'],
              'design_id'   => result['design_id'],
              'design_type' => design_type,
              'floxed_exon' => result['floxed_start_exon']
            )
          end
        
          ##
          ## Targeting Vectors
          ##
        
          unless result['mutation_subtype'] == 'targeted_non_conditional'
            data['targeting_vectors'].push(
              'name'         => result['targeting_vector'],
              'design_id'    => result['design_id'],
              'design_type'  => design_type,
              'cassette'     => result['cassette'],
              'backbone'     => result['backbone'],
              'floxed_exon'  => result['floxed_start_exon']
            )
          end
        
          ##
          ## ES Cells
          ##

          next if result['escell_clone'].nil? or result['escell_clone'].empty?

          push_to = 'targeted non-conditional'
          push_to = 'conditional' if result['mutation_subtype'] == 'conditional_ready'

          # Prepare the QC data
          qc_data = { 'qc_count' => 0 }
          qc_metrics.each do |metric|
            if result[metric].nil?
              qc_data[metric]     = '-'
            else
              qc_data[metric]     = result[metric]
              qc_data['qc_count'] = qc_data['qc_count'] + 1
            end
          end

          do_i_have_a_mouse = 'no'
          unless mouse_data.nil?
            do_i_have_a_mouse = 'yes' if mouse_data.any?{ |mouse| mouse[:escell_clone] == result['escell_clone'] }
          end

          data['es_cells'][push_to]['allele_img'] = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/allele-image"
          data['es_cells'][push_to]['allele_gb']  = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file"
          data['es_cells'][push_to]['cells'].push(
            {
              'name'                      => result['escell_clone'],
              'allele_symbol_superscript' => result['allele_symbol_superscript'],
              'parental_cell_line'        => result['parental_cell_line'],
              'targeting_vector'          => result['targeting_vector'],
              'mouse?'                    => do_i_have_a_mouse
            }.merge(qc_data)
          )

          if design_type != 'conditional_ready'
            data['es_cells'][push_to]['design_type'] = design_type
          end
        end

        unless data.empty?
          data['intermediate_vectors'].uniq!
          data['targeting_vectors'].uniq!

          # Uniqify and sort the ES Cells...
          ['conditional','targeted non-conditional'].each do |cond_vs_non|
            data['es_cells'][cond_vs_non]['cells'].uniq!
            data['es_cells'][cond_vs_non]['cells'].sort! do |elm1,elm2|
              compstr1 = ''
              compstr2 = ''

              if elm1['mouse?'] == 'yes' then compstr1 = 'A '
              else                            compstr1 = 'Z '
              end

              if elm2['mouse?'] == 'yes' then compstr2 = 'A '
              else                            compstr2 = 'Z '
              end

              compstr1 << "#{elm1['qc_count']} "
              compstr1 << elm1['name']

              compstr2 << "#{elm2['qc_count']} "
              compstr2 << elm2['name']

              compstr1 <=> compstr2
            end
          end
        end

        return data.recursively_symbolize_keys!
      end
      
      # Helper function to determine how to draw the progress bar at the top of the 
      # report page.
      #
      # @param [String] status The current projects status
      # @return [Hash] The configuration needed to draw the progress bar
      def get_pipeline_stage( status )
        status_definitions = {
          # KOMP-CSD, EUCOMM, NorCOMM
          "On Hold"                                                 => { :stage => "pre",     :stage_type => "warn"   },
          "Transferred to NorCOMM"                                  => { :stage => "pre",     :stage_type => "error"  },
          "Transferred to KOMP"                                     => { :stage => "pre",     :stage_type => "error"  },
          "Withdrawn From Pipeline"                                 => { :stage => "pre",     :stage_type => "error"  },
          "Design Requested"                                        => { :stage => "designs", :stage_type => "normal" },
          "Alternate Design Requested"                              => { :stage => "designs", :stage_type => "warn"   },
          "VEGA Annotation Requested"                               => { :stage => "designs", :stage_type => "warn"   },
          "Design Not Possible"                                     => { :stage => "designs", :stage_type => "error"  },
          "Design Completed"                                        => { :stage => "designs", :stage_type => "normal" },
          "Vector Construction in Progress"                         => { :stage => "vectors", :stage_type => "normal" },
          "Vector Unsuccessful - Project Terminated"                => { :stage => "vectors", :stage_type => "error"  },
          "Vector Unsuccessful - Alternate Design in Progress"      => { :stage => "vectors", :stage_type => "warn"   },
          "Vector - Initial Attempt Unsuccessful"                   => { :stage => "vectors", :stage_type => "warn"   },
          "Vector Complete"                                         => { :stage => "vectors", :stage_type => "normal" },
          "Vector - DNA Not Suitable for Electroporation"           => { :stage => "vectors", :stage_type => "warn"   },
          "ES Cells - Electroporation in Progress"                  => { :stage => "cells",   :stage_type => "normal" },
          "ES Cells - Electroporation Unsuccessful"                 => { :stage => "cells",   :stage_type => "error"  },
          "ES Cells - No QC Positives"                              => { :stage => "cells",   :stage_type => "warn"   },
          "ES Cells - Targeting  Unsuccessful - Project Terminated" => { :stage => "cells",   :stage_type => "error"  },
          "ES Cells - Targeting Confirmed"                          => { :stage => "cells",   :stage_type => "normal" },
          "Mice - Microinjection in progress"                       => { :stage => "mice",    :stage_type => "normal" },
          "Mice - Germline transmission"                            => { :stage => "mice",    :stage_type => "normal" },
          "Mice - Genotype confirmed"                               => { :stage => "mice",    :stage_type => "normal" },

          # KOMP-Regeneron
          "Regeneron Selected"                                      => { :stage => "pre",     :stage_type => "normal" },
          "Design Finished/Oligos Ordered"                          => { :stage => "designs", :stage_type => "normal" },
          "Parental BAC Obtained"                                   => { :stage => "vectors", :stage_type => "normal" },
          "Targeting Vector QC Completed"                           => { :stage => "vectors", :stage_type => "normal" },
          "Vector Electroporated into ES Cells"                     => { :stage => "vectors", :stage_type => "normal" },
          "ES cell colonies picked"                                 => { :stage => "cells",   :stage_type => "normal" },
          "ES cell colonies screened / QC no positives"             => { :stage => "cells",   :stage_type => "warn"   },
          "ES cell colonies screened / QC one positive"             => { :stage => "cells",   :stage_type => "warn"   },
          "ES cell colonies screened / QC positives"                => { :stage => "cells",   :stage_type => "normal" },
          "ES Cell Clone Microinjected"                             => { :stage => "cells",   :stage_type => "normal" },
          "Germline Transmission Achieved"                          => { :stage => "mice",    :stage_type => "normal" }
        }

        return status_definitions[ status ]
      end
  end
  
end