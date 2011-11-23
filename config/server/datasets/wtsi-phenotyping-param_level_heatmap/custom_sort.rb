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

      # grab the MP heatmap config once
      mp_heatmap_config = wtsi_phenotyping_param_level_heatmap_mp_heatmap_config

      # Group the data by colony_prefix...
      results.each do |result|
        # Setup the data object...
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        sorted_results[joined_attribute] ||= {}
        sorted_results[joined_attribute][joined_attribute.to_sym] ||= {
          :population_id => result[:population_id].to_i,
          :mp_groups => {},
          :test_groups => {}
        }

        mp_groups   = sorted_results[joined_attribute][joined_attribute.to_sym][:mp_groups]
        test_groups = sorted_results[joined_attribute][joined_attribute.to_sym][:test_groups]

        # process and store the individual results data...
        wtsi_phenotyping_param_level_heatmap_sort_mp_heatmap_data( result, mp_groups, mp_heatmap_config )
        wtsi_phenotyping_param_level_heatmap_sort_test_group_data( result, test_groups )

        # TODO: When MIG gets their collab data in the param level heatmap we can ditch this clause!
        test_groups.delete( :eye_histopathology )

        # TODO: When the ABR data is handled correctly too we can also ditch this...
        test_groups.delete( :auditory_brainstem_response )

      end

      return sorted_results
    end

    private

    def wtsi_phenotyping_param_level_heatmap_mp_heatmap_config
      ms = MartSearch::Controller.instance()

      config_data = ms.fetch_from_cache("wtsi-pheno-mp-heatmap-config")
      if config_data.nil?
        config_data = wtsi_phenotyping_build_mp_heatmap_config
        ms.write_to_cache("wtsi-pheno-mp-heatmap-config",config_data)
      end

      return config_data
    end

    def wtsi_phenotyping_build_mp_heatmap_config
      ms = MartSearch::Controller.instance()

      mp_ontology = wtsi_phenotyping_mp_groups

      heatmap_config = []
      parameter_map = {}

      datasource = ms.datasources[:'wtsi-possible_mp_terms']
      raise MartSearch::InvalidConfigError, "MartSearch::DataSet.wtsi_phenotyping_build_mp_heatmap_config cannot be called if the 'wtsi-possible_mp_terms' datasource is inactive" if datasource.nil?

      mart = datasource.ds

      results  = mart.search(
        :process_results => true,
        :attributes => [
          "protocol",
          "test_name",
          "parameter_name",
          "mp_term"
        ]
      )

      results.recursively_symbolize_keys!

      results.each do |row|
        param_key = row[:mp_term]
        param_value = [ row[:test_name], row[:protocol], row[:parameter_name] ].join('|')

        parameter_map[ param_key ] ||= []
        parameter_map[ param_key ].push( param_value )
      end

      mp_ontology.each do |mp_term|
        mp_term = mp_term.clone

        mp_term[:mgp_parameters] = []

        mp_term[:child_terms].each do |term|
          if parameter_map.has_key?(term)
            parameters = parameter_map[term]
            mp_term[:mgp_parameters].push( parameters )
          end
        end

        mp_term[:mgp_parameters].flatten!
        mp_term[:mgp_parameters].uniq!

        heatmap_config.push(mp_term)
      end

      return heatmap_config
    end

    def wtsi_phenotyping_mp_groups
      config      = []
      mp_ontology = OLS.find_by_id('MP:0000001')

      ignored_terms = [ 
        "normal phenotype",
        "no phenotypic analysis"
      ]

      mp_ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
        unless ignored_terms.include?(child.term_name)
          conf_data = {
            :term                => child.term_id,
            :name                => child.term_name.gsub(' phenotype',''),
            :slug                => child.term_name.gsub(' phenotype','').gsub(/[\/\s\-]/,'-').downcase,
            :child_terms         => [ child.term_id, child.all_child_ids ].flatten.uniq
          }

          config.push(conf_data)
        end
      end

      return config
    end

    def wtsi_phenotyping_param_level_heatmap_sort_mp_heatmap_data( result, mp_groups, mp_heatmap_config )
      mp_group_conf = nil

      mp_heatmap_config.each do |mp_conf|
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
      test_key                = result[:test].gsub(/[\(\)]/,"").gsub(/[ -]/,"_").downcase.to_sym
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
        :population_parameter => { :population_id => result[:population_id].to_i, :parameter_id => result[:parameter_id].to_i },
        :order_by             => result[:parameter_order_by].to_i,
        :graphs               => [],
		    :data_files	          => [],
        :mp_annotation        => {}
      }

      graph_url     = result[:graph_url]
	    data_url		  = result[:raw_data_url]
      gender_genotype = :"#{result[:gender]}_#{result[:genotype]}"

      param_data[:graphs].push( graph_url ) unless param_data[:graphs].include?( graph_url )
	    param_data[:data_files].push( data_url ) unless param_data[:data_files].include?( data_url )
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
