# encoding: utf-8

module MartSearch
  
  # Class for handling the caching of MartSearch::OntologyTerm objects. 
  # Creates a small cache table within the OLS database schema and handles 
  # all of the serialisation/de-serialisation to store and fetch the objects.
  #
  # @author Darren Oakley
  class OntologyTermCache
    
    def initialize()
      unless MartSearch::OLS_DB.table_exists?( :martsearch_cache )
        MartSearch::OLS_DB.run <<-SQL
          CREATE TABLE martsearch_cache (
            term varchar(255) NOT NULL PRIMARY KEY,
            compressed_json longblob NOT NULL
          ) ENGINE=MyISAM DEFAULT CHARSET=utf8
        SQL
      end
      
      @dataset = MartSearch::OLS_DB[:martsearch_cache]
    end
    
    # Looks up a given term in the cache.  If not found, it creates it.
    # 
    # @param [String] term The ontology term (id) i.e. GO:00032
    # @return [OntologyTerm] The OntologyTerm object
    def fetch( term )
      obj        = nil
      select_obj = @dataset.first( :term => term )
      select_par = @dataset.first( :term => "#{term}-parents" )
      
      if select_obj.nil?
        obj = MartSearch::OntologyTerm.new(term)
      else
        obj = JSON.parse( Zlib::Inflate.inflate(select_obj[:compressed_json]), :max_nesting => false )
        
        unless select_par.nil?
          parents = JSON.parse( Zlib::Inflate.inflate(select_par[:compressed_json]), :max_nesting => false )
          obj.already_fetched_parents = true
          
          target = obj
          parent = parents.pop
          while parent
            parent.already_fetched_parents = true
            target.parent                  = parent
            target                         = parent
            parent                         = parents.pop
          end
        end
      end
      
      return obj
    end
    
    # Builds an OntologyTerm object for the given term and appeneds the 
    # parent terms to it from the cache. - useful if you're not interested in 
    # the children of a given term.
    #
    # @param [String] term The ontology term (id) i.e. GO:00032
    # @return [OntologyTerm] The OntologyTerm object
    def fetch_just_parents( term )
      obj        = MartSearch::OntologyTerm.new(term)
      select_par = @dataset.first( :term => "#{term}-parents" )
      
      unless select_par.nil?
        parents = JSON.parse( Zlib::Inflate.inflate(select_par[:compressed_json]), :max_nesting => false )
        obj.already_fetched_parents = true
        
        target = obj
        parent = parents.pop
        while parent
          parent.already_fetched_parents = true
          target.parent                  = parent
          target                         = parent
          parent                         = parents.pop
        end
      else
        obj.get_parents
      end
      
      return obj
    end
    
    # Save a cache entry for a given term.  First creates the OntologyTerm 
    # object, then saves it to the cache.
    # 
    # @param [String] term The ontology term (id) i.e. GO:00032
    # @param [Boolean] build Build the full OntologyTerm tree before save
    # @return [OntologyTerm] The OntologyTerm object
    def cache_term( term, build=false )
      obj = MartSearch::OntologyTerm.new(term)
      
      if build
        obj.build_tree
        obj.all_child_terms
      else
        obj.get_parents
        obj.get_children
      end
      
      cache_obj( obj )
      return obj
    end
    
    # Save an existing OntologyTerm object into the cache.
    # 
    # @param [OntologyTerm] obj The OntologyTerm object to be stored
    # @return [OntologyTerm] The OntologyTerm object
    def cache_obj( obj )
      MartSearch::OLS_DB.transaction do
        @dataset.filter( :term => obj.term ).delete
        @dataset.filter( :term => "#{obj.term}-parents" ).delete
        
        @dataset.insert(
          :term            => obj.term,
          :compressed_json => Zlib::Deflate.deflate( JSON.generate( obj, :max_nesting => false ) )
        )
        
        if obj.parentage and !obj.parentage.empty?
          @dataset.insert(
            :term            => "#{obj.term}-parents",
            :compressed_json => Zlib::Deflate.deflate( JSON.generate( obj.parentage, :max_nesting => false ) )
          )
        end
      end
      
      return obj
    end
    
    # Helper function to cache all the possible entries of an ontology tree.
    # 
    # @param [String] term The ROOT ontology term (id) - i.e. EMAP:0
    # @param [Boolean] cache_full_tree Whether to build and store the full ontology tree (good for small ontologies - not so good for big ones)
    def prepare_full_cache( term, cache_full_tree=true )
      obj = cache_term( term, cache_full_tree )
      puts "   - caching #{obj.term}"
      recursively_cache_children( obj, cache_full_tree )
    end
    
    private
      
      # Helper function to recursively cache the children of an OntologyTerm.
      #
      # @param [OntologyTerm] obj The OntologyTerm object to be processed
      # @param [Boolean] cache_full_tree Whether to build and store the full ontology tree of the child terms (good for small ontologies - not so good for big ones)
      def recursively_cache_children( obj, cache_full_tree=true )
        obj.children.each do |child|
          if cache_full_tree
            child.all_child_terms
          else
            child.get_children
          end
          
          cache_obj( child )
          puts "   - caching #{child.term}"
          recursively_cache_children( child, cache_full_tree ) if child.has_children?
        end
      end
    
  end
  
end