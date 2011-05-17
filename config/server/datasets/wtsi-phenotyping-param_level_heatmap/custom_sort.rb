# encoding: utf-8

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
      mp_group_conf = nil
      @config[:mp_heatmap_config].each do |mp_conf|
        next unless mp_group_conf.nil?
        
        if result[:mp_id]
          # Can we test by MP term?
          mp_group_conf = mp_conf if mp_conf[:child_terms].include?( result[:mp_id] )
        else
          # No MP term - try to match via "test|prototcol|parameter"
          param_key = [ result[:test], result[:protocol], result[:parameter] ].join('|')
          mp_group_conf  = mp_conf if mp_conf[:mgp_parameters].include?( param_key )
        end
      end
      
      unless mp_group_conf.nil?
        slug = mp_group_conf[:slug].to_sym
        mp_groups[slug] ||= {
          :mp_id     => mp_group_conf[:term],
          :mp_term   => mp_group_conf[:name],
          :test_data => {},
          :call      => nil
        }
        
        wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[slug][:test_data] )
        
        if result[:manual_call] == 'Significant'
          mp_groups[slug][:call] = 'significant'
        else
          mp_groups[slug][:call] = 'no_significant_annotations' unless mp_groups[slug][:call] == 'significant'
        end
      end
      
    end
    
    def wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, test_groups )
      test_key                = result[:test].gsub("[\(\)]","").gsub(" ","_").downcase.to_sym
      parameter               = result[:parameter]
      protocol_id_key         = result[:protocol_id].to_sym
      test_groups[test_key] ||= { :test => result[:test], :protocol_data => {} }
      
      per_protocol_data = test_groups[test_key][:protocol_data][protocol_id_key] ||= {
        :protocol               => result[:protocol],
        :protocol_description   => result[:protocol_description],
        :order_by               => result[:protocol_order_by],
        :pipeline               => result[:pipeline],
        :parameters             => {},
        :significant_parameters => false
      }
      
      per_protocol_data[:significant_parameters] = true if result[:manual_call] == 'Significant'
      
      param_data = per_protocol_data[:parameters][parameter] ||= {
        :order_by      => result[:parameter_order_by].to_i,
        :graphs        => [],
        :mp_annotation => {}
      }
      
      graph_url         = result[:graph_url]
      gender_genotype   = :"#{result[:gender]}_#{result[:genotype]}"
      
      param_data[:graphs].push( graph_url ) unless param_data[:graphs].include?( graph_url )
      param_data[:mp_annotation].merge!({ result[:mp_id] => result[:mp_term] }) unless result[:mp_id].blank?
      
      param_data[gender_genotype] ||= {
        :gender                     => result[:gender],
        :genotype                   => result[:genotype],
        :manual_call                => result[:manual_call]
      }
      
      test_groups[test_key][:protocol_data][protocol_id_key] = per_protocol_data
    end
    
  end
end
