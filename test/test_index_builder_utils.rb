require 'test_helper'

class MartSearchIndexBuilderUtilsTest < Test::Unit::TestCase
  include MartSearch::IndexBuilderUtils
  
  def setup
    VCR.insert_cassette('test_index_builder_utils')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  def test_setup_and_move_to_work_directory
    setup_and_move_to_work_directory()
    assert( File.directory?('dataset_dowloads') )
    assert( File.directory?('dataset_dowloads/current') )
    assert( File.directory?('document_cache') )
    assert( File.directory?('solr_xml') )
    
    Dir.chdir('../../')
  end
  
  def test_open_daily_directory
    open_daily_directory( 'solr_xml', false )
    
    Dir.chdir('..')
    (1..10).each do |index|
      Dir.mkdir("daily_0000#{index}") unless File.directory?("daily_0000#{index}")
    end
    
    open_daily_directory( 'solr_xml', false )
    
    Dir.chdir('..')
    directories = Dir.glob("daily_*").sort
    
    assert_equal( 5, directories.size )

    directories.each do |dir|
      if dir.match("daily_0000")
        system("/bin/rm -r '#{dir}'")
      end
    end
    
    Dir.chdir('../../')
  end
  
  def test_new_document
    index_config = MartSearch::Controller.instance().config[:index]
    doc = new_document()
    assert( doc.is_a?(Hash) )
    
    schema_fields = index_config[:schema][:fields].keys
    copy_fields   = []
    
    index_config[:schema][:copy_fields].each do |copy_field|
      copy_fields.push( copy_field[:dest] )
    end
    
    schema_fields.each do |field|
      if copy_fields.include?( field.to_s )
        assert( doc[field].nil?, "The Solr copy field '#{field}' is present in the doc object." )
      else
        assert( doc[field] != nil, "The Solr doc object does not contain an entry for '#{field}'." )
        assert( doc[field].is_a?(Array) )
      end
    end
  end
  
  def test_process_attribute_map
    attribute_map = [
      { :attr =>  'mgi_accession_id', :idx =>  'mgi_accession_id_key', :use_to_map =>  true },
      { :attr =>  'omim_id',          :idx =>  'omim_id' },
      { :attr =>  'disorder_name',    :idx =>  'omim_desc' },
      { :attr =>  'disorder_omim_id', :idx =>  'omim_id' }
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
    
    assert_equal( { :attr => 'omim_id', :idx => :omim_id }, map_obj[:attribute_map]['omim_id'] )
    
    assert_raise(RuntimeError) {
      attribute_map.push({ :attr => 'foo', :idx => 'ignore_me', :use_to_map => true })
      map_obj = process_attribute_map( attribute_map )
    }
    
    assert_raise(RuntimeError) {
      attribute_map = [
        { :attr =>  'mgi_accession_id', :idx =>  'mgi_accession_id_key' },
        { :attr =>  'omim_id',          :idx =>  'omim_id' },
        { :attr =>  'disorder_name',    :idx =>  'omim_desc' },
        { :attr =>  'disorder_omim_id', :idx =>  'omim_id' }
      ]
      map_obj = process_attribute_map( attribute_map )
    }
    
  end
  
  def test_extract_value_to_index
    kermits = MartSearch::BiomartDataSource.new( :url => "http://www.i-dcc.org/biomart", :dataset => "kermits" ).ds
    
    map_obj = {
      'marker_symbol' => {},
      'colony_prefix' => { :index_attr_name => true },
      'mi_centre'     => { :if_attr_equals => 'MGP' },
      'status'        => { :if_other_attr_indexed => 'mi_centre' }
    }
    
    data_row_obj  = { 'marker_symbol' => 'Cbx1', 'colony_prefix' => 'MAAA', 'mi_centre' => 'WTSI', 'status' => 'done' }
    data_row_obj2 = { 'marker_symbol' => 'Cbx1', 'colony_prefix' => 'MAAA', 'mi_centre' => 'MGP', 'status' => 'done' }
    
    assert_equal( 'Cbx1', extract_value_to_index( 'marker_symbol', map_obj, data_row_obj ) )
    assert_equal( nil,    extract_value_to_index( 'mi_centre', map_obj, data_row_obj ) )
    assert_equal( 'MGP',  extract_value_to_index( 'mi_centre', map_obj, data_row_obj2 ) )
    
    assert( extract_value_to_index( 'colony_prefix', map_obj, data_row_obj, kermits ).include?( kermits.attributes['colony_prefix'].display_name ) )
    
    map_obj['colony_prefix'][:index_attr_display_name_only] = true
    assert_equal( kermits.attributes['colony_prefix'].display_name, extract_value_to_index( 'colony_prefix', map_obj, data_row_obj, kermits ) )
    
    assert_equal( nil,     extract_value_to_index( 'status', map_obj, data_row_obj ) )
    assert_equal( 'done',  extract_value_to_index( 'status', map_obj, data_row_obj2 ) )
    
    map_obj['marker_symbol'] = { :attr_prepend => 'Somethin like... ' }
    assert_equal( 'Somethin like... Cbx1', extract_value_to_index( 'marker_symbol', map_obj, data_row_obj ) )
    
    map_obj['marker_symbol'] = { :attr_append => ' w00t' }
    assert_equal( 'Cbx1 w00t', extract_value_to_index( 'marker_symbol', map_obj, data_row_obj ) )
  end
  
  def test_index_extracted_attributes
    extract_conf = { :idx => "mp_id", :regexp => "MP\\:\\d+" }
    text         = 'This is a test MP:0001 comment...'
    array        = ['More test text MP:0002','Extra MP:0003 woo']
    doc          = new_document()
    
    index_extracted_attributes( extract_conf, doc, text )
    
    assert( !doc[:mp_id].nil? )
    assert( doc[:mp_id].is_a?(Array) )
    assert_equal( 1, doc[:mp_id].size )
    assert_equal( 'MP:0001', doc[:mp_id][0] )
    
    index_extracted_attributes( extract_conf, doc, array )
    
    assert( doc[:mp_id].include?('MP:0002') )
    assert( doc[:mp_id].include?('MP:0003') )
  end
  
  def test_index_grouped_attributes
    attr_map = [
      { :attr =>  'marker_symbol', :idx =>  'marker_symbol', :use_to_map =>  true },
      { :attr =>  'colony_prefix', :idx =>  'colony_prefix' },
      { :attr =>  'mi_centre',     :idx =>  'microinjection_centre' },
      { :attr =>  'status',        :idx =>  'microinjection_status' }
    ]
    grouped_attr_conf = [
      {
        :attrs => ['mi_centre','status'],
        :idx   => 'microinjection_centre_status',
        :using => ' - '
      },
      {
        :attrs  => ['marker_symbol','colony_prefix'],
        :idx   => 'microinjection_centre_status'
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
    ontology_cache = {}
    doc = new_document()
    attr_map = [
      { :attr => 'mgi_accession_id', :idx => 'mgi_accession_id_key', :use_to_map => true },
      { :attr => 'mp_term',          :idx => 'mp_id' }
    ]
    ontology_term_conf = [
      {
        :attr => 'mp_term',
        :idx  => { :term => 'mp_id', :term_name => 'mp_term', :breadcrumb => 'mp_ontology' }
      }
    ]
    data_row_obj = {
      'mgi_accession_id' => 'MGI:2444584',
      'mp_term'          => 'EMAP:3018',
    }
    
    # Perform the search from fresh...
    index_ontology_terms( ontology_term_conf, doc, data_row_obj, process_attribute_map(attr_map), ontology_cache )
    
    assert_equal( 5, doc[:mp_id].size ) # we expect 5 terms to be indexed from this id...
    assert_equal( 4, doc[:mp_term].size )
    assert( doc[:mp_id].include?('EMAP:3018') )
    assert( doc[:mp_id].include?('EMAP:0') )
    assert( doc[:mp_term].include?('TS18,nose') )
    assert( doc[:mp_term].include?('TS18,embryo') )
    assert( doc[:mp_ontology].include?('EMAP:0 | EMAP:2636 | EMAP:2822 | EMAP:2987 | EMAP:3018') )
    
    # Perform the search from cache...
    doc2 = new_document()
    
    index_ontology_terms( ontology_term_conf, doc2, data_row_obj, process_attribute_map(attr_map), ontology_cache )
    
    assert_equal( 5, doc2[:mp_id].size )
    assert_equal( 4, doc2[:mp_term].size )
    assert( doc2[:mp_id].include?('EMAP:3018') )
    assert( doc2[:mp_id].include?('EMAP:0') )
    assert( doc2[:mp_term].include?('TS18,nose') )
    assert( doc2[:mp_term].include?('TS18,embryo') )
    assert( doc2[:mp_ontology].include?('EMAP:0 | EMAP:2636 | EMAP:2822 | EMAP:2987 | EMAP:3018') )
    
    # Make sure a bad ontology term doesn't blow stuff up...
    doc3 = new_document()
    data_row_obj2 = {
      'mgi_accession_id' => 'MGI:2444584',
      'mp_term'          => 'FLIBBLE:5',
    }
    
    index_ontology_terms( ontology_term_conf, doc3, data_row_obj2, process_attribute_map(attr_map), ontology_cache )
    
    assert( doc3[:mp_id].empty? )
    assert( doc3[:mp_term].empty? )
    assert( doc3[:mp_ontology].empty? )
  end
  
  def test_concatenated_ontology_terms
    ontology_cache = {}
    doc = new_document()
    attr_map = [
      { :attr => 'colony_prefix', :idx => 'colony_prefix', :use_to_map => true },
      { :attr => 'annotations',   :idx => 'ignore_me' }
    ]
    concatenated_ontology_term_conf = {
        :attr       => 'annotations',
        :split_on   => '; ',
        :ontologies => {
          :"^MA\\:\\d+$" => { :term => 'ma_id', :term_name => 'ma_term', :breadcrumb => 'ma_ontology' },
          :"^MP\\:\\d+$" => { :term => 'mp_id', :term_name => 'mp_term', :breadcrumb => 'mp_ontology' }
        }
    }
    data_row_obj = {
      'colony_prefix' => 'MAMM',
      'annotations'   => 'MA:0000053; MP:0003866'
    }
    
    # Perform the search from fresh...
    index_concatenated_ontology_terms( concatenated_ontology_term_conf, doc, data_row_obj, process_attribute_map(attr_map), ontology_cache )
    
    assert_equal( 6, doc[:ma_id].size )
    assert_equal( 5, doc[:ma_term].size )
    assert( doc[:ma_id].include?('MA:0000005') )
    assert( doc[:ma_id].include?('MA:0000001') )
    assert( doc[:ma_term].include?('body cavity or lining') )
    assert( doc[:ma_term].include?('adult mouse') )
    assert( doc[:ma_ontology].include?('MA:0000001 | MA:0002405 | MA:0002433 | MA:0000005 | MA:0002447 | MA:0000053') )
    
    assert_equal( 4, doc[:mp_id].size )
    assert_equal( 3, doc[:mp_term].size )
    assert( doc[:mp_id].include?('MP:0001663') )
    assert( doc[:mp_id].include?('MP:0000001') )
    assert( doc[:mp_term].include?('abnormal defecation') )
    assert( doc[:mp_term].include?('digestive/alimentary phenotype') )
    assert( doc[:mp_ontology].include?('MP:0000001 | MP:0005381 | MP:0001663 | MP:0003866') )
    
    # Perform the search from cache...
    doc2 = new_document()
    
    index_concatenated_ontology_terms( concatenated_ontology_term_conf, doc2, data_row_obj, process_attribute_map(attr_map), ontology_cache )
    
    assert_equal( 6, doc2[:ma_id].size )
    assert_equal( 5, doc2[:ma_term].size )
    assert( doc2[:ma_id].include?('MA:0000005') )
    assert( doc2[:ma_id].include?('MA:0000001') )
    
    assert_equal( 4, doc2[:mp_id].size )
    assert_equal( 3, doc2[:mp_term].size )
    assert( doc2[:mp_id].include?('MP:0001663') )
    assert( doc2[:mp_id].include?('MP:0000001') )
    
    # Make sure a bad ontology term doesn't blow stuff up...
    doc3 = new_document()
    data_row_obj2 = {
      'colony_prefix' => 'MAMM',
      'annotations'   => 'FLIBBLE:5',
    }
    
    index_concatenated_ontology_terms( concatenated_ontology_term_conf, doc3, data_row_obj2, process_attribute_map(attr_map), ontology_cache )
    
    assert( doc3[:ma_id].empty? )
    assert( doc3[:ma_term].empty? )
    assert( doc3[:ma_ontology].empty? )
    assert( doc3[:mp_id].empty? )
    assert( doc3[:mp_term].empty? )
    assert( doc3[:mp_ontology].empty? )
  end
  
end