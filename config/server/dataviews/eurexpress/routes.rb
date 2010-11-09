
get "/eurexpress_browse/?" do
  content_type 'application/json', :charset => 'utf-8'
  
  options     = params[:id].split('-')
  mgi_acc_id  = options[0].gsub('MGI','MGI:')
  assay_index = options[1].to_i
  emap_id     = options[2].gsub('EMAP','EMAP:')
  
  cached_dataset_data = @ms.cache.fetch( "datasets:#{mgi_acc_id}" )
  cached_dataset_data = BSON.deserialize(cached_dataset_data) unless @ms.cache.is_a?(MartSearch::MongoCache)
  cached_dataset_data = cached_dataset_data.clean_hash if RUBY_VERSION < '1.9'
  cached_dataset_data.recursively_symbolize_keys!
  
  data      = cached_dataset_data[:eurexpress][assay_index]
  tree_data = []
  
  if emap_id == 'EMAP:0'
    tree      = @ms.ontology_cache.fetch( 'EMAP:7148' )
    tree_data = [{
      :data  => "Mouse_anatomy_by_time_xproduct (EMAP:0)",
      :state => "open",
      :children => [
        {
          :data     => "TS23,embryo (EMAP:7148)",
          :attr     => { :id => "#{options[0]}-#{options[1]}-EMAP7148" },
          :state    => 'open',
          :children => calc_emap_tree( options, tree.children, data[:annotations], 3 )
        }
      ]
    }]
  else
    tree      = @ms.ontology_cache.fetch( emap_id )
    tree_data = calc_emap_tree( options, tree.children, data[:annotations], tree.node_depth+1 )
  end
  
  return JSON.generate( tree_data, :max_nesting => false )
end

def calc_emap_tree( get_options, children, annotations, node_depth )
  tree_data = []
  
  children.each do |child|
    terms_to_test = child.all_child_terms
    child_anns    = terms_to_test.select { |term| annotations.has_key?(term.to_sym) }
    anns_recorded = child_anns.size
    anns_recorded = anns_recorded + 1 if annotations.has_key?(child.term.to_sym)
    
    child_data = {
      :data  => "#{child.term_name} (#{child.term}) - <em>#{anns_recorded} annotations recorded</em>",
      :attr  => { :id => "#{get_options[0]}-#{get_options[1]}-#{child.term.gsub(':','')}" },
      :state => 'closed'
    }
    
    if child_anns.size > 0 and child.node_depth < node_depth
      child_data[:children] = calc_emap_tree( get_options, child.children, annotations, node_depth )
    elsif child_anns.size > 0
      child_data[:children] = []
    else
      child_data[:attr][:rel] = 'leaf_node' 
      child_data[:state]      = 'open'
      child_data[:children]   = []
    end
    
    tree_data.push(child_data) if anns_recorded > 0
  end
  
  return tree_data
end
