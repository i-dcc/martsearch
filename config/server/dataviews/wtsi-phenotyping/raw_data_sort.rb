# encoding: utf-8

class RawDataSort
  
  #
  # Entry point for sorting phenotyping raw data by graph type.
  #
  # @param [Hash] the result set to sort.
  #
  def self.sort( results )
    lresults    = self.strip_attribute_names( results )
    graph_type  = self.get_graph_type( lresults )

    case graph_type
    when :Bar
      sorted_results = self.sort_bar_data( lresults )
    else
      sorted_results = self.sort_data( lresults )
    end
  
    return graph_type, sorted_results
  end
  
  
  private

  #
  # Sort the data in the default way which is by gender and by membership (baseline, 
  # control or subject).
  #
  # @param [Hash] the result set to sort.
  #
  def self.sort_data( results )
    processed_results = {}

    results.each do |result|
      gender      = result[:gender]
      membership  = result[:membership]

      if !processed_results.has_key?(gender)
        processed_results[gender] = {}
      end
      
      if !processed_results[gender].has_key?(membership)
        processed_results[gender][membership] = []
      end
      processed_results[gender][membership].push(result)
    end
    return processed_results
  end
  
  
  #
  # Sorts the results for the bar graph type.
  #
  # @param [Hash] the result set to sort.
  #
  def self.sort_bar_data( results )
  
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
      membership  = self.get_membership( result )
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
      membership  = self.get_membership( result )
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
  
  
  def self.sort_line_data( results )
    
    processed_results = {
      :observations => [],
      :genders      => [],
      :titles       => ["Group","Mouse"],
      :time_points  => [],
      :results      => {}
    }
    
    results.each do |result|

      gender      = result[:gender]
      observation = result[:observation]
      time_point  = result[:x_value]
      
      if !processed_results[:genders].include?( gender )
        processed_results[:genders].push( gender )
      end

      if !processed_results[:observations].include?( observation )
        processed_results[:observations].push( observation )
      end

      if !processed_results[:titles].include?( time_point )
        processed_results[:titles].push( time_point )
        processed_results[:time_points].push( time_point )
      end
    end
    
    results.each do |result|
      observation = result[:observation]
      gender      = result[:gender]
      
      if !processed_results[:results].has_key?( observation )
        processed_results[:results][observation] = {}
        if !processed_results[:results][observation].has_key?( gender )
          processed_results[:results][observation][gender] = {}
        end
      end
      
    end
    
  end
  
  #
  # Returns the string genotype for subject mice or the membership for mice in 
  # the control or baseline.
  #
  # TODO: This can be simplified once the new :genotype_str column is added to the Biomart.
  #
  # @param [Hash] results hash for a single mouse.
  # @return [String] Het or Hom for Subject mice, otherwise Control or Baseline membership.
  #
  def self.get_membership( result )
    if result[:membership] == "Subject"
      return result[:genotype_str]
    end
    return result[:membership]
  end
  
  
  #
  # Strips the attribute name down to the basic. Removes the 'published_graph_data_' prefix
  # from each attribute key.
  #
  # @param [Hash] Results for a single mouse.
  # @return [Hash] Results with modified keys.
  #
  def self.strip_attribute_names( results )
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
  
  
  #
  # Returns the type of graph that the data is representing.
  #
  # @param [Hash] A hash of results.
  # @return [Symbol] The first results :graph_type key value.
  #
  def self.get_graph_type( results )
    return results[0][:graph_type].to_sym
  end

end