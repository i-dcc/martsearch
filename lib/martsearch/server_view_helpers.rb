module MartSearch
  
  module ServerViewHelpers
    def partial(template, *args)
      template_array = template.to_s.split('/')
      template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.merge!(:layout => false)
      if collection = options.delete(:collection) then
        collection.inject([]) do |buffer, member|
          buffer << erubis(:"#{template}", options.merge(:layout =>
          false, :locals => {template_array[-1].to_sym => member}))
        end.join("\n")
      else
        erubis(:"#{template}", options)
      end
    end

    def tag_options(options, escape = true)
      option_string = options.collect {|k,v| %{#{k}="#{v}"}}.join(" ")
      option_string = " " + option_string unless option_string.blank?
    end

    def content_tag(name, content, options, escape = true)
      tag_options = tag_options(options, escape) if options
      "<#{name}#{tag_options}>#{content}</#{name}>"
    end

    def link_to(text, link = nil, options = {})
      link ||= text
      link = url_for(link)
      tag_options = tag_options(options, true) unless options.empty?
      "<a href=\"#{link}\"#{tag_options}>#{text}</a>"
    end

    def url_for(link_options)
      case link_options
      when Hash
        path = link_options.delete(:path) || request.path_info
        params.delete("captures")
        path + "?" + build_query(params.merge(link_options))
      else
        if link_options =~ /\/search|\/browse/
          # we've been given a search/browse link
          tmp  = link_options.split("?")
          opts = parse_query(tmp[1])
          url  = ""

          # Work out the url to use
          if link_options.match("/search")
            # First try RESTful style urls
            url = "#{@base_uri}/search/#{opts["query"]}"
            if opts["page"] then url = "#{url}/#{opts["page"]}" end

            begin
              uri = URI.parse(url)
            rescue URI::InvalidURIError
              # If that goes pear shaped trying to do a weird query, 
              # use the standard ? interface and CGI::escape...
              url = "#{@base_uri}/search?query=#{CGI::escape(opts["query"])}"
              if opts["page"] then url = "#{url}&page=#{opts["page"]}" end
            end
          elsif link_options.match("/browse")
            url = "#{@base_uri}/browse/#{opts["field"]}/#{opts["query"]}"
            if opts["page"] then url = "#{url}/#{opts["page"]}" end
          end

          return url
        else
          link_options
        end
      end
    end

    def process_ensembl_tracks( additional_tracks=[] )
      standard_tracks = {
        "contig"                            => "normal",
        "ruler"                             => "normal",
        "scalebar"                          => "normal",
        "transcript_core_ensembl"           => "transcript_label",
        "transcript_vega_otter"             => "transcript_label",
        "alignment_compara_364_constrained" => "compact",
        "alignment_compara_364_scores"      => "off",
        "chr_band_core"                     => "off",
        "dna_align_cdna_cDNA_update"        => "off",
        "dna_align_core_CCDS"               => "off",
        "fg_regulatory_features_funcgen"    => "off",
        "fg_regulatory_features_legend"     => "off",
        "gene_legend"                       => "off",
        "gc_plot"                           => "off",
        "info"                              => "off",
        "missing"                           => "off",
        "transcript_core_ncRNA"             => "off",
        "transcript_core_ensembl_IG_gene"   => "off",
        "variation_legend"                  => "off"
      }
      settings = standard_tracks.collect { |key,value| "#{key}=#{value}" }

      additional_tracks.each do |track|
        settings.unshift("#{track}=normal")
      end

      return settings.join(",")
    end

    def ensembl_human_link_url_from_gene( gene, das_tracks=[] )
      ensembl_link = "http://www.ensembl.org/Homo_sapiens/Location/View"
      ensembl_link += "?g=#{gene};"
      ensembl_link += "contigviewbottom=#{process_ensembl_tracks(das_tracks)}"

      return ensembl_link
    end

    def ensembl_human_link_url_from_coords( chr, start_pos, end_pos, das_tracks=[] )
      ensembl_link = "http://www.ensembl.org/Homo_sapiens/Location/View"
      ensembl_link += "?r=#{chr}:#{start_pos}-#{end_pos};"
      ensembl_link += "contigviewbottom=#{process_ensembl_tracks(das_tracks)}"

      return ensembl_link
    end

    def ensembl_link_url_from_gene( gene, das_tracks=[] )
      ensembl_link = "http://www.ensembl.org/Mus_musculus/Location/View"
      ensembl_link += "?g=#{gene};"
      ensembl_link += "contigviewbottom=#{process_ensembl_tracks(das_tracks)}"

      return ensembl_link
    end

    def ensembl_link_url_from_coords( chr, start_pos, end_pos, das_tracks=[] )
      ensembl_link = "http://www.ensembl.org/Mus_musculus/Location/View"
      ensembl_link += "?r=#{chr}:#{start_pos}-#{end_pos};"
      ensembl_link += "contigviewbottom=#{process_ensembl_tracks(das_tracks)}"

      return ensembl_link
    end
  end
  
end