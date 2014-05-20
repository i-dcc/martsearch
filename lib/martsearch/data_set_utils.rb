# encoding: utf-8

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

       type = case allele_symbol
       when /tm\d+a/ then "Knockout First, Reporter-tagged insertion with conditional potential";
       when /tm\d+b/ then "Knockout-First, Post-Cre - Reporter Tagged Deletion"
       when /tm\d+c/ then "Knockout-First, Post-Flp - Conditional"
       when /tm\d+d/ then "Knockout-First, Post-Flp and Cre - Deletion, No Reporter"
       when /tm\d+e/ then "Targeted Non-Conditional"
       else

         if /tm\d+\(/ =~ allele_symbol && ! design_type
           "Reporter-Tagged Deletion"
         else

          case design_type
          when nil          then ""
          when /Cre Knock In/i  then "Cre Knock In"
          when /Deletion/i  then "Reporter-Tagged Deletion"
          else                   ''
          end

         end
       end

      return type
    end

  end
end
