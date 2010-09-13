require 'test_helper'

class MartSearchServerUtilsTest < Test::Unit::TestCase
  include MartSearch::ServerUtils
  
  def test_compressed_js
    js = compressed_js()
    assert( js.is_a?(String) )
    assert( js.size > 0 )
  end
  
  def test_compressed_css
    css = compressed_css()
    assert( css.is_a?(String) )
    assert( css.size > 0 )
  end
  
end