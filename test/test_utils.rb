require 'test_helper'

class MartSearchUtilsTest < Test::Unit::TestCase
  include MartSearch::Utils
  
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
  
  def test_hash_and_array_key_symbolization
    test = [
      { 'foo' => true },
      { 'fee' => { 'a' => 1, 'b' => { 'foo' => true } } },
      { 'fii' => [ 'a', { 'a' => 2, 'b' => 3 } ] },
      [ 0, 1, 2, { 'a' => true } ]
    ]
    
    test_orig = test.clone
    test.recursively_symbolize_keys!
    
    assert( test[0].keys.include?(:foo) )
    assert( test[1].keys.include?(:fee) )
    assert( test[1][:fee].keys.include?(:a) )
    assert( test[1][:fee][:b].keys.include?(:foo) )
    assert( test[1][:fee][:b][:foo] )
    assert( test[2][:fii][1].keys.include?(:a) )
    assert( test[3][3].keys.include?(:a) )
    assert( test[3][3][:a] )
    
    test.recursively_stringify_keys!
    
    assert_equal( test_orig, test )
    assert( test[0].keys.include?('foo') )
  end
end