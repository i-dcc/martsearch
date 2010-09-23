module MartSearch
  
  # DataView class for modelling a display of data.
  #
  # @author Darren Oakley
  class DataView
    
    attr_reader :config
    attr_accessor :stylesheet, :javascript
    
    # @param [Hash] conf Configuration hash
    def initialize(conf)
      @config = conf
    end
    
    
  end
  
end