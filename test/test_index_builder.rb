require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchIndexBuilderTest < Test::Unit::TestCase
  def setup
    @index_builder = MartSearch::IndexBuilder.new()
  end
  
  context 'A MartSearch::IndexBuilder object' do
    should 'initialze correctly' do
      assert( @index_builder.is_a?(MartSearch::IndexBuilder), 'MartSearch::IndexBuilder did not initialze correctly.' )
    end
    
    should 'correctly call the DataSource to fetch all data ready for indexing' do
      VCR.use_cassette( 'test_index_builder_fetch_datasource', :record => :new_episodes ) do
        ret = @index_builder.fetch_datasource('ikmc-kermits')
        
        assert( ret.is_a?(Hash), "fetch_all_terms_for_indexing() does not return a hash." )
        assert( ret[:headers] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :headers." )
        assert( ret[:data] != nil, "the returned hash from fetch_all_terms_for_indexing() contains a nil value for :data." )
        
        assert( ret[:headers].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :headers." )
        assert( ret[:data].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array for :data." )
        assert( ret[:data][0].is_a?(Array), "the returned hash from fetch_all_terms_for_indexing() does not return an Array of Arrays for :data." )
      end
    end
    
    should 'correctly process the results from a DataSource return' do
      VCR.use_cassette( 'test_index_builder_process_results', :record => :new_episodes ) do
        @index_builder.config[:datasources][:'ikmc-dcc'][:indexing]['filters'] = {
          'status' => ['Mice - Genotype confirmed','Mice - Germline transmission']
        }
        
        @index_builder.process_results( 'ikmc-dcc', @index_builder.fetch_datasource( 'ikmc-dcc' ) )
        @index_builder.process_results( 'ikmc-kermits', @index_builder.fetch_datasource('ikmc-kermits') )
        
        docs = @index_builder.document_cache
        
        assert( docs.is_a?(Hash), "@index_builder.document_cache is not a Hash." )
        assert( docs.has_key?('MGI:105369'), "@index_builder.document_cache doesn't contain an entry for Cbx1!!!" )
        assert( docs['MGI:105369'][:colony_prefix].include?('MAAT'), "The document entry for Cbx1 hasn't got a colony_prefix from kermits." )
      end
    end
    
  end
end
