# encoding: utf-8

module MartSearch
  module DataSetUtils
    # Sort the mouse data from EMMA and KERMITS
    #
    # @param  [Hash] search_data
    # @return [Hash]
    def dummy_mice_secondary_sort( search_data )
      search_data.each do |key,result_data|
        kermits = result_data[:'ikmc-kermits'] || []
        emma    = result_data[:'emma-strains'] || {}

        # Empty the dummy mice and set default values for the columns we want
        result_data[:'dummy-mice'] = []
        columns_to_merge           = {
          :references                       => {},
          :availability                     => [],
          :emma_id                          => nil,
          :international_strain_name        => nil,
          :common_name                      => nil,
          :synonym                          => nil,
          :maintained_background            => nil,
          :mutation_main_type               => nil,
          :mutation_sub_type                => nil,
          :genetic_description              => nil,
          :phenotype_description            => nil,
          :owner                            => nil,
          :allele_name                      => nil,
          :marker_symbol                    => nil,
          :pipeline                         => nil,
          :production_centre                => nil,
          :distribution_centre              => nil,
          :escell_clone                     => nil,
          :colony_prefix                    => nil,
          :escell_strain                    => nil,
          :test_cross_strain                => nil,
          :colony_background_strain         => nil,
          :microinjection_status            => nil,
          :allele_name                      => nil,
          :emma                             => nil,
          :qc_southern_blot                 => nil,
          :qc_tv_backbone_assay             => nil,
          :qc_five_prime_lr_pcr             => nil,
          :qc_loa_qpcr                      => nil,
          :qc_homozygous_loa_sr_pcr         => nil,
          :qc_neo_count_qpcr                => nil,
          :qc_lacz_sr_pcr                   => nil,
          :qc_five_prime_cassette_integrity => nil,
          :qc_neo_sr_pcr                    => nil,
          :qc_mutant_specific_sr_pcr        => nil,
          :qc_loxp_confirmation             => nil,
          :qc_three_prime_lr_pcr            => nil,
          :allele_type                      => nil,
          :qc_count                         => 0,
          :ikmc_project_id                  => nil,
          :cassette_type                    => nil,
          :mgi_accession_id                 => nil,
          :genetic_background               => nil
        }

        if kermits.empty? and emma.empty?
          result_data.delete(:'ikmc-kermits')
          result_data.delete(:'emma-strains')
          result_data.delete(:'dummy-mice')
          next
        elsif !kermits.empty? and emma.empty?
          kermits.each do |kermits_mouse|
            result_data[:'dummy-mice'].push( columns_to_merge.merge(kermits_mouse) )
          end
        elsif kermits.empty? and !emma.empty?
          emma.values.each do |emma_strain|
            result_data[:'dummy-mice'].push( columns_to_merge.merge(emma_strain) )
          end
        else
          result_data[:'dummy-mice'] = dummy_mice_merge_emma_and_kermits( emma, kermits, columns_to_merge )
        end
      end

      return search_data
    end

    # Merge the EMMA and KERMITS data
    #
    # @param  [Hash]  emma
    # @param  [Array] kermits
    # @param  [Hash]  defaults
    # @return [Array]
    def dummy_mice_merge_emma_and_kermits( emma, kermits, defaults )
      results   = []
      emma_copy = emma.clone
      
      # associate KERMITS mice to EMMA strains
      kermits.each do |mouse|
        strains = emma_copy.values.select { |strain| mouse[:escell_clone] == strain[:common_name] }
        strain  = strains.nil? || strains.empty? ? defaults : strains.first
        results.push(strain.merge(mouse))
        emma_copy.delete(strain[:emma_id])
      end
      
      # check for EMMA mice with no corresponding KERMITS mouse
      emma_copy.values.each do |strain|
        results.push(defaults.merge(strain))
      end
      
      return results
    end
  end
end
