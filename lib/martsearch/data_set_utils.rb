module MartSearch
  
  # Utility module for the DataSet class.
  #
  # @author Darren Oakley
  module DataSetUtils
    
    # Utility function to clean up superscript text in attributes
    # will convert text between <> tags to <sup></sup>, but leave other 
    # HTML formatted text alone.
    #
    # @param [String] attribute The attribute text to be cleaned
    # @return [String] The cleaned text
    def fix_superscript_text_in_attribute( attribute )
      if attribute and attribute.match("<.+>.+</.+>")
        # HTML code - leave alone...
      elsif attribute and attribute.match("<.+>")
        match = /(.+)<(.+)>(.*)/.match(attribute);
        attribute = match[1] + "<sup>" + match[2] + "</sup>" + match[3];
      end

      return attribute;
    end
    
    # Helper function to retrieve the allele type
    #
    # @param  [String] allele_symbol The allele symbol superscript
    # @param  [String] design_type   The design type
    # @return [String]
    def allele_type( allele_symbol, design_type=nil )
       case allele_symbol
       when /tm\d+a/ then "Knockout-First - Reporter Tagged Insertion"
       when /tm\d+b/ then "Knockout-First, Post-Cre - Reporter Tagged Deletion"
       when /tm\d+c/ then "Knockout-First, Post-Flp - Conditional"
       when /tm\d+d/ then "Knockout-First, Post-Flp and Cre - Deletion, No Reporter"
       when /tm\d+e/ then "Targeted Non-Conditional"
       when /tm\d+\(/ then "Deletion"
       else
         case design_type
         when nil          then ""
         when /deletion/i  then "Deletion"
         else                   "Knockout-First"
         end
       end
    end
  end
end
