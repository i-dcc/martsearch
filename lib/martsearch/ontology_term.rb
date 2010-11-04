module MartSearch
  
  env    = ENV['RACK_ENV']
  env    = 'development' if env.nil?
  dbc    = YAML.load_file("#{MARTSEARCH_PATH}/config/ols_database.yml")[env]
  OLS_DB = Sequel.connect({
    :adapter  => 'mysql2',
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
    
    # @param [String] name The ontology term (id) i.e. GO00032
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
    # @param [Hash] json_hash The parsed JSON hash to de-serialize
    # @return [OntologyTerm] The de-serialized object 
    def self.json_create(json_hash)
      node = new(json_hash["name"], json_hash["content"])
      node.already_fetched_parents  = true
      node.already_fetched_children = true
      
      json_hash["children"].each do |child|
        child.already_fetched_parents  = true
        child.already_fetched_children = true
        node << child
      end if json_hash["children"]
      
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
        end
        
        @already_fetched_parents = true
      end
      
      # Recursive function to query the OLS database and collect all of 
      # the child objects and build up a tree of OntologyTerm's.
      def get_children( node=self, recursively=false )
        unless @already_fetched_children
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
        end
        
        @already_fetched_children = true
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
  
end