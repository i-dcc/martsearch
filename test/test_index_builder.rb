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
end