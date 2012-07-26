module MartSearch
  class Server

    get "/go_ontology/?" do
      #if params[:id].nil? || ! params[:id].include?('-')
      #  status 404
      #  erb :not_found
      #  halt
      #end

      id_params = params[:id].split('-')

      mgi_acc_id = id_params[0].gsub('MGI','MGI:')
      go_id      = id_params[1].gsub('GO','GO:')

      cached_ontology_data = @ms.fetch_from_cache( "go-ontology:#{mgi_acc_id}" )
      if cached_ontology_data.nil?
        @ms.search( mgi_acc_id )
        cached_ontology_data = @ms.fetch_from_cache( "go-ontology:#{mgi_acc_id}" )

        if cached_ontology_data.nil?
          status 404
          erb :not_found
          halt
        end
      end

      go_data = cached_ontology_data[go_id.to_sym]
      if go_data.nil?
        status 404
        erb :not_found
        halt
      else
        content_type 'application/json', :charset => 'utf-8'
        return go_data.to_json
      end
    end

  end
end
