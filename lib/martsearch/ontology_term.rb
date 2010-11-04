module MartSearch
  
  env    = ENV['RACK_ENV']
  env    = 'development' if env.nil?
  dbc    = YAML.load_file("#{MARTSEARCH_PATH}/config/ols_database.yml")[env]
  OLS_DB = Sequel.connect({
    :adapter  => 'mysql2',
    :encoding => 'utf8',
    :database => dbc['database'],
    :host     => dbc['host'],
    :port     => dbc['port'],
    :user     => dbc['username'],
    :password => dbc['password']
  })
  
  # Error class for when we can't find a given ontology term.
  class OntologyTermNotFoundError < StandardError; end

  # Class for handling ontology terms.  Simple wrapper around the a local copy 
  # of an OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
  # database (created and managed by the EBI) using the Tree::TreeNode (rubytree) 
  # gem as a base class.
  #
  # @author Darren Oakley
  class OntologyTerm < Tree::TreeNode
    attr_accessor :already_fetched_parents, :already_fetched_children
    protected     :already_fetched_parents, :already_fetched_children
    
    # @param [String] name The ontology term (id) i.e. GO:00032
    # @param [String] content The ontology term name/description - optional this will be looked up in the OLS database
    def initialize( name, content=nil )
      super
      
      @already_fetched_parents  = false
      @already_fetched_children = false
      
      get_term_details if @content.nil? or @content.empty?
    end
    
    # Override to ensure compatibility with Tree::TreeNode.
    #
    # @return [String] The ontology term (id) i.e. GO00032
    def term
      self.name
    end

    # Override to ensure compatibility with Tree::TreeNode.
    #
    # @return [String] The ontology term name/description
    def term_name
      self.content
    end

    # Returns an array of parent OntologyTerm objects.
    #
    # @return [Array] An array of parent OntologyTerm objects
    def parentage
      get_parents
      super
    end
    
    # Returns the children of this term as a tree. Will include the current term 
    # as the 'root' of the tree.
    #
    # @return [OntologyTerm] The children of this term as a tree. Will include the current term as the 'root' of the tree.
    def child_tree
      get_children
      child_tree = self.clone
      child_tree.remove_from_parent!
      child_tree
    end

    # Returns an array of the direct children (OntologyTerm objects) of this term.
    #
    # @return [Array] An array of the direct children (OntologyTerm objects) of this term.
    def children
      get_children
      super
    end

    # Returns a flat array containing all the possible child terms
    # for this given ontology term.
    #
    # @return [Array] An array of all possible child terms (Strings) for this given ontology term
    def all_child_terms
      get_all_child_lists
      return @all_child_terms
    end

    # Returns a flat array containing all the possible child term 
    # names for this given ontology term.
    #
    # @return [Array] A flat array containing all the possible child term names (Strings) for this given ontology term
    def all_child_names
      get_all_child_lists
      return @all_child_names
    end
    
    # Function to force the OntologyTerm object to flesh out it's structure 
    # from the OLS database.  By default OntologyTerm objects are lazy and will 
    # only retieve child data one level below themselves, so this is used to 
    # recursivley flesh out a full tree.
    def build_tree
      get_parents
      get_children( self, true )
    end
    
    # Class level function to build an OntologyTerm object from a serialized JSON hash
    #
    # @example
    #   emap = JSON.parse( File.read("emap.json"), :max_nesting => false )
    #
    # @param [Hash] json_hash The parsed JSON hash to de-serialize
    # @return [OntologyTerm] The de-serialized object 
    def self.json_create(json_hash)
      node = new(json_hash["name"], json_hash["content"])
      node.already_fetched_children = true
      
      json_hash["children"].each do |child|
        child.already_fetched_children = true
        node << child
      end if json_hash["children"]
      
      node.build_tree
      
      return node
    end
    
    protected
      
      # Recursive function to query the OLS database and collect all of 
      # the parent objects and insert them into @parents in the correct 
      # order.
      def get_parents( node=self )
        unless @already_fetched_parents
          sql = <<-SQL
            select
              subject_term.identifier  as child_identifier,
              subject_term.term_name   as child_term,
              predicate_term.term_name as relation,
              object_term.identifier   as parent_identifier,
              object_term.term_name    as parent_term
            from
              term_relationship tr
              join term as subject_term 	on tr.subject_term_pk   = subject_term.term_pk
              join term as predicate_term on tr.predicate_term_pk = predicate_term.term_pk
              join term as object_term    on tr.object_term_pk    = object_term.term_pk
            where
                  predicate_term.term_name in ('part_of','is_a','develops_from')
              and subject_term.identifier = ?
          SQL
          
          MartSearch::OLS_DB[ sql, node.term ].each do |row|
            parent = OntologyTerm.new( row[:parent_identifier], row[:parent_term] )
            parent << node
            get_parents( parent )
          end
          
          @already_fetched_parents = true
        end
      end
      
      # Recursive function to query the OLS database and collect all of 
      # the child objects and build up a tree of OntologyTerm's.
      def get_children( node=self, recursively=false )
        unless @already_fetched_children or node.has_children?
          sql = <<-SQL
            select
              subject_term.identifier  as child_identifier,
              subject_term.term_name   as child_term,
              predicate_term.term_name as relation,
              object_term.identifier   as parent_identifier,
              object_term.term_name    as parent_term
            from
              term_relationship tr
              join term as subject_term   on tr.subject_term_pk   = subject_term.term_pk
              join term as predicate_term on tr.predicate_term_pk = predicate_term.term_pk
              join term as object_term    on tr.object_term_pk    = object_term.term_pk
            where
                  predicate_term.term_name in ('part_of','is_a','develops_from')
              and object_term.identifier = ?
          SQL
          
          MartSearch::OLS_DB[sql,node.term].each do |row|
            child = OntologyTerm.new( row[:child_identifier], row[:child_term] )
            child.get_children( child, true ) if recursively
            node << child
          end
          
          @already_fetched_children = true
        end
      end
      
    private

      # Helper function to query the OLS database and grab the full 
      # details of the ontology term.
      def get_term_details
        # This query ensures we look at the most recent fully loaded ontologies
        sql = <<-SQL
          select term.*
          from term
          join ontology on ontology.ontology_id = term.ontology_id
          where term.identifier = ?
          order by ontology.fully_loaded desc, ontology.load_date asc
        SQL

        term_set = MartSearch::OLS_DB[ sql, @name ].all()

        if term_set.size == 0
          get_term_from_synonym
        else
          subject      = term_set.first
          @content     = subject[:term_name]
          @term_pk     = subject[:term_pk]
          @ontology_id = subject[:ontology_id]
        end
      end

      # Helper function to try to find an ontology term via a synonym.
      def get_term_from_synonym
        sql = <<-SQL
          select term.*
          from term
          join ontology on ontology.ontology_id = term.ontology_id
          join term_synonym on term.term_pk = term_synonym.term_pk
          where term_synonym.synonym_value = ?
          order by ontology.fully_loaded desc, ontology.load_date asc
        SQL
        
        term_set = MartSearch::OLS_DB[ sql, @name ].all()
        
        if term_set.size == 0
          raise MartSearch::OntologyTermNotFoundError, "Unable to find the term '#{@name}' in the OLS database."
        end
        
        subject      = term_set.first
        @name        = subject[:identifier]
        @content     = subject[:term_name]
        @term_pk     = subject[:term_pk]
        @ontology_id = subject[:ontology_id]
      end

      # Helper function to produce the flat lists of all the child
      # terms and names.
      def get_all_child_lists
        get_children

        if @all_child_terms.nil? and @all_child_names.nil?
          @all_child_terms = []
          @all_child_names = []

          self.children.each do |child|
            @all_child_terms.push( child.term )
            @all_child_terms.push( child.all_child_terms )
            @all_child_names.push( child.term_name )
            @all_child_names.push( child.all_child_names )
          end

          @all_child_terms = @all_child_terms.flatten.uniq
          @all_child_names = @all_child_names.flatten.uniq
        end
      end
    
  end
  
  class OntologyTermCache
    
    def initialize()
      create_table = <<-SQL
        CREATE TABLE martsearch_cache (
          term varchar(255) NOT NULL PRIMARY KEY,
          json longtext NOT NULL
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8
      SQL
      
      unless MartSearch::OLS_DB.table_exists?( :martsearch_cache )
        MartSearch::OLS_DB.run create_table
      end
      
      @dataset = MartSearch::OLS_DB[:martsearch_cache]
    end
    
    # Looks up a given term in the cache.  If not found, it creates it 
    # before saving it.
    # 
    # @param [String] term The ontology term (id) i.e. GO:00032
    # @return [OntologyTerm] The OntologyTerm object
    def fetch( term )
      obj    = nil
      select = @dataset.first( :term => term )
      
      if select.nil?
        obj = cache_term( term, true )
      else
        obj = JSON.parse( select[:json], :max_nesting => false )
      end
      
      return obj
    end
    
    # Save a cache entry for a given term.  First creates the OntologyTerm 
    # object, then saves it to the cache.
    # 
    # @param [String] term The ontology term (id) i.e. GO:00032
    # @param [Boolean] build Build the full OntologyTerm tree before save
    # @return [OntologyTerm] The OntologyTerm object
    def cache_term( term, build=true )
      obj = MartSearch::OntologyTerm.new(term)
      obj.build_tree if build
      MartSearch::OLS_DB.transaction do
        @dataset.filter( :term => obj.term ).delete
        @dataset.insert( :term => obj.term, :json => obj.to_json )
      end
      return obj
    end
    
    # Save an existing OntologyTerm object into the cache.
    # 
    # @param [OntologyTerm] obj The OntologyTerm object to be stored
    # @return [OntologyTerm] The OntologyTerm object
    def cache_obj( obj )
      MartSearch::OLS_DB.transaction do
        @dataset.filter( :term => obj.term ).delete
        @dataset.insert( :term => obj.term, :json => obj.to_json )
      end
      return obj
    end
    
    # Helper function to cache all the possible entries of an ontology tree.
    # 
    # @param [String] term The ROOT ontology term (id) - i.e. EMAP:0
    def prepare_full_cache( term )
      obj = cache_term( term, true )
      recursively_cache_children( obj )
    end
    
    private
      
      # Helper function to recursively cache the children of an OntologyTerm.
      #
      # @param [OntologyTerm] obj The OntologyTerm object to be processed
      def recursively_cache_children( obj )
        obj.children.each do |child|
          cache_obj( child )
          recursively_cache_children( child ) if child.has_children?
        end
      end
    
  end
  
end