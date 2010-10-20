require 'test_helper'

class MartSearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = MartSearch::Controller.instance()
    setup_access_to_private_methods( @controller )
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
        bad_result = @controller.search_from_fresh_index_public( @controller.config[:index][:test][:bad_search], 1 )
        assert_equal( false, bad_result )
        
        good_result = @controller.search_from_fresh_index_public( @controller.config[:index][:test][:single_return_search], 1 )
        assert_equal( true, good_result )
        
        # Now check the 'cached' data
        fresh_index_data  = Marshal.load( Marshal.dump( @controller.search_data ) )
        cached_index_data = @controller.cache.fetch("index:#{@controller.config[:index][:test][:single_return_search]}-page1")
        
        @controller.clear_instance_variables_public()
        @controller.search_from_cached_index_public( cached_index_data )
        assert_equal( fresh_index_data, @controller.search_data )
        
        ##
        ## Test search_from_fresh_datasets
        ##
        
        # First prepare the search terms to drive the dataset searches
        grouped_search_terms = @controller.prepare_dataset_search_terms_public( @controller.search_data.keys )
        
        # Now drive the dataset searches
        dataset_results = @controller.search_from_fresh_datasets_public( grouped_search_terms )
        assert( dataset_results.is_a?(TrueClass) || dataset_results.is_a?(FalseClass) )
        
        @controller.search_data.each do |key,value|
          assert( value.keys.size > 2 )
        end
      end
    end
    
    should "allow us to perform end-to-end searches" do
      VCR.use_cassette('test_controller_search') do
        @controller.clear_instance_variables_public()
        @controller.cache.clear
        
        fresh_results  = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
        cached_results = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
        
        assert_equal( fresh_results, cached_results )
      end
    end
    
  end
  
  def setup_access_to_private_methods( controller )
    def controller.search_from_fresh_index_public(*args)
      search_from_fresh_index(*args)
    end
    
    def controller.search_from_cached_index_public(*args)
      search_from_cached_index(*args)
    end
    
    def controller.prepare_dataset_search_terms_public(*args)
      prepare_dataset_search_terms(*args)
    end
    
    def controller.search_from_fresh_datasets_public(*args)
      search_from_fresh_datasets(*args)
    end
    
    def controller.clear_instance_variables_public(*args)
      clear_instance_variables(*args)
    end
  end
end