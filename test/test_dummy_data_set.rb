require 'test_helper'

# Test the return values for searches involving (NEEDS A BIT OF THOUGHT):
#
# Smyd3         | no emma data                      | MGI:1916976 | 1 |
# Dync1h1       | no kermiks data                   | MGI:103147  | 1 |
# Cbx1          | kermits and emma data             | MGI:105369  | 1 |
# B020004C17Rik | no kermits or emma data           | MGI:3588236 | 1 |
# MBBS          | 1 emma strain and 2 kermits mice  | MGI:107846  | 2 |
# MBBZ          | 1 emma strain and 1 kermits mouse | MGI:1339795 | 1 |
# MAVE          | no match b/w emma and kermits     | MGI:1336167 | 2 |

class MartSearchDummyDataSetTest < Test::Unit::TestCase
  context 'A MartSearch::DummyDataSet object' do
    setup do
      VCR.insert_cassette('test_dummy_mice')
      @conf_obj          = MartSearch::Controller.instance
      @mgi_accession_ids = {
        'MGI:1916976' => 1,
        'MGI:103147'  => 1,
        'MGI:105369'  => 1,
        'MGI:107846'  => 2,
        'MGI:1339795' => 1,
        'MGI:1336167' => 2,
      }
    end

    teardown do
      VCR.eject_cassette
    end

    should 'instiantiate' do
      assert @conf_obj
    end

    should 'return the correct number of dummy mice' do
      @mgi_accession_ids.each do |mgi_accession_id, expected_count|
        assert_nothing_raised { @conf_obj.search(mgi_accession_id, 1, false) }
        assert_equal expected_count, @conf_obj.search_data[mgi_accession_id.to_sym][:'dummy-mice'].size
      end
    end
  end
end
