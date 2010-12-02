module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_heatmap_secondary_sort( search_data )
      ##
      ## Sort the phenotyping results into the groupings defined in the config
      ## ready for display...
      ##
      
      ms          = MartSearch::Controller.instance()
      ds_attribs  = ms.datasources[:"wtsi-phenotyping"].ds.attributes
      test_groups = @config[:test_groups]

      search_data.each do |key,result_data|
        next if result_data[:'wtsi-phenotyping-heatmap'].nil?
        
        heatmap_raw_data = result_data[:'wtsi-phenotyping-heatmap']
        heatmap_data     = {}
        
        ##
        ## Calculate what to display for each group bubble
        ##
        test_groups.each do |group,group_conf|
          
          ##
          ## First, determine if we should show the group bubble
          ##
          show_this_group   = false
          tests             = group_conf[:tests]
          allowed_pipelines = group_conf[:pipelines]
          
          heatmap_raw_data.each do |result|
            show_this_group = true if allowed_pipelines.include?(result[:pipeline])
          end
          
          if show_this_group
            group_data = {
              :results_of_interest => false,
              :allowed_pipelines   => allowed_pipelines,
              :tests               => {},
              :results             => []
            }
            
            ##
            ## Work out the display headings for these tests...
            ##
            tests.each do |test|
              group_data[:tests][test.to_sym] = ds_attribs[test].display_name
            end
            
            ##
            ## Now calculate what we should display for each 'result' row...
            ##
            heatmap_raw_data.each do |result|
              
              ##
              ## Do we want to show this row of data?
              ##
              next unless allowed_pipelines.include?(result[:pipeline])
              
              ##
              ## On a group level - do we have 'results of interest' for this group?
              ##
              unless group_data[:results_of_interest]
                tests.each do |test|
                  if wtsi_phenotyping_css_class_for_test(result[test.to_sym]) == "significant_difference"
                    group_data[:results_of_interest] = true
                  end
                end
              end
              
              ##
              ## First, see if we can match this mouse colony up to a colony 
              ## in Kermits - the allele names are a little more reliable there...
              ##
              related_kermits_entry = nil
              if result[:colony_prefix] && result_data[:'ikmc-kermits']
                result_data[:'ikmc-kermits'].each do |kerm|
                  if kerm[:colony_prefix] == result[:colony_prefix]
                    related_kermits_entry = kerm
                  end
                end
              end
              
              if related_kermits_entry and related_kermits_entry[:allele_name]
                result[:allele_name] = related_kermits_entry[:allele_name]
                result[:allele_type] = related_kermits_entry[:allele_type]
              end
              
              if related_kermits_entry and related_kermits_entry[:escell_clone]
                result[:escell_clone] = related_kermits_entry[:escell_clone]
              end
              
              ##
              ## Now try to match this colony up to an EPD clone in the targ_rep
              ## to get the cassette details - and also the allele name 
              ## (they're even more reliable in there :-P )...
              ##
              cassette               = nil
              related_targ_rep_clone = nil
              if (related_kermits_entry and related_kermits_entry[:escell_clone]) and result_data[:'ikmc-idcc_targ_rep']
                result_data[:'ikmc-idcc_targ_rep'].each do |project|
                  [:conditional_clones,:nonconditional_clones].each do |clone_type|
                    if project[clone_type]
                      project[clone_type].each do |clone|
                        if clone[:escell_clone] == related_kermits_entry[:escell_clone]
                          cassette               = project[:cassette]
                          related_targ_rep_clone = clone
                        end
                      end
                    end
                  end
                end
              end
              
              if (related_targ_rep_clone and related_targ_rep_clone[:allele_symbol_superscript]) and result_data[:index][:marker_symbol]
                result[:allele_name] = "#{result_data[:'index'][:marker_symbol]}<sup>#{related_targ_rep_clone[:allele_symbol_superscript]}</sup>"
              end
              
              if cassette
                result[:cassette_type] = "Promotorless"
                result[:cassette_type] = "Promotor Driven" if cassette =~ /_P$/
              end
              
              ##
              ## Finally check all the other WTSI MGP datasets for data and add links 
              ## to detailed report pages for each test...
              ##
              tests.each do |test|
                test_display_name = group_data[:tests][test.to_sym]
                
                # wtsi-mgp_graphs
                if result_data[:'wtsi-mgp_graphs']
                  mgp_graphs = result_data[:'wtsi-mgp_graphs'][result[:colony_prefix].to_sym]
                  unless mgp_graphs.nil?
                    mgp_graphs.each do |test_name,image_data|
                      if test_display_name.gsub("\(","").gsub("\)","") =~ Regexp.new(image_data[0][:heatmap_group], true)
                        result["#{test}_data".to_sym] = image_data
                      end
                    end
                  end
                end
                
                # wtsi-phenotyping-fertility
                if result_data[:'wtsi-phenotyping-fertility']
                  fertility = result_data[:'wtsi-phenotyping-fertility'][result[:colony_prefix].to_sym]
                  result[:fertility_data] = fertility unless fertility.nil?
                end
                
                # wtsi-phenotyping-hom_viability
                if result_data[:'wtsi-phenotyping-hom_viability']
                  viability = result_data[:'wtsi-phenotyping-hom_viability'][result[:colony_prefix].to_sym]
                  result[:homozygote_viability_data] = viability unless viability.nil?
                end
                
                # wtsi-expression-ticklist
                if result_data[:'wtsi-expression-ticklist']
                  ticklist = result_data[:'wtsi-expression-ticklist'][result[:colony_prefix].to_sym]
                  
                  if ticklist and !ticklist.empty?
                    result[:adult_expression_data]  = {} if result[:adult_expression_data].nil?
                    # result[:embryo_expression_data] = {} if result[:embryo_expression_data].nil?
                    result[:adult_expression_data][:ticklist]  = ticklist
                    # result[:embryo_expression_data][:ticklist] = ticklist
                  end
                end
                
                # wtsi-mgp_images-wholemount_expression
                if result_data[:'wtsi-mgp_images-wholemount_expression']
                  images = result_data[:'wtsi-mgp_images-wholemount_expression'][result[:colony_prefix].to_sym]
                  
                  if images and ( images[:adult] and !images[:adult].empty? )
                    result[:adult_expression_data] = {} if result[:adult_expression_data].nil?
                    result[:adult_expression_data][:images] = images[:adult]
                  end
                  
                  if images and ( images[:embryo] and !images[:embryo].empty? )
                    result[:embryo_expression_data] = {} if result[:embryo_expression_data].nil?
                    result[:embryo_expression_data][:images] = images[:embryo]
                  end
                end
                
                # wtsi-phenotyping-abr
                if result_data[:'wtsi-phenotyping-abr']
                  abr_page = result_data[:'wtsi-phenotyping-abr'][result[:colony_prefix].to_sym]
                  result[:abr_data] = { :page => abr_page } unless abr_page.nil?
                end
                
              end
              
              group_data[:results].push(result)
            end
            
          end
          
          heatmap_data[group.to_sym] = group_data
        end
        
        result_data[:'wtsi-phenotyping-heatmap-processed'] = heatmap_data
      end
      
      ##
      ## Run through the data one last time to cache the results details 
      ## ready for the report pages...
      ##
      
      search_data.each do |key,result_data|
        next if result_data[:'wtsi-phenotyping-heatmap'].nil?
        
        heatmap_data  = result_data[:'wtsi-phenotyping-heatmap']
        marker_symbol = result_data[:index][:marker_symbol]
        cache_data    = {}
        
        heatmap_data.each do |result|
          cache_data[result[:colony_prefix]] = {} if cache_data[result[:colony_prefix]].nil?
          
          result.keys.select{ |name| name.to_s =~ /_data$/ }.each do |result_key|
            test_data = result[result_key].clone
            
            if test_data.is_a?(Hash)
              test_data[:marker_symbol] = marker_symbol
            elsif test_data.is_a?(Array)
              test_data.map!{ |elm| elm[:marker_symbol] = marker_symbol; elm }
            end
            
            cache_data[result[:colony_prefix]][result_key] = test_data
          end
          
        end
        
        cache_data.each do |colony_prefix,obj_to_cache|
          cache_id = "wtsi-pheno-data:#{colony_prefix.upcase}"
          ms.cache.delete(cache_id)
          if ms.cache.is_a?(MartSearch::MongoCache)
            ms.cache.write( cache_id, obj_to_cache, { :expires_in => 36.hours } )
          else
            ms.cache.write( cache_id, BSON.serialize(obj_to_cache), { :expires_in => 36.hours } )
          end
        end
        
        result_data[:'cached_pheno_data'] = cache_data
      end
      
    end
    
  end
end