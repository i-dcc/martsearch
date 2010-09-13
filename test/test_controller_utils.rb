require 'test_helper'

class MartSearchControllerUtilsTest < Test::Unit::TestCase
  include MartSearch::ControllerUtils
  
  def test_build_datasources
    config_dir  = "#{MARTSEARCH_PATH}/config"
    datasources = build_datasources(config_dir)
    
    assert( datasources.is_a?(Hash) )
    datasources.each do |key,value|
      assert( key.is_a?(Symbol) )
      assert( value.is_a?(MartSearch::DataSource) )
    end
  end
  
  def test_build_index_builder_conf
    conifg_dir = "#{MARTSEARCH_PATH}/config/index_builder"
    conifg     = build_index_builder_conf(conifg_dir)
    
    assert( conifg.is_a?(Hash) )
    assert( conifg.keys.include?(:datasources) )
    assert( conifg.keys.include?(:datasources_to_index) )
    assert( conifg.keys.include?(:url) )
    assert( conifg[:datasources].is_a?(Hash) )
  end
  
  def test_build_server_conf
    conifg_dir = "#{MARTSEARCH_PATH}/config/server"
    conifg     = build_server_conf(conifg_dir)
    
    assert( conifg.is_a?(Hash) )
    assert( conifg.keys.include?(:portal_url) )
    assert( conifg.keys.include?(:base_uri) )
    assert( conifg.keys.include?(:dataviews) )
    assert( conifg.keys.include?(:dataviews_by_name) )
    assert( conifg[:dataviews].is_a?(Array) )
    assert( conifg[:dataviews].size > 0 )
    assert( conifg[:dataviews_by_name].is_a?(Hash) )
    assert( conifg[:dataviews_by_name].size > 0 )
  end
  
  def test_initialize_cache
    memory_based_cache = initialize_cache()
    assert( memory_based_cache.is_a?(ActiveSupport::Cache::MemoryStore) )
    check_file_and_memory_based_cache_use( memory_based_cache, 'memory' )
    
    file_based_cache = initialize_cache({ :type => 'file' })
    assert( file_based_cache.is_a?(ActiveSupport::Cache::FileStore) )
    check_file_and_memory_based_cache_use( file_based_cache, 'file' )
    
    memcache_based_cache = initialize_cache({ :type => 'memcache' })
    assert( memcache_based_cache.is_a?(ActiveSupport::Cache::MemCacheStore) )
  end
  
  private
    
    def check_file_and_memory_based_cache_use( cache, type )
      todays_date = Date.today
      cache.write( "date", todays_date )
      assert_equal( todays_date, cache.fetch("date"), "The #{type} based cache fell over storing a 'date' stamp!" )
      assert_equal( true, cache.exist?("date"), "The #{type} based cache fell over recalling a 'date' stamp!" )
      assert_equal( nil, cache.fetch("foo"), "The #{type} based cache does not return 'nil' upon an empty value." )

      cache.delete_matched( Regexp.new(".*") )
      assert_equal( false, cache.exist?("foo"), "The 'delete_matched' method hasn't emptied out the cache..." )
    end
end