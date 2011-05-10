module MartSearch
  module DataSetUtils
    
    # Custom sort for the param_level_heatmap data coming from the WTSI MGP 
    # phenotyping activities.  Sorts the data two ways - one by MP ontology, 
    # and the other into test groupings.
    def wtsi_phenotyping_param_level_heatmap_sort_results( results )
      sorted_results = {}
      
      # remove the 'param_level_heatmap_' prefix from the attributes
      prefix            = /^param_level_heatmap\_/
      processed_results = []
      results.each do |result|
        processed_result = {}
        result.each do |key,value|
          processed_result[key] = value if key == @config[:searching][:joined_attribute].to_sym
          processed_result[ key.to_s.gsub(prefix,'').to_sym ] = value
        end
        processed_results.push(processed_result)
      end
      results = processed_results
      
      # Group the data by colony_prefix...
      results.each do |result|
        # Setup the data object...
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        sorted_results[joined_attribute] ||= {}
        sorted_results[joined_attribute][joined_attribute.to_sym] ||= { :mp_groups => {}, :test_groups => {} }
        
        mp_groups   = sorted_results[joined_attribute][joined_attribute.to_sym][:mp_groups]
        test_groups = sorted_results[joined_attribute][joined_attribute.to_sym][:test_groups]
        
        # process and store the individual results data...
        wtsi_phenotyping_param_level_heatmap_sort_mp_heatmap_data( result, mp_groups )
        wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, test_groups )
      end
      
      return sorted_results
    end
    
    private
    
    def wtsi_phenotyping_param_level_heatmap_sort_mp_heatmap_data( result, mp_groups )
      mp_group = nil
      @config[:mp_heatmap_config].each do |mp_conf|
        next unless mp_group.nil?
        
        if result[:mp_id]
          # Can we test by MP term?
          mp_group = mp_conf[:term].to_sym if mp_conf[:child_terms].include?( result[:mp_id] )
        else
          # No MP term - try to match via "test|prototcol|parameter"
          param_key = [ result[:test], result[:protocol], result[:parameter] ].join('|')
          mp_group  = mp_conf[:term].to_sym if mp_conf[:mgp_parameters].include?( param_key )
        end
      end
      
      unless mp_group.nil?
        mp_groups[mp_group] ||= {
          :significant   => {}, 
          :insignificant => {},
          :call          => nil
        }
        
        if result[:manual_call] == 'Significant'
          wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][:significant] )
          mp_groups[mp_group][:call] = 'significant'
        else
          wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][:insignificant] )
          mp_groups[mp_group][:call] = 'no_significant_annotations' unless mp_groups[mp_group][:call] == 'significant'
        end
      end
      
    end
    
    def wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, test_groups )
      test                   = result[:test]
      protocol_description   = result[:protocol_description]
      parameter              = result[:parameter]
      
      # Use an MD5 hash of the test_description to correctly group the graphs - this 
      # helps sort out protocols that have the SAME name but DIFFERENT descriptions!
      protocol_desc_hash = Digest::MD5.hexdigest(protocol_description)
      
      test_groups[test]    ||= { :test => test, :significant => {}, :all => {} }
      
      baskets_to_add_to = [:all]
      baskets_to_add_to.push(:significant) if result[:manual_call] == 'Significant'
      
      baskets_to_add_to.each do |basket|
        graph_url         = result[:graph_url]
        per_protocol_data = test_groups[test][basket][protocol_desc_hash] ||= {
          :protocol             => result[:protocol],
          :protocol_description => protocol_description,
          :pipeline             => result[:pipeline],
          :parameters           => {}
        }
        
        unless graph_url.blank?
          param_data = per_protocol_data[:parameters][parameter] ||= { :order_by => result[:parameter_order_by].to_i, :graphs => [] }
          param_data[:graphs].push( graph_url ) unless param_data[:graphs].include?( graph_url )
        end
        
        test_groups[test][basket][protocol_desc_hash] = per_protocol_data
      end
    end
    
  end
end
