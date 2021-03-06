# encoding: utf-8

require 'test_helper'

class MartSearchFileSystemDataSourceTest < Test::Unit::TestCase
  def setup
    @conf_obj      = MartSearch::Controller.instance()
    @fs_datasource = MartSearch::FileSystemDataSource.new( :location => "/tmp/pheno_abr" )
  end

  context 'A MartSearch::FileSystemDataSource object' do
    should 'initialze correctly' do
      assert( @fs_datasource.is_a?(MartSearch::FileSystemDataSource) )
      assert( @fs_datasource.fs_location != nil )
    end

    should 'have a simple heartbeat function' do
      assert( @fs_datasource.is_alive? )
    end

    should 'not have implemented fetch_all_terms_for_indexing()' do
      assert_raise(NotImplementedError) { @fs_datasource.fetch_all_terms_for_indexing( {} ) }
    end

    should 'return the expeced data structure for search()' do
      omit_if(
        @conf_obj.datasets[:'wtsi-phenotyping-abr'].nil?,
        "Can't run a FileSystemDataSource.search() test without a configured dataset."
      )

      dataset_conf = @conf_obj.datasets[:'wtsi-phenotyping-abr'].config()
      ret          = @fs_datasource.search( ['MAMH','MAMJ'], dataset_conf[:searching] )

      assert( ret.is_a?(Array), 'search() does not return an array.' )
      assert( ret.size > 0, 'the return from search() is empty - it should have data...' )
      assert( ret[0].is_a?(Hash), 'The elements of the array from search() are not hashes.' )

      ret.each do |data_return|
        assert( data_return.keys.include?( :file ), "The attribute :file is missing from the data hash." )
      end
    end

    should 'not provide a URL link to the datasource of a search' do
      assert_equal( nil, @fs_datasource.data_origin_url( ['foo','bar'], {} ) )
    end

    # temporary check until copy of pheno_abr completed as part of test
	should 'expect to find files in location' do
      assert( @fs_datasource.fs_location != nil )
      assert( ! Dir["#{@fs_datasource.fs_location}/*"].empty?, "You need to copy the files from ~do2/projects/martsearch/tmp/pheno_abr or similar!" )
    end

  end

end
