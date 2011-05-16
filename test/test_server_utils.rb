# encoding: utf-8

require 'test_helper'

class MartSearchServerUtilsTest < Test::Unit::TestCase
  include MartSearch::ServerUtils
  
  def test_compressed_js
    head_js = compressed_head_js( 'test-suite' )
    assert( head_js.is_a?(String) )
    assert( head_js.size > 0 )
    base_js = compressed_base_js( 'test-suite' )
    assert( base_js.is_a?(String) )
    assert( base_js.size > 0 )
  end
  
  def test_compressed_css
    css = compressed_css( 'test-suite' )
    assert( css.is_a?(String) )
    assert( css.size > 0 )
  end
  
end