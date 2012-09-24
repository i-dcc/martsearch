# encoding: utf-8

require 'test_helper'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  include MartSearch::IndexBuilderUtils

  def setup
    @index_builder           = MartSearch::IndexBuilder.new()
    @index_builder.log.level = Logger::FATAL
  end

  context 'A MartSearch::IndexBuilder object' do
    should 'initialze correctly' do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), 'MartSearch::IndexBuilder did not initialze correctly.' )
    end

    should 'correctly call the DataSource to fetch all data ready for indexing' do
      VCR.use_cassette( 'test_index_builder_fetch_dataset', :record => :new_episodes ) do
        ret = @index_builder.send( :fetch_dataset, 'ikmc-imits', false )

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
        @index_builder.builder_config[:datasets][:'ikmc-dcc-gene_details'][:indexing][:filters] = {
          :status => ['Mice - Genotype confirmed','Mice - Germline transmission', 'Mice - Phenotype Data Available']
        }

        setup_and_move_to_work_directory()
        open_daily_directory( 'dataset_dowloads', false )

        @index_builder.send( :fetch_dataset, 'ikmc-dcc-gene_details' )
        @index_builder.send( :fetch_dataset, 'ikmc-imits' )

        setup_and_move_to_work_directory()
        Dir.chdir('dataset_dowloads/current')

        @index_builder.send( :process_dataset, 'ikmc-dcc-gene_details' )
        @index_builder.send( :process_dataset, 'ikmc-imits' )

        docs = @index_builder.document_cache

        assert( docs.is_a?(Hash), "@index_builder.document_cache is not a Hash." )
        assert( docs.has_key?('MGI:105369'), "@index_builder.document_cache doesn't contain an entry for Cbx1!!!" )
        assert( docs['MGI:105369'][:colony_prefix].include?('MAAT'), "The document entry for Cbx1 hasn't got a colony_prefix from imits." )

        # Test the document cleaning while we're here...
        assert( docs['MGI:105369'][:marker_symbol].size > 1 )
        @index_builder.send( :clean_document_cache )
        assert_equal( 1, docs['MGI:105369'][:marker_symbol].size )

        # And try saving the document_cache and xml files to disk...
        pwd = Dir.pwd
        @index_builder.send( :save_document_cache )
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

    should 'correctly fetch all of the datasets for indexing' do
      VCR.use_cassette( 'test_index_builder_fetch_datasets' ) do
        pwd = Dir.pwd
        setup_and_move_to_work_directory()
        Dir.chdir('dataset_dowloads/current')
        system("rm -f *.marshal")
        system("rm -f *.csv")
        Dir.chdir(pwd)

        # Run twice to make sure we run the file aging code...
        @index_builder.fetch_datasets()
        @index_builder.fetch_datasets()

        pwd = Dir.pwd
        setup_and_move_to_work_directory()
        Dir.chdir('dataset_dowloads/current')

        assert_equal( @index_builder.builder_config[:datasets].size, Dir.glob("*.marshal").size )
        assert_equal( @index_builder.builder_config[:datasets].size, Dir.glob("*.csv").size )

        Dir.chdir(pwd)
      end
    end

    should 'correctly process all of the datasets data for indexing' do
      VCR.use_cassette( 'test_index_builder_process_datasets' ) do
        # Cut down the amount of data to process - takes too long...
        original_ds_list = @index_builder.builder_config[:datasets_to_index].clone
        @index_builder.builder_config[:datasets_to_index] = original_ds_list[0..1]

        @index_builder.process_datasets()

        pwd = Dir.pwd
        setup_and_move_to_work_directory()
        open_daily_directory( 'document_cache', false )

        assert( @index_builder.document_cache != nil )
        assert( @index_builder.document_cache.size > 10 )
        assert_equal( 1, Dir.glob("document_cache.marshal").size )

        @index_builder.builder_config[:datasets_to_index] = original_ds_list
        Dir.chdir(pwd)
      end
    end
  end

end
