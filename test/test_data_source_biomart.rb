# encoding: utf-8

require 'test_helper'

class MartSearchBiomartDataSourceTest < Test::Unit::TestCase
  def setup
    @conf_obj        = MartSearch::Controller.instance()
    @imits_biomart = MartSearch::BiomartDataSource.new( :url => 'http://www.knockoutmouse.org/biomart', :dataset => 'imits' )
  end

  context 'A MartSearch::BiomartDataSource object' do
    should 'initialze correctly' do
      assert( @imits_biomart.is_a?(MartSearch::BiomartDataSource) )
      assert( @imits_biomart.ds.is_a?(Biomart::Dataset) )
    end

    should 'have a simple heartbeat function' do
      VCR.use_cassette('test_biomart_data_source_is_alive') do
        assert( @imits_biomart.is_alive? )
      end
    end

    should 'have a funcioning Biomart::Dataset object' do
      VCR.use_cassette('test_biomart_data_source_dataset_object') do
        assert( @imits_biomart.ds.alive? )
        assert( @imits_biomart.ds.list_attributes.is_a?(Array) )
        assert( @imits_biomart.ds.list_filters.is_a?(Array) )
        assert( @imits_biomart.ds_attributes.is_a?(Hash) )
        assert( @imits_biomart.ds_attributes == @imits_biomart.ds.attributes )
      end
    end

    should 'return the expeced data structure for fetch_all_terms_for_indexing()' do
      VCR.use_cassette('test_biomart_data_source_index_fetch') do
        ds_conf = @conf_obj.config[:index_builder][:datasets][:'ikmc-imits']
        ret     = @imits_biomart.fetch_all_terms_for_indexing( ds_conf[:indexing] )
        assert( ret.is_a?(Hash), 'fetch_all_terms_for_indexing() does not return a hash.' )
        assert( ret[:headers] != nil, 'the returned hash from fetch_all_terms_for_indexing() contains a nil value for :headers.' )
        assert( ret[:data] != nil, 'the returned hash from fetch_all_terms_for_indexing() contains a nil value for :data.' )

        assert( ret[:headers].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array for :headers.' )
        assert( ret[:data].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array for :data.' )
        assert( ret[:data][0].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array of Arrays for :data.' )
      end
    end

    should 'return the expeced data structure for search()' do
      VCR.use_cassette('test_biomart_data_source_search') do
        dataset_conf = {
          :joined_index_field => 'marker_symbol',
          :joined_filter      => 'marker_symbol',
          :joined_attribute   => 'marker_symbol',
          :attributes         => [ 'marker_symbol', 'pipeline', 'colony_prefix', 'microinjection_status',  'emma' ]
        }

        ret = @imits_biomart.search( ['Cbx1','Art4'], dataset_conf )

        assert( ret.is_a?(Array), 'search() does not return an array.' )
        assert( ret.size > 0, 'the return from search() is empty - it should have data...' )
        assert( ret[0].is_a?(Hash), 'The elements of the array from search() are not hashes.' )

        ret.each do |data_return|
          dataset_conf[:attributes].each do |attribute|
            assert( data_return.keys.include?( attribute.to_sym ), "The attribute :#{attribute} is missing from the data hash." )
          end
        end

        dataset_conf[:required_attributes] = ['colony_prefix']
        ret2 = @imits_biomart.search( ['Cbx1','Art4'], dataset_conf )

        ret2.each do |data_return|
          assert( data_return[:colony_prefix] != nil )
        end
      end
    end

    should 'throw a MartSearch::DataSourceError if something goes wrong with the search' do
      VCR.use_cassette('test_biomart_data_source_error') do
        assert_raise(MartSearch::DataSourceError) {
          dataset_conf = {
            :joined_index_field => 'marker_symbol',
            :joined_filter      => 'marker_symbol',
            :joined_attribute   => 'marker_symbol',
            :attributes         => [ 'marker_symbol', 'pipeline', 'colony_prefix', 'wibble' ]
          }

          ret = @imits_biomart.search( ['Cbx1','Art4'], dataset_conf )
        }
      end
    end

    should 'provide a URL link to the datasource of a search' do
      dataset_conf = {
        :joined_index_field => 'marker_symbol',
        :joined_filter      => 'marker_symbol',
        :joined_attribute   => 'marker_symbol',
        :attributes         => [ 'marker_symbol', 'pipeline', 'colony_prefix', 'microinjection_status',  'emma' ]
      }

      url = @imits_biomart.data_origin_url( ['Cbx1','Art4'], dataset_conf )

      assert( url.is_a?(String) )
      assert( !url.empty?, 'datasource.data_origin_url() does not return an empty string.' )
      assert( url.match(/^http:\/\/.*/), 'dataset.data_origin_url() does not return a url.' )
    end
  end
  
end
