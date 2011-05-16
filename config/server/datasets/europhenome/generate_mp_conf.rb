#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'

MP_TOP    = 'MP:0000001'
CURR_PATH = File.expand_path(File.dirname(__FILE__))

$:.unshift("#{CURR_PATH}/../../../../lib")
require 'martsearch'

# Setup the connection for the Europhenome biomart...
mart = MartSearch::Controller.instance().config[:datasources][:europhenome].ds

# Get a map of all of the parameters to potential MP terms - the reason 
# for doing this is so that we can map test results that haven't been 
# assigned an MP term yet... (We're not really interested in this data 
# but we need to be able to show that a test has been done and no significant 
# data is associated with it).
parameter_search = mart.search(
  :filters         => {},
  :attributes      => ['parameter_eslim_id','parameter_name','mp_term'],
  :process_results => true
)

parameter_map = {}
parameter_search.each do |result|
  map = parameter_map[ result['parameter_eslim_id'] ]
  map = [] if map.nil?
  map.push( result['mp_term'] ) unless result['mp_term'].nil?
  parameter_map[ result['parameter_eslim_id'] ] = map
end

config      = []
mp_ontology = MartSearch::OntologyTerm.new(MP_TOP)

mp_ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
  puts "#{child.term} - #{child.term_name.gsub(' phenotype','')}"
  
  conf_data = {
    'term'                => child.term,
    'name'                => child.term_name.gsub(' phenotype',''),
    'child_terms'         => [ child.term, child.all_child_terms ].flatten,
    'test_eslim_ids'      => [],
    'parameter_eslim_ids' => []
  }
  
  conf_data['child_terms'].each do |term|
    parameter_map.each do |param_eslim_id,param_terms|
      if param_terms.include?(term)
        conf_data['test_eslim_ids'].push( param_eslim_id[ 0, ( param_eslim_id.size - 4 ) ] )
        conf_data['parameter_eslim_ids'].push(param_eslim_id)
      end
    end
  end
  
  conf_data['test_eslim_ids'].uniq!
  conf_data['parameter_eslim_ids'].uniq!
  
  config.push(conf_data)
end

File.open( "#{CURR_PATH}/mp_conf.json", 'w' ) do |file|
  file.write( config.to_json )
end
