module MartSearch
  
  # Utility module containing generic helper funcions.
  #
  # @author Darren Oakley
  module Utils
    
    # Takes an input hash and turns all of the keys into symbols.
    #
    # @param [Hash] hash A hash to symbolise
    # @return [Hash] The resulting converted hash
    def symbolise_hash_keys( hash )
      hash.each do |key,value|
        if key.is_a?(String)
          hash[key.to_sym] = value
          hash.delete(key)
        end
      end
      return hash
    end
    
    # Utility function to convert an array of data to a hash, 
    # given a set of headers to key the hash by (they will be matched
    # by the array index).
    #
    # @param [Array] headers This array will become the hash keys
    # @param [Array] data This array will become the hash values
    # @return [Hash] The resulting converted hash
    def convert_array_to_hash( headers, data )
      converted_data = {}
      headers.each_index do |position|
        if data[position].nil? or data[position] === ""
          converted_data[ headers[position] ] = nil
        else
          converted_data[ headers[position] ] = data[position]
        end

      end
      return converted_data
    end
    
    # Utility function to read in a file and return the files 
    # entire contents as a string.
    #
    # @param [String] filename The name of the file to read
    # @return [String] The contents of the file
    def get_file_as_string(filename)
      data = ''
      f = File.open( filename, "r" ) 
      f.each_line do |line|
        data += line
      end
      return data
    end
    
  end
end