# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_data_set_sort_results( results )
      graph_type = get_graph_type( results )
      if graph_type == :Scatter
        sorted_results = sort_scatter_data( results )
      elsif graph_type == :Bar
        sorted_results = sort_bar_data( results )
      end
      return graph_type, sorted_results
    end
    
    
    private
    
    def sort_scatter_data( results )
      sorted_results  = {}
      results         = strip_attribute_names( results )
      # remove the 'param_level_heatmap_' prefix from the attributes
      processed_results = {}
      results.each do |result|
        membership = result[:membership]
        if !processed_results.has_key?(membership)
          processed_results[membership] = []
        end
        processed_results[membership].push(result)
      end
      return processed_results
    end


    # Sorts the results for the bar graph type.
    #
    #
    # @param [Hash] The result set.
    #
    def sort_bar_data( results )
      sorted_results    = {}
      results           = strip_attribute_names( results )
      
      processed_results = { 
        :observations => [],
        :genders      => [],
        :memberships  => [], 
        :x_values     => [],
        :results      => {} 
      }

      results.each do |result|
        observation = result[:observation]
        gender      = result[:gender]
        membership  = get_membership( result )
        x_value     = result[:x_value]
        if !processed_results[:observations].include?( observation )
          processed_results[:observations].push( observation )
        end
        if !processed_results[:genders].include?( gender )
          processed_results[:genders].push( gender )
        end
        if !processed_results[:memberships].include?( membership )
          processed_results[:memberships].push( membership )
        end
        if !processed_results[:x_values].include?( x_value )
          processed_results[:x_values].push( x_value )
        end
      end
      
      results.each do |result|
        observation = result[:observation]
        membership  = get_membership( result )
        gender      = result[:gender]
        x_value     = result[:x_value]
        y_value     = result[:y_value]

        if !processed_results[:results].has_key?( observation )
          processed_results[:results][observation] = {}
          processed_results[:genders].each do |g|
            processed_results[:results][observation][g] = {}
            processed_results[:memberships].each do |m|
              processed_results[:results][observation][g][m] = {}
              processed_results[:x_values].each do |x|
                processed_results[:results][observation][g][m][x] = 0
              end
            end
          end
        end

        processed_results[:results][observation][gender][membership][x_value] += 1
      end
      
      processed_results[:memberships].sort!
      processed_results[:genders].sort!
      processed_results[:x_values].sort!
      
      return processed_results
    end
    
    
    # Returns the string genotype for subject mice or the membership for mice in 
    # the control or baseline.
    #
    # TODO: This can be simplified once the new :genotype_str column is added to the Biomart.
    #
    # @param [Hash] results hash for a single mouse.
    # @return [String] Het or Hom for Subject mice, otherwise Control or Baseline membership.
    def get_membership( result )
      if result[:membership] == "Subject"
        return result[:genotype_str]
      end
      return result[:membership]
    end
    
    
    # Strips the attribute name down to the basic. Removes the 'published_graph_data_' prefix
    # from each attribute key.
    #
    # @param [Hash] Results for a single mouse.
    # @return [Hash] Results with modified keys.
    def strip_attribute_names( results )
      prefix            = /^published_graph_data\_/
      processed_results = []
      results.each do |result|
        processed_result = {}
        result.each do |key,value|
          processed_result[ key.to_s.gsub(prefix,'').to_sym ] = value
        end
        processed_results.push( processed_result )
      end
      return processed_results
    end
    
    
    # Returns the type of graph that the data is representing.
    #
    # @param [Hash] A hash of results.
    # @return [Symbol] The first results :graph_type key value.
    def get_graph_type( results )
      return results[0][:graph_type].to_sym
    end

  end
end