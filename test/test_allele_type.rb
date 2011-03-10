require "test_helper"

class TestMartSearchDataSetUtils < Test::Unit::TestCase

  include MartSearch::DataSetUtils

  context "A valid allele_symbol and design_type" do
    setup do
      @example_data = [
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
    end

    should "produce the correct allele_type" do
      @example_data.each do |example|
        assert_equal example[:expected_type], allele_type(example[:allele_symbol], example[:design_type]),
        "Did not produce expected allele_type with #{example[:allele_symbol]} and #{example[:design_type]}"
      end
    end
  end
end
