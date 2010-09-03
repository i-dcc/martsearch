require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  def setup
    @index_builder = MartSearch::IndexBuilder.new()
  end
  
  context "A MartSearch::IndexBuilder object" do
    should "initialze correctly" do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), "MartSearch::IndexBuilder did not initialze correctly." )
    end
  end
end

class MartSearchIndexBuilderUtilsTest < Test::Unit::TestCase
  include MartSearch::IndexBuilderUtils
  
  def test_flatten_primary_secondary_datasources
    hash  = { 'primary' => [1,2], 'secondary' => [3,4,5] }
    array = flatten_primary_secondary_datasources( hash )
    
    assert( array.is_a?(Array) )
    assert_equal( 1, array[0] )
    assert_equal( 4, array[3] )
    assert_equal( 5, array.size )
  end
  
  def test_process_attribute_map
    attribute_map = [
      { 'attr' =>  'mgi_accession_id', 'idx' =>  'mgi_accession_id_key', 'use_to_map' =>  true },
      { 'attr' =>  'omim_id',          'idx' =>  'omim_id' },
      { 'attr' =>  'disorder_name',    'idx' =>  'omim_desc' },
      { 'attr' =>  'disorder_omim_id', 'idx' =>  'omim_id' }
    ]
    map_obj = process_attribute_map( attribute_map )
    
    assert( map_obj.has_key?(:attribute_map) )
    assert( map_obj.has_key?(:primary_attribute) )
    assert( map_obj.has_key?(:map_to_index_field) )
    
    assert_equal( 'mgi_accession_id', map_obj[:primary_attribute] )
    assert_equal( :mgi_accession_id_key, map_obj[:map_to_index_field] )
    
    assert( map_obj[:attribute_map].is_a?(Hash) )
    assert_equal( { 'attr' => 'omim_id', 'idx' => :omim_id }, map_obj[:attribute_map]['omim_id'] )
  end
  
  def test_index_extracted_attributes
  end
  
  def test_index_grouped_attributes
  end
  
  def test_index_ontology_terms
  end
  
  
end