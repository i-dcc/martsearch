# encoding: utf-8

module MartSearch
  module ServerViewHelpers
    
    # View helpers for linking to a Gbrowse instance.
    # 
    # @author Darren Oakley
    module GbrowseLinks
      
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
      
      private
        
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
        
    end
    
  end
end