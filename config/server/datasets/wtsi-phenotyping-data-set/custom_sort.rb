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

    def sort_bar_data( results )
      sorted_results    = {}
      results           = strip_attribute_names( results )
      processed_results = { :memberships => [], :results => {} }
      results.each do |result|
        observation = result[:observation]
        gender      = result[:gender]
        x_value     = result[:x_value]
        y_value     = result[:membership]
        if !processed_results[:memberships].include?( membership )
          processed_results[:memberships].push( membership )
        end
        processed_results[:results][observation][gender][membership][x_value] += 1
      end
      processed_results[:memberships].sort!
      return processed_results
    end
    
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
    
    def get_graph_type( results )
      return "Bar".to_sym #results[0][:graph_type]
    end

  end
end