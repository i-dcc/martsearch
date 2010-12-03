require 'test_helper'

class MartSearchOntologyTermTest < Test::Unit::TestCase
  include MartSearch
  
  context "An OntologyTerm object" do
    setup do
      @emap_id   = "EMAP:3018"
      @emap_name = "TS18,nose"
      @ont = OntologyTerm.new(@emap_id)
    end
    
    should "have basic attributes" do
      assert_equal( @emap_id, @ont.name, "OntologyTerm.name does not equal '#{@emap_id}'." )
      assert_equal( @emap_id, @ont.term, "OntologyTerm.term does not equal '#{@emap_id}'." )
      
      assert_equal( @emap_name, @ont.content, "OntologyTerm.content does not equal '#{@emap_name}'." )
      assert_equal( @emap_name, @ont.term_name, "OntologyTerm.term_name does not equal '#{@emap_name}'." )
      
      assert_equal( false, @ont.term_name.nil?, "The OntologyTerm.term_name is nil." )
      assert_equal( false, @ont.content.nil?, "The OntologyTerm.term_name is nil." )
    end
    
    should "raise appropriate errors" do
      assert_raise(MartSearch::OntologyTermNotFoundError) { OntologyTerm.new("FLIBBLE:5") }
    end
    
    should "be able to represent itself as a String" do
      string = @ont.to_s
      
      assert( string.include?('Term Name'), "OntologyTerm.to_s does not include 'Term Name'." )
      assert( string.include?(@ont.content), "OntologyTerm.to_s does not include '@content'." )
      assert( string.include?('Root Term?'), "OntologyTerm.to_s does not include 'Root Term?'." )
      assert( string.include?('Leaf Node?'), "OntologyTerm.to_s does not include 'Leaf Node?'." )
    end
    
    should "respond correctly to the .parentage method" do
      assert( @ont.parentage.is_a?(Array), "OntologyTerm.parentage is not an Array when we have parents." )
      assert( @ont.parentage[0].is_a?(OntologyTerm), "OntologyTerm.parentage[0] does not return an OntologyTerm tree." )
      assert_equal( 4, @ont.parentage.size, "OntologyTerm.parentage is not returning the correct number of entries (we expect 4 for #{@emap_id})." )
    end
    
    should "be able to generate its child tree" do
      assert( @ont.child_tree.is_a?(OntologyTerm), "OntologyTerm.child_tree does not return an OntologyTerm tree." )
      assert_equal( @ont.term, @ont.child_tree.term, "OntologyTerm.child_tree.root is equal to self." )
    end
        
    should "respond correctly to the .children method" do
      assert( @ont.children.is_a?(Array), "OntologyTerm.children is not an Array when we have children." )
      assert( @ont.children[0].is_a?(OntologyTerm), "OntologyTerm.children[0] does not return an OntologyTerm tree." )
      assert_equal( 3, @ont.children.size, "OntologyTerm.children is not returning the correct number of entries (we expect 3 direct children for #{@emap_id})." )
    end
    
    should "be able to generate a flat list of all child terms/names" do
      assert( @ont.all_child_terms.is_a?(Array), "OntologyTerm.all_child_terms is not an Array." )
      assert( @ont.all_child_terms[0].is_a?(String), "OntologyTerm.all_child_terms[0] is not an String." )
      assert_equal( 14, @ont.all_child_terms.size, "OntologyTerm.all_child_terms is not returning the correct number of entries (we expect 14 children for #{@emap_id})." )
      
      assert( @ont.all_child_names.is_a?(Array), "OntologyTerm.all_child_names is not an Array." )
      assert( @ont.all_child_names[0].is_a?(String), "OntologyTerm.all_child_names[0] is not an String." )
      assert_equal( 14, @ont.all_child_names.size, "OntologyTerm.all_child_names is not returning the correct number of entries (we expect 14 children for #{@emap_id})." )
      
      assert_equal( @ont.all_child_terms.size, @ont.all_child_names.size, "OntologyTerm.all_child_terms and OntologyTerm.all_child_names do not produce an array of the same size." )
    end
    
    should "be able to locate ontology terms via synonyms" do
      go_id = 'GO:0007242'
      ont   = OntologyTerm.new(go_id)
      
      assert_equal( 'GO:0023034', ont.term, "A synonym search for GO:0007242 has not found GO:0023034." )
      assert_equal( 'intracellular signaling pathway', ont.term_name, "A synonym search for GO:0007242 has not found 'intracellular signaling pathway'." )
    end
    
    should "be able to serialize/deserialize itself as a JSON string" do
      @ont.build_tree()
      
      json_string = nil
      assert_nothing_raised(Exception) { json_string = @ont.to_json }
      assert( json_string.is_a?(String) )
      
      duplicate = nil
      assert_nothing_raised(Exception) { duplicate = JSON.parse(json_string) }
      assert( duplicate.is_a?(OntologyTerm) )
      assert_equal( @ont.term, duplicate.term )
      assert_equal( @ont.term_name, duplicate.term_name )
      assert_equal( @ont.is_root?, duplicate.is_root? )
      assert_equal( @ont.is_leaf?, duplicate.is_leaf? )
    end
    
    should "be able to produce a detached copy of itself" do
      @ont.build_tree()
      duplicate = @ont.detached_copy
      
      assert_equal( @ont.term, duplicate.term )
      assert_equal( @ont.term_name, duplicate.term_name )
      assert_equal( @ont.is_root?, duplicate.is_root? )
      assert_equal( @ont.is_leaf?, duplicate.is_leaf? )
      
      assert_equal( false, duplicate.send(:already_fetched_parents) )
      assert_equal( false, duplicate.send(:already_fetched_children) )
    end
    
    should "be able to merge two ontology trees" do
      @ont2 = OntologyTerm.new('EMAP:3003')
      
      @ont.build_tree
      @ont2.build_tree
      
      merged_tree = @ont.merge(@ont2)
      
      assert( merged_tree['EMAP:2636']['EMAP:2822']['EMAP:2987'].is_a?(OntologyTerm) )
      assert_equal( 2, merged_tree['EMAP:2636']['EMAP:2822']['EMAP:2987'].children.size )
      assert_equal( 34, merged_tree.size )
      
      another_ont     = OntologyTerm.new('GO:0023034')
      yet_another_ont = OntologyTerm.new('EMAP:3003')
      another_ont.build_tree
      yet_another_ont.build_tree
      
      assert_raise(ArgumentError) { foo = another_ont.merge(yet_another_ont) }
      assert_raise(TypeError) { bar = another_ont.merge('EMAP:3003') }
    end
  end
end