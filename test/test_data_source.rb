require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchDataSourceTest < Test::Unit::TestCase
  def setup
    @conf_obj        = MartSearch::ConfigBuilder.instance()
    @datasource      = MartSearch::DataSource.new( :url => "http://www.google.com" )
    @kermits_biomart = MartSearch::BiomartDataSource.new( :url => "http://www.i-dcc.org/biomart", :dataset => "kermits" )
    
    VCR.insert_cassette('test_data_source')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  context "A MartSearch::DataSource object" do
    should "initialze correctly" do
      assert( @datasource.is_a?(MartSearch::DataSource) )
    end
    
    should "return the expeced data structure for fetch_all_terms_for_indexing()" do
      ret = @datasource.fetch_all_terms_for_indexing()
      check_the_response_from_fetch_all_terms_for_indexing( ret )
    end
  end
  
  context "A MartSearch::BiomartDataSource object" do
    should "initialze correctly" do
      assert( @kermits_biomart.is_a?(MartSearch::BiomartDataSource) )
      assert( @kermits_biomart.ds.is_a?(Biomart::Dataset) )
    end
    
    should "have a funcioning Biomart::Dataset object" do
      assert( @kermits_biomart.ds.alive? )
      assert( @kermits_biomart.ds.list_attributes.is_a?(Array) )
      assert( @kermits_biomart.ds.list_filters.is_a?(Array) )
    end
    
    should "return the expeced data structure for fetch_all_terms_for_indexing()" do
      ds_conf = @conf_obj.config[:index_builder][:datasources][:"ikmc-kermits"]
      ret     = @kermits_biomart.fetch_all_terms_for_indexing( ds_conf[:indexing] )
      
      check_the_response_from_fetch_all_terms_for_indexing( ret )
    end
  end
  
  def check_the_response_from_fetch_all_terms_for_indexing( ret )
    assert( ret.is_a?(Hash), "fetch_all_terms_for_indexing() does not return a hash." )
    assert( ret[:headers] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :headers." )
    assert( ret[:data] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :data." )
    
    assert( ret[:headers].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :headers." )
    assert( ret[:data].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :data." )
    assert( ret[:data][0].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array of Arrays for :data." )
  end
end