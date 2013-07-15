# encoding: utf-8

HoptoadNotifier.configure do |config|
  config.api_key          = '68676feedcd392d8c97dae123e7750b9'
  config.host             = 'htgt-web.internal.sanger.ac.uk'
  config.port             = 4007 # Note: Deployment notifications only work on port 80
  config.environment_name = MartSearch::ENVIRONMENT
end

module MartSearch

  # MartSearch::Server - Sinatra based web interface for MartSearch
  #
  # @author Darren Oakley
  class Server < Sinatra::Base

    set :biomart_search_params_timeout, 2400
    set :biomart_search_options_timeout, 200

    configure(:production) {
      set :biomart_search_params_timeout, 240
      set :biomart_search_options_timeout, 20
    }

    # hack/monkey-patch whatever
    # stop with your 'Sinatra::Base#options is deprecated and will be removed, use #settings instead.'
    def options; settings; end

    include MartSearch::ServerUtils
    include MartSearch::ProjectUtils
    register Sinatra::StaticAssets
    use HoptoadNotifier::Rack

    set :root, Proc.new { File.join( File.dirname(__FILE__), 'server' ) }
    enable :logging, :raise_errors, :dump_errors, :xhtml

    # We're going to use the version number as a cache breaker for the CSS
    # and javascript code. Update with each release of your portal (especially
    # if you change the CSS or JS)!!!
    VERSION = '1.1.44'
    DEFAULT_CSS_FILES = [
      'reset.css',
      'jquery.prettyPhoto.css',
      'jquery.tablesorter.css',
      'jquery.fontresize.css',
      'jquery-ui-1.8.9.redmond.css',
      'jquery.qtip.css',
      'screen.css'
    ]
    DEFAULT_HEAD_JS_FILES  = [
      'jquery-1.4.4.min.js',
      'martsearch-head.js'
    ]
    DEFAULT_BASE_JS_FILES  = [
      'jquery.prettyPhoto.js',
      'jquery.tablesorter.js',
      'jquery.cookie.js',
      'jquery.fontResize.js',
      'jquery.scrollTo-1.4.2.js',
      'jquery.jstree.js',
      'jquery.qtip.js',
      'jquery-ui-1.8.9.min.js',
      'modernizr-1.6.min.js',
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
      erb :not_found
    end

    before do
      content_type 'text/html', :charset => 'utf-8'

      # TODO: We need a better way of configuring idiots to block
      accept_request = true
      blocked_hosts  = ['picmole.com','YandexBot']

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
      include MartSearch::DataSetUtils
      include MartSearch::ServerViewHelpers

      alias_method :h, :escape_html
    end

    ##
    ## Basic Routes
    ##

    #get '/*' do
      #pass if ! File.exist?("#{settings.root}/public/maintenance.html")
      #redirect "#{request.script_name}/maintenance.html"
    #end

    get '/?' do
      @current               = 'home'
      @hide_side_search_form = true
      @phenotyping_counts    = @ms.wtsi_phenotyping_progress_counts()
      @counts                = @ms.fetch_from_cache("wtsi_front_page_counts")

      if @counts.nil?
        @counts = {
          :mice               => { :query => 'microinjection_centre_status:"WTSI - Genotype confirmed"' },
          :escells            => { :query => 'ikmc_project_product_status_str:"KOMP-CSD ES Cell Available" OR ikmc_project_product_status_str:"EUCOMM ES Cell Available"' },
          :targ_vectors       => { :query => 'ikmc_project_product_status_str:"KOMP-CSD Vector Available" OR ikmc_project_product_status_str:"EUCOMM Vector Available"' },
          :micer_clones       => { :query => 'dna_library:"MICER"' },
          :c57_bacs           => { :query => 'dna_library:"C57Bl/6J"' },
          :one_two_nine_bacs  => { :query => 'dna_library:"129S7"' }
        }

        @counts.each do |param,details|
          details[:count] = @ms.index.count( details[:query] )
        end

        @ms.write_to_cache( "wtsi_front_page_counts", @counts, { :expires_in => 12.hours } )
      end

      erb :main
    end

    get '/about/?' do
      @current    = 'about'
      @page_title = 'About'
      erb :about
    end

    get '/help/?' do
      @current    = 'help'
      @page_title = 'Help'
      erb :help
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

        @ms.logger.debug("[MartSearch::Server] /search?query=#{params[:query]}&page=#{params[:page]} - running search")
        # Marker.mark("running search") do
          use_cache   = params[:fresh] == "true" ? false : true
          @results    = @ms.search( params[:query], params[:page].to_i, use_cache )
        # end
        @ms.logger.debug("[MartSearch::Server] /search?query=#{params[:query]}&page=#{params[:page]} - running search - DONE")

        @data       = @ms.search_data
        @errors     = @ms.errors

        if params[:wt] == 'json'
          @ms.logger.debug("[MartSearch::Server] /search?query=#{params[:query]}&page=#{params[:page]} - rendering JSON")
          content_type 'application/json', :charset => 'utf-8'
          return JSON.generate( @data, :max_nesting => false )
        else
          @ms.logger.debug("[MartSearch::Server] /search?query=#{params[:query]}&page=#{params[:page]} - rendering templates")
          # Marker.mark("rendering page") do
            erb :search
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
      @current       = 'browse'
      @page_title    = 'Browse'
      @results       = nil
      @data          = nil
      @params        = params
      @browse_counts = @ms.browse_counts

      if params[:field] and params[:query]
        if !@config[:browsable_content].has_key?(params[:field].to_sym)
          status 404
          halt
        elsif !@config[:browsable_content][params[:field].to_sym][:options].has_key?(params[:query].to_sym)
          status 404
          halt
        else
          browser_field_conf = @config[:browsable_content][params[:field].to_sym]
          browser            = browser_field_conf[:options][params[:query].to_sym]
          use_cache          = params[:fresh] == "true" ? false : true

          @page_title    = "Browsing Data by #{browser_field_conf[:display_name]}: '#{browser[:text]}'"
          @results_title = @page_title
          @solr_query    = browser[:query]
          @ms.logger.debug("[MartSearch::Server] /browse?field=#{params[:field]}&query=#{params[:query]}&page=#{params[:page]} - running search")
          @results       = @ms.search( @solr_query, params[:page].to_i, use_cache )
          @ms.logger.debug("[MartSearch::Server] /browse?field=#{params[:field]}&query=#{params[:query]}&page=#{params[:page]} - running search - DONE")
          @data          = @ms.search_data
          @errors        = @ms.errors
          # @do_not_show_search_explaination = true if browser_field_conf[:exact_search] == false
          @do_not_show_search_explaination = false
        end
      end

      if params[:wt] == 'json'
        @ms.logger.debug("[MartSearch::Server] /browse?field=#{params[:field]}&query=#{params[:query]}&page=#{params[:page]} - rendering JSON")
        content_type 'application/json', :charset => 'utf-8'
        return JSON.generate( @data, :max_nesting => false )
      else
        @ms.logger.debug("[MartSearch::Server] /browse?field=#{params[:field]}&query=#{params[:query]}&page=#{params[:page]} - rendering templates")
        erb :browse
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

        @ms.logger.debug("[MartSearch::Server] /project/#{params[:id]} - running get_project_page_data")
        get_project_page_data( project_id, params )
        @ms.logger.debug("[MartSearch::Server] /project/#{params[:id]} - running get_project_page_data - DONE")

        if @data.nil?
          status 404
          erb :not_found
        else
          if params[:wt] == 'json'
            @ms.logger.debug("[MartSearch::Server] /project/#{params[:id]} - rendering JSON")
            content_type 'application/json', :charset => 'utf-8'
            return JSON.generate( @data, :max_nesting => false )
          else
            @ms.logger.debug("[MartSearch::Server] /project/#{params[:id]} - rendering templates")
            erb :project_report
          end
        end
      end
    end

    get '/project/:id/pcr_primers/?' do
      project_id = params[:id]

      if project_id.nil?
        status 404
        erb :not_found
      else
        get_project_page_data( project_id, params )

        if @data[:pcr_primers].nil?
          status 404
          erb :not_found
        else
          erb :'project_report/pcr_primers', :layout => :ajax_layout
        end
      end
    end

    def get_project_page_data( project_id, params )
      @ms.logger.debug("[MartSearch::Server] ::get_project_page_data - running get_project_page_data( '#{project_id}', '#{params}' )")
      @data = @ms.fetch_from_cache("project-report-#{project_id}")
      if @data.nil? or params[:fresh] == "true"
        results = get_ikmc_project_page_data( project_id )
        @data   = results[:data]
        @errors = { :project_page_errors => results[:errors] }

        unless @data.nil?
          @ms.write_to_cache( "project-report-#{project_id}", @data )
        end
      end
      @ms.logger.debug("[MartSearch::Server] ::get_project_page_data - running get_project_page_data( '#{project_id}', '#{params}' ) - DONE")
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
        load "#{MARTSEARCH_PATH}/config/server/dataviews/#{dv.internal_name}/routes.rb"
      end
    end

  end

end
