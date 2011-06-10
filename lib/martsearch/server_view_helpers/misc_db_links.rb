# encoding: utf-8

module MartSearch
  module ServerViewHelpers
    
    # View helpers for linking to other databases.
    # 
    # @author Darren Oakley
    # @author Nelo Onyiah
    module MiscDbLinks
      
      # Helper function to generate a link URL to InterPro
      #
      # @param  [String] interpro_ac The InterPro ID
      # @return [String] The URL for InterPro
      def interpro_link_url( interpro_ac )
        "http://www.ebi.ac.uk/interpro/ISearch?query=#{ interpro_ac }"
      end
      
      # Helper function that produces a link to a HTGT design
      #
      # @param  [Int] design_id The design ID
      # @return [String] A URL link to the design in HTGT
      def htgt_design_url( design_id )
        "http://www.sanger.ac.uk/htgt/design/designedit/refresh_design?design_id=#{design_id}"
      end
      
      # Helper function that produces a link to EMMA
      #
      # @param  [String] emma_id The EMMA ID
      # @return [String] A URL to the mouse strain in EMMA
      def emma_link_url( emma_id )
        "http://www.emmanet.org/mutant_types.php?keyword=#{emma_id}"
      end
      
    end
    
  end
end