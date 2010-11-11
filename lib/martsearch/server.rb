HoptoadNotifier.configure do |config|
  config.api_key          = ''
  config.host             = 'htgt.internal.sanger.ac.uk'
  config.port             = 4007 # Note: Deployment notifications only work on port 80
  config.environment_name = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : 'development'
end

module MartSearch
  
  # MartSearch::Server - Sinatra based web interface for MartSearch
  #
  # @author Darren Oakley
  class Server < Sinatra::Base
    include MartSearch::ServerUtils
    include MartSearch::ProjectUtils
    register Sinatra::StaticAssets
    use HoptoadNotifier::Rack
    
    set :root, Proc.new { File.join( File.dirname(__FILE__), 'server' ) }
    enable :logging, :raise_errors, :dump_errors, :xhtml
    
    # We're going to use the version number as a cache breaker for the CSS 
    # and javascript code. Update with each release of your portal (especially 
    # if you change the CSS or JS)!!!
    VERSION = '0.1.2'
    DEFAULT_CSS_FILES = [
      'reset.css',
      'jquery.prettyPhoto.css',
      'jquery.tablesorter.css',
      'jquery.fontresize.css',
      'jquery-ui-1.8.1.redmond.css',
      'screen.css'
    ]
    DEFAULT_HEAD_JS_FILES  = [
      'jquery-1.4.2.min.js',
      'martsearch-head.js'
    ]
    DEFAULT_BASE_JS_FILES  = [
      'jquery.qtip-1.0.js',
      'jquery.prettyPhoto.js',
      'jquery.tablesorter.js',
      'jquery.cookie.js',
      'jquery.fontResize.js',
      'jquery.scrollTo-1.4.2.js',
      'jquery-ui-1.8.1.min.js',
      'modernizr-1.6.min.js',
      'jquery.jstree.js',
      'martsearch-base.js'
    ]
    
    def initialize
      @ms          = MartSearch::Controller.instance()
      @config      = @ms.config[:server]
      @portal_name = @config[:portal_name]
      
      super
    end
    
    not_found do
      @martsearch_error = false
      if request.env["HTTP_REFERER"] and request.env["HTTP_REFERER"].match(request.env["HTTP_HOST"])
        @martsearch_error = true
      end

      @request = request
      erubis :not_found
    end
    
    before do
      content_type 'text/html', :charset => 'utf-8'

      # TODO: We need a better way of configuring idiots to block
      accept_request = true
      blocked_hosts  = ['picmole.com']

      blocked_hosts.each do |host|
        if \
             ( request.env['HTTP_FROM'] and request.env['HTTP_FROM'].match(host) ) \
          or ( request.env['HTTP_USER_AGENT'] and request.env['HTTP_USER_AGENT'].match(host) )
          accept_request = false
        end
      end

      halt 403, 'go away!' unless accept_request

      @request               = request
      @current               = nil
      @page_title            = nil
      @hide_side_search_form = false
      @errors                = {}
    end
    
    helpers do
      include Rack::Utils
      include WillPaginate::ViewHelpers
      include MartSearch::ServerViewHelpers
      
      alias_method :h, :escape_html
    end
    
    ##
    ## Basic Routes
    ##
    
    get '/?' do
      @current               = 'home'
      @hide_side_search_form = true
      erubis :main
    end
    
    get '/about/?' do
      @current    = 'about'
      @page_title = 'About'
      erubis :about
    end

    get '/help/?' do
      @current    = 'help'
      @page_title = 'Help'
      erubis :help
    end
    
    get '/clear_cache/?' do
      @ms.cache.clear
      redirect "#{request.script_name}/"
    end
    
    ##
    ## Searching
    ##
    
    get '/search/?' do
      if params.empty?
        redirect "#{request.script_name}/"
      else
        @current    = 'home'
        @page_title = "Search Results for '#{params[:query]}'"
        
        # Marker.mark("running search") do
          use_cache   = params[:fresh] == "true" ? false : true
          @results    = @ms.search( params[:query], params[:page].to_i, use_cache )
        # end
        @data       = @ms.search_data
        @errors     = @ms.errors

        if params[:wt] == 'json'
          content_type 'application/json', :charset => 'utf-8'
          return @data.to_json
        else
          # Marker.mark("rendering page") do
            erubis :search
          # end
        end
      end
    end
    
    ['/search/:query/?', '/search/:query/:page/?'].each do |path|
      get path do
        url = "#{request.script_name}/search?query=#{params[:query]}"
        url << "&page=#{params[:page]}" if params[:page]
        status 301
        redirect url
      end
    end
    
    ##
    ## Browsing
    ##
    
    get '/browse/?' do
      @current    = 'browse'
      @page_title = 'Browse'
      @results    = nil
      @data       = nil
      @params     = params
      
      if params[:field] and params[:query]
        
        
        if !@config[:browsable_content].has_key?(params[:field].to_sym)
          status 404
          halt
        elsif !@config[:browsable_content][params[:field].to_sym][:processed_options].has_key?(params[:query].to_sym)
          status 404
          halt
        else
          browser_field_conf = @config[:browsable_content][params[:field].to_sym]
          browser            = browser_field_conf[:processed_options][params[:query].to_sym]
          use_cache          = params[:fresh] == "true" ? false : true
          
          @page_title    = "Browsing Data by #{browser_field_conf[:display_name]}: '#{browser[:display_arg]}'"
          @results_title = @page_title
          @solr_query    = browser[:solr_query]
          @results       = @ms.search( @solr_query, params[:page].to_i, use_cache )
          @data          = @ms.search_data
          @errors        = @ms.errors
        end
      end
      
      if params[:wt] == 'json'
        content_type 'application/json', :charset => 'utf-8'
        return @data.to_json
      else
        erubis :browse
      end
    end
    
    ['/browse/:field/:query/?', '/browse/:field/:query/:page?'].each do |path|
      get path do
        url = "#{request.script_name}/browse?field=#{params[:field]}&query=#{params[:query]}"
        url << "&page=#{params[:page]}" if params[:page]
        status 301
        redirect url
      end
    end
    
    ##
    ## IKMC Project Reports
    ##
    
    ['/project/:id','/project/?'].each do |path|
      get path do
        project_id = params[:id]
        redirect "#{request.script_name}/" if project_id.nil?
        
        @current    = "home"
        @page_title = "IKMC Project: #{project_id}"
        @data       = nil
        cache       = MartSearch::Controller.instance().cache
        
        cached_data = cache.fetch("project-report-#{project_id}")
        if cached_data.nil? or params[:fresh] == "true"
          @data = get_ikmc_project_page_data( project_id )
          
          unless @data.nil?
            if cache.is_a?(MartSearch::MongoCache)
              cache.write("project-report-#{project_id}", @data, :expires_in => 12.hours )
            else
              cache.write("project-report-#{project_id}", BSON.serialize(@data), :expires_in => 12.hours )
            end
          end
        else
          @data = cached_data
          @data = BSON.deserialize(@data) unless cache.is_a?(MartSearch::MongoCache)
          @data = @data.clean_hash if RUBY_VERSION < '1.9'
          @data.recursively_symbolize_keys!
        end
        
        if @data.nil?
          status 404
          erubis :not_found
        else
          if params[:wt] == 'json'
            content_type 'application/json', :charset => 'utf-8'
            return @data.to_json
          else
            erubis :project_report
          end
        end
      end
    end
    
    ##
    ## Dynamic CSS/Javascript 
    ##
    
    get '/css/martsearch-*.css' do
      content_type 'text/css', :charset => 'utf-8'
      @compressed_css = compressed_css( VERSION ) if @compressed_css.nil?
      return @compressed_css
    end

    get '/js/martsearch-head-*.js' do
      content_type 'text/javascript', :charset => 'utf-8'
      @compressed_head_js = compressed_head_js( VERSION ) if @compressed_head_js.nil?
      return @compressed_head_js
    end
    
    get '/js/martsearch-base-*.js' do
      content_type 'text/javascript', :charset => 'utf-8'
      @compressed_base_js = compressed_base_js( VERSION ) if @compressed_base_js.nil?
      return @compressed_base_js
    end
    
    get '/dataview-css/:dataview_name' do
      content_type 'text/css', :charset => 'utf-8'
      dataview_name = params[:dataview_name].sub('.css','')
      @ms.dataviews_by_name[ dataview_name.to_sym ].stylesheet
    end

    get '/dataview-head-js/:dataview_name' do
      content_type 'text/javascript', :charset => 'utf-8'
      dataview_name = params[:dataview_name].sub('.js','')
      @ms.dataviews_by_name[ dataview_name.to_sym ].javascript_head
    end
    
    get '/dataview-base-js/:dataview_name' do
      content_type 'text/javascript', :charset => 'utf-8'
      dataview_name = params[:dataview_name].sub('.js','')
      @ms.dataviews_by_name[ dataview_name.to_sym ].javascript_base
    end
    
    ##
    ## Load in any custom (per dataset) routes
    ##
    
    MartSearch::Controller.instance().dataviews.each do |dv|
      if dv.use_custom_routes?
        eval File.read("#{MARTSEARCH_PATH}/config/server/dataviews/#{dv.internal_name}/routes.rb")
      end
    end
    
  end
  
end