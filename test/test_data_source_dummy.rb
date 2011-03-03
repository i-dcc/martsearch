require 'test_helper'

class MartSearchDummyDataSourceTest < Test::Unit::TestCase
  def setup
    @conf_object      = MartSearch::Controller.instance()
    @dummy_datasource = MartSearch::DummyDataSource.new({})
  end
  
  context 'A MartSearch::DummyDataSource object' do
    should 'initialze correctly' do
      assert( @dummy_datasource.is_a?(MartSearch::DummyDataSource) )
    end
    
    should 'have a simple heartbeat function' do
      assert( @dummy_datasource.is_alive? )
    end
    
    should 'not have implemented fetch_all_terms_for_indexing()' do
      assert_raise(NotImplementedError) { @dummy_datasource.fetch_all_terms_for_indexing( {} ) }
    end

    # Test the return values for searches involving:
    #
    #               - no emma data
    # Dync1h1       - no kermiks data
    # Cbx1          - kermits and emma data
    # B020004C17Rik - no kermits or emma data
    should 'return the expeced data structure for search()' do
    end
    
    should 'not provide a URL link to the datasource of a search' do
      assert_equal( nil, @dummy_datasource.data_origin_url( ['foo','bar'], {} ) )
    end
    
  end
  
end