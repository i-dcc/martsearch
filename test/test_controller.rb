require 'test_helper'

class MartSearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = MartSearch::Controller.instance()
  end
  
  context "A MartSearch::Controller object" do
    should "initialize correctly" do
      assert( @controller.is_a?(MartSearch::Controller) )
      assert( @controller.config != nil )
      assert( @controller.cache != nil )
      assert( @controller.index.is_a?(MartSearch::Index) )
    end
    
    should "be a singleton class" do
      assert_raise(NoMethodError) { obj = MartSearch::Controller.new() }
      @second_obj = MartSearch::Controller.instance()
      assert_equal( @controller.object_id, @second_obj.object_id, "MartSearch::Controller is not a singleton - we've created a second instance!" )
    end
    
    should "have built many DataSources" do
      assert( @controller.config[:datasources].is_a?(Hash) )
      assert( !@controller.config[:datasources].empty? )
      
      @controller.config[:datasources].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol) )
        assert( ds.is_a?(MartSearch::DataSource) )
      end
    end
    
    should "have built up the server config correctly" do
      assert( @controller.config[:server].is_a?(Hash) )
      assert( !@controller.config[:server].empty? )
      @controller.config[:server].each do |key,value|
        assert( key.is_a?(Symbol) )
      end
      
      assert( @controller.config[:server][:dataviews]  != nil )
      assert( @controller.config[:server][:datasets]   != nil )
      
      assert( @controller.config[:server][:dataviews].is_a?(Array) )
      assert( @controller.config[:server][:dataviews_by_name].is_a?(Hash) )
      
      assert( @controller.config[:server][:datasets].is_a?(Hash) )
      @controller.config[:server][:datasets].each do |ds_name,ds|
        assert( ds_name.is_a?(Symbol) )
        assert( ds.is_a?(MartSearch::DataSet) )
      end
    end
    
    should "allow us to perform controlled searches" do
      VCR.use_cassette('test_controller_search_simulation') do
        @controller.cache.clear
        
        assert( @controller.search_data.is_a?(Hash) )
        assert( @controller.search_data.empty? )
        
        ##
        ## Test search_from_*_index
        ##
        
        # Hit the 'fresh' searches first
        bad_result = @controller.send( :search_from_fresh_index, @controller.config[:index][:test][:bad_search], 1 )
        assert_equal( false, bad_result )
        
        good_result = @controller.send( :search_from_fresh_index, @controller.config[:index][:test][:single_return_search], 1 )
        assert_equal( true, good_result )
        
        # Now check the 'cachability' of the data
        search_data = BSON.deserialize( BSON.serialize( @controller.search_data ) )
        search_data = search_data.clean_hash if RUBY_VERSION < '1.9'
        search_data.recursively_symbolize_keys!
        assert_equal( search_data, @controller.search_data )
        
        ##
        ## Test search_from_fresh_datasets
        ##
        
        # First prepare the search terms to drive the dataset searches
        grouped_search_terms = @controller.send( :prepare_dataset_search_terms, @controller.search_data.keys )
        
        # Now drive the dataset searches
        dataset_results = @controller.send( :search_from_fresh_datasets, grouped_search_terms )
        assert( dataset_results.is_a?(TrueClass) || dataset_results.is_a?(FalseClass) )
        
        @controller.search_data.each do |key,value|
          assert( value.keys.size > 2 )
        end
      end
    end
    
    should "allow us to perform end-to-end searches" do
      VCR.use_cassette('test_controller_search') do
        @controller.send( :clear_instance_variables )
        @controller.cache.clear
        
        fresh_results  = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
        cached_results = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
        
        assert_equal( fresh_results, cached_results )
      end
    end
    
    should "give a count of genes/items for each of the configured browsing options" do
      VCR.use_cassette( 'test_controller_browse_counts' ) do
        @controller.cache.clear
        
        fresh_counts  = @controller.browse_counts()
        cached_counts = @controller.browse_counts()
        
        assert_equal( fresh_counts, cached_counts )
        assert( fresh_counts.is_a?(Hash) )
        
        @controller.config[:server][:browsable_content].each do |field,field_config|
          assert_not_nil( fresh_counts[field] )
          field_config[:options].each do |option,option_config|
            assert_not_nil( fresh_counts[field][option] )
          end
        end
      end
    end
    
    should "give top-level progress counts for the WTSI MGP" do
      omit_if(
        @controller.datasets[:'wtsi-phenotyping-heatmap'].nil?,
        "Skipping WTSI MGP progress counts tests as the DataSet 'wtsi-phenotyping-heatmap' is not active."
      )
      
      VCR.use_cassette( 'test_controller_wtsi_mgp_counts' ) do
        @controller.cache.clear
        
        fresh_counts  = @controller.wtsi_phenotyping_progress_counts()
        cached_counts = @controller.wtsi_phenotyping_progress_counts()
        
        assert_equal( fresh_counts, cached_counts )
        assert( fresh_counts.is_a?(Hash) )
        
        assert( fresh_counts.has_key?(:standard_phenotyping) )
        assert( fresh_counts.has_key?(:infection_challenge) )
        assert( fresh_counts.has_key?(:expression) )
        
        assert( fresh_counts[:standard_phenotyping] > 0 )
        assert( fresh_counts[:infection_challenge] > 0 )
        assert( fresh_counts[:expression] > 0 )
      end
    end
    
    should "allow us to interact with the cache via helpers" do
      @controller.cache.clear
      assert_equal( @controller.fetch_from_cache("foo"), nil )
      
      data = { :a => 'a', :b => 23, :c => [1,2,3] }
      
      @controller.write_to_cache( "foo", data )
      assert_equal( data, @controller.fetch_from_cache("foo") )
    end
  end
  
end