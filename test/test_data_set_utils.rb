require 'test_helper'

class MartSearchDataSetUtilsTest < Test::Unit::TestCase
  include MartSearch::DataSetUtils
  
  def test_fix_superscript_text_in_attribute
    test_str = "Foo<tm1a(EUCOMM)WTSI>"
    expt_str = "Foo<sup>tm1a(EUCOMM)WTSI</sup>"
    
    assert_equal( expt_str, fix_superscript_text_in_attribute(test_str) )
    assert_equal( expt_str, fix_superscript_text_in_attribute(expt_str) )
  end
  
  def test_allele_type
    example_data = [
      {
        :expected_type => "Knockout-First",
        :allele_symbol => "tm1a(EUCOMM)Wtsi",
        :design_type   => nil,
      },
      {
        :expected_type => "Targeted Non-Conditional",
        :allele_symbol => "tm1e(EUCOMM)Wtsi",
        :design_type   => nil,
      },
      {
        :expected_type => "Deletion",
        :allele_symbol => "tm1(EUCOMM)Wtsi",
        :design_type   => nil,
      },
      {
        :expected_type => "Deletion",
        :allele_symbol => "Some Symbol",
        :design_type   => "deletion",
      },
      {
        :expected_type => "Deletion",
        :allele_symbol => nil,
        :design_type   => "deletion",
      },
      {
        :expected_type => "Knockout-First",
        :allele_symbol => "Some Symbol",
        :design_type   => "Some Other Design Type",
      },
      {
        :expected_type => "Knockout-First",
        :allele_symbol => nil,
        :design_type   => "Some Other Design Type",
      },
      {
        :expected_type => "",
        :allele_symbol => nil,
        :design_type   => nil,
      },
    ]
    
    example_data.each do |example|
      assert_equal example[:expected_type], allele_type(example[:allele_symbol], example[:design_type]),
      "Did not produce expected allele_type with #{example[:allele_symbol]} and #{example[:design_type]}"
    end
  end
end