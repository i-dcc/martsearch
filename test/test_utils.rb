require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchUtilsTest < Test::Unit::TestCase
  include MartSearch::Utils
  
  def test_symbolise_hash_keys
    test_hash = symbolise_hash_keys({ 'foo' => 'bar', :wibble => 'blib' })
    test_hash.each_key do |key|
      assert( key.is_a?(Symbol), "symbolise_hash_keys has not converted a String into a Symbol." )
    end
  end
  
end