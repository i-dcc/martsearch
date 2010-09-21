require 'test_helper'

class MartSearchMockTest < Test::Unit::TestCase
  def test_method_override
    hello        = "hello"
    hello_in_rev = MartSearch::Mock.method( hello, :to_s ) { super().reverse }
    
    assert_equal( "hello", hello.to_s )
    assert_equal( "olleh", hello_in_rev.to_s )
  end
end