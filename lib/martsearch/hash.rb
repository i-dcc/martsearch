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
    
    if RUBY_VERSION < '1.9'
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
end

class Hash
  include MartSearch::HashExtensions
end

class BSON::OrderedHash
  include MartSearch::HashExtensions
end