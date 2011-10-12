#!/usr/bin/env ruby
# encoding: utf-8

# Writes the config for the top level mp terms into mp_conf.json
# Copy the output into config.json as the property mp_heatmap_config
# some terms are excluded, see the list below:

MP_TOP    = 'MP:0000001'
CURR_PATH = File.expand_path(File.dirname(__FILE__))

$:.unshift("#{CURR_PATH}/../../../../lib")
require 'martsearch'

puts " - organising mp config..."

config      = []
mp_ontology = MartSearch::OntologyTerm.new(MP_TOP)

ignored_terms = [ 
  "normal phenotype",
  "no phenotypic analysis"
]

mp_ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
  if ignored_terms.include?(child.term_name)
    puts "   - ignoring #{child.term_name}"   
  else
    puts "   - #{child.term} - #{child.term_name.gsub(' phenotype','')}"
  
    conf_data = {
      'term'                => child.term,
      'name'                => child.term_name.gsub(' phenotype',''),
      'slug'                => child.term_name.gsub(' phenotype','').gsub(/[\/\s\-]/,'-').downcase,
      'child_terms'         => [ child.term, child.all_child_terms ].flatten
    }
  
    config.push(conf_data)
  end

  
end

File.open( "#{CURR_PATH}/mp_conf.json", 'w' ) do |file|
  file.write( JSON.pretty_generate(config) )
end
