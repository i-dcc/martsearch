require 'test_helper'

class MartSearchDataSourceTest < Test::Unit::TestCase
  def setup
    @datasource = MartSearch::DataSource.new( :url => 'http://www.google.com' )
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
  
end