# encoding: utf-8

require 'test_helper'

# Test the return values for searches involving:
#
# Gene          | What we got?                    | MGI Acc.    | No of mice expected after merge |
# ---------------------------------------------------------------------------------------------------
# Smyd3         | no emma data                    | MGI:1916976 | 1                               |
# Dync1h1       | no imits data                   | MGI:103147  | 1                               |
# Cbx1          | imits and emma data             | MGI:105369  | 1                               |
# MBBS          | 1 emma strain and 2 imits mice  | MGI:107846  | 2                               |
# MBBZ          | 1 emma strain and 1 imits mouse | MGI:1339795 | 1                               |
# MAVE          | no match b/w emma and imits     | MGI:1336167 | 2                               |

class MartSearchDataSetDummyMiceTest < Test::Unit::TestCase
  context 'The "dummy-mice" DataSet' do
    setup do
      VCR.insert_cassette('test_dummy_mice')
      @ms                = MartSearch::Controller.instance
      @mgi_accession_ids = {
        'MGI:1916976' => 2,
        'MGI:103147'  => 3,
        'MGI:105369'  => 1,
        'MGI:107846'  => 2,
        'MGI:1339795' => 1,
        'MGI:1336167' => 2
      }
    end

    teardown do
      VCR.eject_cassette
    end

    should 'return the correct number of mouse records' do
      @mgi_accession_ids.each do |mgi_accession_id, expected_count|
        assert_nothing_raised { @ms.search(mgi_accession_id, 1, false) }

        # puts "IKMC KERMITS"
        # ap @ms.search_data[mgi_accession_id.to_sym][:'ikmc-imits']
        # puts "EMMA STRAINS"
        # ap @ms.search_data[mgi_accession_id.to_sym][:'emma-strains']
        # puts "DUMMY MICE"
        # ap @ms.search_data[mgi_accession_id.to_sym][:'dummy-mice']

        assert_equal( expected_count, @ms.search_data[mgi_accession_id.to_sym][:'dummy-mice'].size, "dummy mice for #{mgi_accession_id} has the wrong count..." )
      end
    end
  end
end
