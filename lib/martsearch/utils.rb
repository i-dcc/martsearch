module MartSearch
  module Utils
    
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
    # given a set of headers to key the hash by.
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
    
  end
end