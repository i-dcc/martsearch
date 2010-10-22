require 'test_helper'

class MartSearchDataSourceTest < Test::Unit::TestCase
  def setup
    @conf_obj        = MartSearch::Controller.instance()
    @datasource      = MartSearch::DataSource.new( :url => 'http://www.google.com' )
    @kermits_biomart = MartSearch::BiomartDataSource.new( :url => 'http://www.i-dcc.org/biomart', :dataset => 'kermits' )
  end
  
  context 'A MartSearch::DataSource object' do
    should 'initialze correctly' do
      assert( @datasource.is_a?(MartSearch::DataSource) )
    end
    
    should 'have a simple heartbeat function' do
      assert_raise(MartSearch::InvalidConfigError) { @datasource.is_alive? }
    end
    
    should 'return the expeced data structure for fetch_all_terms_for_indexing()' do
      assert_raise(MartSearch::InvalidConfigError) { @datasource.fetch_all_terms_for_indexing( {} ) }
    end
    
    should 'return the expeced data structure for search()' do
      assert_raise(MartSearch::InvalidConfigError) { @datasource.search( 'foo', {} ) }
    end
    
    should 'provide a URL link to the datasource of a search' do
      assert_raise(MartSearch::InvalidConfigError) { @datasource.data_origin_url( 'foo', {} ) }
    end
  end
  
  context 'A MartSearch::BiomartDataSource object' do
    should 'initialze correctly' do
      assert( @kermits_biomart.is_a?(MartSearch::BiomartDataSource) )
      assert( @kermits_biomart.ds.is_a?(Biomart::Dataset) )
    end
    
    should 'have a simple heartbeat function' do
      VCR.use_cassette('test_biomart_data_source_is_alive') do
        assert( @kermits_biomart.is_alive? )
      end
    end
    
    should 'have a funcioning Biomart::Dataset object' do
      VCR.use_cassette('test_biomart_data_source_dataset_object') do
        assert( @kermits_biomart.ds.alive? )
        assert( @kermits_biomart.ds.list_attributes.is_a?(Array) )
        assert( @kermits_biomart.ds.list_filters.is_a?(Array) )
      end
    end
    
    should 'return the expeced data structure for fetch_all_terms_for_indexing()' do
      VCR.use_cassette('test_biomart_data_source_index_fetch') do
        ds_conf = @conf_obj.config[:index_builder][:datasets][:'ikmc-kermits']
        ret     = @kermits_biomart.fetch_all_terms_for_indexing( ds_conf[:indexing] )
        check_the_response_from_fetch_all_terms_for_indexing( ret )
      end
    end
    
    should 'return the expeced data structure for search()' do
      VCR.use_cassette('test_biomart_data_source_search') do
        dataset_conf = {
          :joined_index_field => 'marker_symbol',
          :joined_filter      => 'marker_symbol',
          :joined_attribute   => 'marker_symbol',
          :attributes         => [ 'marker_symbol', 'sponsor', 'colony_prefix', 'status',  'emma' ]
        }
        
        ret = @kermits_biomart.search( ['Cbx1','Art4'], dataset_conf )
        
        assert( ret.is_a?(Array), 'search() does not return an array.' )
        assert( ret.size > 0, 'the return from search() is empty - it should have data...' )
        assert( ret[0].is_a?(Hash), 'The elements of the array from search() are not hashes.' )
        
        ret.each do |data_return|
          dataset_conf[:attributes].each do |attribute|
            assert( data_return.keys.include?( attribute.to_sym ), "The attribute :#{attribute} is missing from the data hash." )
          end
        end
        
        dataset_conf[:required_attributes] = ['colony_prefix']
        ret2 = @kermits_biomart.search( ['Cbx1','Art4'], dataset_conf )
        
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
            :attributes         => [ 'marker_symbol', 'sponsor', 'colony_prefix', 'wibble' ]
          }
          
          ret = @kermits_biomart.search( ['Cbx1','Art4'], dataset_conf )
        }
      end
    end
    
    should 'provide a URL link to the datasource of a search' do
      dataset_conf = {
        :joined_index_field => 'marker_symbol',
        :joined_filter      => 'marker_symbol',
        :joined_attribute   => 'marker_symbol',
        :attributes         => [ 'marker_symbol', 'sponsor', 'colony_prefix', 'status',  'emma' ]
      }
      
      url = @kermits_biomart.data_origin_url( ['Cbx1','Art4'], dataset_conf )
      
      assert( url.is_a?(String) )
      assert( !url.empty?, 'datasource.data_origin_url() does not return an empty string.' )
      assert( url.match(/^http:\/\/.*/), 'dataset.data_origin_url() does not return a url.' )
      assert( url.length < 2048, "dataset.data_origin_url() is returning url's that are too long for IE to handle." )
    end
  end
  
  def check_the_response_from_fetch_all_terms_for_indexing( ret )
    assert( ret.is_a?(Hash), 'fetch_all_terms_for_indexing() does not return a hash.' )
    assert( ret[:headers] != nil, 'the returned hash from fetch_all_terms_for_indexing() contains a nil value for :headers.' )
    assert( ret[:data] != nil, 'the returned hash from fetch_all_terms_for_indexing() contains a nil value for :data.' )
    
    assert( ret[:headers].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array for :headers.' )
    assert( ret[:data].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array for :data.' )
    assert( ret[:data][0].is_a?(Array), 'the returned hash from fetch_all_terms_for_indexing() does not return an Array of Arrays for :data.' )
  end
end