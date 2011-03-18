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
    
  end
end
