require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  def setup
    @index_builder = MartSearch::IndexBuilder.new()
  end
  
  context "A MartSearch::IndexBuilder object" do
    should "initialze correctly" do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), "MartSearch::IndexBuilder did not initialze correctly." )
    end
  end
  
  context "The MartSearch::IndexBuilderUtils methods" do
    include MartSearch::IndexBuilderUtils
    
    should "extract the unique attributes from an attribute map" do
      map   = JSON.parse( '[{ "attr": "foo" }, { "attr": "foo" }, { "attr": "baz" }, { "attr": "bar" }]' )
      attrs = all_attributes_to_fetch(map)
      assert_equal( 3, attrs.size, "MartSearch::IndexBuilderUtils::all_attributes_to_fetch did not extract unique attribute names." )
    end
  end
end