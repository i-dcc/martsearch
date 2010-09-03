require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  def setup
    @index_builder = MartSearch::IndexBuilder.new()
  end
  
  context 'A MartSearch::IndexBuilder object' do
    should 'initialze correctly' do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), 'MartSearch::IndexBuilder did not initialze correctly.' )
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
  
  def test_new_document
    @index_builder_config = MartSearch::ConfigBuilder.instance().config[:index_builder]
    doc = new_document()
    
    assert( doc.is_a?(Hash) )
    
    schema_fields = @index_builder_config[:schema]['fields'].keys
    copy_fields   = []
    
    @index_builder_config[:schema]['copy_fields'].each do |copy_field|
      copy_fields.push( copy_field['dest'] )
    end
    
    schema_fields.each do |field|
      if copy_fields.include?( field )
        assert( doc[field.to_sym].nil?, "The Solr copy field '#{field}' is present in the doc object." )
      else
        assert( doc[field.to_sym] != nil, "The Solr doc object does not contain an entry for '#{field}'." )
        assert( doc[field.to_sym].is_a?(Array) )
      end
    end
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
    assert( map_obj[:primary_attribute].is_a?(String) )
    assert( map_obj[:map_to_index_field].is_a?(Symbol) )
    
    assert_equal( { 'attr' => 'omim_id', 'idx' => :omim_id }, map_obj[:attribute_map]['omim_id'] )
  end
  
  def test_extract_value_to_index
    
  end
  
  def test_index_extracted_attributes
    extract_conf = { "idx" => "mp_id", "regexp" => "MP\\:\\d+" }
    text         = 'This is a test MP:0001 comment...'
    doc          = new_document()
    
    index_extracted_attributes( extract_conf, doc, text )
    
    assert( !doc[:mp_id].nil? )
    assert( doc[:mp_id].is_a?(Array) )
    assert_equal( 1, doc[:mp_id].size )
    assert_equal( 'MP:0001', doc[:mp_id][0] )
  end
  
  def test_index_grouped_attributes
    attr_map = [
      { 'attr' =>  'marker_symbol', 'idx' =>  'marker_symbol', 'use_to_map' =>  true },
      { 'attr' =>  'colony_prefix', 'idx' =>  'colony_prefix' },
      { 'attr' =>  'mi_centre',     'idx' =>  'microinjection_centre' },
      { 'attr' =>  'status',        'idx' =>  'microinjection_status' }
    ]
    grouped_attr_conf = [
      {
        'attrs' => ['mi_centre','status'],
        'idx'   => 'microinjection_centre_status',
        'using' => ' - '
      },
      {
        'attrs'  => ['marker_symbol','colony_prefix'],
        'idx'   => 'microinjection_centre_status'
      }
    ]
    data_row_obj = {
      'marker_symbol' => 'Cbx1',
      'colony_prefix' => 'MAAA',
      'mi_centre'     => 'WTSI',
      'status'        => 'done'
    }
    doc = new_document()
    
    index_grouped_attributes( grouped_attr_conf, doc, data_row_obj, process_attribute_map(attr_map) )
    
    assert( !doc[:microinjection_centre_status].nil? )
    assert( doc[:microinjection_centre_status].is_a?(Array) )
    assert_equal( 2, doc[:microinjection_centre_status].size )
    assert_equal( 'WTSI - done', doc[:microinjection_centre_status][0] )
    assert_equal( 'Cbx1||MAAA', doc[:microinjection_centre_status][1] )
  end
  
  def test_index_ontology_terms
    
  end
  
  
end