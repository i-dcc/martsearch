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
      
      if collection = options.delete(:collection) then
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
        if (scheme == 'http' && request.port == 80 || scheme == 'https' && request.port == 443)
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
        path = ''
        
        unless url_fragment["path"].nil?
          path = url + url_fragment.delete("path")
        else
          path = request.path_info
        end
        
        params.delete("captures")
        url = path + "?" + build_query( params.merge(url_fragment) )
      else
        url << url_fragment
      end
      
      return url
    end
    
    # def url_for(link_options)
    #   case link_options
    #   when Hash
    #     path = link_options.delete(:path) || request.path_info
    #     params.delete("captures")
    #     path + "?" + build_query(params.merge(link_options))
    #   else
    #     if link_options =~ /\/search|\/browse/
    #       # we've been given a search/browse link
    #       tmp  = link_options.split("?")
    #       opts = parse_query(tmp[1])
    #       url  = ""
    # 
    #       # Work out the url to use
    #       if link_options.match("/search")
    #         # First try RESTful style urls
    #         url = "#{@base_uri}/search/#{opts["query"]}"
    #         if opts["page"] then url = "#{url}/#{opts["page"]}" end
    # 
    #         begin
    #           uri = URI.parse(url)
    #         rescue URI::InvalidURIError
    #           # If that goes pear shaped trying to do a weird query, 
    #           # use the standard ? interface and CGI::escape...
    #           url = "#{@base_uri}/search?query=#{CGI::escape(opts["query"])}"
    #           if opts["page"] then url = "#{url}&page=#{opts["page"]}" end
    #         end
    #       elsif link_options.match("/browse")
    #         url = "#{@base_uri}/browse/#{opts["field"]}/#{opts["query"]}"
    #         if opts["page"] then url = "#{url}/#{opts["page"]}" end
    #       end
    # 
    #       return url
    #     else
    #       link_options
    #     end
    #   end
    # end

    # Helper function to construct a url for linking to Ensembl from an 
    # Ensembl Gene ID.
    #
    # @param [String/Symbol] species The Ensmebl species to link to
    # @param [String] gene The Ensembl Gene ID
    # @param [Array] das_tracks Any extra tracks that need to be turned on
    # @raise TypeError if an unkown species is passed
    def ensembl_link_url_from_gene( species, gene, das_tracks=[] )
      ensembl_vega_link_url( :ensembl, species, "?g=#{gene}", das_tracks )
    end
    
    # Helper function to construct a url for linking to Ensembl from a 
    # series of co-ordinates.
    #
    # @param [String/Symbol] species The Ensmebl species to link to
    # @param [String] chr The chromosome
    # @param [String/Integer] start_pos The start location that you would like contigview to centre on
    # @param [String/Integer] end_pos The end location that you would like contigview to centre on
    # @param [Array] das_tracks Any extra tracks that need to be turned on
    # @raise TypeError if an unkown species is passed
    def ensembl_link_url_from_coords( species, chr, start_pos, end_pos, das_tracks=[] )
      ensembl_vega_link_url( :ensembl, species, "?r=#{chr}:#{start_pos}-#{end_pos};", das_tracks )
    end
    
    # Helper function to construct a url for linking to Vega from a 
    # Vega Gene ID.
    #
    # @param [String/Symbol] species The Vega species to link to
    # @param [String] gene The Vega Gene ID
    # @param [Array] das_tracks Any extra tracks that need to be turned on
    # @raise TypeError if an unkown species is passed
    def vega_link_url_from_gene( species, gene, das_tracks=[] )
      ensembl_vega_link_url( :vega, species, "?g=#{gene}", das_tracks )
    end
    
    private
      
      # Helper function to product the required attribute strings for a HTML tag.
      #
      # @param [Hash] options A hash representing the HTML attributes
      def tag_options( options )
        option_string = options.collect {|k,v| %{#{k}="#{v}"}}.join(" ")
        option_string = " " + option_string unless option_string.blank?
      end
      
      # Helper function to build up a link to Ensembl.
      #
      # @param [String/Symbol] db :ensembl or :vega
      # @param [String/Symbol] species The Ensmebl species to link to
      # @param [String] args The first part of the url arguments
      # @param [Array] das_tracks Any extra tracks that need to be turned on
      # @raise TypeError if an unkown species is passed
      def ensembl_vega_link_url( db, spec, args, das_tracks=[] )
        species = case spec.to_sym
          when :mouse then 'Mus_musculus'
          when :human then 'Homo_sapiens'
          else
            raise TypeError, "Unknown species for #{spec}, try :human or :mouse..."
        end
        
        database = case db
          when :ensembl then 'www.ensembl.org'
          when :vega    then 'vega.sanger.ac.uk'
        end
        
        url = "http://#{database}/#{species}/Location/View#{args}"
        url << "contigviewbottom=#{process_ensembl_tracks(das_tracks)}"
        
        return url
      end
      
      # Helper function to provide the raw text string needed to configure the 
      # Ensembl contig view page.
      # 
      # @param [Array] additional_tracks An array of additional (das) tracks to activate in the view
      def process_ensembl_tracks( additional_tracks=[] )
        standard_tracks = {
          "contig"                            => "normal",
          "ruler"                             => "normal",
          "scalebar"                          => "normal"
        }
        settings = standard_tracks.collect { |key,value| "#{key}=#{value}" }
        
        additional_tracks.each do |track|
          settings.unshift("#{track}=normal")
        end
        
        return settings.join(",")
      end
      
  end
  
end
