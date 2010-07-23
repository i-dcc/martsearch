require File.dirname(__FILE__) + '/test_helper.rb'

class MartSearchDataSourceTest < Test::Unit::TestCase
  def setup
    @ikmc_dcc_biomart = MartSearch::BiomartDataSource.new( :url => "http://www.i-dcc.org/biomart" )
  end
  
  context "A MartSearch::DataSource object" do
    should "" do
      
    end
  end
end