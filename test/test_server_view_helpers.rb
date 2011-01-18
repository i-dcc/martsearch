require 'test_helper'

class MartSearchServerViewHelpersTest < Test::Unit::TestCase
  include MartSearch::ServerViewHelpers
  
  def test_content_tag
    assert_equal( "<p>w00t</p>", content_tag( 'p', 'w00t' ) )
    assert_equal( '<a href="http://google.com">google</a>', content_tag( :a, 'google', { :href => 'http://google.com' } ) )
  end
  
  def test_ensembl_link_url_from_gene
    link = ensembl_link_url_from_gene( :human, 'ENSG00001' )
    assert( link =~ /ensembl.org/ )
    assert( link =~ /Homo_sapiens/ )
    assert( link =~ /ENSG00001/ )
    
    link = ensembl_link_url_from_gene( :mouse, 'ENSMUS00001' )
    assert( link =~ /Mus_musculus/ )
    
    link = ensembl_link_url_from_gene( :human, 'ENSG00001', ['das:wibble'] )
    assert( link =~ /das:wibble=normal/ )
    
    assert_raise(TypeError) { ensembl_link_url_from_gene( :monkey, 'ENSG00001' ) }
  end
  
  def test_ensembl_link_url_from_coords
    link = ensembl_link_url_from_coords( :human, 1, 20, 42 )
    assert( link =~ /Homo_sapiens/ )
    assert( link =~ /\?r=1:20-42/ )
    
    link = ensembl_link_url_from_coords( :mouse, 1, 20, 42 )
    assert( link =~ /Mus_musculus/ )
    
    link = ensembl_link_url_from_coords( :human, 1, 20, 42, ['das:wibble'] )
    assert( link =~ /das:wibble=normal/ )
    
    assert_raise(TypeError) { ensembl_link_url_from_coords( :monkey, 1, 20, 42 ) }
  end
  
  def test_vega_link_url_from_gene
    link = vega_link_url_from_gene( :mouse, 'OTTMUSG00001' )
    assert( link =~ /vega.sanger.ac.uk/ )
    assert( link =~ /Mus_musculus/ )
    assert( link =~ /OTTMUSG00001/ )
  end

  def test_ensembl_link_url_from_transcript
    link = ensembl_link_url_from_transcript('ENSMUSG00000018666', 'ENSMUST00000093943' )
    assert_match( /Mus_musculus/, link )
    assert_match( /Summary/, link )

    link = ensembl_link_url_from_transcript( 'ENSMUSG00000018666', 'ENSMUST00000093943', :exon )
    assert_match( /Mus_musculus/, link )
    assert_match( /Exons/, link )

    assert_raise(TypeError) do
      ensembl_link_url_from_transcript( 'ENSMUSG00000018666', 'ENSMUST00000093943', :foo )
    end
  end
  # DataView Helper Tests...
  
  def test_emma_strain_type
    if   MartSearch::ServerViewHelpers.private_methods.include?(:emma_strain_type) \
      or MartSearch::ServerViewHelpers.private_methods.include?('emma_strain_type')
      assert_equal( 'Induced Mutant Strains', emma_strain_type('IN','') )
      assert_equal( 'Induced Mutant Strains : Chemically-Induced', emma_strain_type('IN','CH') )
      assert_raise( ArgumentError ) { emma_strain_type('IN') }
    end
  end
  
  def test_europhenome_link_url
    if   MartSearch::ServerViewHelpers.private_methods.include?(:europhenome_link_url) \
      or MartSearch::ServerViewHelpers.private_methods.include?('europhenome_link_url')
      url = 'http://www.europhenome.org/databrowser/viewer.jsp?pid_ESLIM_007_001_001=on&l=73&x=Female&m=true&set=true&zygosity=Hom&p=ESLIM_007_001&compareLines=View+Data'
      opts = {
        :europhenome_id => '73',
        :zygosity       => 'Hom',
        :sex            => 'Female',
        :test_id        => 'ESLIM_007_001',
        :parameter_id   => 'ESLIM_007_001_001'
      }
      
      tar_url = URI.parse(url)
      gen_url = URI.parse( europhenome_link_url(opts) )
      
      assert_equal( tar_url.host, gen_url.host )
      assert_equal( tar_url.path, gen_url.path )
      assert_raise( ArgumentError ) { europhenome_link_url() }
      assert_raise( ArgumentError ) { europhenome_link_url({}) }
    end
  end
  
  def test_idcc_targ_rep_get_progressbar_info
    if   MartSearch::ServerViewHelpers.private_methods.include?(:idcc_targ_rep_get_progressbar_info) \
      or MartSearch::ServerViewHelpers.private_methods.include?('idcc_targ_rep_get_progressbar_info')
      assert_equal( { :vectors => "normal", :cells => "normal", :mice => "normal" }, idcc_targ_rep_get_progressbar_info({ :mouse_available => '1' }) )
      assert_equal( { :vectors => "normal", :cells => "normal", :mice => "incomp" }, idcc_targ_rep_get_progressbar_info({ :escell_available => '1' }) )
      assert_equal( { :vectors => "normal", :cells => "incomp", :mice => "incomp" }, idcc_targ_rep_get_progressbar_info({ :vector_available => '1' }) )
      assert_equal( { :vectors => "normal", :cells => "incomp", :mice => "incomp" }, idcc_targ_rep_get_progressbar_info({ :no_products_available => true, :status => 'foo' }) )
      assert_equal( { :vectors => "incomp", :cells => "incomp", :mice => "incomp" }, idcc_targ_rep_get_progressbar_info({}) )
    end
  end
  
  def test_idcc_targ_rep_product_order_url
    if   MartSearch::ServerViewHelpers.private_methods.include?(:idcc_targ_rep_product_order_url) \
      or MartSearch::ServerViewHelpers.private_methods.include?('idcc_targ_rep_product_order_url')
      result_data = { :index => { :marker_symbol => 'foo' } }
      
      komp_csd_project = { :pipeline => 'KOMP-CSD', :mgi_accession_id => 'MGI:1234', :ikmc_project_id => '1234' }
      assert_equal( 'http://www.komp.org/vectorOrder.php?projectid=1234',           idcc_targ_rep_product_order_url( komp_csd_project, result_data, 'vectors' ) )
      assert_equal( 'http://www.komp.org/orders.php?project=CSD1234&amp;product=1', idcc_targ_rep_product_order_url( komp_csd_project, result_data, 'cells' ) )
      assert_equal( 'http://www.komp.org/geneinfo.php?project=CSD1234',             idcc_targ_rep_product_order_url( komp_csd_project, result_data, 'nought' ) )
      
      komp_reg_project = { :pipeline => 'KOMP-Regeneron', :mgi_accession_id => 'MGI:1234', :ikmc_project_id => 'VG1234' }
      assert_equal( 'http://www.komp.org/vectorOrder.php?projectid=VG1234',        idcc_targ_rep_product_order_url( komp_reg_project, result_data, 'vectors' ) )
      assert_equal( 'http://www.komp.org/orders.php?project=VG1234&amp;product=1', idcc_targ_rep_product_order_url( komp_reg_project, result_data, 'cells' ) )
      assert_equal( 'http://www.komp.org/geneinfo.php?project=VG1234',             idcc_targ_rep_product_order_url( komp_reg_project, result_data, 'nought' ) )
      
      ['EUCOMM','mirKO'].each do |pipeline|
        eucomm_mirKO_project = { :pipeline => pipeline, :mgi_accession_id => 'MGI:1234', :ikmc_project_id => '1234' }
        assert_equal( 'http://www.eummcr.org/final_vectors.php?mgi_id=1234', idcc_targ_rep_product_order_url( eucomm_mirKO_project, result_data, 'vectors' ) )
        assert_equal( 'http://www.eummcr.org/es_cells.php?mgi_id=1234',      idcc_targ_rep_product_order_url( eucomm_mirKO_project, result_data, 'cells' ) )
        assert_equal( 'http://www.emmanet.org/mutant_types.php?keyword=foo%25EUCOMM&select_by=InternationalStrainName&search=ok', idcc_targ_rep_product_order_url( eucomm_mirKO_project, result_data, 'mice' ) )
        assert_equal( 'http://www.eummcr.org/order.php',                         idcc_targ_rep_product_order_url( eucomm_mirKO_project, result_data, 'nought' ) )
      end
      
      norcomm_project = { :pipeline => 'NorCOMM', :mgi_accession_id => 'MGI:1234', :ikmc_project_id => '1234' }
      assert_equal( 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', idcc_targ_rep_product_order_url( norcomm_project, result_data, 'something' ) )
    end
  end
  
end