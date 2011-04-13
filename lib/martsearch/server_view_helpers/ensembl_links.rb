module MartSearch
  module ServerViewHelpers
    
    # View helpers for linking to Ensembl/Vega
    # 
    # @author Darren Oakley
    module EnsemblLinks
      
      # Helper function to construct a url for linking to Ensembl from an 
      # Ensembl Gene ID.
      #
      # @param [String/Symbol] species The Ensembl species to link to
      # @param [String] gene The Ensembl Gene ID
      # @param [Array] das_tracks Any extra tracks that need to be turned on
      # @raise TypeError if an unkown species is passed
      def ensembl_link_url_from_gene( species, gene, das_tracks=[] )
        ensembl_vega_contigview_link_url( :ensembl, species, "?g=#{gene}", das_tracks )
      end
      
      # Helper function to construct a url for linking to Ensembl from an
      # Ensembl Transcript ID.
      #
      # @param [String/Symbol] species The Ensembl species to link to
      # @param [String] gene The Ensembl Gene ID
      # @param [String] transcript The Ensembl Transcript ID
      # @param [String/Symbol] view The display to view (exon|transcript)
      def ensembl_link_url_from_transcript( species, gene, transcript, view=:transcript )
        ensembl_vega_transcriptview_link_url( :ensembl, species, view, "g=#{gene};t=#{transcript}" )
      end
      
      # Helper function to construct a url for linking to Ensembl from a
      # Ensembl Exon ID.
      #
      # @param [String/Symbol] species The Ensembl species to link to
      # @param [String] exon The Ensembl Exon ID
      def ensembl_link_url_from_exon( species, exon )
        ensembl_vega_exonview_link_url( :ensembl, species, exon )
      end
      
      # Helper function to construct a url for linking to Vega from a
      # Ensembl Exon ID.
      #
      # @param [String/Symbol] species The Ensembl species to link to
      # @param [String] exon The Ensembl Exon ID
      def vega_link_url_from_exon( species, exon )
        ensembl_vega_exonview_link_url( :vega, species, exon )
      end
      
      # Helper function to construct a url for linking to Ensembl from a 
      # series of co-ordinates.
      #
      # @param [String/Symbol] species The Ensembl species to link to
      # @param [String] chr The chromosome
      # @param [String/Integer] start_pos The start location that you would like contigview to centre on
      # @param [String/Integer] end_pos The end location that you would like contigview to centre on
      # @param [Array] das_tracks Any extra tracks that need to be turned on
      # @raise TypeError if an unkown species is passed
      def ensembl_link_url_from_coords( species, chr, start_pos, end_pos, das_tracks=[] )
        ensembl_vega_contigview_link_url( :ensembl, species, "?r=#{chr}:#{start_pos}-#{end_pos};", das_tracks )
      end
      
      # Helper function to construct a url for linking to Vega from a 
      # Vega Gene ID.
      #
      # @param [String/Symbol] species The Vega species to link to
      # @param [String] gene The Vega Gene ID
      # @param [Array] das_tracks Any extra tracks that need to be turned on
      # @raise TypeError if an unkown species is passed
      def vega_link_url_from_gene( species, gene, das_tracks=[] )
        ensembl_vega_contigview_link_url( :vega, species, "?g=#{gene}", das_tracks )
      end
      
      private
        
        # Helper function to build up a link to Ensembl's ContigView.
        #
        # @param [String/Symbol] db The Ensembl database to connect to
        # @param [String/Symbol] species The Ensembl species to link to
        # @param [String] args The first part of the url arguments
        # @param [Array] das_tracks Any extra tracks that need to be turned on
        # @raise TypeError if an unkown species is passed
        def ensembl_vega_contigview_link_url( db, species, args, das_tracks=[] )
          species  = ensembl_species_map(species)
          database = ensembl_vega_db_url( db )
          
          url = "http://#{database}/#{species}/Location/View#{args}"
          url << "&contigviewbottom=#{process_ensembl_tracks(das_tracks)}"
          
          return url
        end
        
        # Helper function to build up a link to Ensembl's ExonView.
        #
        # @param [String/Symbol] db The Ensembl database to connect to
        # @param [String/Symbol] species The Ensembl species to link to
        # @param [String] exon Te Ensembl Exon ID
        def ensembl_vega_exonview_link_url( db, species, exon )
          species  = ensembl_species_map( species )
          database = ensembl_vega_db_url( db )
          return "http://#{database}/#{species}/exonview?exon=#{exon}"
        end
        
        # Helper function to build up a link to Ensembl's TranscriptView
        #
        # @param [String/Symbol] db The Ensembl database to connect to
        # @param [String/Symbol] species The Ensembl species to link to
        # @param [String/Symbol] view The display to view (exon|transcript)
        # @param [String] args The final part of the url (specific to each query)
        # @raise TypeError if an unkown view is specified
        def ensembl_vega_transcriptview_link_url( db, species, view, args )
          species  = ensembl_species_map( species )
          database = ensembl_vega_db_url( db )
          display = case view.to_sym
            when :exon       then 'Exons'
            when :transcript then 'Summary'
            else
              raise TypeError, "Unkown display #{view}, try ':exon' or ':transcript'"
          end
          
          url = "http://#{database}/#{species}/Transcript/#{display}?db=core;"
          url << args
          
          return url
        end
        
        # Helper function to give the base url for a given Ensembl install.
        #
        # @param [String/Symbol] db The Ensembl database to connect to
        def ensembl_vega_db_url( db )
          case db
            when :ensembl then 'www.ensembl.org'
            when :vega    then 'vega.sanger.ac.uk'
          end
        end
        
        # Helper function to give the correct species name for a supported 
        # ensembl database.
        #
        # @param [String/Symbol] species The Ensembl species to link to
        def ensembl_species_map( species )
          species_text = case species.to_sym
            when :mouse then 'Mus_musculus'
            when :human then 'Homo_sapiens'
            when :rat   then 'Rattus_norvegicus'
            else
              raise TypeError, "Unknown species for #{species}, try :human or :mouse..."
          end
          return species_text
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
end