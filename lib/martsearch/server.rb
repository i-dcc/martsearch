module MartSearch
  
  # MartSearch::Server - Sinatra based web interface for MartSearch
  #
  # @author Darren Oakley
  class Server < Sinatra::Base
    include MartSearch::ServerUtils
    
    set :root, Proc.new { File.join( File.dirname(__FILE__), 'server' ) }
    enable :logging, :dump_errors
    
    # We're going to use the version number as a cache breaker for the CSS 
    # and javascript code. Update with each release of your portal (especially 
    # if you change the CSS or JS)!!!
    VERSION = "0.0.15"
    DEFAULT_CSS_FILES = [
      "reset.css",
      "jquery.prettyPhoto.css",
      "jquery.tablesorter.css",
      "jquery.fontresize.css",
      "jquery-ui-1.8.1.redmond.css",
      "screen.css"
    ]
    DEFAULT_JS_FILES  = [
      "jquery.qtip-1.0.js",
      "jquery.prettyPhoto.js",
      "jquery.tablesorter.js",
      "jquery.cookie.js",
      "jquery.fontResize.js",
      "jquery.scrollTo-1.4.2.js",
      "jquery-ui-1.8.1.min.js",
      "martsearchr.js"
    ]
    
    def initialize
      @config      = MartSearch::ConfigBuilder.instance().config[:server]
      @portal_name = @config[:portal_name]
      @base_uri    = @config[:base_uri]
      
      super
    end
    
    before do
      response["Content-Type"] = "text/html; charset=utf-8"

      # TODO: We need a better way of configuring idiots to block
      accept_request = true
      blocked_hosts  = ['picmole.com']

      blocked_hosts.each do |host|
        if \
             ( request.env["HTTP_FROM"] and request.env["HTTP_FROM"].match(host) ) \
          or ( request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"].match(host) )
          accept_request = false
        end
      end

      halt 403, "go away!" unless accept_request

      @current    = nil
      @page_title = nil

      @messages = {
        :status => [],
        :error  => []
      }

      # check_for_messages
    end
    
    get '/?' do
      @current               = "home"
      @hide_side_search_form = true
      erubis :main
    end
    
    get "/dataview-css/:dataview_name" do
      content_type "text/css"
      dataview_name = params[:dataview_name].sub(".css","")
      @config[:dataviews_by_name][ dataview_name.to_sym ][:stylesheet]
    end

    get "/dataview-js/:dataview_name" do
      content_type "text/javascript"
      dataview_name = params[:dataview_name].sub(".js","")
      @config[:dataviews_by_name][ dataview_name.to_sym ][:javascript]
    end
    
  end
  
end