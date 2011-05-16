# encoding: utf-8

require 'test_helper'

class MartSearchDataSetTest < Test::Unit::TestCase
  def setup
    @conf_obj = MartSearch::Controller.instance()
  end
  
  context 'A MartSearch::DataSet object' do
    should 'initialze correctly' do
      dataset = MartSearch::DataSet.new( :datasource => 'mgi-markers' )
      assert( dataset.is_a?(MartSearch::DataSet) )
    end
    
    should 'raise an error if given a dodgy config object' do
      assert_raise( MartSearch::InvalidConfigError ) do
        bad_ds = MartSearch::DataSet.new( :datasource => 'wibble' )
        
        def bad_ds.datasource_public(*args)
          datasource(*args)
        end
        
        bad_ds.datasource_public
      end
    end
    
    should 'be able to drive a search function over a datasource' do
      VCR.use_cassette('test_data_set_search') do
        conf = {
          :datasource =>  'mgi-markers',
          :searching  => {
            :joined_index_field => 'mgi_accession_id_key',
            :joined_attribute   => 'mgi_marker_id_att',
            :joined_filter      => 'marker_id',
            :attributes         => [
              'marker_symbol_107', 'marker_name_107', 'marker_type_107',
              'chromosome_107', 'rep_genome_start_102','rep_genome_end_102', 
              'rep_genome_strand_102', 'mgi_marker_id_att'
            ]
          }
        }
        
        dataset = MartSearch::DataSet.new( conf )
        query   = ['MGI:1202710','MGI:105369','MGI:2444584']
        results = dataset.search( query )
        
        assert( results.is_a?(Hash) )
        assert_equal( query.size, results.size )
        query.each do |mgi_id| 
          assert( results.keys.include?(mgi_id), "#{mgi_id} is missing from the results hash." )
        end
      end
    end
    
    should 'be able to get a url for an datasource search' do
      conf = {
        :datasource =>  'mgi-markers',
        :searching  => {
          :joined_index_field => 'mgi_accession_id_key',
          :joined_attribute   => 'mgi_marker_id_att',
          :joined_filter      => 'marker_id',
          :attributes         => [
            'marker_symbol_107', 'marker_name_107', 'marker_type_107',
            'chromosome_107', 'rep_genome_start_102','rep_genome_end_102', 
            'rep_genome_strand_102', 'mgi_marker_id_att'
          ]
        }
      }
      
      dataset = MartSearch::DataSet.new( conf )
      query   = ['MGI:1202710','MGI:105369','MGI:2444584']
      url     = dataset.data_origin_url( query )
      
      assert( url.is_a?(String) )
      assert( !url.empty?, 'dataset.data_origin_url() does not return an empty string.' )
      assert( url.match(/^http:\/\/.*/), 'dataset.data_origin_url() does not return a url.' )
      assert( url.length < 2048, "dataset.data_origin_url() is returning url's that are too long for IE to handle." )
    end
  end
  
end