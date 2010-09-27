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
      check_conf_attrs
    end
    
    # @return The display name for this DataView
    def name
      @config[:name]
    end
    
    # @return The internal_name for this DataView
    def internal_name
      @config[:internal_name]
    end
    
    # @return The short description for this DataView
    def description
      @config[:description]
    end
    
    # @return [Boolean] True/False 
    def use_custom_view_helpers?
      @config[:custom_view_helpers] ? true : false
    end
    
    # Function that determines if we have enough data from the DataSets
    # to be able to produce a display.
    #
    # @param [Hash] result One of the result objects from {MartSearch::Controller#search}
    # @return [Boolean] True/False 
    def display_for_result?( result )
      check_datasets unless @alredy_checked_datasets_ok
      
      display = true
      @config[:datasets][:required].each do |ds_name|
        display = false if result[ds_name.to_sym].nil?
      end
      
      return display
    end
    
    private
      
      # Helper function to check that configuration is not missing required fields.
      #
      # @raise [MartSearch::InvalidConfigError]
      def check_conf_attrs
        required_config_attrs = [ :name, :description, :enabled, :display, :datasets ]
        required_config_attrs.each do |attribute|
          if @config[attribute].nil?
            raise MartSearch::InvalidConfigError, "The config file for DataView '#{@config[:internal_name]}' is missing the '#{attribute}' attribute."
          end
        end
      end
      
      # Helper function to check that the dataset configuration is ok.
      #
      # @raise [MartSearch::InvalidConfigError]
      def check_datasets
        martsearch = MartSearch::Controller.instance()
        datasets   = martsearch.datasets
        
        @alredy_checked_datasets_ok = true
        
        [ :required, :optional ].each do |ds_class|
          @config[:datasets][ds_class].each do |ds_name|
            unless datasets.has_key?(ds_name.to_sym)
              raise MartSearch::InvalidConfigError, "The config file for DataView '#{@config[:internal_name]}' has an invalid dataset name: '#{ds_name}'"
            end
          end
        end
      end
      
  end
  
end