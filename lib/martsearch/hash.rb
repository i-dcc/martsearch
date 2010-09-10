# Small extensions to the Hash class.
class Hash
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
end
