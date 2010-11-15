$LOAD_PATH.unshift( File.dirname( __FILE__ ) + "/../lib" )

require "rubygems"
require "biomart"
require "pp"
require "shoulda"
require "martsearch"

include MartSearch::ProjectUtils

def some_biomart_query_function
  handle_biomart_errors "ikmc-dcc", do
    @biomart.count( :filters => { "mgi_accession_id" => ["MGI:101757", "MGI:101758"] } )
  end
end

def raises_exception
  handle_biomart_errors "dodgy-mart", do
    raise Biomart::BiomartError.new("some Biomart::BiomartError we want to handle")
  end
end

class TestHandleBiomartErrors < Test::Unit::TestCase
  context "A wrapped function" do
    setup do
      @biomart = Biomart::Dataset.new( "http://www.i-dcc.org/biomart", { :name => "dcc" } )
    end

    context "that does not raise exceptions" do
      should "return data" do
        assert_equal 2, some_biomart_query_function[:data]
      end
    end

    context "that does raise exceptions" do
      should "not raise Biomart::BiomartError exceptions" do
        assert_nothing_raised do
          puts raises_exception[:error]
        end
      end
    end
  end
end
