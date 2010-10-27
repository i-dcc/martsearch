# Small extensions to the Array class.
class Array
  
  # Splits an array into an array-of-arrays of the defined length.
  #
  # @author _why
  # @see http://en.wikipedia.org/wiki/Why's_(poignant)_Guide_to_Ruby Why's (Poignant) Guide to Ruby
  #
  # @param [Integer] length The size of the chunks to be created
  # @example
  #   "[1,2,3,4,5,6,7,8,9,10].chunk(5)"       => "[[1,2,3,4,5],[6,7,8,9,10]]"
  #   "[1,2,3,4,5,6,7,8,9,10,11,12].chunk(5)" => "[[1,2,3,4,5],[6,7,8,9,10],[11,12]]"
  def chunk( length )
    chunks = []
    each_with_index do |element,index|
      chunks << [] if index % length == 0
      chunks.last << element
    end
    chunks
  end
  
  # Recursivley converts the keys of all contained hashes to symbols.
  # @see http://snippets.dzone.com/posts/show/12019
  def recursively_symbolize_keys!
    self.each do |item|
      if item.is_a?(Hash)
        item.recursively_symbolize_keys!
      elsif item.is_a? Array
        item.recursively_symbolize_keys!
      end
    end
  end
  
  # Recursivley converts the keys of all contained hashes to strings.
  # @see http://snippets.dzone.com/posts/show/12019
  def recursively_stringify_keys!
    self.each do |item|
      if item.is_a?(Hash)
        item.recursively_stringify_keys!
      elsif item.is_a? Array
        item.recursively_stringify_keys!
      end
    end
  end
  
  # Randomises an array returns the defined number of elements.
  #
  # If +number+ is greater than the size of the array, the method
  # will simply return the array itself sorted randomly.
  #
  # @param [Integer] number The number of elements to return
  # @return [Array] The randomised array
  # @example
  #   "[1,2,3,4,5,6,7,8,9,10,11,12].randomly_pick(3)" => "[3,12,7]"
  def randomly_pick( number )
    sort_by{ rand }.slice( 0...number )
  end
  
  # Helper function for {Hash#clean_hashes} - this just call .clean_hashes 
  # if one of the elements of the array is an instance of Hash (or one of its children).
  def clean_hashes
    self.map do |item|
      if item.is_a?(Hash)
        item.clean_hash
      elsif item.is_a?(Array)
        item.clean_hashes
      else
        item
      end
    end
  end
end
