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
      
      results.each do |result|
        # Setup the data object...
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        sorted_results[joined_attribute] ||= {}
        sorted_results[joined_attribute][joined_attribute.to_sym] ||= { :mp_groups => {}, :test_groups => {} }
        
        mp_groups   = sorted_results[joined_attribute][joined_attribute.to_sym][:mp_groups]
        test_groups = sorted_results[joined_attribute][joined_attribute.to_sym][:test_groups]
        
        # Fix integers...
        result[:parameter_order_by] = result[:parameter_order_by].to_i
        
        # Now process and store the individual results data...
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
          mp_group = mp_conf[:term] if mp_conf[:child_terms].include?( result[:mp_id] )
        else
          # No MP term - try to match via "test|prototcol|parameter"
          param_key = [ result[:test], result[:protocol], result[:parameter] ].join('|')
          mp_group  = mp_conf[:term] if mp_conf[:mgp_parameters].include?( param_key )
        end
      end
      
      unless mp_group.nil?
        mp_groups[mp_group] ||= {
          :results               => { :significant => {}, :insignificant => {} },
          :is_significant        => nil
          
          # :male_results          => { :significant => {}, :insignificant => {} },
          # :female_results        => { :significant => {}, :insignificant => {} },
          # :is_male_significant   => nil,
          # :is_female_significant => nil
        }
        
        # sex_basket       = "#{result[:gender].downcase}_results".to_sym
        # sex_significance = "is_#{result[:gender].downcase}_significant".to_sym    
        
        if result[:manual_call] == 'Significant'
          wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][:results][:significant] )
          mp_groups[mp_group][:is_significant]  = true
          
          # wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][sex_basket][:significant] )
          # mp_groups[mp_group][sex_significance] = true
        else
          wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][:results][:insignificant] )
          mp_groups[mp_group][:is_significant]  = false if mp_groups[mp_group][:is_significant].nil?
          
          # wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, mp_groups[mp_group][sex_basket][:insignificant] )
          # mp_groups[mp_group][sex_significance] = false if mp_groups[mp_group][sex_significance].nil?
        end
      end
      
    end
    
    def wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, test_groups )
      pipeline             = result[:pipeline]
      colony_prefix        = result[:colony_prefix]
      test                 = result[:test]
      protocol             = result[:protocol]
      protocol_description = result[:protocol_description]
      
      # Set up a storage object - remove lots of redundancy in the data
      stored_result               = result.clone
      fields_to_omit_from_storage = [
        :pipeline, :colony_prefix, :param_level_heatmap_colony_prefix,
        :test, :protocol, :protocol_description, :mp_id, :mp_term
      ]
      stored_result.delete_if { |key,value| fields_to_omit_from_storage.include?(key) }
      
      if result[:mp_id].nil?
        stored_result[:mp_annotation] = {}
      else
        stored_result[:mp_annotation] = { result[:mp_id] => result[:mp_term] }
      end
      
      if protocol_description.nil?
        # This is a PDF (or collaborator) download - they don't have descriptions in the MIG system
        test_groups[test] ||= { :significant => [], :insignificant => [] }

        significant = :insignificant
        significant = :significant if result[:manual_call] == 'Significant'

        test_groups[test][significant].push(result)
      else
        # 'Regular' published graphs...
        test_groups[test] ||= { :significant => {}, :insignificant => {} }
        
        significant = :insignificant
        significant = :significant if result[:manual_call] == 'Significant'
        
        test_groups[test][significant][:test] = test
        
        # Use an MD5 hash of the test_description to correctly group the graphs - this 
        # helps sort out protocols that have the SAME name but DIFFERENT descriptions!
        protocol_desc_hash = Digest::MD5.hexdigest(protocol_description)
        
        test_groups[test][significant][protocol_desc_hash]                        ||= {}
        test_groups[test][significant][protocol_desc_hash][:graphs]               ||= {}
        test_groups[test][significant][protocol_desc_hash][:protocol]               = protocol
        test_groups[test][significant][protocol_desc_hash][:protocol_description]   = protocol_description
        test_groups[test][significant][protocol_desc_hash][:pipeline]               = pipeline
        
        graph_data = test_groups[test][significant][protocol_desc_hash][:graphs][result[:parameter_order_by]]
        
        if graph_data.nil?
          graph_data = stored_result
        else
          graph_data[:mp_annotation].merge!(stored_result[:mp_annotation])
        end
        
        test_groups[test][significant][protocol_desc_hash][:graphs][result[:parameter_order_by]] = graph_data
      end
      
    end
    
  end
end
