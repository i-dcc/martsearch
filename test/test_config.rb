require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchConfigBuilderTest < Test::Unit::TestCase
  def setup
    @conf_obj = MartSearch::ConfigBuilder.instance()
  end
  
  context "A MartSearch::ConfigBuilder object" do
    should "initialize correctly" do
      assert( @conf_obj.is_a?(MartSearch::ConfigBuilder), "@conf_obj is not a MartSearch::ConfigBuilder object." )
      assert( @conf_obj.config != nil, "@conf_obj.config is nil." )
    end
    
    should "be a singleton class" do
      assert_raise(NoMethodError) { obj = MartSearch::ConfigBuilder.new() }
      @second_obj = MartSearch::ConfigBuilder.instance()
      assert_equal( @conf_obj.object_id, @second_obj.object_id, "MartSearch::ConfigBuilder is not a singleton - we've created a second instance!" )
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