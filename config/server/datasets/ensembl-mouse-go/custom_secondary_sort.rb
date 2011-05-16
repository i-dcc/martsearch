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
            tree = MartSearch::OntologyTerm.new(result[:go_id])
            tree.get_parents
            tree.instance_variable_set( :@already_fetched_children, true )
            tree.instance_variable_set( :@leaf_node, true )
            tree.remove_all!
            go_terms[ tree.root.term_name.to_sym ].push(tree)
          rescue MartSearch::OntologyTermNotFoundError => e
            # Not a lot we can do here... move along...
          end
        end
        
        # Now merge the trees and prepare for conversion to json (for the jstree) 
        # tree widget.
        go_terms.each do |category,trees|
          merged_tree = nil
          trees.each do |tree|
            if merged_tree.nil?
              merged_tree = tree
            else
              merged_tree = merged_tree.merge( tree )
            end
          end
          
          unless merged_tree.nil?
            go_terms[category] = ensembl_mouse_go_prepare_ontology_tree_for_jsonifying( merged_tree )
          end
        end
        
        # Cache the json for the jstree widget.
        ontology_tree = []
        ontology_tree.push( go_terms[:molecular_function] ) unless go_terms[:molecular_function].empty?
        ontology_tree.push( go_terms[:biological_process] ) unless go_terms[:biological_process].empty?
        ontology_tree.push( go_terms[:cellular_component] ) unless go_terms[:cellular_component].empty?
        
        ms.write_to_cache( "go-ontology:#{mgi_acc_id}", { :json => JSON.generate( ontology_tree, :max_nesting => false ) } )
        # result_data[:'ensembl-mouse-go'] = JSON.generate( ontology_tree, :max_nesting => false )
      end
      
      return search_data
    end
    
    private
    
    def ensembl_mouse_go_prepare_ontology_tree_for_jsonifying( tree )
      root_node       = tree.root
      json            = ensembl_mouse_go_basic_json( root_node )
      json[:children] = ensembl_mouse_go_child_json( root_node ) if root_node.has_children?
      return json
    end
    
    def ensembl_mouse_go_basic_json( tree )
      mgi_ontology_link = '<a href="http://www.informatics.jax.org/searches/GO.cgi?id=' + tree.term + '" class="ext_link" target="_blank">view at MGI</a>'
      
      json        = { :data => "#{tree.term_name} (#{tree.term}) #{mgi_ontology_link}" }
      json[:attr] = { :rel => 'leaf_node' } unless tree.has_children?
      return json
    end
    
    def ensembl_mouse_go_child_json( tree )
      children_json = []
      
      tree.children.each do |child|
        child_json            = ensembl_mouse_go_basic_json( child )
        child_json[:children] = ensembl_mouse_go_child_json( child ) if child.has_children?
        children_json.push( child_json )
      end
      
      return children_json
    end
    
  end
end
