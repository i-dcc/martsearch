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
    # @param [Hash] errors A hash containing error records for the dataset searches (if any)
    # @return [Boolean] True/False 
    def display_for_result?( result, errors )
      check_datasets unless @alredy_checked_datasets_ok
      
      display = true
      @config[:datasets][:required].each do |ds_name|
        display = false if result[ds_name.to_sym].nil?
        display = true  unless errors[ds_name.to_sym].nil?
      end
      
      return display
    end
    
    # Function to determine if there are any search errors related to this dataview.
    #
    # @param [Hash] dataset_errors A hash of recorded search errors - keyed by dataset name
    # @return [Hash] A hash of any dataset errors related to this view
    def search_errors( dataset_errors )
      errors = { :required => [], :optional => [] }
      
      [ :required, :optional ].each do |ds_class|
        @config[:datasets][ds_class].each do |ds_name|
          if dataset_errors.has_key?(ds_name.to_sym)
            errors[ds_class].push( dataset_errors[ds_name.to_sym] )
          end
        end
      end
      
      return errors
    end
    
    # Function to provide details for attribution links to the sources of the data.
    #
    # @param [Hash] result_data The result_data stash of returned data for a given gene/doc
    # @return [Array] An array of arrays containing the [ link_text, link_url ]
    def attribution_links( result_data )
      martsearch = MartSearch::Controller.instance()
      datasets   = martsearch.datasets
      links      = []
      
      [ :required, :optional ].each do |ds_class|
        @config[:datasets][ds_class].each do |ds_name|
          if result_data.has_key?(ds_name.to_sym) and result_data[ds_name.to_sym] != nil
            dataset = datasets[ds_name.to_sym]
            unless dataset.config[:attribution].nil? and dataset.config[:attribution_link].nil?
              links.push( [ dataset.config[:attribution], dataset.config[:attribution_link] ] )
            end
          end
        end
      end
      
      return links.uniq
    end
    
    # Function to provide details for the links to the *actual* data that makes
    # up the data view.
    #
    # @param [Hash] result_data The result_data stash of returned data for a given gene/doc
    # @return [Array] An array of arrays containing the [ link_text, link_url ]
    def data_origin_links( result_data )
      martsearch = MartSearch::Controller.instance()
      datasets   = martsearch.datasets
      links      = []
      
      [ :required, :optional ].each do |ds_class|
        @config[:datasets][ds_class].each do |ds_name|
          if result_data.has_key?(ds_name.to_sym) and result_data[ds_name.to_sym] != nil
            dataset = datasets[ds_name.to_sym]
            
            links.push([
              "#{dataset.config[:attribution]} - <em>&quot;#{ds_name}&quot;</em>",
              dataset.data_origin_url( result_data[:index][ dataset.joined_index_field.to_sym ] )
            ])
          end
        end
      end
      
      return links.uniq
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