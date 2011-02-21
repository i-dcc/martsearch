module MartSearch
  class Server
    
    ##
    ## Static routes for ABR - these are just forwarding static content.
    ##
    
    get "/phenotyping/:colony_prefix/abr" do
      redirect url_for( "/phenotyping/#{params[:colony_prefix]}/abr/" )
    end
    
    get "/phenotyping/:colony_prefix/abr/" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'abr' )
      fs_location    = @ms.datasources[:'wtsi-phenotyping-abr'].fs_location
      file           = "#{fs_location}/#{@colony_prefix}/ABR/index.shtml"
      
      if @data and File.exists?(file)
        @page_title = "#{@data[:marker_symbol]} (#{@colony_prefix}): Auditory Brainstem Response (ABR)"
        html_text   = File.read(file)
        
        erubis html_text
      else
        status 404
        erubis :not_found
      end
    end
    
    get "/phenotyping/:colony_prefix/abr/*" do
      @colony_prefix = params[:colony_prefix].upcase
      
      fs_location = @ms.datasources[:'wtsi-phenotyping-abr'].fs_location
      file        = "#{fs_location}/#{@colony_prefix}/ABR/#{params[:splat][0]}"
      
      if File.exists?(file)
        content = nil
        File.open(file,"r") do |f|
          content = f.read
        end
        
        content_type MIME::Types.type_for(file)
        return content
      else
        status 404
        erubis :not_found
      end
    end
    
    ##
    ## Static routes for more tests that use different 
    ## templates so need to be handled differently.
    ##
    
    get "/phenotyping/:colony_prefix/adult-expression/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'adult_expression' )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Adult Expression"
        @bg_staining_imgs = @ms.dataviews_by_name[:'wtsi-phenotyping'].config[:wt_lacz_background_staining_adult]
        erubis :"dataviews/wtsi-phenotyping/adult_expression_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/embryo-expression/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'embryo_expression' )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Embryo Expression"
        erubis :"dataviews/wtsi-phenotyping/embryo_expression_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/skin-screen/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'skin_screen' )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @page_title       = "#{@data[:marker_symbol]} (#{@colony_prefix}): Skin Screen"
        erubis :"dataviews/wtsi-phenotyping/skin_screen_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/homozygote-viability/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'homozygote_viability' )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @page_title = "#{@data[:marker_symbol]} (#{@colony_prefix}): Homozygote Viability"
        erubis :"dataviews/wtsi-phenotyping/homviable_details"
      end
    end
    
    get "/phenotyping/:colony_prefix/fertility/?" do
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'fertility' )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @marker_symbol = @data[0][:marker_symbol]
        @page_title    = "#{@marker_symbol} (#{@colony_prefix}): Fertility"
        erubis :"dataviews/wtsi-phenotyping/fertility_details"
      end
    end
    
    ##
    ## Routes for everything else
    ##
    
    get "/phenotyping/:colony_prefix/:pheno_test/?" do
      test           = params[:pheno_test].downcase.gsub('-','_')
      @colony_prefix = params[:colony_prefix].upcase
      @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, test )
      
      if @data.nil?
        status 404
        erubis :not_found
      else
        @marker_symbol = @data[:marker_symbol]
        @test_name     = @data[:heatmap_group]
        @page_title    = "#{@marker_symbol} (#{@colony_prefix}): #{@test_name}"
        erubis :"dataviews/wtsi-phenotyping/test_details"
      end
    end
    
  end
end