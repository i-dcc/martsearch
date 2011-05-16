#!/usr/bin/env ruby
# encoding: utf-8

MP_TOP    = 'MP:0000001'
CURR_PATH = File.expand_path(File.dirname(__FILE__))

$:.unshift("#{CURR_PATH}/../../../../lib")
require 'martsearch'

# First hook up to the MIG database to determine which MP terms the 
# phenotyping tests could potentially map to...

puts " - getting 'htgt_param_possible_mp_terms' data from mig..."

parameter_map = {}

MIG_DB = Sequel.connect(
  :adapter  => 'oracle',
  :database => 'migp_ha.world',
  :user     => 'mig',
  :password => 'sau5age5',
  :test     => true
)

MIG_DB[:htgt_param_possible_mp_terms].each do |row|
  param_key = [ row[:test_name], row[:protocol], row[:parameter_name] ].join('|')
  
  parameter_map[ param_key ] ||= []
  parameter_map[ param_key ].push( row[:mp_term] )
end

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
    'child_terms'         => [ child.term, child.all_child_terms ].flatten,
    'mgp_parameters'      => []
  }
  
  conf_data['child_terms'].each do |term|
    parameter_map.each do |param_key,mp_terms|
      if mp_terms.include?(term)
        conf_data['mgp_parameters'].push( param_key )
      end
    end
  end
  
  conf_data['mgp_parameters'].uniq!
  
  config.push(conf_data)
end

File.open( "#{CURR_PATH}/mp_conf.json", 'w' ) do |file|
  file.write( config.to_json )
end
