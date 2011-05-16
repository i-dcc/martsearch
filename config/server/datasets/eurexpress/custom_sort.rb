# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def eurexpress_sort_results( results )
      sorted_results = {}
      # chart_config   = @config[:chart_config]
      
      results.each do |result|
        joined_attribute      = result[ @config[:searching][:joined_attribute].to_sym ]
        ass_assay_id_key      = result[:ass_assay_id_key]
        
        result_data           = sorted_results[joined_attribute] ||= {}
        result_data_for_assay = result_data[ass_assay_id_key]    ||= {}
        
        
        # chart_config.keys.each do |field|
        #   result_data_for_assay[:chart][field] = { :score => 0, :found_terms => [] }
        # end
        
        result_data_for_assay[:assay_id]            = ass_assay_id_key
        result_data_for_assay[:assay_image_count]   = result[:assay_image_count]
        result_data_for_assay[:annotations]       ||= {}
        
        emap_id = result[:emap_id]
        emap_id = "EMAP:#{emap_id}" unless emap_id =~ /EMAP/
        
        result_data_for_assay[:annotations][emap_id.to_sym] = {
          :ann_pattern  => result[:ann_pattern],
          :ann_strength => result[:ann_strength]
        }
        
        # # Add to the chart...
        # result_data_for_assay[:chart].keys.each do |field|
        #   if chart_config[field][:all_terms].include?(emap_id)
        #     score = case result[:ann_strength]
        #     when 'strong'   then 10
        #     when 'moderate' then 5
        #     when 'weak'     then 2
        #     when 'possible' then 1
        #     else                 0
        #     end
        #     
        #     result_data_for_assay[:chart][field][:score] += score
        #     result_data_for_assay[:chart][field][:found_terms].push(emap_id)
        #   end
        # end
        
      end
      
      # Now sort the annotations into order of the ones with more 
      # annotations at the top...
      results_to_return = {}
      
      sorted_results.each do |id,the_results|
        assays = []
        the_results.each do |assay_id,assay_data|
          assays.push(assay_data)
        end
        results_to_return[id] = assays.sort_by { |elm| -1*(elm[:annotations].size) }
      end
      
      # Now calculate the EMAP ontology trees for the annotations and 
      # do the final correction for the expression chart...
      # ontology_cache = MartSearch::Controller.instance().ontology_cache
      # sorted_results.each do |id,assays|
      #   assays.each do |assay_id,assay_data|
      #     
      #     # EMAP tree...
      #     emap_ids  = assay_data[:annotations].keys.map { |emap_id| emap_id.to_s }
      #     emap_tree = ontology_cache.fetch_just_parents( emap_ids.shift )
      # 
      #     emap_ids.each do |emap_id|
      #       new_tree  = ontology_cache.fetch_just_parents( emap_id )
      #       emap_tree = emap_tree.merge( new_tree )
      #     end
      #     
      #     assay_data[:emap_tree] = JSON.generate( emap_tree, :max_nesting => false )
      #     
      #     # # Expression chart...
      #     # assay_data[:chart].each do |field,chart_data|
      #     #   assay_data[:chart][field][:found_terms].uniq!
      #     #   
      #     #   # coverage
      #     #   found_term_count = 0
      #     #   assay_data[:chart][field][:found_terms].each do |term|
      #     #     found_term_count += chart_config[field][:counts][term.to_sym]
      #     #   end
      #     #   assay_data[:chart][field][:coverage] = ( ( found_term_count * 100 ).to_f / chart_config[field][:all_terms].size.to_f ).round(2)
      #     # end
      #     
      #     assays[assay_id] = assay_data
      #   end
      #   
      #   sorted_results[id] = assays
      # end
      
      return results_to_return
    end
    
  end
end
