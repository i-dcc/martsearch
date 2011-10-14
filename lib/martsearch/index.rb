# encoding: utf-8

module MartSearch
  
  # Error class for when an index search misbehaves
  class IndexSearchError < StandardError; end
  
  # Error class for when the index is unavailable
  class IndexUnavailableError < StandardError; end
  
  # Class representation for a Solr Index service used in MartSearch.
  #
  # @author Darren Oakley
  class Index
    include MartSearch::Utils
    
    attr_reader   :config, :current_results, :primary_field, :paginated_results
    attr_accessor :url, :current_results_total, :current_page
    
    def initialize( config )
      @config        = config
      @url           = @config[:url]
      @primary_field = @config[:schema][:unique_key].to_sym
      @http_client   = build_http_client()
      
      # Placeholders
      @current_results       = {}
      @paginated_results     = []
      @current_results_total = 0
      @current_page          = 1
      @grouped_terms         = {}
    end
    
    # Simple heartbeat function to determine if the index 
    # service is alive.
    #
    # @return [Boolean] true/false depending on if the solr server is up.
    # @raise [MartSearch::IndexUnavailableError]
    def is_alive?
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::is_alive? - running is_alive?()")
      clear_instance_variables
      res = @http_client.get_response( URI.parse("#{@url}/admin/ping?wt=ruby") )

      if res.code != "200"
        raise MartSearch::IndexUnavailableError, "Index HTTP error #{res.code}"
      else
        data = eval(res.body)
        if data["status"] === "OK"
          return true
        else
          raise MartSearch::IndexUnavailableError, "Index Error: #{res.body}"
        end
      end
    end
    
    # Function to submit a query to the search index and 
    # return the processed response object.
    #
    # @param [String] query The query string to pass to Solr
    # @param [Integer] page The page of results to search for/return
    # @return [Hash] A hash of the documents returned from the Solr index - keyed by the primary field
    def search( query, page=1 )
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::search - running search( '#{query}', '#{page}' )")
      clear_instance_variables
      
      # Calculate the start page
      start_doc = 0
      if page > 1
        start_doc = ( page - 1 ) * @config[:docs_per_page]
      end
      
      data = index_request(
        {
          "q"                       => query,
          "sort"                    => @config[:sort_results_by],
          "start"                   => start_doc,
          "rows"                    => @config[:docs_per_page],
          "hl"                      => true,
          "hl.fl"                   => '*',
          "hl.usePhraseHighlighter" => true,
          "hl.simple.pre"           => '<span class="highlight">',
          "hl.simple.post"          => '</span>'
        }
      )
      
      data.recursively_symbolize_keys!
      
      if start_doc == 0
        @current_page = 1
      else
        @current_page = ( start_doc / @config[:docs_per_page] ) + 1
      end
      
      data[:response][:docs].each do |doc|
        @current_results[ doc[ @primary_field ].to_sym ] = {
          :index               => doc,
          :search_explaination => data[:highlighting].stringify_keys![ doc[ @primary_field ] ]
        }
      end
      
      @current_results_total = data[:response][:numFound]
      @paginated_results     = paginate_results( data[:response][:docs] )
      
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::search - running search( '#{query}', '#{page}' ) - DONE")
      return @current_results
    end
    
    # Function to perform a query against the index and 
    # return the processed results.  This is called quick_search 
    # as it bypasses all of the default martsearch post-search 
    # processing actions.
    #
    # @param [String] query The query string to pass to Solr
    # @param [Integer] page The page of results to search for/return
    # @return [Array] A array of the documents returned from the Solr index
    def quick_search( query, page=1 )
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::quick_search - running quick_search( '#{query}', '#{page}' )")
      # Calculate the start page
      start_doc = 0
      if page > 1
        start_doc = ( page - 1 ) * @config[:docs_per_page]
      end

      data = index_request(
        {
          "q"     => query,
          "sort"  => @config[:sort_results_by],
          "start" => start_doc,
          "rows"  => @config[:docs_per_page]
        }
      )
      
      data.recursively_symbolize_keys!
      
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::quick_search - running quick_search( '#{query}', '#{page}' ) - DONE")
      return data[:response][:docs]
    end
    
    # Function to submit a query to the search index, and 
    # return back the number of docs/results found.
    #
    # @param [String] query The query string to pass to Solr
    # @return [Integer] The number of documents that match this query
    def count( query )
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::count - running count( '#{query}' )")
      data = index_request({ "q" => query, "rows" => 0 })
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::count - running count( '#{query}' ) - DONE")
      return data["response"]["numFound"]
    end
    
    # Utility function to return paginated data results.
    #
    # @return [Array] a paginated (using will_paginate) list of the search results (the index primary_field)
    def paginate_results( results )
      MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::paginate_results - running paginate_results()")
      results = WillPaginate::Collection.create( @current_page, @config[:docs_per_page], @current_results_total ) do |pager|
         pager.replace( results )
      end
      return results
    end
    
    private
      
      # Utility function to handle the search/count requsets 
      # to the index.
      def index_request( params={} )
        MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::index_request - running index_request( '#{params}' )")
        res = @http_client.post_form( URI.parse("#{self.url}/select"), params.update({ "wt" => "ruby" }) )
        
        if res.code.to_i != 200
          raise MartSearch::IndexSearchError, "#{res.body}"
        else
          return eval(res.body)
        end
      end
      
      # Utility function to clear all instance variables
      def clear_instance_variables
        MartSearch::Controller.instance().logger.debug("[MartSearch::Index] ::clear_instance_variables - running clear_instance_variables()")
        @current_results       = {}
        @grouped_terms         = {}
        @current_results_total = 0
        @current_page          = 1
        @paginated_results     = []
      end
  end
  
end