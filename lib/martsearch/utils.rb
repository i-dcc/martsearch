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
    
  end
end