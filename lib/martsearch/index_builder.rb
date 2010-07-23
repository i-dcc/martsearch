module MartSearch
  class IndexBuilder
    include MartSearch
    
    def initialize()
      @config = MartSearch::Config.instance()
    end
    
    
  end
end