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
                        :references => {},
                      :availability => [],
                           :emma_id => nil,
         :international_strain_name => nil,
                       :common_name => nil,
                           :synonym => nil,
             :maintained_background => nil,
                :mutation_main_type => nil,
                 :mutation_sub_type => nil,
               :genetic_description => nil,
             :phenotype_description => nil,
                             :owner => nil,
                       :allele_name => nil,
                     :marker_symbol => nil,
                           :sponsor => nil,
                         :mi_centre => nil,
               :distribution_centre => nil,
                      :escell_clone => nil,
                     :colony_prefix => nil,
                     :escell_strain => nil,
                 :test_cross_strain => nil,
                 :back_cross_strain => nil,
                            :status => nil,
                       :allele_name => nil,
                              :emma => nil,
                  :qc_southern_blot => nil,
              :qc_tv_backbone_assay => nil,
              :qc_five_prime_lr_pcr => nil,
                       :qc_loa_qpcr => nil,
          :qc_homozygous_loa_sr_pcr => nil,
                 :qc_neo_count_qpcr => nil,
                    :qc_lacz_sr_pcr => nil,
      :qc_five_prime_cass_integrity => nil,
                     :qc_neo_sr_pcr => nil,
         :qc_mutant_specific_sr_pcr => nil,
              :qc_loxp_confirmation => nil,
             :qc_three_prime_lr_pcr => nil,
                       :allele_type => nil,
                          :qc_count => 0,
                   :ikmc_project_id => nil,
                  :mgi_accession_id => nil,
                :genetic_background => nil
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
          kermits.each do |kermits_mouse|
            emma_mouse = emma.values.select do |strain|
              kermits_mouse[:escell_clone] == strain[:common_name]
            end
            result_data[:'dummy-mice'].push( kermits_mouse.merge( emma_mouse.first ) )
          end
        end
      end

      return search_data
    end
  end
end