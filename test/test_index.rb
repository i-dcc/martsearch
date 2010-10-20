require 'test_helper'

class MartSearchIndexTest < Test::Unit::TestCase
  def setup
    conf   = MartSearch::Controller.instance().config[:index]
    @index = MartSearch::Index.new( conf )
  end
  
  context "A MartSearch::Index object" do
    should "initialize correctly" do
      assert( @index.is_a?(MartSearch::Index) )
      assert( @index.url != nil )
    end
    
    should "respond to pings" do
      VCR.use_cassette('test_index_ping') do
        assert( @index.is_alive?, "The search index is offline or misconfigured." )
      end
    end
    
    should "fail gracefully when we mess with the url" do
      VCR.use_cassette('test_index_unavailable') do
        orig_url   = @index.url
        @index.url = "http://www.foo.com"
        assert_raise(MartSearch::IndexUnavailableError) { @index.is_alive? }
        @index.url = orig_url
      end
    end
    
    should "correctly handle a simple (single item) search" do
      VCR.use_cassette('test_index_simple_search') do
        results = @index.search( @index.config[:test][:single_return_search] )
      
        assert_not_equal( results, false, "The .search function failed." )
        assert( results.is_a?(Hash), ".search does not return a hash object." )
        assert( @index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
        assert( @index.current_results_total === 1, ".current_results_total is not returning a number." )
        assert( @index.current_page === 1, ".current_page is not equal to 1." )
      end
    end
    
    should "correctly handle a more complicated (large) search" do
      VCR.use_cassette('test_index_large_search') do
        results = @index.search( @index.config[:test][:large_search] )
      
        assert_not_equal( results, false, "The .search function failed." )
        assert( results.is_a?(Hash), ".search does not return a hash object." )
        assert( @index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
        assert( @index.current_results_total >= 0, ".current_results_total is not returning a number." )
        assert( @index.current_page === 1, ".current_page should equal 1." )
      
        results2 = @index.search( @index.config[:test][:large_search], 4 )
      
        assert_not_equal( results2, false, "The .search function failed. (page 4)" )
        assert( results2.is_a?(Hash), ".search does not return a hash object. (page 4)" )
        assert( @index.current_results.is_a?(Hash), ".current_results does not return a hash object. (page 4)" )
        assert( @index.current_results_total >= 0, ".current_results_total is not returning a number. (page 4)" )
        assert( @index.current_page === 4, ".current_page should equal 4." )
      end
    end
    
    should "correctly handle a bad (i.e. will cause an error) search" do
      VCR.use_cassette('test_index_bad_search') do
        assert_raise(MartSearch::IndexSearchError) { results = @index.search( @index.config[:test][:bad_search] ) }
      end
    end
    
    should "correctly handle quick_search() requests" do
      VCR.use_cassette('test_index_quick_search') do
        single_result = @index.quick_search( @index.config[:test][:single_return_search] )
        assert( single_result.is_a?(Array), ".quick_search() does not return an Array.")
        assert( single_result.size == 1, ".quick_search() for #{@index.config[:test][:single_return_search]} does not return and array with 1 element.")
        
        multi_results = @index.quick_search( @index.config[:test][:large_search] )
        assert( multi_results.is_a?(Array), ".quick_search() does not return an Array.")
        assert( multi_results.size > 1, ".quick_search() for #{@index.config[:test][:large_search]} does not return an array with >1 element.")
        
        multi_results2 = @index.quick_search( @index.config[:test][:large_search], 4 )
        assert( multi_results2.is_a?(Array), ".quick_search() does not return an Array.")
        assert( multi_results2.size > 1, ".quick_search() for #{@index.config[:test][:large_search]} does not return an array with >1 element.")
        
        assert_raise(MartSearch::IndexSearchError) {
          bad_results = @index.quick_search( @index.config[:test][:bad_search] )
        }
      end
    end
    
    should "correctly handle count() requests" do
      VCR.use_cassette('test_index_count') do
        single_result = @index.count( @index.config[:test][:single_return_search] )
        assert( single_result.is_a?(Integer), ".count() does not return an Integer.")
        assert( single_result == 1, ".count() for #{@index.config[:test][:single_return_search]} does not return 1.")
      
        multi_results = @index.count( @index.config[:test][:large_search] )
        assert( multi_results.is_a?(Integer), ".count() does not return an Integer.")
        assert( multi_results > 1, ".count() for #{@index.config[:test][:large_search]} does not return >1.")
      
        assert_raise(MartSearch::IndexSearchError) {
          bad_results = @index.count( @index.config[:test][:bad_search] )
        }
      end
    end
  end
end