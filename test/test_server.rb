# encoding: utf-8

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
      VCR.use_cassette('test_server_basic_pages') do
        ['/','/about','/help'].each do |path|
          visit path
          assert_equal( path, current_path )
          assert( page.has_selector?( 'h1', :text => @server_conf[:portal_name], :visible => true ) )
        end
      end
    end
    
    should "allow you to manually clear the cache by visiting 'clear_cache'" do
      VCR.use_cassette('test_server_basic_pages') do
        visit '/clear_cache'
        assert_equal( '/', current_path )
        assert( page.has_selector?( 'h1', :text => @server_conf[:portal_name], :visible => true ) )
      end
    end
    
    should "dump you back on the home page if a user tries to search without parameters" do
      VCR.use_cassette('test_server_basic_pages') do
        visit '/search'
        assert_equal( '/', current_path )
      end
    end
    
    should "allow you to do a simple search..." do
      VCR.use_cassette('test_server_simple_search') do
        search_terms_to_test = ['Mysm1','Cbx1','Arid4a','Art4','Myo7a']
        
        search_terms_to_test.each do |search_term|
          visit '/'
          
          fill_in( 'query', :with => search_term )
          click_button('Search')
          
          assert_equal( '/search', current_path, "Simple search for '#{search_term}': The home page form didn't forward to /search." )
          assert( page.has_content?( @server_conf[:portal_name] ), "Simple search for '#{search_term}': /search doesn't have the portal title." )
          assert( page.has_content?( "Search Results for '#{search_term}'" ), "Simple search for '#{search_term}': /search doesn't show the search term we've just looked for..." )
          assert( page.has_css?('#search_results div.doc_content h4.dataset_title'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content h4.dataset_title'." )
          assert( page.has_css?('#search_results div.doc_content div.dataset_content'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content div.dataset_content'." )
          
          ##
          ## Test redirects for the old rest style urls...
          ##

          visit "/search/#{search_term}"
          assert_equal( '/search', current_path, "Simple search for '#{search_term}': The home page form didn't forward to /search." )
          assert( page.has_content?( "Search Results for '#{search_term}'" ), "Simple search for '#{search_term}': /search doesn't show the search term we've just looked for..." )
          assert( page.has_css?('#search_results div.doc_content h4.dataset_title'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content h4.dataset_title'." )
          assert( page.has_css?('#search_results div.doc_content div.dataset_content'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content div.dataset_content'." )

          visit "/search/#{search_term}/1"
          assert_equal( '/search', current_path, "Simple search for '#{search_term}': The home page form didn't forward to /search." )
          assert( page.has_content?( "Search Results for '#{search_term}'" ), "Simple search for '#{search_term}': /search doesn't show the search term we've just looked for..." )
          assert( page.has_css?('#search_results div.doc_content h4.dataset_title'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content h4.dataset_title'." )
          assert( page.has_css?('#search_results div.doc_content div.dataset_content'), "Simple search for '#{search_term}': /search doesn't have the HTML for '#search_results div.doc_content div.dataset_content'." )
        end
      end
    end
    
    should "enable browsing of the data..." do
      VCR.use_cassette('test_server_browsing') do
        @controller.config[:server][:browsable_content].each do |name,conf|
          # Select 5 random pages to hit - doing them all takes forever...
          conf[:options].keys.randomly_pick(5).each do |option_name|
            opts = conf[:options][option_name.to_sym]
            
            page_no = 1
            while page_no < 3
              visit "/browse/#{name}/#{option_name}/#{page_no}"
              assert_equal( '/browse', current_path, "A request to '/browse/#{name}/#{option_name}/#{page_no}' failed!" )
              
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
        project_ids_to_test = ['35505','27042','42474','82403','23242','VG12252','VG11490']
    
        project_ids_to_test.each do |project_id|
          visit "/project/#{project_id}"
          assert_equal( "/project/#{project_id}", current_path )
          assert( page.has_content?("(ID: #{project_id})") )
        end
      end
    end
    
    should "render WTSI Phenotyping (test based) report pages" do
      omit_if(
        @controller.dataviews_by_name[:'wtsi-phenotyping'].nil?,
        "Skipping WTSI Phenotyping report tests as the DataView is not active."
      )
      
      VCR.use_cassette('test_server_wtsi_phenotyping_report_pages') do
        colonies_to_test = ['MAHN','MAMH','MAMJ','MAAD','MAAJ']
        
        colonies_to_test.each do |colony_prefix|
          visit '/'
          fill_in( 'query', :with => "#{colony_prefix}" )
          click_button('Search')
          
          assert_equal( '/search', current_path, "WTSI Phenotyping search for '#{colony_prefix}': The home page form didn't forward to /search." )
          assert( page.has_content?( "Search Results for '#{colony_prefix}'" ), "WTSI Phenotyping search for '#{colony_prefix}': /search doesn't show the search term we've just looked for..." )
          
          cached_data = @controller.fetch_from_cache("wtsi-pheno-data:#{colony_prefix}")
          assert( !cached_data.nil?, "There is no cached phenotyping data for '#{colony_prefix}'!" )
          
          urls_to_hit = []
          
          cached_data.each do |cached_data_key,test_data|
            test_url = cached_data_key.to_s.gsub('_data','').gsub('_','-')
            
            # Don't test PDF downloads...
            next if test_url == 'eye-histopathology'
            
            test_title = case test_url
            when 'auditory-brainstem-response' then 'Auditory Brainstem Response'
            when 'adult-lac-z-expression'      then 'Adult LacZ Expression'
            when 'embryo-lac-z-expression'     then 'Embryo LacZ Expression'
            when 'viability-at-weaning'        then 'Viability at Weaning'
            when 'fertility'                   then 'Fertility'
            when 'tail-epidermis-wholemount'   then 'Tail Epidermis Wholemount'
            else
              test_data[:test]
            end
            
            urls_to_hit.push({
              :test  => test_url,
              :url   => "/phenotyping/#{colony_prefix}/#{test_url}/",
              :title => test_title
            })
          end
          
          # Clear the cache so we test the full stack...
          @controller.cache.delete("wtsi-pheno-data:#{colony_prefix}/")
          
          urls_to_hit.each do |test_conf|
            visit test_conf[:url]
            assert_equal( "#{test_conf[:url]}", current_path, "WTSI Phenotyping - can't visit '#{test_conf[:url]}'!" )
            assert( page.first(:css,'h2').text.include?(test_conf[:title]), "WTSI Phenotyping - '#{test_conf[:url]}' doesn't have the title '#{test_conf[:title]}'..." )
            
            if test_conf[:test_group] == 'auditory-brainstem-response'
              assert( page.has_css?('#abr-thresholds') )
              href = page.first(:css, "#abr-thresholds a[rel='prettyPhoto']")[:href]
              visit "#{test_conf[:url]}#{href}"
              visit "#{test_conf[:url]}foobarweewar.png"
            end
          end
        end
      end
    end
    
    should "render WTSI Phenotyping (MP based) report pages" do
      omit_if(
        @controller.dataviews_by_name[:'wtsi-phenotyping'].nil?,
        "Skipping WTSI Phenotyping report tests as the DataView is not active."
      )
      
      VCR.use_cassette('test_server_wtsi_phenotyping_mp_report_pages') do
        colonies_to_test = ['MAHN','MAMH','MAMJ','MAAD','MAAJ']
        
        colonies_to_test.each do |colony_prefix|
          visit '/'
          fill_in( 'query', :with => "#{colony_prefix}" )
          click_button('Search')
          
          assert_equal( '/search', current_path, "WTSI Phenotyping search for '#{colony_prefix}': The home page form didn't forward to /search." )
          assert( page.has_content?( "Search Results for '#{colony_prefix}'" ), "WTSI Phenotyping search for '#{colony_prefix}': /search doesn't show the search term we've just looked for..." )
          
          cached_data = @controller.fetch_from_cache("wtsi-pheno-mp-data:#{colony_prefix}")
          assert( !cached_data.nil?, "There is no cached phenotyping mp data for '#{colony_prefix}'!" )
          
          cached_data[:mp_groups].each do |mp_group,mp_group_data|
            url = "/phenotyping/#{colony_prefix}/mp-report/#{mp_group}/"
            visit url
            assert_equal( url, current_path, "WTSI Phenotyping - can't visit '#{url}'!" )
            assert( page.has_content?(mp_group_data[:mp_id]), "WTSI Phenotyping - '#{url}' doesn't include the MP id '#{mp_group_data[:mp_id]}'")
            assert( page.has_content?(mp_group_data[:mp_term]), "WTSI Phenotyping - '#{url}' doesn't include the MP term '#{mp_group_data[:mp_term]}'")
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
        search_terms_to_test = ['Mysm1','Cbx1','Arid4a','Art4','Myo7a']
        
        search_terms_to_test.each do |search_term|
          @browser.get "/search?query=#{search_term}&wt=json"
          assert( @browser.last_response.ok?, "Simple search for '#{search_term}': last_response not ok." )
          
          json = JSON.parse( @browser.last_response.body )
          assert( json.is_a?(Hash), "Simple search for '#{search_term}': the parsed JSON is not a hash." )
          assert( json[ json.keys.first ]['index'] != nil, "Simple search for '#{search_term}': the parsed JSON has 'nil' in the first 'index' entry." )
        end
      end
    end
    
    should 'enable browsing of the data and retrieve a JSON response...' do
      VCR.use_cassette('test_server_browsing') do
        @controller.config[:server][:browsable_content].each do |name,conf|
          # Select 5 random pages to hit - doing them all takes forever...
          conf[:options].keys.randomly_pick(5).each do |option_name|
            opts = conf[:options][option_name.to_sym]
            
            @browser.get "/browse?field=#{name}&query=#{option_name}&page=1&wt=json"
            assert( @browser.last_response.ok?, "A request to '/browse?field=#{name}&query=#{option_name}&page=1&wt=json' failed!" )
            json = JSON.parse( @browser.last_response.body )
            assert( json.is_a?(Hash) )
          end
        end
      end
    end
    
    should 'render IKMC project pages...' do
      VCR.use_cassette('test_server_project_page') do
        project_ids_to_test = ['35505','27042','42474','82403','23242','VG12252','VG11490']
    
        project_ids_to_test.each do |project_id|
          @browser.get "/project/#{project_id}?wt=json"
          assert( @browser.last_response.ok?, "A request to '/project/#{project_id}?wt=json' failed!" )
          json = JSON.parse( @browser.last_response.body )
          assert( json.is_a?(Hash) )
          
          @browser.get "/project/#{project_id}/pcr_primers"
          if json['pcr_primers']
            assert( @browser.last_response.ok?, "A request to '/project/#{project_id}/pcr_primers' failed!" )
            assert( @browser.last_response.body.include?("LRPCR Genotyping Primers") )
          else
            assert_equal( 404, @browser.last_response.status )
          end
        end
    
        @browser.get "/project/foobar"
        assert_equal( 404, @browser.last_response.status )
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
    
    should "render WTSI Phenotyping (ABR) report pages with a redirect" do
      omit_if(
        @controller.dataviews_by_name[:'wtsi-phenotyping'].nil?,
        "Skipping WTSI Phenotyping report tests as the DataView is not active."
      )
        
      VCR.use_cassette('test_server_wtsi_phenotyping_report_pages') do
        colonies_to_test = ['MAIG','MAKH','MBAD']
        
        colonies_to_test.each do |colony_prefix|
          @browser.get "/phenotyping/#{colony_prefix}/auditory-brainstem-response"
          @browser.follow_redirect!
          assert( @browser.last_response.ok?, "/phenotyping/#{colony_prefix}/auditory-brainstem-response failed." )
          assert( @browser.last_response.body.include?('Auditory Brainstem Response'), "/phenotyping/#{colony_prefix}/auditory-brainstem-response doesn't have the title 'Auditory Brainstem Response'." )
        end
      end
    end
    
    should "cope gracefully when monkeys start visiting WTSI Phenotyping report pages" do
      omit_if(
        @controller.dataviews_by_name[:'wtsi-phenotyping'].nil?,
        "Skipping WTSI Phenotyping report tests as the DataView is not active."
      )
      
      VCR.use_cassette('test_server_wtsi_phenotyping_report_pages') do
        tests_to_test    = [
          'auditory-brainstem-response', 'viability-at-weaning', 'fertility',
          'adult-lac-z-expression','embryo-lac-z-expression','body-composition-dexa',
          'hot-plate','tail-epidermis-wholemount'
        ]
        colonies_to_test = ['FOOO','BAAR','BAAZ','ARRR']
        
        colonies_to_test.each do |colony_prefix|
          tests_to_test.each do |test|
            @browser.get "/phenotyping/#{colony_prefix}/#{test}/"
            assert_equal( 404, @browser.last_response.status, "WTF?!? '/phenotyping/#{colony_prefix}/#{test}/' is an ok url..." )
          end
        end
      end
    end
    
    should "serve up JSON for Gene Ontology data" do
      VCR.use_cassette('test_server_go_ontology_json') do
        # First test for when we expect a return...
        mgi_acc_ids_to_test = ['MGI:105369','MGI:2444584','MGI:104510']
        mgi_acc_ids_to_test.each do |mgi|
          @browser.get "/go_ontology?id=go-ontology-#{mgi.gsub(':','')}"
          assert( @browser.last_response.ok?, "A request to '/go_ontology?id=go-ontology-#{mgi.gsub(':','')}' failed!" )
          json = JSON.parse( @browser.last_response.body, :max_nesting => false )
          assert( json.is_a?(Array) )
          assert( json.first['data'] != nil )
        end
        
        # Then for when we don't...
        mgis_with_no_return = ['MGI:1921402']
        mgis_with_no_return.each do |mgi|
          @browser.get "/go_ontology?id=go-ontology-#{mgi.gsub(':','')}"
          assert_equal( 404, @browser.last_response.status )
        end
      end
    end
    
  end
end