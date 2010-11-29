
##
## Sort the phenotyping results into the groupings defined in the config
## ready for display...
##

ms          = MartSearch::Controller.instance()
ds_attribs  = ms.datasources[:"wtsi-phenotyping"].ds.attributes
test_groups = @config[:test_groups]

search_data.each do |key,result_data|
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
        
        if related_targ_rep_clone[:allele_symbol_superscript] and result_data[:'index'][:marker_symbol]
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
          unless result_data[:'wtsi-mgp_graphs'].nil?
            mgp_graphs = result_data[:'wtsi-mgp_graphs'][result[:colony_prefix].to_sym]
            unless mgp_graphs.nil?
              mgp_graphs.each do |test_name,image_data|
                if test_display_name.gsub("\(","").gsub("\)","") =~ Regexp.new(image_data[0][:heatmap_group], true)
                  result["#{test}_data".to_sym] = image_data
                end
              end
            end
          end
          
          
          
        end
        
        group_data[:results].push(result)
      end
      
    end
    
    heatmap_data[group.to_sym] = group_data
  end
  
  result_data[:'wtsi-phenotyping-heatmap-processed'] = heatmap_data
end