# encoding: utf-8

module MartSearch
  module DataSetUtils

    # Secondary sort for the Ensembl Mouse GO dataset.  This combines all of the 
    # retrieved GO terms and pre-computes the trees.
    def ensembl_mouse_go_secondary_sort( search_data )
      ms = MartSearch::Controller.instance()

      search_data.each do |key,result_data|
        raw_data   = result_data[:'ensembl-mouse-go']
        mgi_acc_id = result_data[:index][:mgi_accession_id_key]

        next if raw_data.blank?

        go_terms = {
          :molecular_function => [],
          :biological_process => [],
          :cellular_component => []
        }

        # First convert the raw ontology terms into trees, and put them
        # into correct GO baskets.
        raw_data.each do |result|
          begin
            term = OLS.find_by_id(result[:go_id])
            next if term.is_root?
            term.remove_children!
            term.focus_graph!
            go_terms[ term.root.term_name.to_sym ].push(term)
          rescue OLS::TermNotFoundError => e
            # Not a lot we can do here... move along...
          end
        end

        # Now merge the trees and prepare for conversion to json (for the jstree)
        # tree widget.
        go_terms.each do |category,trees|
          merged_tree = trees.reduce(:merge!)
          unless merged_tree.nil?
            go_terms[category] = ensembl_mouse_go_prepare_ontology_tree_for_jsonifying( mgi_acc_id, merged_tree )
          end
        end

        # Cache the json for the jstree widget.
        go_data = {}
        go_data_root = []

        [:molecular_function,:biological_process,:cellular_component].each do |category|
          next if go_terms[category].empty?
          go_data_root.push( go_terms[category][:root] )
          go_terms[category].delete(:root)
          go_data.merge!(go_terms[category])
        end

        go_data['root'] = go_data_root

        ms.write_to_cache( "go-ontology:#{mgi_acc_id}", go_data )
      end

      return search_data
    end

    private

    def ensembl_mouse_go_prepare_ontology_tree_for_jsonifying( mgi_acc_id, tree )
      root_node       = tree.root

      json = { :root => ensembl_mouse_go_basic_json( mgi_acc_id, root_node ) }

      if root_node.has_children?
        json[root_node.term_id] = root_node.children.map { |child| ensembl_mouse_go_basic_json( mgi_acc_id, child ) }

        root_node.all_children.each do |child|
          if child.has_children?
            json[child.term_id] = child.children.map { |grand_child| ensembl_mouse_go_basic_json( mgi_acc_id, grand_child ) }
          end
        end
      end

      return json
    end

    def ensembl_mouse_go_basic_json( mgi_acc_id, tree )
      mgi_ontology_link = '<a href="http://www.informatics.jax.org/searches/GO.cgi?id=' + tree.term_id + '" class="ext_link" target="_blank">view at MGI</a>'

      json = { :data => "#{tree.term_name} (#{tree.term_id}) #{mgi_ontology_link}" }

      if tree.has_children?
        json[:state] = 'closed'
        json[:attr]  = { :id => "#{mgi_acc_id.gsub(':','')}-#{tree.term_id.gsub(':','')}" }
      else
        json[:state] = 'open'
        json[:attr] = { :rel => 'leaf_node' }
      end

      return json
    end

  end
end
