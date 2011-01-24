#!/usr/bin/env ruby

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )
require 'martsearch'

mp_ontology = MartSearch::OntologyTerm.new('MP:0000001')
conf        = {
  "mamalian-phenotype" => {
    "index_field"  => "mp",
    "display_name" => "Mamalian Phenotype",
    "exact_search" => true,
    "options"      => []
  }
}

mp_ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
  # puts "#{child.term} - #{child.term_name.gsub(' phenotype','')}"
  
  conf["mamalian-phenotype"]["options"].push({
    "text"  => child.term_name.gsub(' phenotype',''),
    "query" => child.term.gsub('MP:',''),
    "slug"  => child.term_name.gsub(' phenotype','').gsub(' ','-').gsub('/','-')
  })
end

puts conf.to_json
