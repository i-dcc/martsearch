# Small extensions to the Hash class.
module MartSearch
  module HashExtensions
    # Recursivley converts the keys of all contained hashes to symbols.
    # @see http://snippets.dzone.com/posts/show/12019
    def recursively_symbolize_keys!
      self.symbolize_keys!
      self.values.each do |value|
        if value.is_a?(Hash)
          value.recursively_symbolize_keys!
        elsif value.is_a?(Array)
          value.recursively_symbolize_keys!
        end
      end
      self
    end
  
    # Recursivley converts the keys of all contained hashes to strings.
    # @see http://snippets.dzone.com/posts/show/12019
    def recursively_stringify_keys!
      self.stringify_keys!
      self.values.each do |value|
        if value.is_a?(Hash)
          value.recursively_stringify_keys!
        elsif value.is_a?(Array)
          value.recursively_stringify_keys!
        end
      end
      self
    end
    
    # Simple function to duplicate a hash.  This is useful if your current 
    # object is something derived from the Hash class (i.e. BSON::OrderedHash) 
    # and you just want a pure Hash.
    #
    # @return [Hash] a copy of the current object, but forced as a 'Hash' object
    def clean_hash
      hash = {}
      self.each do |key,value|
        if value.is_a?(Hash)
          hash[key] = value.clean_hash
        elsif value.is_a?(Array)
          hash[key] = value.clean_hashes
        else
          hash[key] = value
        end
      end
      return hash
    end
  end
end

class Hash
  include MartSearch::HashExtensions
end

class BSON::OrderedHash
  include MartSearch::HashExtensions
end