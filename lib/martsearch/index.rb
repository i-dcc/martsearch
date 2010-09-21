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
    
    attr_reader   :config, :current_results, :grouped_terms, :primary_field, :paginated_results
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
      # Reset all of our stored variables
      @current_results       = {}
      @grouped_terms         = {}
      @current_results_total = 0
      @current_page          = 1
      @paginated_results     = []
      
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
          "hl.usePhraseHighlighter" => true
        }
      )
      
      data.recursively_symbolize_keys!
      
      if start_doc == 0
        @current_page = 1
      else
        @current_page = ( start_doc / @config[:docs_per_page] ) + 1
      end
      
      data[:response][:docs].each do |doc|
        @current_results[ doc[ @primary_field ] ] = {
          :index               => doc,
          :search_explaination => data[:highlighting][ doc[ @primary_field ] ]
        }
      end
      
      @current_results_total = data[:response][:numFound]
      @grouped_terms         = grouped_query_terms( @current_results )
      @paginated_results     = paginate_results( data[:response][:docs] )
      
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
      
      return data[:response][:docs]
    end
    
    # Function to submit a query to the search index, and 
    # return back the number of docs/results found.
    #
    # @param [String] query The query string to pass to Solr
    # @return [Integer] The number of documents that match this query
    def count( query )
      data = index_request({ "q" => query })
      return data["response"]["numFound"]
    end
    
    private
      
      # Helper function to process the results of the JSON 
      # response and extract the fields from each doc into 
      # a hash (which is returned).
      #
      # @param [Hash] results A hash of docs returned from a Solr search (the return from {#search})
      # @return [Hash] A hash keyed by the document fields containing all the data returned (from all fetched documents) for the given field
      def grouped_query_terms( results )
        grouped_terms = {}

        results.each do |primary_field,results_stash|
          results_stash[:index].each do |field,value|
            grouped_terms_for_field = grouped_terms[field]

            unless grouped_terms_for_field 
              grouped_terms[field]    = []
              grouped_terms_for_field = grouped_terms[field]
            end

            if value.is_a?(Array)
              value.each do |val|
                grouped_terms_for_field.push( val )
              end
            else
              grouped_terms_for_field.push( value )
            end
          end
        end

        grouped_terms.each do |field,values|
          grouped_terms[field] = values.uniq
        end
        
        return grouped_terms
      end
      
      # Utility function to handle the search/count requsets 
      # to the index.
      def index_request( params={} )
        res = @http_client.post_form( URI.parse("#{self.url}/select"), params.update({ "wt" => "ruby" }) )
        
        if res.code.to_i != 200
          raise MartSearch::IndexSearchError, "Index Search Error: #{res.body}"
        else
          return eval(res.body)
        end
      end
      
      # Utility function to return paginated data results.
      #
      # @return [Array] a paginated (using will_paginate) list of the search results (the index primary_field)
      def paginate_results( results )
        results = WillPaginate::Collection.create( @current_page, @config[:docs_per_page], @current_results_total ) do |pager|
           pager.replace( results )
        end
        return results
      end
      
  end
  
end