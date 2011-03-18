module MartSearch
  module IndexBuilderUtils
    
    # Helper module containing all of the functions for interacting with the 
    # IndexBuilder @document_cache.
    # 
    # @author Darren Oakley
    module DocumentCache
      
      private
      
        # Get a document from the @document_cache.
        #
        # @param [String] key The unique @document_cache key
        def get_document( key )
          @document_cache[key]
        end
        
        # Save a document to the @document_cache.
        #
        # @param [String] key The unique @document_cache key
        # @param [Object] value The object to store in the @document_cache
        def set_document( key, value )
          @document_cache_keys[key] = true
          @document_cache[key] = value
        end
        
        # Utility function to find a specific document (i.e. for a gene).
        #
        # @param [Symbol] field The document field upon which to search within
        # @param [String] search_term The term to search with
        # @return A document object if found or nil
        def find_document( field, search_term )
          if field == @index_config[:schema][:unique_key].to_sym
            return get_document( search_term )
          else
            map_term = @document_cache_lookup[field][search_term]
            if map_term
              return get_document( map_term )
            else
              return nil
            end
          end
        end
        
        # Utility function to cache a lookup for the @document_cache by a given field. 
        # This allows a much faster lookup of documents when we are not linking by 
        # the primary field.
        #
        # @param [Symbol] field The document field to cache the documents by
        def cache_documents_by( field )
          @document_cache_lookup[field] = {}
          
          @document_cache_keys.each_key do |cache_key|
            document = get_document(cache_key)
            document[field].each do |lookup_value|
              @document_cache_lookup[field][lookup_value] = cache_key
            end
          end
        end
        
        # Utility function to remove any duplication from the document cache.
        def clean_document_cache
          @document_cache_keys.each_key do |cache_key|
            document = get_document(cache_key)
            
            document.each do |index_field,index_values|
              if index_values.size > 0
                document[index_field] = index_values.uniq
              end
              
              # If we have multiple value entries in what should be a single valued 
              # field, not the best solution, but just arbitrarily pick the first entry.
              if !@index_config[:schema][:fields][index_field][:multi_valued] and index_values.size > 1
                new_array = []
                new_array.push(index_values[0])
                document[index_field] = new_array
              end
            end
            
            set_document( cache_key, document )
          end
        end
        
    end
    
  end
end