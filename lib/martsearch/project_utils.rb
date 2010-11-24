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
      errors      = []

      top_level_data = get_top_level_project_info( datasources, project_id )

      if top_level_data[:data].nil? or top_level_data[:data].empty?
        return { :data => nil }
      else
        data.merge!( top_level_data[:data][0] )
        errors.push( top_level_data[:error] ) unless top_level_data[:error].empty?

        if data[:ensembl_gene_id]
          human_orthalogs = get_human_orthalog( datasources, data[:ensembl_gene_id] )
          data.merge!( human_orthalogs[:data][0] )
          errors.push( human_orthalogs[:error] ) unless human_orthalogs[:error].empty?
        end

        if data[:marker_symbol]
          mice = get_mice( datasources, data[:marker_symbol] )
          data.merge!( mice[:data] )
          errors.push( mice[:error] ) unless mice[:error].empty?
        end

        vectors_and_cells = get_vectors_and_cells( datasources, project_id, data[:mice] )
        data.merge!( vectors_and_cells[:data] )
        errors.push( vectors_and_cells[:error] ) unless vectors_and_cells[:error].empty?

        data.merge!( get_pipeline_stage( data[:status]) ) if data[:status]
      end

      return { :data => data, :errors => errors }
    end

    private

      # Wrapper function to handle Biomart::BiomartErrors
      #
      # @param  [String] data_source - the biomart data source name
      # @param  [String] error_string - a brief explanation of potential errors
      # @param  [Block]  A block that queries the biomart
      # @return [Hash]   A hash containing the data and any errors
      def handle_biomart_errors( data_source, error_string )
        results      = { :data => {}, :error => {} }
        error_prefix = "There was a problem querying the '#{data_source}' biomart."
        error_suffix = "Try refreshing your browser or come back in 10 minutes."
        begin
          results[:data] = yield
        rescue Biomart::BiomartError => error
          results[:error] = {
            :text  => error_prefix + " " + error_string + " " + error_suffix,
            :error => error.to_s,
            :type  => error.class
          }
        rescue Timeout::Error => error
          results[:error] = {
            :text  => error_prefix + " " + error_string + " " + error_suffix,
            :error => error.to_s,
            :type  => error.class
          }
        end
        return results
      end

      # This function hits the ikmc-dcc mart for top level information
      # about the IKMC project ID being looked at.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] project_id The IKMC project ID
      # @return [Hash] The data relating to this project
      def get_top_level_project_info( datasources, project_id )
        dcc_mart     = datasources[:'ikmc-dcc'].ds
        error_string = "This supplies information on gene identifiers and IKMC tracking information. This page will not work without this datasource."
        results      = handle_biomart_errors( "ikmc-dcc", error_string ) do
          dcc_mart.search({
            :process_results => true,
            :filters         => {'ikmc_project_id' => project_id },
            :attributes      => [
              'marker_symbol',   'mgi_accession_id', 'ensembl_gene_id',
              'vega_gene_id',    'ikmc_project',     'status',
              'mouse_available', 'escell_available', 'vector_available'
            ]
          })
        end

        unless results[:data].empty? or results[:data].nil?
          results[:data][0].symbolize_keys!
        end

        return results
      end
      
      # This function hits the Ensembl (mouse) mart and looks for a human orthalog.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] ensembl_gene_id The (mouse) Ensembl ID to look for Human orthalogs of
      # @return [Hash] The data relating to the human orthalog
      def get_human_orthalog( datasources, ensembl_gene_id )
        ens_mart     = datasources[:'ensembl-mouse'].ds
        error_string = "This supplies information on the human ensembl gene orthalog. As a result this data will not be available on the page."
        results      = handle_biomart_errors( "ensembl-mouse", error_string ) do
          ens_mart.search({
            :process_results     => true,
            :filters             => { 'ensembl_gene_id' => ensembl_gene_id },
            :attributes          => [ 'human_ensembl_gene' ],
            :required_attributes => [ 'human_ensembl_gene' ]
          })
        end
        unless results[:data].empty?
          results[:data][0] = { :human_ensembl_gene => results[:data][0]['human_ensembl_gene'] }
        end
        return results
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
        error_string = "This supplies information on mouse breeding. As a result this data will not be available on the page."
        results      = handle_biomart_errors( "ikmc-kermits", error_string ) do
          kermits_mart.search({
            :process_results => true,
            :filters         => {
              'marker_symbol' => marker_symbol,
              'status'        => 'Genotype Confirmed',
              'emma'          => '1'
            },
            :attributes      => [
                'status', 'allele_name', 'escell_clone', 'emma',
                'escell_strain', 'escell_line', 'mi_centre', 'distribution_centre',
                qc_metrics
            ].flatten,
            :required_attributes => ['status']
          })
        end

        if results[:data].empty?
          results[:data] = {}
        else
          results[:data].recursively_symbolize_keys!

          # Test for QC data - set each empty qc_metric to '-' or count it
          results[:data].each do |result|
            result[:qc_count] = 0
            qc_metrics.each do |metric|
              if result[metric].nil?
                result[metric] = '-'
              else
                result[:qc_count] = result[:qc_count] + 1
              end
            end
          end

          results[:data] = { :mice => results[:data] }
        end

        return results
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
          'distribution_qc_thawing',
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
        error_string  = "This data source provides information on Targeting Vectors and ES Cells. As a result this data will not be available on the page."
        results       = handle_biomart_errors( "ikmc-ikmc-targ_rep", error_string ) do
          targ_rep_mart.search({
            :process_results => true,
            :filters         => { 'ikmc_project_id' => project_id },
            :attributes      => [
              'allele_id',
              'design_id',
              'mutation_subtype',
              'cassette',
              'backbone',
              'allele_gb_file',
              'vector_gb_file',
              'intermediate_vector',
              'targeting_vector',
              'allele_symbol_superscript',
              'escell_clone',
              'floxed_start_exon',
              'parental_cell_line',
              qc_metrics
            ].flatten
          })
        end
      
        data = {}
      
        results[:data].each do |result|
          if data.empty?
            data = {
              'intermediate_vectors' => [],
              'targeting_vectors'    => [],
              'es_cells'             => {
                'conditional'              => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }, 
                'targeted non-conditional' => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }
              }
            }
          end
          
          if result['vector_gb_file'] == 'yes'
            data['vector_image'] = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/vector-image"
            data['vector_gb']    = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
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
            unless result['intermediate_vector'].nil?
              data['intermediate_vectors'].push(
                'name'        => result['intermediate_vector'],
                'design_id'   => result['design_id'],
                'design_type' => design_type,
                'floxed_exon' => result['floxed_start_exon']
              )
            end
          end
        
          ##
          ## Targeting Vectors
          ##
        
          unless result['mutation_subtype'] == 'targeted_non_conditional'
            unless result['targeting_vector'].nil?
              data['targeting_vectors'].push(
                'name'         => result['targeting_vector'],
                'design_id'    => result['design_id'],
                'design_type'  => design_type,
                'cassette'     => result['cassette'],
                'backbone'     => result['backbone'],
                'floxed_exon'  => result['floxed_start_exon']
              )
            end
          end
        
          ##
          ## ES Cells
          ##

          next if result['escell_clone'].nil?

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

          if result['allele_gb_file'] == 'yes'
            data['es_cells'][push_to]['allele_img'] = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/allele-image"
            data['es_cells'][push_to]['allele_gb']  = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file"
          end
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

        results[:data] = data.recursively_symbolize_keys!

        return results
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
          "Vector Complete - Project Terminated"                    => { :stage => "vectors", :stage_type => "error"  },
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