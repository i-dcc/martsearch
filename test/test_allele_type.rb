require "test_helper"

class TestMartSearchDataSetUtils < Test::Unit::TestCase

  include MartSearch::DataSetUtils

  context "A valid allele_symbol" do
    setup do
      @allele_symbols = {
        "tm1a(EUCOMM)Wtsi" => "Knockout-First",
        "tm1e(EUCOMM)Wtsi" => "Targeted Non-Conditional",
        "tm1(EUCOMM)Wtsi"  => "Deletion",
      }
    end

    should "produce the correct allele_type" do
      @allele_symbols.each do |allele_symbol, expected_type|
        assert_equal expected_type, allele_type(allele_symbol), "not the expected type"
      end
    end
  end

  context "An invalid allele_symbol marked as a deletion" do
    setup do
      @example_data = [
        {
          :expected_type => "Deletion",
          :allele_symbol => "Some Symbol",
          :design_type   => "deletion",
        },
        {
          :expected_type => "Knockout-First",
          :allele_symbol => "Some Symbol",
          :design_type   => "Some Other Design Type",
        }
      ]
    end

    should "still produce the correct allele_type" do
      @example_data.each do |example|
        assert_equal example[:expected_type], allele_type(example[:allele_symbol], example[:design_type]),
        "Did not produce expected allele_type with #{example[:allele_symbol]} and #{example[:design_type]}"
      end
    end
  end

  # what happens when the allele_symbol doesn't match any regex and
  # design_type is nil?
end
