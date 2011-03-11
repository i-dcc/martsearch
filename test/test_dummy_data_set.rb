require 'test_helper'

# Test the return values for searches involving (NEEDS A BIT OF THOUGHT):
#
# Smyd3         | no emma data            | MGI:1916976 |
# Dync1h1       | no kermiks data         | MGI:103147  |
# Cbx1          | kermits and emma data   | MGI:105369  |
# B020004C17Rik | no kermits or emma data | MGI:3588236 |
#
# Use MartSearchDataSetTest as a template.

module MartSearch
  module DataSetUtils
    # Merge the EMMA and KERMITS data
    #
    # @param  [Hash]  emma
    # @param  [Array] kermits
    # @return [Array]
    def merge_emma_and_kermits( emma, kermits )
      results = []
      kermits.each do |kermit_mouse|
        emma_mouse = emma.values.select { |e| e['common_name'] == kermit_mouse['escell_clone'] }
        results.push( kermit_mouse.merge( emma_mouse.first ) )
      end
      return results
    end
  end
end

class MartSearchDummyDataSetTest < Test::Unit::TestCase

  include MartSearch::DataSetUtils

  context 'A MartSearch::DummyDataSet' do
    context 'with corresponding EMMA and KERMITS data' do
      setup do
        @emma     = { 'EM:00001' => { 'common_name' => 'EPD0001' }, 'EM:00002' => { 'common_name' => 'EPD0002' } }
        @kermits  = [ { 'escell_clone' => 'EPD0001' }, { 'escell_clone' => 'EPD0002' } ]
        @expected = [ { 'common_name' => 'EPD0001', 'escell_clone' => 'EPD0001' }, { 'common_name' => 'EPD0002', 'escell_clone' => 'EPD0002' } ]
      end

      should 'merge the EMMA and KERMITS data correctly' do
        assert_equal @expected, merge_emma_and_kermits( @emma, @kermits )
      end
    end
  end
end
