# encoding: utf-8

require "test_helper"

class TestProjectUtilsHandleBiomartErrors < Test::Unit::TestCase
  include MartSearch::ProjectUtils
  public  :handle_biomart_errors

  def does_not_raise_exception
    handle_biomart_errors( "ikmc-dcc", "" ) do
      @biomart.count( :filters => { "mgi_accession_id" => ["MGI:101757", "MGI:101758"] } )
    end
  end

  def raises_biomart_exception
    handle_biomart_errors( "dodgy-mart", "" ) do
      raise Biomart::BiomartError.new("some Biomart::BiomartError we want to handle")
    end
  end

  def raises_timeout_exception
    handle_biomart_errors( "slow-mart", "" ) do
      raise Timeout::Error.new("fake a timeout error")
    end
  end

  context "A wrapped function" do
    setup do
      VCR.insert_cassette( "test_handle_biomart_errors" )
      @biomart = Biomart::Dataset.new( "http://www.i-dcc.org/biomart", { :name => "dcc" } )
    end

    context "that does not raise exceptions" do
      should "not raise Biomart::BiomartError exceptions" do
        assert_nothing_raised do
          does_not_raise_exception
        end
      end
    end

    context "that does raise exceptions" do
      should "catch all Biomart::BiomartError exceptions" do
        assert_nothing_raised do
          raises_biomart_exception
        end
      end

      should "catch all Timeout::Error exceptions" do
        assert_nothing_raised do
          raises_timeout_exception
        end
      end
    end

    teardown do
      VCR.eject_cassette
    end
  end
end
