module MartSearch
  
  # Class for making dynamic mocks.
  #
  # Used to allow the Dataset sorting routines to be dynamically
  # overriden on a per-dataset basis.
  #
  # @see http://michal.hantl.cz/how-to-override-ruby-object-methods-dynamically/
  class Mock

    # Mocks (overrides) method using new_method, returns duplicate instance. 
    # It is possible to mock again and again. We get cloned instance each time.
    # 
    # @example
    #   hello = Mock.method("hello", :to_s) do
    #     super().reverse
    #   end
    #   
    #   hello.to_s # returns "olleh"
    #
    # @param [Object] The Object that is to be touched
    # @param [Symbol] The method to override
    # @param [Code Block] The new method code
    def self.method( instance, method_name, &new_method )
      instance_clone = instance.clone
      instance_clone.extend(Module.new { define_method(method_name, &new_method) })
      instance_clone
    end
  end
  
end
