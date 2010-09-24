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
end