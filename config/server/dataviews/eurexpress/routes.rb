module MartSearch
  class Server

    get "/eurexpress_browse/?" do
      content_type 'application/json', :charset => 'utf-8'

      options     = params[:id].split('-')
      mgi_acc_id  = options[0].gsub('MGI','MGI:')
      assay_index = options[1].to_i
      emap_id     = options[2].gsub('EMAP','EMAP:')

      cached_dataset_data = @ms.fetch_from_cache( "datasets:#{mgi_acc_id}" )
      if cached_dataset_data.nil?
        @ms.search( mgi_acc_id )
        cached_dataset_data = @ms.search_data
      end

      tree_data = []

      unless cached_dataset_data[:eurexpress].nil?
        data = cached_dataset_data[:eurexpress][assay_index]

        if emap_id == 'EMAP:0'
          tree      = OLS.find_by_id( 'EMAP:7148' )
          tree_data = [{
            :data  => "mouse anatomy",
            :state => "open",
            :children => [
              {
                :data     => "TS23, embryo #{link_to( 'search', '/search?query=EMAP:7148', { :class => 're_search' } )}",
                :attr     => { :id => "#{options[0]}-#{options[1]}-EMAP7148" },
                :state    => 'open',
                :children => calc_emap_tree( options, tree.children, data[:annotations], 2 )
              }
            ]
          }]

          if data[:annotations].has_key?(:'EMAP:7148') and data[:annotations].size == 1
            tree_data[0][:children] = [
              {
                :data     => "TS23, embryo #{link_to( 'search', '/search?query=EMAP:7148', { :class => 're_search' } )}",
                :attr     => {
                  :id     => "#{options[0]}-#{options[1]}-EMAP7148",
                  :class  => data[:annotations][:'EMAP:7148'][:ann_strength].gsub(' ','_'),
                  :rel    => 'leaf_node'
                },
                :state    => 'open',
                :children => []
              }
            ]
          end
        else
          tree      = OLS.find_by_id( emap_id )
          tree_data = calc_emap_tree( options, tree.children, data[:annotations], tree.level+1 )
        end
      end

      return JSON.generate( tree_data, :max_nesting => false )
    end

    def calc_emap_tree( get_options, children, annotations, node_depth )
      tree_data = []

      children.each do |child|
        terms_to_test = child.all_child_ids
        child_anns    = terms_to_test.select { |term| annotations.has_key?(term.to_sym) }
        anns_recorded = child_anns.size
        anns_recorded = anns_recorded + 1 if annotations.has_key?(child.term_id.to_sym)

        child_data = {
          :data  => "#{child.term_name.sub('TS23,','')} - (#{anns_recorded}) #{link_to( 'search', '/search?query=' + child.term_id, { :class => 're_search' } )}",
          :attr  => { :id => "#{get_options[0]}-#{get_options[1]}-#{child.term_id.gsub(':','')}" },
          :state => 'closed'
        }

        if child_anns.size > 0 and child.level <= node_depth
          child_data[:children] = calc_emap_tree( get_options, child.children, annotations, node_depth )
        elsif child_anns.size > 0
          child_data[:children] = []
        elsif annotations.has_key?(child.term_id.to_sym)
          child_data[:data]         = "#{child.term_name.sub('TS23,','')} #{link_to( 'search', '/search?query=' + child.term_id, { :class => 're_search' } )}"
          child_data[:attr][:class] = annotations[child.term_id.to_sym][:ann_strength].gsub(' ','_')
          child_data[:attr][:rel]   = 'leaf_node' 
          child_data[:state]        = 'open'
        end

        tree_data.push(child_data) if anns_recorded > 0
      end

      return tree_data
    end

  end
end
