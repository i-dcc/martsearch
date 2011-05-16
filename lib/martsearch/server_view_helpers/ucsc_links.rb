# encoding: utf-8

module MartSearch
  module ServerViewHelpers
    
    # View helpers for linking to the UCSC Genome Browser
    # 
    # @author Darren Oakley
    module UcscLinks
      
      # Helper function to generate link URL to Mouse UCSC
      #
      # @param  [Symbol] species The species to link to
      # @param  [String] chromosome Chromosome
      # @param  [Int]    start_pos Chromosome start position
      # @param  [Int]    end_pos Chromosome end position
      # @param  [Hash]   tracks Name and display options of any extra tracks you wish to configure
      # @return [String] The URL for UCSC
      def ucsc_link_url( species, chromosome, start_pos, end_pos, tracks={} )
        url = 'http://genome.ucsc.edu/cgi-bin/hgTracks?'
        
        db = case species
        when :mouse then 'mm9'
        when :human then 'hg19'
        end
        
        url << "db=#{db}"
        url << "&#{process_ucsc_tracks(tracks)}" unless tracks.empty?
        url << "&position=chr#{chromosome}:#{start_pos}-#{end_pos}"
        
        return url
      end
      
      private
        
        def process_ucsc_tracks( tracks )
          urls = []
          tracks.each do |name,display|
            urls.push("#{name}=#{display}")
          end
          return urls.join('&')
        end
        
    end
    
  end
end