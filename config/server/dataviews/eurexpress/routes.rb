# encoding: utf-8

module MartSearch
  class Server

    get "/eurexpress_emap/?" do
      options  = params[:id].split('-')

      assay_id = options[0]
      emap_id  = options[1].gsub('EMAP','EMAP:')

      cached_ontology_data = @ms.fetch_from_cache("eurexpress_emap_graph:#{assay_id}")
      if cached_ontology_data.nil?
        status 404
        erb :not_found
        halt
      end

      emap_data = cached_ontology_data[emap_id.to_sym]
      if emap_data.nil?
        status 404
        erb :not_found
        halt
      else
        # append a search link to the :data string
        emap_data.each do |child_data|
          next if child_data[:emap_id] == 'EMAP:0'
          child_data[:data] << " #{link_to( 'search', "/search?query=#{child_data[:emap_id]}", { :class => 're_search' } )}"
        end

        content_type 'application/json', :charset => 'utf-8'
        return emap_data.to_json
      end

    end

  end
end
