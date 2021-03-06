# encoding: utf-8

module MartSearch
  
  # Utility module containing generic helper funcions.
  #
  # @author Darren Oakley
  module Utils
    
    # Sets up a Net::HTTP object
    #
    # @return [Net::HTTP] A Net::HTTP object
    def build_http_client
      http_client = Net::HTTP
      proxy_env   = ENV['http_proxy'] || ENV['HTTP_PROXY']
      if proxy_env
        proxy       = URI.parse( proxy_env )
        http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
      end
      return http_client
    end
    
    # Utility function to convert an array of data to a hash, 
    # given a set of headers to key the hash by (they will be matched
    # by the array index).
    #
    # @param [Array] headers This array will become the hash keys
    # @param [Array] data This array will become the hash values
    # @return [Hash] The resulting converted hash
    def convert_array_to_hash( headers, data )
      converted_data = {}
      headers.each_index do |position|
        if data[position].nil? or data[position] === ""
          converted_data[ headers[position] ] = nil
        else
          converted_data[ headers[position] ] = data[position]
        end

      end
      return converted_data
    end
    
  end
end