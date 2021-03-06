# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    # Secondary sort for the 'wtsi-phenotyping-heatmap' dataset.  This arranges 
    # all of the phenotyping results (from the related datasets) into a processed 
    # config object ready for display.
    #
    # @param [Hash] search_data All of the returned dataset data
    # @return [Hash] The search_data hash with the :'processed-wtsi-phenotyping-heatmap' data inserted
    def wtsi_phenotyping_heatmap_secondary_sort( search_data )
      ms          = MartSearch::Controller.instance()
      ds_attribs  = ms.datasources[:"wtsi-phenotyping"].ds_attributes
      
      # Work out the display names for the tests
      test_display_names = {}
      attribs            = @config[:searching][:attributes]
      attribs.each do |attrib|
        next if [:colony_prefix,:allele_name,:allele_type,:escell_clone,:strain_group].include?( attrib.to_sym )
        test_display_names[attrib.to_sym] = ds_attribs[attrib] ? ds_attribs[attrib].display_name : attrib.to_s
      end
      
      mp_group_config = wtsi_phenotyping_param_level_heatmap_mp_heatmap_config
      
      # Now process the heatmap
      search_data.each do |key,result_data|
        heatmap_raw_data = result_data[:'wtsi-phenotyping-heatmap']
        heatmap_data     = {}
        
        next if heatmap_raw_data.nil?
        
        result_data[:'wtsi-phenotyping-heatmap-test_display_names'] = test_display_names
        result_data[:'wtsi-phenotyping-mp_group_config'] = mp_group_config
        
        # First, append any supporting data to the basic heatmap return.
        heatmap_raw_data.each do |result|
          # Try to improve the quality of the clone and allele data
          result, related_imits_entry = wtsi_phenotyping_heatmap_append_related_imits_entry( result, result_data )
          result                      = wtsi_phenotyping_heatmap_append_related_targ_rep_entry( result, result_data, related_imits_entry )
          
          colony_prefix = result[:colony_prefix].to_sym
          
          # wtsi-phenotyping-param_level_heatmap
          param_level_heatmap_data = result_data[:'wtsi-phenotyping-param_level_heatmap']
          unless param_level_heatmap_data.nil? or param_level_heatmap_data[colony_prefix].nil?
            graphs = param_level_heatmap_data[colony_prefix][:test_groups]
            result[:population_id] ||= param_level_heatmap_data[colony_prefix][:population_id].to_i
            
            graphs.keys.each do |test|
              mart_attribute = ds_attribs[test.to_s]
              next if mart_attribute.nil?
              result.merge!({ "#{test}_data".to_sym => graphs[test] })
            end
            
            # Finally, add in some extra data from the 'main' heatmap and create a seperate
            # entry for the mp_heatmap store...
            
            mp_heatmap_data = {
              :marker_symbol => result_data[:index][:marker_symbol],
              :colony_prefix => result[:colony_prefix],
              :population_id => param_level_heatmap_data[colony_prefix][:population_id].to_i,
              :allele_name   => result[:allele_name],
              :allele_type   => result[:allele_type],
              :escell_clone  => result[:escell_clone],
              :mp_groups     => param_level_heatmap_data[colony_prefix][:mp_groups]
            }
            
            result_data[:'wtsi-phenotyping-mp_heatmap'] ||= []
            result_data[:'wtsi-phenotyping-mp_heatmap'].push(mp_heatmap_data)
            
            # Now cache this for easy access in the reports pages...
            ms.write_to_cache( "wtsi-pheno-mp-data:#{colony_prefix.to_s.upcase}", mp_heatmap_data )
          end
          
          # wtsi-phenotyping-collaborator_data
          collaborator_data = result_data[:'wtsi-phenotyping-collaborator_data']
          unless collaborator_data.nil? or collaborator_data[colony_prefix].nil?
            collaborator_data_for_colony = collaborator_data[colony_prefix]
            
            collaborator_data_for_colony.keys.each do |test|
              mart_attribute = ds_attribs[test.to_s]
              next if mart_attribute.nil?
              result.merge!({ "#{test}_data".to_sym => collaborator_data_for_colony[test] })
            end
          end
          
          # wtsi-phenotyping-fertility
          fertility_data = result_data[:'wtsi-phenotyping-fertility']
          result.merge!( wtsi_phenotyping_heatmap_fertility_data( colony_prefix, fertility_data ) ) unless fertility_data.nil?
          
          # wtsi-phenotyping-hom_viability
          hom_viability_data = result_data[:'wtsi-phenotyping-hom_viability']
          result.merge!( wtsi_phenotyping_heatmap_hom_viability_data( colony_prefix, hom_viability_data ) ) unless hom_viability_data.nil?
          
          # wtsi-phenotyping-abr
          abr_data = result_data[:'wtsi-phenotyping-abr']
          result.merge!( wtsi_phenotyping_heatmap_abr_data( colony_prefix, abr_data ) ) unless abr_data.nil?
          
          # wtsi-phenotyping-adult_expression
          adult_expression_data = result_data[:'wtsi-phenotyping-adult_expression']
          result = wtsi_phenotyping_heatmap_append_adult_expression_data( colony_prefix, adult_expression_data, result ) unless adult_expression_data.nil?
          
          # wtsi-phenotyping-published_images
          published_image_data = result_data[:'wtsi-phenotyping-published_images']
          result = wtsi_phenotyping_heatmap_append_published_image_data( colony_prefix, published_image_data, result ) unless published_image_data.nil?
        end
        
      end
      
      # Run through the data one last time to cache the results details 
      # ready for the report pages...
      wtsi_phenotyping_heatmap_cache_colony_heatmap_data( ms, search_data )
      
      # We've now got a tonne of redundant data flowing around.  Let's clear some of
      # it out so we don't rely on the stuff we shouldn't somewhere...
      datasets_to_purge = [
        :'wtsi-phenotyping-param_level_heatmap',
        :'wtsi-phenotyping-collaborator_data',
        :'wtsi-phenotyping-fertility',
        :'wtsi-phenotyping-hom_viability',
        :'wtsi-phenotyping-abr',
        :'wtsi-phenotyping-adult_expression',
        :'wtsi-phenotyping-published_images'
      ]
      search_data.each do |key,result_data|
        datasets_to_purge.each do |dataset_name|
          result_data[dataset_name] = true unless result_data[dataset_name].nil?
        end
      end
      
    end
    
    private
    
    # Helper function to look up clone and allele names in the imits dataset as this is
    # slightly more reliable than the wtsi-heatmap data.
    def wtsi_phenotyping_heatmap_append_related_imits_entry( result, result_data )
      related_imits_entry = nil
      colony_prefix       = result[:colony_prefix]
      imits_data          = result_data[:'ikmc-imits']
      
      if colony_prefix && imits_data
        imits_data.each do |kerm|
          related_imits_entry = kerm if kerm[:colony_prefix] == colony_prefix
        end
      end
      
      if related_imits_entry && related_imits_entry[:allele_name]
        result[:allele_name] = related_imits_entry[:allele_name]
        result[:allele_type] = related_imits_entry[:allele_type]
      end
      
      if related_imits_entry && related_imits_entry[:escell_clone]
        result[:escell_clone] = related_imits_entry[:escell_clone]
      end
      
      return result, related_imits_entry
    end
    
    # Helper function to look up clone and allele details in the targ_rep dataset as this is 
    # slightly more reliable than the imits and wtsi-heatmap datasets.
    def wtsi_phenotyping_heatmap_append_related_targ_rep_entry( result, result_data, related_imits_entry )
      targ_rep_data          = result_data[:'ikmc-idcc_targ_rep']
      marker_symbol          = result_data[:index][:marker_symbol]
      cassette               = nil
      related_targ_rep_clone = nil
      
      if related_imits_entry && targ_rep_data
        related_imits_clone = related_imits_entry[:escell_clone]
        if related_imits_clone
          targ_rep_data.each do |project_name,project|
            next if project.nil? || project.empty?
            [:conditional_clones,:nonconditional_clones].each do |clone_type|
              project[clone_type].each do |clone|
                if clone[:escell_clone] == related_imits_clone
                  cassette               = project[:cassette]
                  related_targ_rep_clone = clone
                end
              end if project[clone_type]
            end
          end
        end
      end
      
      if (related_targ_rep_clone && related_targ_rep_clone[:allele_symbol_superscript]) && marker_symbol
        result[:allele_name] = "#{marker_symbol}<sup>#{related_targ_rep_clone[:allele_symbol_superscript]}</sup>"
      end
      
      if cassette
        result[:cassette_type] = case cassette
        when /_P$/ then "Promotor Driven"
        else            "Promotorless"
        end
      end
      
      return result
    end
    
    # Helper function to return the fertility data for a given colony.
    def wtsi_phenotyping_heatmap_fertility_data( colony_prefix, fertility_data )
      data_to_return                  = {}
      data_for_colony                 = fertility_data[colony_prefix]
      data_to_return[:fertility_data] = data_for_colony unless data_for_colony.nil?
      return data_to_return
    end
    
    # Helper function to return the hom_viability data for a given colony.
    def wtsi_phenotyping_heatmap_hom_viability_data( colony_prefix, hom_viability_data )
      data_to_return                             = {}
      data_for_colony                            = hom_viability_data[colony_prefix]
      data_to_return[:viability_at_weaning_data] = data_for_colony unless data_for_colony.nil?
      return data_to_return
    end
    
    # Helper function to return the abr data for a given colony.
    def wtsi_phenotyping_heatmap_abr_data( colony_prefix, abr_data )
      data_to_return = {}
      
      abr_data.each do |abr_result|
        data_to_return[:auditory_brainstem_response_data] = abr_result if abr_result[:colony_prefix] == colony_prefix.to_s
      end
      
      return data_to_return
    end
    
    # Helper function to append the adult_expression data for a given colony into 'result'.
    def wtsi_phenotyping_heatmap_append_adult_expression_data( colony_prefix, adult_expression_data, result )
      ticklist = adult_expression_data[colony_prefix]
      
      if ticklist and !ticklist.empty?
        result[:adult_lac_z_expression_data]            ||= {}
        result[:adult_lac_z_expression_data][:ticklist]   = ticklist
      end
      
      return result
    end
    
    # Helper function to append the published_image data for a given colony into 'result'.
    def wtsi_phenotyping_heatmap_append_published_image_data( colony_prefix, published_image_data, result )
      images = published_image_data[colony_prefix]
      
      ['adult_lac_z_expression','embryo_lac_z_expression','tail_epidermis_wholemount'].each do |image_group|
        if images && ( images[image_group.to_sym] && !images[image_group.to_sym].empty? )
          result["#{image_group}_data".to_sym]          ||= {}
          result["#{image_group}_data".to_sym][:images]   = images[image_group.to_sym]
        end
      end
      
      return result
    end
    
    # Helper function to group all of the *_data fields from the processed heatmap by 
    # colony and stuff them into the cache so it's easier to produce the MGP report pages.
    def wtsi_phenotyping_heatmap_cache_colony_heatmap_data( ms, search_data )
      search_data.each do |key,result_data|
        heatmap_data  = result_data[:'wtsi-phenotyping-heatmap']
        marker_symbol = result_data[:index][:marker_symbol]
        cache_data    = {}
        
        next if heatmap_data.nil?
        
        # First insert the marker_symbol into each of the *_data entries (for easy templating)
        heatmap_data.each do |result|
          cache_data_for_colony = cache_data[ result[:colony_prefix] ] ||= {}
          
          result.keys.select{ |name| name.to_s =~ /_data$/ }.each do |result_key|
            test_data = result[result_key].clone
            
            if test_data.is_a?(Hash)
              test_data[:marker_symbol] = marker_symbol
            elsif test_data.is_a?(Array)
              test_data.map!{ |elm| elm[:marker_symbol] = marker_symbol; elm }
            end
            
            cache_data_for_colony[result_key] = test_data
          end
        end
        
        # Now cache the data
        cache_data.each do |colony_prefix,obj_to_cache|
          ms.write_to_cache( "wtsi-pheno-data:#{colony_prefix.upcase}", obj_to_cache )
        end
        
        # result_data[:'cached_pheno_data'] = cache_data
      end
    end
    
  end
end
