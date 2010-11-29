
##
## Static route for more tests that use different 
## templates so need to be handled differently.
##

get "/phenotyping/:colony_prefix/homozygote-viability/?" do
  @colony_prefix = params[:colony_prefix].upcase
  @data          = wtsi_phenotyping_fetch_report_data( @colony_prefix, 'homozygote_viability' )
  
  if @data.nil?
    status 404
    erubis :not_found
  else
    @page_title    = "#{@data[:marker_symbol]} (#{@colony_prefix}): Homozygote Viability"
    erubis :"dataviews/wtsi-phenotyping/homviable_test_details"
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
    erubis :"dataviews/wtsi-phenotyping/fertility_test_details"
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
    @marker_symbol = @data[0][:marker_symbol]
    @test_name     = @data[0][:heatmap_group]
    @test_desc     = @data[0][:heatmap_group_description]
    @page_title    = "#{@marker_symbol} (#{@colony_prefix}): #{@test_name}"
    erubis :"dataviews/wtsi-phenotyping/test_details"
  end
end