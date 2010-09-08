require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchUtilsTest < Test::Unit::TestCase
  include MartSearch::Utils
  
  def test_symbolise_hash_keys
    test_hash = symbolise_hash_keys({ 'foo' => 'bar', :wibble => 'blib' })
    test_hash.each_key do |key|
      assert( key.is_a?(Symbol), "symbolise_hash_keys has not converted a String into a Symbol." )
    end
  end
  
  def test_convert_array_to_hash
    headers = ['one','two','three']
    data    = [1,2,3]
    
    hash = convert_array_to_hash( headers, data )
    assert_equal( 1, hash['one'] )
    assert_equal( 2, hash['two'] )
    assert_equal( 3, hash['three'] )
  end
  
  def test_array_chunking
    ten_elm_array    = [1,2,3,4,5,6,7,8,9,10]
    twelve_elm_array = [1,2,3,4,5,6,7,8,9,10,11,12]
    
    assert_equal( [[1,2,3,4,5],[6,7,8,9,10]], ten_elm_array.chunk(5) )
    assert_equal( [[1,2,3,4,5],[6,7,8,9,10],[11,12]], twelve_elm_array.chunk(5) )
  end
end