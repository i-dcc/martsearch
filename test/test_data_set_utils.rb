require 'test_helper'

class MartSearchDataSetUtilsTest < Test::Unit::TestCase
  include MartSearch::DataSetUtils
  
  def test_fix_superscript_text_in_attribute
    test_str = "Foo<tm1a(EUCOMM)WTSI>"
    expt_str = "Foo<sup>tm1a(EUCOMM)WTSI</sup>"
    
    assert_equal( expt_str, fix_superscript_text_in_attribute(test_str) )
    assert_equal( expt_str, fix_superscript_text_in_attribute(expt_str) )
  end
  
end