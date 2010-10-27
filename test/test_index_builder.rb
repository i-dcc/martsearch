require 'test_helper'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  include MartSearch::IndexBuilderUtils
  
  def setup
    @index_builder           = MartSearch::IndexBuilder.new()
    @index_builder.log.level = Logger::FATAL
    setup_access_to_private_methods( @index_builder )
  end
  
  context 'A MartSearch::IndexBuilder object' do
    should 'initialze correctly' do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), 'MartSearch::IndexBuilder did not initialze correctly.' )
    end
    
    should 'correctly call the DataSource to fetch all data ready for indexing' do
      VCR.use_cassette( 'test_index_builder_fetch_dataset', :record => :new_episodes ) do
        ret = @index_builder.fetch_dataset_public( 'ikmc-kermits', false )
        
        assert( ret.is_a?(Hash), "fetch_all_terms_for_indexing() does not return a hash." )
        assert( ret[:headers] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :headers." )
        assert( ret[:data] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :data." )
        
        assert( ret[:headers].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :headers." )
        assert( ret[:data].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :data." )
        assert( ret[:data][0].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array of Arrays for :data." )
      end
    end
    
    should 'correctly process the results from a DataSource return' do
      VCR.use_cassette( 'test_index_builder_process_dataset' ) do
        @index_builder.builder_config[:datasets][:'ikmc-dcc'][:indexing][:filters] = {
          :status => ['Mice - Genotype confirmed','Mice - Germline transmission']
        }
        
        setup_and_move_to_work_directory()
        open_daily_directory( 'dataset_dowloads', false )
        
        @index_builder.fetch_dataset_public( 'ikmc-dcc' )
        @index_builder.fetch_dataset_public( 'ikmc-kermits' )
        
        setup_and_move_to_work_directory()
        Dir.chdir('dataset_dowloads/current')
        
        @index_builder.process_dataset_public( 'ikmc-dcc' )
        @index_builder.process_dataset_public( 'ikmc-kermits' )
        
        docs = @index_builder.document_cache
        
        assert( docs.is_a?(Hash), "@index_builder.document_cache is not a Hash." )
        assert( docs.has_key?('MGI:105369'), "@index_builder.document_cache doesn't contain an entry for Cbx1!!!" )
        assert( docs['MGI:105369'][:colony_prefix].include?('MAAT'), "The document entry for Cbx1 hasn't got a colony_prefix from kermits." )
        
        # Test the document cleaning while we're here...
        assert( docs['MGI:105369'][:marker_symbol].size > 1 )
        @index_builder.clean_document_cache_public()
        assert_equal( 1, docs['MGI:105369'][:marker_symbol].size )
        
        # And try saving the document_cache and xml files to disk...
        pwd = Dir.pwd
        @index_builder.save_document_cache_public()
        assert_equal( pwd, Dir.pwd )
        
        open_daily_directory( 'document_cache', false )
        assert( File.exists?( 'document_cache.marshal' ) )
        
        Dir.chdir(pwd)
        @index_builder.save_solr_document_xmls()
        assert_equal( pwd, Dir.pwd )
        
        open_daily_directory( 'solr_xml', false )
        assert( Dir.glob("solr-xml-*.xml").size > 0 )
        
        Dir.chdir('../../../../')
      end
    end
    
  end
  
  def setup_access_to_private_methods( builder )
    def builder.fetch_dataset_public(*args)
      fetch_dataset(*args)
    end
    
    def builder.process_dataset_public(*args)
      process_dataset(*args)
    end
    
    def builder.clean_document_cache_public(*args)
      clean_document_cache(*args)
    end
    
    def builder.save_document_cache_public(*args)
      save_document_cache(*args)
    end
  end
end
