module MartSearch
  
  # View helpers for the web app code.
  #
  # As we use Sinatra::StaticAssets the following helpers are also available 
  # in the views:
  # * image_tag
  # * stylesheet_link_tag
  # * javascript_script_tag
  # * link_to
  #
  # @author Darren Oakley
  module ServerViewHelpers
    
    include MartSearch::ServerViewHelpers::EnsemblLinks
    include MartSearch::ServerViewHelpers::GbrowseLinks
    include MartSearch::ServerViewHelpers::MiscDbLinks
    include MartSearch::ServerViewHelpers::OrderButtons
    
    # Load in any custom (per dataset) helpers
    MartSearch::Controller.instance().dataviews.each do |dv|
      if dv.use_custom_view_helpers?
        load "#{MARTSEARCH_PATH}/config/server/dataviews/#{dv.internal_name}/view_helpers.rb"
      end
    end
    
    # Standard partial helper - allows erubis templates to easily call
    # smaller sub-templates.
    #
    # @param [String] template The location/name of the template to call
    # @param [Hash] options Options hash to pass to the template
    # @return [String] The processed sub-template
    def partial( template, options={} )
      template_array = template.to_s.split('/')
      template_array[-1].sub!("_", "") if template_array[-1] =~ /^_/
      
      template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
      
      options.merge!( :layout => false )
      collection = options.delete(:collection)
      
      if collection
        collection.inject([]) do |buffer, member|
          buffer << erubis( :"#{template}", options.merge( :locals => { template_array[-1].to_sym => member } ) )
        end.join("\n")
      else
        erubis( :"#{template}", options )
      end
    end
    
    # View helper to produce a HTML tag.
    #
    # @param [String] name The name for the HTML tag (i.e. 'p', 'h1' etc.)
    # @param [String] content The content that goes inside the tag
    # @param [Hash] options A hash representing the HTML attributes to apply to the tag
    # @return [String] The HTML tag
    def content_tag( name, content, options=nil )
      tag_options = tag_options( options ) if options
      "<#{name}#{tag_options}>#{content}</#{name}>"
    end
    
    # View helper to generate a URL for a static/dynamic page/item.  Will automagically 
    # cope if the app is not hosted at the root of the domain.  ALWAYS use this function 
    # (or functions such as 'link_to' that call this under the covers), to link to assets/pages 
    # in the app.
    #
    # @param [String/Hash] url_fragment The url string to link to, or a Hash containing :path and any other parameters that are desired
    # @param [Symbol] mode Do we want a full url (i.e. for RSS feeds etc) or a relative link. Can be either :path_only or :full
    # @return [String] The generated url
    # @raise TypeError if an unkown url mode is passed
    def url_for( url_fragment, mode=:path_only )
      case mode
      when :path_only
        base = request.script_name
      when :full
        scheme = request.scheme
        if (scheme == 'http' && request.port == 80) || (scheme == 'https' && request.port == 443)
          port = ""
        else
          port = ":#{request.port}"
        end
        base = "#{scheme}://#{request.host}#{port}#{request.script_name}"
      else
        raise TypeError, "Unknown url_for mode #{mode}"
      end
      
      url = "#{base}"
            
      if url_fragment.is_a?(Hash)
        url_fragment.stringify_keys!
        path = ''
        
        unless url_fragment['path'].nil?
          path = url + url_fragment.delete('path')
        else
          path = request.path_info
        end
        
        params.delete('captures')
        params.delete('page')
        url = path + "?" + build_query( params.merge(url_fragment) )
      else
        url << url_fragment
      end
      
      return url
    end
    
    private
      
      # Helper function to product the required attribute strings for a HTML tag.
      #
      # @param [Hash] options A hash representing the HTML attributes
      def tag_options( options )
        option_string = options.collect {|k,v| %{#{k}="#{v}"}}.join(" ")
        option_string = " " + option_string unless option_string.blank?
      end
      
  end
  
end
