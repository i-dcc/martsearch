require 'test_helper'

require 'capybara'
require 'capybara/dsl'
require 'rack/test'

class MartSearchServerCapybaraTest < Test::Unit::TestCase
  include Capybara
  
  def setup
    # Capybara.current_driver = :selenium
    Capybara.app            = MartSearch::Server.new
    @controller             = MartSearch::Controller.instance()
    @server_conf            = @controller.config[:server]
  end
  
  context "A MartSearch::Server web app instance" do
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
    
    should "enable browsing of the data..." do
      VCR.use_cassette('test_server_browsing') do
        @controller.config[:server][:browsable_content].each do |name,conf|
          conf[:options].each do |option_name|
            search_opts  = conf[:search_options][option_name.to_sym]
            display_opts = conf[:display_options][option_name.to_sym]
            
            page_no = 1
            while page_no < 3
              visit "/browse/#{name}/#{display_opts[:link_query]}/#{page_no}"
              assert_equal( '/browse', current_path )
              assert( page.has_content?("Browsing Data by #{conf[:display_name]}: '#{search_opts[:display_query]}'") )
              
              if page.has_css?('.pagination a.next_page')
                page_no = page_no + 1
              else
                page_no = 10
              end
            end
          end
        end
      end
    end
  end
  
end

# We do the other tests separately as Capybara/Selenium doesn't like looking at certain things
class MartSearchServerRackTest < Test::Unit::TestCase
  def setup
    @controller  = MartSearch::Controller.instance()
    @server_conf = @controller.config[:server]
    @browser     = Rack::Test::Session.new( Rack::MockSession.new( MartSearch::Server ) )
  end
  
  context 'A MartSearch::Server web app inatance' do
    should 'handle people trying to make up urls...' do
      @browser.get '/foo'
      assert_equal( 404, @browser.last_response.status )
      
      ['/browse/marker-symbol/wibble','/browse/flibble/blip'].each do |url|
        @browser.get url
        @browser.follow_redirect!
        assert_equal( 404, @browser.last_response.status )
      end
    end
    
    should 'allow you to do a simple search and retrieve a JSON response...' do
      VCR.use_cassette('test_server_simple_search') do
        search_term = @controller.index.config[:test][:single_return_search]
        
        @browser.get "/search?query=#{search_term}&wt=json"
        assert( @browser.last_response.ok? )
        
        json = JSON.parse( @browser.last_response.body )
        
        assert( json.is_a?(Hash) )
        assert( json[ json.keys.first ]['index'] != nil )
      end
    end
    
    should 'enable browsing of the data and retrieve a JSON response...' do
      VCR.use_cassette('test_server_browsing') do
        @controller.config[:server][:browsable_content].each do |name,conf|
          conf[:options].each do |option_name|
            search_opts  = conf[:search_options][option_name.to_sym]
            display_opts = conf[:display_options][option_name.to_sym]
            
            @browser.get "/browse?field=#{name}&query=#{display_opts[:link_query]}&page=1&wt=json"
            assert( @browser.last_response.ok? )
            
            json = JSON.parse( @browser.last_response.body )
            
            assert( json.is_a?(Hash) )
          end
        end
      end
    end
  end
end