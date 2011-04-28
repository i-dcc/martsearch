module MartSearch
  class Server
    
    get "/go_ontology/?" do
      mgi_acc_id = params[:id].gsub('go-ontology-','').gsub('MGI','MGI:')
      
      cached_ontology_data = @ms.fetch_from_cache( "go-ontology:#{mgi_acc_id}" )
      if cached_ontology_data.nil?
        @ms.search( mgi_acc_id )
        cached_ontology_data = @ms.fetch_from_cache( "go-ontology:#{mgi_acc_id}" )
        
        if cached_ontology_data.nil?
          status 404
          erubis :not_found
          halt
        end
      end
      
      content_type 'application/json', :charset => 'utf-8'
      return cached_ontology_data[:json]
    end
    
  end
end