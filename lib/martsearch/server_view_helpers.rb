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
    
    # Helper function to centralise the generation of product ordering links.
    #
    # @param [Symbol] product_type The type of product to get a link for [:vector,:es_cell,:mouse]
    # @param [String] pipeline The IKMC pipeline name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
    # @param [String] project_id The IKMC project ID
    # @param [String] mgi_acc_id The MGI accession ID for the gene
    # @param [String] marker_symbol The marker_symbol for the gene
    # @return [Hash] A hash containing all of the relevant urls for this project
    def ikmc_product_order_url( product_type, project=nil, project_id=nil, mgi_accession_id=nil, marker_symbol=nil )
      mgi_accession_id.sub!('MGI:','') unless mgi_accession_id.nil?
      
      order_url = case project
      when ( "KOMP" or "KOMP-CSD") then "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
      when "KOMP-Regeneron"        then "http://www.komp.org/geneinfo.php?project=#{project_id}"
      when "NorCOMM"               then "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
      when ("EUCOMM" or "mirKO")
        case product_type
        when :vector  then "http://www.eummcr.org/final_vectors.php?mgi_id=#{mgi_accession_id}"
        when :es_cell then "http://www.eummcr.org/es_cells.php?mgi_id=#{mgi_accession_id}"
        when :mouse   then "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}%25EUCOMM&select_by=InternationalStrainName&search=ok"
        else
          "http://www.eummcr.org/order.php"
        end
      else
        ""
      end
      
      return order_url
    end
    
    # Helper function to centralise the logic for producing a button for 
    # ordering a mouse.
    #
    # @param [String] marker_symbol The marker_symbol for the gene
    # @param [String] project The IKMC project name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
    # @param [String] project_id The IKMC project ID
    # @param [Boolean] flagged_for_dist Whether the mouse has been flagged as available at the repositories
    # @return [String] The html markup for a button
    def mouse_order_button( marker_symbol, project, project_id, flagged_for_dist )
      button_text = '<span class="order unavailable">currently&nbsp;unavailable</span>'
      
      if flagged_for_dist
        order_url = ikmc_product_order_url( :mouse, project, project_id, nil, marker_symbol )
        unless order_url.empty?
          button_text = "<a href=\"#{order_url}\" class=\"order\" target=\"_blank\">order</a>"
        end
      end
      
      return button_text
    end
    
    # TODO: Finish the other order buttons!
    
    # Helper function to embed an image from the MGI GBrowse server.
    # 
    # @see #format_gbrowse_img_opts
    def mgi_gbrowse_img( width, chromosome, start_pos, end_pos, img_tracks={} )
      mgi_url        = "http://gbrowse.informatics.jax.org/cgi-bin/gbrowse_img/mouse_current/"
      default_tracks = {
        'NCBI_Transcripts'               => :expanded_labeled,
        'ENSEMBL_Transcripts'            => :expanded_labeled,
        'MGI_Representative_Transcripts' => :expanded_labeled,
        'VEGA_Transcripts'               => :expanded_labeled
      }
      
      img_url = mgi_url + format_gbrowse_img_opts( width, chromosome, start_pos, end_pos, img_tracks )
      
      embed_url = mgi_url + format_gbrowse_img_opts( 700, chromosome, start_pos, end_pos, img_tracks.merge!(default_tracks) )
      embed_url << 'embed=1;'
      embed_url << '&iframe=true&width=95%&height=95%'
      
      return "<a href=\"#{embed_url}\" rel=\"prettyPhoto\"><img src=\"#{img_url}\" /></a>"
    end
    
    # Helper function to generate the options to drive a GBrowse img server.
    # 
    # @example
    #   format_gbrowse_img_opts(
    #     400, 4, 94608731, 94645791,
    #     {
    #       'MGI_Representative_Transcripts' => :expanded_labeled,
    #       'ENSEMBL_Transcripts'            => :expanded_labeled
    #     }
    #   )
    # 
    # @param [Integer] width The width of the image to generate
    # @param [Integer/String] chromosome Chromosome name
    # @param [Integer] start_pos Chromosomal start position
    # @param [Integer] end_pos Chromosomal end position
    # @param [Hash] img_tracks Hash of data tracks and options to render (accepted options: [:auto,:compact,:expanded,:expanded_labeled])
    # 
    # @return [String] The formatted options string
    # @see http://gbrowse.informatics.jax.org/gbrowse/docs/pod/MAKE_IMAGES_HOWTO.html
    def format_gbrowse_img_opts( width, chromosome, start_pos, end_pos, img_tracks=[] )
      url_opts =  "?"
      url_opts << "abs=1;"
      url_opts << "name=#{chromosome}:#{start_pos}-#{end_pos};"
      url_opts << "width=#{width};"
      
      tracks  = []
      options = []
      
      img_tracks.each do |track,option|
        option_code = case option
        when :auto              then 0
        when :compact           then 1
        when :expanded          then 2
        when :expanded_labeled  then 3
        else
          0
        end
        
        tracks.push(track)
        options.push("#{track}+#{option_code}")
      end
      
      unless img_tracks.empty?
        url_opts << "type=#{tracks.join('+')};"
        url_opts << "options=#{options.join('+')};"
      end
      
      return url_opts
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
          when :rat   then 'Rattus_norvegicus'
          else
            raise TypeError, "Unknown species for #{spec}, try :human or :mouse..."
        end
        
        database = case db
          when :ensembl then 'www.ensembl.org'
          when :vega    then 'vega.sanger.ac.uk'
        end
        
        url = "http://#{database}/#{species}/Location/View#{args}"
        url << "&contigviewbottom=#{process_ensembl_tracks(das_tracks)}"
        
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
