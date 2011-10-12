#!/usr/bin/env ruby
# encoding: utf-8

MP_TOP    = 'MP:0000001'
CURR_PATH = File.expand_path(File.dirname(__FILE__))

$:.unshift("#{CURR_PATH}/../../../../lib")
require 'martsearch'


# Now we need to just arrange things into the correct MP baskets

puts " - organising mp config..."

config      = []
mp_ontology = MartSearch::OntologyTerm.new(MP_TOP)

mp_ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
  puts "   - #{child.term} - #{child.term_name.gsub(' phenotype','')}"
  
  conf_data = {
    'term'                => child.term,
    'name'                => child.term_name.gsub(' phenotype',''),
    'slug'                => child.term_name.gsub(' phenotype','').gsub(/[\/\s\-]/,'-').downcase,
    'child_terms'         => [ child.term, child.all_child_terms ].flatten
  }
  
  config.push(conf_data)
end

File.open( "#{CURR_PATH}/mp_conf.json", 'w' ) do |file|
  file.write( JSON.pretty_generate(config) )
end
