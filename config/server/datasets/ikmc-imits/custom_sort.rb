# encoding: utf-8

module MartSearch
  module DataSetUtils

    def ikmc_kermits_sort_results( results )
      sorted_results = {}

      results.each do |result|
        next unless result[:microinjection_status] == 'Genotype confirmed' and result[:emma] == '1'

        joined_attribute = @config[:searching][:joined_attribute].to_sym

        # Try and set the allele_name
        unless result[:allele_symbol_superscript].blank?
          result[:allele_name] = "#{result[:marker_symbol]}<sup>#{result[:allele_symbol_superscript]}</sup>"

          # Override the allele_name if we have a corrected one for the mouse...
          unless result[:mouse_allele_symbol_superscript].blank?
            result[:allele_name] = "#{result[:marker_symbol]}<sup>#{result[:mouse_allele_symbol_superscript]}</sup>"
          end

          result[:allele_type] = allele_type(result[:allele_name])
        end

        # Fix the strain names
        [:colony_background_strain, :test_cross_strain].each do |strain_type|
          result[strain_type] = fix_superscript_text_in_attribute(result[strain_type]) unless result[strain_type].blank?
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
          :qc_five_prime_cassette_integrity,
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

        # Store the result
        sorted_results[ result[ joined_attribute ] ] ||= []
        sorted_results[ result[ joined_attribute ] ].push(result)
      end

      return sorted_results
    end

  end
end
