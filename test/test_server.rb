require 'test_helper'

require 'capybara'
require 'capybara/dsl'

class MartSearchServerTest < Test::Unit::TestCase
  include Capybara
  
  def setup
    # Capybara.current_driver = :selenium
    Capybara.app            = MartSearch::Server.new
    @controller             = MartSearch::Controller.instance()
    @server_conf            = @controller.config[:server]
  end
  
  context "A MartSearch::Server web app inatance" do
    should "have 'home', 'about' and 'help' pages" do
      ['/','/about','/help'].each do |path|
        visit path
        assert_equal( path, current_path )
        assert( page.has_content?( @server_conf[:portal_name] ) )
      end
    end
    
    should "allow you to manually clear the cache by visiting 'clear_cache'" do
      visit '/clear_cache'
      assert_equal( '/', current_path )
      assert( page.has_content?( @server_conf[:portal_name] ) )
    end
    
    should "dump you back on the home page if a user tries to search without parameters" do
      visit '/search'
      assert_equal( '/', current_path )
    end
    
    should "allow you to do a simple search..." do
      VCR.use_cassette('test_server_simple_search') do
        visit '/'
        
        search_term = @controller.index.config[:test][:single_return_search]
        
        fill_in( 'query', :with => search_term )
        click_button('Search')
        
        assert_equal( '/search', current_path )
        assert( page.has_content?( @server_conf[:portal_name] ) )
        assert( page.has_content?( "Search Results for '#{search_term}'" ) )
        assert( page.has_css?('#search_results div.doc_content h4.dataset_title') )
        assert( page.has_css?('#search_results div.doc_content div.dataset_content') )
        
        ##
        ## Test redirects for the old rest style urls...
        ##
        
        visit "/search/#{search_term}"
        assert_equal( '/search', current_path )
        assert( page.has_content?( "Search Results for '#{search_term}'" ) )
        assert( page.has_css?('#search_results div.doc_content h4.dataset_title') )
        assert( page.has_css?('#search_results div.doc_content div.dataset_content') )
        
        visit "/search/#{search_term}/1"
        assert_equal( '/search', current_path )
        assert( page.has_content?( "Search Results for '#{search_term}'" ) )
        assert( page.has_css?('#search_results div.doc_content h4.dataset_title') )
        assert( page.has_css?('#search_results div.doc_content div.dataset_content') )
      end
    end
  end
  
end

# We do the JSON tests separately as Selenium doesn't like looking at JSON
class MartSearchServerJSONTest < Test::Unit::TestCase
  include Capybara
  
  def setup
    Capybara.current_driver = :rack_test
    Capybara.app            = MartSearch::Server.new
    @controller             = MartSearch::Controller.instance()
    @server_conf            = @controller.config[:server]
  end
  
  context "A MartSearch::Server web app inatance" do
    should "allow you to do a simple search and retrieve a JSON response..." do
      VCR.use_cassette('test_server_simple_search') do
        search_term = @controller.index.config[:test][:single_return_search]
        
        visit "/search?query=#{search_term}&wt=json"
        
        json = JSON.parse( page.body )
        
        assert( json.is_a?(Hash) )
        assert( json[ json.keys.first ]['index'] != nil )
      end
    end
  end
end