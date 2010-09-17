require 'test_helper'

class MartSearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = MartSearch::Controller.instance()
  end
  
  context "A MartSearch::Controller object" do
    should "initialize correctly" do
      assert( @controller.is_a?(MartSearch::Controller) )
      assert( @controller.config != nil )
      assert( @controller.cache != nil )
      assert( @controller.index.is_a?(MartSearch::Index) )
    end
    
    should "be a singleton class" do
      assert_raise(NoMethodError) { obj = MartSearch::Controller.new() }
      @second_obj = MartSearch::Controller.instance()
      assert_equal( @controller.object_id, @second_obj.object_id, "MartSearch::Controller is not a singleton - we've created a second instance!" )
    end
    
    should "have built many DataSources" do
      assert( @controller.config[:datasources].is_a?(Hash) )
      assert( !@controller.config[:datasources].empty? )
      
      @controller.config[:datasources].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol) )
        assert( ds.is_a?(MartSearch::DataSource) )
      end
    end
    
    should "have built up the server config correctly" do
      assert( @controller.config[:server].is_a?(Hash) )
      assert( !@controller.config[:server].empty? )
      @controller.config[:server].each do |key,value|
        assert( key.is_a?(Symbol) )
      end
      
      assert( @controller.config[:server][:portal_url] != nil )
      assert( @controller.config[:server][:base_uri]   != nil )
      assert( @controller.config[:server][:dataviews]  != nil )
      assert( @controller.config[:server][:datasets]   != nil )
      
      assert( @controller.config[:server][:dataviews].is_a?(Array) )
      assert( @controller.config[:server][:dataviews_by_name].is_a?(Hash) )
      
      assert( @controller.config[:server][:datasets].is_a?(Hash) )
      @controller.config[:server][:datasets].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol) )
        assert( ds.is_a?(MartSearch::DataSet) )
      end
    end
    
  end
end