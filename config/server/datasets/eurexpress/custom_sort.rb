# encoding: utf-8

module MartSearch
  module DataSetUtils

    def eurexpress_sort_results(results)
      sorted_results = {}
      ms = MartSearch::Controller.instance()

      # First pass over the data an extract/group the information
      results.each do |result|
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        assay_id         = result[:ass_assay_id_key]

        result_data    = sorted_results[joined_attribute] ||= {}
        data_for_assay = result_data[assay_id]            ||= {}

        data_for_assay[:assay_id]           = assay_id
        data_for_assay[:assay_image_count]  = result[:assay_image_count]
        data_for_assay[:annotations]      ||= {}

        emap_id = result[:emap_id]
        emap_id = "EMAP:#{emap_id}" unless emap_id =~ /EMAP/

        data_for_assay[:annotations][emap_id] = {
          :ann_strength => result[:ann_strength],
          :ann_pattern  => result[:ann_pattern]
        }
      end

      # Now build up the ontology graphs for the annotations
      sorted_results.each do |joined_attribute,result_data|
        result_data.each do |assay_id,data_for_assay|
          emap_graphs = []
          emap_ids    = data_for_assay[:annotations].keys

          data_for_assay[:annotation_count] = emap_ids.size

          # Generate the initial graphs
          emap_ids.each do |emap_id|
            begin
              graph = OLS.find_by_id(emap_id)
              graph.remove_children!
              graph.focus_graph! unless graph.is_root?
              emap_graphs.push( graph )
            rescue OLS::TermNotFoundError => e
              # Not a lot we can do here... move along...
            end
          end

          # Merge the graphs
          merged_graph = emap_graphs.reduce(:merge!)

          # Create the JSON structures for jsTree
          merged_graph_json = eurexpress_prepare_ontology_for_jstree( data_for_assay[:assay_id], data_for_assay[:annotations], merged_graph )

          # Save it to cache
          ms.write_to_cache( "eurexpress_emap_graph:#{data_for_assay[:assay_id]}", merged_graph_json )
        end
      end

      # Finally, order the assays
      results_to_return = {}

      sorted_results.each do |id,the_results|
        assays = []
        the_results.each do |assay_id,assay_data|
          assays.push(assay_data)
        end
        results_to_return[id] = assays.sort_by { |elm| -1*(elm[:annotation_count]) }
      end

      return results_to_return
    end

    private

    def eurexpress_prepare_ontology_for_jstree( assay_id, annotations, merged_graph )
      root_node = merged_graph.root

      json = { :root => [ eurexpress_emap_term_json( assay_id, annotations, root_node ) ] }

      if root_node.has_children?
        json[root_node.term_id.to_sym] = root_node.children.map do |child|
          eurexpress_emap_term_json( assay_id, annotations, child )
        end

        root_node.all_children.each do |child|
          if child.has_children?
            json[child.term_id.to_sym] = child.children.map do |grand_child|
              eurexpress_emap_term_json( assay_id, annotations, grand_child )
            end
          end
        end
      end

      return json
    end

    def eurexpress_emap_term_json( assay_id, annotations, term )
      json = { :emap_id => term.term_id }

      if term.term_id == 'EMAP:0'
        json[:data] = 'mouse anatomy'
      else
        all_terms_to_test = term.all_child_ids
        annotation_count = annotations.keys.dup.delete_if { |term_id| !all_terms_to_test.include?(term_id) }.size

        json[:data] = "#{term.term_name}"
        json[:data].sub!('TS23,','') if term.term_id != 'EMAP:7148'
        json[:data] << " (#{annotation_count})" if annotation_count > 0
      end

      if term.has_children?
        json[:state] = 'closed'
        json[:attr]  = { :id => "#{assay_id}-#{term.term_id.gsub(':','')}" }
      else
        json[:state] = 'open'
        json[:attr] = { :rel => 'leaf_node' }
      end

      if annotations.has_key? term.term_id
        json[:attr][:class] = annotations[term.term_id][:ann_strength].gsub(' ','_')
      end

      return json
    end

  end
end
