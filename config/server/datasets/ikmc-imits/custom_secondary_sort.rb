# encoding: utf-8

module MartSearch
  module DataSetUtils

    def ikmc_imits_secondary_sort( search_data )
      search_data.each do |key,result_data|
        next if result_data[:'ikmc-imits'].nil?       or result_data[:'ikmc-imits'].empty?
        next if result_data[:'ikmc-idcc_targ_rep'].nil? or result_data[:'ikmc-idcc_targ_rep'].empty?

        # Cache the IKMC Project ID's for clones...
        escell_cache = {}
        result_data[:'ikmc-idcc_targ_rep'].each do |targ_rep_data|
          next if targ_rep_data.nil? or targ_rep_data.empty?
          [:conditional_clones,:nonconditional_clones].each do |clone_type|
            unless targ_rep_data[clone_type].nil?
              targ_rep_data[clone_type].each do |clone|
                escell_cache[ clone[:escell_clone] ] = { 
                  :ikmc_project_id => targ_rep_data[:ikmc_project_id],
                  :cassette_type   => targ_rep_data[:cassette_type],
                  :escell_strain   => clone[:escell_strain]
                }
              end
            end
          end
        end

        # Now relate the mice to the cells/projects
        mouse_data = []
        result_data[:'ikmc-imits'].each do |mouse|
          mouse[:mgi_accession_id] = result_data[:index][:mgi_accession_id]

          escell_data = escell_cache[ mouse[:escell_clone] ]
          unless escell_data.nil?
            mouse[:ikmc_project_id]  = escell_data[:ikmc_project_id]
            mouse[:cassette_type]    = escell_data[:cassette_type]
            mouse[:escell_strain]    = escell_data[:escell_strain]
          end

          mouse[:genetic_background] = ikmc_imits_set_genetic_background(mouse)

          mouse_data.push(mouse)
        end

        result_data[:'ikmc-imits'] = mouse_data
      end

      return search_data
    end

    private

    # Set the genetic background
    #
    # @param  [Hash] imits_mouse the mouse you wish to update
    # @return [String]
    def ikmc_imits_set_genetic_background( mouse )
      genetic_background = []
      genetic_background.push(mouse[:colony_background_strain]) if mouse[:colony_background_strain]
      genetic_background.push(mouse[:test_cross_strain])        if mouse[:test_cross_strain]
      genetic_background.push(mouse[:escell_strain])            if mouse[:escell_strain]
      genetic_background.join(';')
    end

  end
end
