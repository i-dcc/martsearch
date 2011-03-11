require 'test_helper'

# Test the return values for searches involving (NEEDS A BIT OF THOUGHT):
#
# Smyd3         | no emma data            | MGI:1916976 |
# Dync1h1       | no kermiks data         | MGI:103147  |
# Cbx1          | kermits and emma data   | MGI:105369  |
# B020004C17Rik | no kermits or emma data | MGI:3588236 |
#
# Use MartSearchDataSetTest as a template.

class MartSearchDummyDataSetTest < Test::Unit::TestCase

  include MartSearch::DataSetUtils

  context 'A MartSearch::DummyDataSet' do
    context 'with corresponding EMMA and KERMITS data' do
      setup do
        @emma     = {
          'EM:00001' => { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001' },
          'EM:00002' => { 'emma_id' => 'EM:00002', 'common_name' => 'EPD0002' },
        }
        @kermits  = [ { 'escell_clone' => 'EPD0001' }, { 'escell_clone' => 'EPD0002' } ]
        @expected = [
          { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001', 'escell_clone' => 'EPD0001' },
          { 'emma_id' => 'EM:00002', 'common_name' => 'EPD0002', 'escell_clone' => 'EPD0002' },
        ]
        @defaults = { 'common_name' => nil, 'emma_id' => nil, 'escell_clone' => nil }
      end

      should 'merge the EMMA and KERMITS data correctly' do
        assert_equal @expected, merge_emma_and_kermits( @emma, @kermits, @defaults )
      end
    end

    context 'with EMMA data missing' do
      setup do
        @emma     = { 'EM:00001' => { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001' } }
        @kermits  = [ { 'escell_clone' => 'EPD0001' }, { 'escell_clone' => 'EPD0002' } ]
        @expected = [
          { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001', 'escell_clone' => 'EPD0001' },
          { 'emma_id' => nil, 'common_name' => nil, 'escell_clone' => 'EPD0002' },
        ]
        @defaults = { 'common_name' => nil, 'emma_id' => nil, 'escell_clone' => nil }
      end

      should 'merge the EMMA and KERMITS data correctly' do
        assert_equal @expected, merge_emma_and_kermits( @emma, @kermits, @defaults )
      end
    end

    context 'with KERMITS data missing' do
      setup do
        @emma     = {
          'EM:00001' => { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001' },
          'EM:00002' => { 'emma_id' => 'EM:00002', 'common_name' => 'EPD0002' },
        }
        @kermits  = [ { 'escell_clone' => 'EPD0001' } ]
        @expected = [
          { 'emma_id' => 'EM:00001', 'common_name' => 'EPD0001', 'escell_clone' => 'EPD0001' },
          { 'emma_id' => 'EM:00002', 'common_name' => 'EPD0002', 'escell_clone' => nil },
        ]
        @defaults = { 'common_name' => nil, 'emma_id' => nil, 'escell_clone' => nil }
      end

      should 'merge the EMMA and KERMITS data correctly' do
        assert_equal @expected, merge_emma_and_kermits( @emma, @kermits, @defaults )
      end
    end
  end
end
