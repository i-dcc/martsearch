require "rubygems"
require "shoulda"

# 
module MartSearch
  module Utils
    # Helper function to retrieve the allele type
    #
    # @param  [String] allele_symbol the allele symbol superscript
    # @param  [String] design_type   the design type
    # @return [String]
    def allele_type( allele_symbol, design_type = nil )
       case allele_symbol
       when /tm\d+a/ then "Knockout-First"
       when /tm\d+e/ then "Targeted Non-Conditional"
       when /tm\d\(/ then "Deletion"
       else
         case design_type
         when /deletion/i  then "Deletion"
         else                   "Knockout-First"
         end
       end
    end
  end
end

class TestMartSearchUtils < Test::Unit::TestCase
  include MartSearch::Utils
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
end
