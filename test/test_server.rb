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
          # Select 5 random pages to hit - doing them all takes forever...
          conf[:options].randomly_pick(5).each do |option_name|
            opts = conf[:processed_options][option_name.to_sym]
            
            page_no = 1
            while page_no < 3
              visit "/browse/#{name}/#{opts[:link_arg]}/#{page_no}"
              assert_equal( '/browse', current_path )
              assert( page.has_content?("Browsing Data by #{conf[:display_name]}: '#{opts[:display_arg]}'"), "A request to '/browse/#{name}/#{opts[:link_arg]}/#{page_no}' failed!" )
              
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
    
    should "render IKMC project pages" do
      VCR.use_cassette('test_server_project_page') do
        project_ids_to_test = ['35505','27042','42474']

        project_ids_to_test.each do |project_id|
          visit "/project/#{project_id}"
          assert_equal( "/project/#{project_id}", current_path )
          assert( page.has_content?("(ID: #{project_id})") )
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
  
  context 'A MartSearch::Server web app instance' do
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
          # Select 5 random pages to hit - doing them all takes forever...
          conf[:options].randomly_pick(5).each do |option_name|
            opts = conf[:processed_options][option_name.to_sym]
            
            @browser.get "/browse?field=#{name}&query=#{opts[:link_arg]}&page=1&wt=json"
            assert( @browser.last_response.ok?, "A request to '/browse?field=#{name}&query=#{opts[:link_arg]}&page=1&wt=json' failed!" )
            json = JSON.parse( @browser.last_response.body )
            assert( json.is_a?(Hash) )
          end
        end
      end
    end
    
    should 'render IKMC project pages as JSON...' do
      VCR.use_cassette('test_server_project_page') do
        project_ids_to_test = ['35505','27042','42474']
        
        project_ids_to_test.each do |project_id|
          @browser.get "/project/#{project_id}?wt=json"
          assert( @browser.last_response.ok?, "A request to '/project/#{project_id}?wt=json' failed!" )
          json = JSON.parse( @browser.last_response.body )
          assert( json.is_a?(Hash) )
        end
        
        @browser.get "/project/foobar"
        assert_equal( 404, @browser.last_response.status.to_i )
      end
    end
    
    should 'generate compressed css and javascript...' do
      @browser.get '/css/martsearch-foo.css'
      assert( @browser.last_response.ok? )
      assert_equal( 'text/css;charset=utf-8', @browser.last_response.headers["Content-Type"] )
      
      @browser.get '/js/martsearch-head-foo.js'
      assert( @browser.last_response.ok? )
      assert_equal( 'text/javascript;charset=utf-8', @browser.last_response.headers["Content-Type"] )
      
      @browser.get '/js/martsearch-base-foo.js'
      assert( @browser.last_response.ok? )
      assert_equal( 'text/javascript;charset=utf-8', @browser.last_response.headers["Content-Type"] )
    end
    
    should 'render dataview css and javascript...' do
      @controller.dataviews_by_name.each do |name,view|
        unless view.stylesheet.nil?
          @browser.get "/dataview-css/#{name}.css"
          assert( @browser.last_response.ok?, "/dataview-css/#{name}.css failed." )
          assert_equal( 'text/css;charset=utf-8', @browser.last_response.headers["Content-Type"], "/dataview-css/#{name}.css has the wrong content_type." )
          assert_equal( view.stylesheet, @browser.last_response.body, "/dataview-css/#{name}.css is not as expected." )
        end
        
        unless view.javascript_head.nil?
          @browser.get "/dataview-head-js/#{name}.js"
          assert( @browser.last_response.ok?, "/dataview-head-js/#{name}.js failed." )
          assert_equal( 'text/javascript;charset=utf-8', @browser.last_response.headers["Content-Type"], "/dataview-head-js/#{name}.js has the wrong content_type." )
          assert_equal( view.javascript_head, @browser.last_response.body, "/dataview-head-js/#{name}.js is not as expected." )
        end
        
        unless view.javascript_base.nil?
          @browser.get "/dataview-base-js/#{name}.js"
          assert( @browser.last_response.ok?, "/dataview-base-js/#{name}.js failed." )
          assert_equal( 'text/javascript;charset=utf-8', @browser.last_response.headers["Content-Type"], "/dataview-base-js/#{name}.js has the wrong content_type." )
          assert_equal( view.javascript_base, @browser.last_response.body, "/dataview-base-js/#{name}.js is not as expected." )
        end
      end
    end
  end
end