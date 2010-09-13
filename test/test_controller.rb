require 'test_helper'

class MartSearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = MartSearch::Controller.instance()
  end
  
  context "A MartSearch::Controller object" do
    should "initialize correctly" do
      assert( @controller.is_a?(MartSearch::Controller), "@controller is not a MartSearch::Controller object." )
      assert( @controller.config != nil, "@controller.config is nil." )
      assert( @controller.cache != nil, "@controller.cache is nil." )
      assert( @controller.index.is_a?(MartSearch::Index), "@controller.index is not a MartSearch::Index object." )
    end
    
    should "be a singleton class" do
      assert_raise(NoMethodError) { obj = MartSearch::Controller.new() }
      @second_obj = MartSearch::Controller.instance()
      assert_equal( @controller.object_id, @second_obj.object_id, "MartSearch::Controller is not a singleton - we've created a second instance!" )
    end
    
    should "have built many DataSources" do
      assert( @controller.config[:datasources].is_a?(Hash), "@controller.config[:datasources] is not a Hash." )
      assert( !@controller.config[:datasources].empty?, "@controller.config[:datasources] is empty." )
      
      @controller.config[:datasources].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol), "The keys of @controller.config[:datasources] are not symbols." )
        assert( ds.is_a?(MartSearch::DataSource), "The values of @controller.config[:datasources] are not MartSearch::DataSource objects." )
      end
    end
    
    
    
  end
end