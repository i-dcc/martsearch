require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchConfigTest < Test::Unit::TestCase
  def setup
    @conf_obj = MartSearch::Config.instance()
  end
  
  context "A MartSearch::Config object" do
    should "initialize correctly" do
      assert( @conf_obj.is_a?(MartSearch::Config), "@conf_obj is not a MartSearch::Config object." )
      assert( @conf_obj.config != nil, "@conf_obj.config is nil." )
    end
    
    should "be a singleton class" do
      assert_raise(NoMethodError) { obj = MartSearch::Config.new() }
      @second_obj = MartSearch::Config.instance()
      assert_equal( @conf_obj.object_id, @second_obj.object_id, "MartSearch::Config is not a singleton - we've created a second instance!" )
    end
    
    should "have built many DataSources" do
      assert( @conf_obj.config[:datasources].is_a?(Hash), "@conf_obj.config[:datasources] is not a Hash." )
      assert( !@conf_obj.config[:datasources].empty?, "@conf_obj.config[:datasources] is empty." )
      
      @conf_obj.config[:datasources].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol), "The keys of @conf_obj.config[:datasources] are not symbols." )
        assert( ds.is_a?(MartSearch::DataSource), "The values of @conf_obj.config[:datasources] are not MartSearch::DataSource objects." )
      end
    end
  end
end