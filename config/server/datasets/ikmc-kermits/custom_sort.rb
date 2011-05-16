# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def ikmc_kermits_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        # We're only interested in data with a status of 'Genotype Confirmed'
        if result[:status] and result[:status] === "Genotype Confirmed"
          
          # Correct the <> notation in several attributes...
          if result[:allele_name]
            result[:allele_name] = fix_superscript_text_in_attribute(result[:allele_name])
            
            # Override the allele_name if we have a corrected one for the mouse...
            unless result[:mouse_allele_name].nil?
              result[:allele_name] = fix_superscript_text_in_attribute(result[:mouse_allele_name])
            end
            
            result[:allele_type] = allele_type(result[:allele_name])
          end
          if result[:back_cross_strain]
            result[:back_cross_strain] = fix_superscript_text_in_attribute(result[:back_cross_strain])
          end
          
          # Test for QC data
          result[:qc_count] = 0
          qc_metrics = [
            :qc_southern_blot,
            :qc_tv_backbone_assay,
            :qc_five_prime_lr_pcr,
            :qc_loa_qpcr,
            :qc_homozygous_loa_sr_pcr,
            :qc_neo_count_qpcr,
            :qc_lacz_sr_pcr,
            :qc_five_prime_cass_integrity,
            :qc_neo_sr_pcr,
            :qc_mutant_specific_sr_pcr,
            :qc_loxp_confirmation,
            :qc_three_prime_lr_pcr
          ]
          
          qc_metrics.each do |metric|
            if result[metric].nil?
              result[metric] = '-'
            else
              result[:qc_count] = result[:qc_count] + 1
            end
          end

          # set the genetic background
          result[:genetic_background] = ikmc_kermits_set_genetic_background(result)

          # Store the result
          unless sorted_results[ result[ joined_attribute ] ]
            sorted_results[ result[ joined_attribute ] ] = []
          end
          sorted_results[ result[ joined_attribute ] ].push(result)
          
        end
        
      end
      
      return sorted_results
    end

    # Set the genetic background
    #
    # @param  [Hash] kermits_mouse the mouse you wish to update
    # @return [String]
    def ikmc_kermits_set_genetic_background( kermits_mouse )
      genetic_background = []
      genetic_background.push(kermits_mouse[:back_cross_strain]) if kermits_mouse[:back_cross_strain]
      genetic_background.push(kermits_mouse[:test_cross_strain]) if kermits_mouse[:test_cross_strain]
      genetic_background.push(kermits_mouse[:escell_strain])     if kermits_mouse[:escell_strain]
      genetic_background.join(';')
    end
  end
end
