# encoding: utf-8

# Small extensions to the String class.
module MartSearch
  module StringExtensions

    # Wrap the String at the specified width
    #
    # @param  [Integer] width - The width to wrap the string
    # @param  [String]  sep   - The separation character
    # @return [String]
    def wrap( width = 80, sep = $/ )
       res = []
       for i in 0 .. self.size / width
         res.push( self.slice( width * i, width ) )
       end
       res.join( sep )
    end
  end
end

class String
  include MartSearch::StringExtensions
end
