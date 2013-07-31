# encoding: utf-8

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
    assert_equal( "Knockout First, Reporter-tagged insertion with conditional potential", allele_type('tm1a(EUCOMM)WTSI') )
    assert_equal( "Knockout First, Reporter-tagged insertion with conditional potential", allele_type('tm2a(EUCOMM)WTSI') )
    assert_equal( "Knockout First, Reporter-tagged insertion with conditional potential", allele_type('tm10a(EUCOMM)WTSI') )

    assert_equal( "Knockout-First, Post-Cre - Reporter Tagged Deletion", allele_type('tm1b(EUCOMM)WTSI') )
    assert_equal( "Knockout-First, Post-Cre - Reporter Tagged Deletion", allele_type('tm12b(EUCOMM)WTSI') )

    assert_equal( "Knockout-First, Post-Flp - Conditional", allele_type('tm1c(EUCOMM)WTSI') )
    assert_equal( "Knockout-First, Post-Flp - Conditional", allele_type('tm12c(EUCOMM)WTSI') )

    assert_equal( "Knockout-First, Post-Flp and Cre - Deletion, No Reporter", allele_type('tm1d(EUCOMM)WTSI') )
    assert_equal( "Knockout-First, Post-Flp and Cre - Deletion, No Reporter", allele_type('tm12d(EUCOMM)WTSI') )

    assert_equal( "Targeted Non-Conditional", allele_type('tm1e(EUCOMM)WTSI') )
    assert_equal( "Targeted Non-Conditional", allele_type('tm12e(EUCOMM)WTSI') )

    assert_equal( "Reporter-Tagged Deletion", allele_type('tm1(EUCOMM)WTSI') )
    assert_equal( "Reporter-Tagged Deletion", allele_type('tm12(EUCOMM)WTSI') )

    assert_equal( "", allele_type( nil, nil ) )
    assert_equal( "Reporter-Tagged Deletion", allele_type( nil, 'deletion' ) )
    assert_equal( "Knockout First, Reporter-tagged insertion with conditional potential", allele_type( nil, 'ko_first' ) )
  end

end
