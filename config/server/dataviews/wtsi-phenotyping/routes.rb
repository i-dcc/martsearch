module MartSearch
  class Server
    
    ##
    ## Static route for serving the MGP spreadsheet
    ##
    
    get "/phenotyping/mgp_heatmap.xls" do
      file = "#{MARTSEARCH_PATH}/tmp/pheno_overview.xls"
      if File.exists?(file)
        content = IO.binread(file)
        cache_control :no_cache
        content_type Rack::Mime.mime_type('.xls')
        return content
      else
        status 404
        erb :not_found
      end
    end
    
    ##
    ## Static routes for ABR - these are just forwarding static content.
    ##
    
    get "/phenotyping/:colony_prefix/auditory-brainstem-response" do
      redirect url_for( "/phenotyping/#{params[:colony_prefix]}/auditory-brainstem-response/" )
    end
    
    get "/phenotyping/:colony_prefix/auditory-brainstem-response/" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'auditory_brainstem_response' )
      fs_location    = @ms.datasources[:'wtsi-phenotyping-abr'].fs_location
      file           = "#{fs_location}/#{@colony_prefix}/ABR/index.shtml"
      
      if @data and File.exists?(file)
        @page_title = "#{@data[:marker_symbol]} (#{@colony_prefix}): Auditory Brainstem Response (ABR)"
        html_text   = File.read(file)
        
        erb html_text
      else
        status 404
        erb :not_found
      end
    end
    
    get "/phenotyping/:colony_prefix/auditory-brainstem-response/*" do
      @colony_prefix = params[:colony_prefix].upcase
      
      fs_location = @ms.datasources[:'wtsi-phenotyping-abr'].fs_location
      file        = "#{fs_location}/#{@colony_prefix}/ABR/#{params[:splat][0]}"
      
      if File.exists?(file)
        content = IO.binread(file)
        content_type Rack::Mime.mime_type( File.extname(file) )
        return content
      else
        status 404
        erb :not_found
      end
    end
    
    ##
    ## Static routes for more tests that use different 
    ## templates so need to be handled differently.
    ##
    
    get "/phenotyping/:colony_prefix/adult-lac-z-expression/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'adult_lac_z_expression' )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Adult LacZ Expression"
        @bg_staining_imgs = @ms.dataviews_by_name[:'wtsi-phenotyping'].config[:wt_lacz_background_staining_adult]
        erb :"dataviews/wtsi-phenotyping/adult_expression_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/embryo-lac-z-expression/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'embryo_lac_z_expression' )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Embryo LacZ Expression"
        erb :"dataviews/wtsi-phenotyping/embryo_expression_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/tail-epidermis-wholemount/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'tail_epidermis_wholemount' )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Tail Epidermis Wholemount"
        erb :"dataviews/wtsi-phenotyping/tail_epidermis_wholemount_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/viability-at-weaning/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'viability_at_weaning' )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @page_title = "#{@data[:marker_symbol]} (#{@colony_prefix}): Viability at Weaning"
        erb :"dataviews/wtsi-phenotyping/homviable_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/fertility/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'fertility' )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @marker_symbol = @data[0][:marker_symbol]
        @page_title    = "#{@marker_symbol} (#{@colony_prefix}): Fertility"
        erb :"dataviews/wtsi-phenotyping/fertility_details"
      end
    end
    
    ##
    ## Routes for everything else
    ##
    
    get "/phenotyping/:colony_prefix/mp-report/:mp_slug/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_mp_report_data( @colony_prefix, params[:mp_slug].downcase )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @marker_symbol = @data[:marker_symbol]
        @page_title    = "#{@marker_symbol} (#{@colony_prefix}): #{@data[:mp_id]} - #{@data[:mp_term]}"
        erb :"dataviews/wtsi-phenotyping/mp_test_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/:pheno_test/?" do
      test           = params[:pheno_test].downcase.gsub('-','_')
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, test )
      
      if @data.nil?
        status 404
        erb :not_found
      else
        @marker_symbol = @data[:marker_symbol]
        @test_name     = @data[:test]
        @page_title    = "#{@marker_symbol} (#{@colony_prefix}): #{@test_name}"
        erb :"dataviews/wtsi-phenotyping/test_details"
      end
    end
    
  end
end