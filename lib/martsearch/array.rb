# This is a small extension to the Array class.
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
end
