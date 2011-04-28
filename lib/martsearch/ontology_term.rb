module MartSearch
  
  dbc    = YAML.load_file("#{MARTSEARCH_PATH}/config/ols_database.yml")[MartSearch::ENVIRONMENT]
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
    
    attr_accessor :root_term, :leaf_node
    attr_writer   :all_child_terms, :all_child_names
    protected     :root_term, :leaf_node
    
    # @param [String] name The ontology term (id) i.e. GO:00032
    # @param [String] content The ontology term name/description - optional this will be looked up in the OLS database
    def initialize( name, content=nil )
      super
      
      @already_fetched_parents  = false
      @already_fetched_children = false
      @root_term                = false
      @leaf_node                = false
      
      @all_child_terms          = nil
      @all_child_names          = nil
      
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
    
    # Returns +true+ if the receiver is a root node.  Note that
    # orphaned children will also be reported as root nodes.
    #
    # @return [Boolean] +true+ if this is a root node.
    def is_root?
      @root_term
    end
    
    # Returns +true+ if the receiver node is a 'leaf' - i.e., one without
    # any children.
    #
    # @return [Boolean] +true+ if this is a leaf node.
    def is_leaf?
      @leaf_node
    end
    
    # Returns string representation of the receiver node.
    # This method is primarily meant for debugging purposes.
    #
    # @return [String] A string representation of the node.
    def to_s
      "Term: #{@name}" +
        " Term Name: " + (@content || "<Empty>") +
        " Root Term?: #{is_root?}" +
        " Leaf Node?: #{is_leaf?} " +
        " Total Nodes Loaded: #{size()}"
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
      build_tree
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
    
    # Creates a JSON representation of this node including all it's children.   This requires the JSON gem to be
    # available, or else the operation fails with a warning message.
    #
    # @return The JSON representation of this subtree.
    #
    # @see {OntologyTerm#json_create}
    def to_json(*a)
      json_hash = {
        "name"            => name,
        "content"         => content,
        "root_term"       => @root_term,
        "leaf_node"       => @leaf_node,
        "all_child_terms" => @all_child_terms,
        "all_child_names" => @all_child_names,
        JSON.create_id    => self.class.name
      }

      if has_children?
        json_hash["children"] = children
      end

      return JSON.generate( json_hash, :max_nesting => false )
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
      node.already_fetched_children = true if json_hash["children"]
      
      node.root_term       = true if json_hash["root_term"]
      node.leaf_node       = true if json_hash["leaf_node"]
      node.all_child_terms = json_hash["all_child_terms"]
      node.all_child_names = json_hash["all_child_names"]
      
      json_hash["children"].each do |child|
        child.already_fetched_parents  = true
        child.already_fetched_children = true if child.has_children?
        node << child
      end if json_hash["children"]
      
      return node
    end
    
    # Method to set the parent node for the receiver node.
    # This method should *NOT* be invoked by client code.
    #
    # @param [OntologyTerm] parent The parent node.
    # @return [OntologyTerm] The parent node.
    def parent=(parent)         # :nodoc:
      @parent = parent
    end
    
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
            object_term.term_name    as parent_term,
            object_term.is_root_term as parent_is_root
          from
            term_relationship tr
            join term as subject_term 	on tr.subject_term_pk   = subject_term.term_pk
            join term as predicate_term on tr.predicate_term_pk = predicate_term.term_pk
            join term as object_term    on tr.object_term_pk    = object_term.term_pk
          where
                predicate_term.term_name in ('part_of','is_a','develops_from')
            and subject_term.identifier = ?
        SQL
        
        # FIXME: This does not take into account terms that have multiple parents... we need to model this.
        MartSearch::OLS_DB.fetch( sql, node.term ).first(1).each do |row|
          parent           = OntologyTerm.new( row[:parent_identifier], row[:parent_term] )
          parent.root_term = true if row[:parent_is_root].to_i == 1
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
            subject_term.is_leaf     as child_is_leaf,
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
          child.leaf_node = true if row[:child_is_leaf].to_i == 1
          child.get_children( child, true ) if recursively and !child.is_leaf?
          node << child
        end
        
        @already_fetched_children = true
      end
    end
    
    # Returns a copy of the receiver node, with its parent and children links removed.
    # The original node remains attached to its tree.
    #
    # @return [OntologyTerm] A copy of the receiver node.
    def detached_copy
      copy = MartSearch::OntologyTerm.new(@name, @content ? @content.clone : nil)
      copy.root_term = @root_term
      copy.leaf_node = @leaf_node
      return copy
    end
    
    # Function that merges one OntologyTerm tree into another.
    #
    # @param [OntologyTerm] tree The tree that is to be merged into self
    # @param [Boolean] do_not_expand_trees Stop the merged ontology trees from dynamically expanding from thier current state?
    # @return [OntologyTerm] The merged tree
    def merge( tree, do_not_expand_trees=true )
      unless tree.is_a?(MartSearch::OntologyTerm)
        raise TypeError, "You can only merge in another OntologyTerm tree!"
      end
      
      unless self.root.name == tree.root.name
        raise ArgumentError, "Unable to merge trees as they do not share the same root!"
      end
      
      new_tree = merge_subtrees( self.root, tree.root )
    end
    
    private
      
      # Utility function to recursivley merge two subtrees
      #
      # @param [OntologyTerm] tree1 The target tree to merge into
      # @param [OntologyTerm] tree2 The donor tree (that will be merged into target)
      # @param [Boolean] do_not_expand_trees Stop the merged ontology trees from dynamically expanding from thier current state?
      def merge_subtrees( tree1, tree2, do_not_expand_trees=true )
        if do_not_expand_trees
          tree1.instance_variable_set( :@already_fetched_children, true )
          tree2.instance_variable_set( :@already_fetched_children, true )
        end
        
        names1 = tree1.has_children? ? tree1.children.map { |child| child.name } : []
        names2 = tree2.has_children? ? tree2.children.map { |child| child.name } : []

        names_to_merge = names2 - names1
        names_to_merge.each do |name|
          tree1 << tree2[name].detached_subtree_copy
        end

        tree1.children.each do |child|
          unless tree2[child.name].nil?
            merge_subtrees( child, tree2[child.name] )
          end
        end

        return tree1
      end
      
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
          @root_term   = true if subject[:is_root_term].to_i == 1
          @leaf_node   = true if subject[:is_leaf].to_i == 1
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
        @root_term   = true if subject[:is_root_term].to_i == 1
        @leaf_node   = true if subject[:is_leaf].to_i == 1
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
