require 'test_helper'

class MartSearchDataViewTest < Test::Unit::TestCase
  def setup
    @controller = MartSearch::Controller.instance()
    @test_conf  = {
      :internal_name       => 'gene-details',
      :name                => "Gene Details",
      :description         => "A test dataview",
      :enabled             => true,
      :display             => true,
      :custom_css          => false,
      :custom_js           => true,
      :custom_view_helpers => false,
      :custom_routes       => false,
      :datasets => {
        :required => [ "mgi-markers" ],
        :optional => [ "ikmc-omim", "ensembl-mouse-homologs" ]
      }
    }
    VCR.insert_cassette('test_data_view')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  context 'A MartSearch::DataView object' do
    should 'initialze correctly' do
      dataview = MartSearch::DataView.new( @test_conf )
      assert( dataview.is_a?(MartSearch::DataView) )
    end
    
    should 'raise an error if given a config object missing values' do
      assert_raise( MartSearch::InvalidConfigError ) do
        @test_conf.delete(:name)
        dataview = MartSearch::DataView.new( @test_conf )
      end
    end
    
    should 'raise an error if given a config object with incorrect dataset names' do
      assert_raise( MartSearch::InvalidConfigError ) do
        @test_conf[:datasets][:required] = ['flibble','monkey']
        dataview       = MartSearch::DataView.new( @test_conf )
        search_results = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
        result         = @controller.search_data[ search_results[0][ @controller.index.primary_field ] ]
      
        dataview.display_for_result?( result, {} )
      end
    end
    
    should 'let the view know if it has data worth displaying' do
      dataview       = MartSearch::DataView.new( @test_conf )
      search_results = @controller.search( @controller.config[:index][:test][:single_return_search], 1 )
      result         = @controller.search_data[ search_results[0][ @controller.index.primary_field ].to_sym ].dup
      
      assert_equal( true, dataview.display_for_result?( result, {} ) )
      assert_equal( true, dataview.display_for_result?( result, { :'mgi-markers' => [1,2,3] } ) )
      
      result.each do |key,value|
        result[key] = nil
      end
      
      assert_equal( true, dataview.display_for_result?( result, { :'mgi-markers' => [1,2,3] } ) )
      assert_equal( false, dataview.display_for_result?( result, {} ) )
    end
  end
  
end