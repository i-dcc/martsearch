#!/usr/bin/env ruby

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )
require 'martsearch'

# Configuration for the builder
CONF = {
  :mp => {
    :id               => 'mamalian-phenotype',
    :index_field      => 'mp',
    :root_term        => 'MP:0000001',
    :display_name     => "Mamalian Phenotype",
    :descriptive_text => "browse for genes that when knocked-out have been annotated as causing a distinct phenotype (as classified by the <a href='http://nbirn.net/research/ontology/mammalian_ontology.shtm' target='_blank'>mamalian phenotype ontology</a>)",
    :gsub_term_name   => " phenotype"
  },
  :ma => {
    :id               => 'adult-mouse-anatomy',
    :index_field      => 'ma',
    :root_term        => 'MA:0002405',
    :display_name     => "Adult Mouse Anatomy",
    :descriptive_text => "browse for genes that when knocked-out have been annotated as ..."
  }
}

generated_conf = {}

raise ArgumentError, "No options given!" if ARGV.empty?
ARGV.each do |cmd|
  raise ArgumentError, "I have no config for '#{cmd}'..." if CONF[cmd.downcase.to_sym].nil?
  
  conf     = CONF[cmd.downcase.to_sym]
  
  generated_conf[ conf[:id] ] = {
    "index_field"      => conf[:index_field],
    "display_name"     => conf[:display_name],
    "descriptive_text" => conf[:descriptive_text],
    "exact_search"     => true,
    "options"          => []
  }
  
  ontology = MartSearch::OntologyTerm.new(conf[:root_term])
  ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
    term      = child.term
    term_name = child.term_name
    
    term_name.gsub!(conf[:gsub_term_name],'') if conf[:gsub_term_name]
    
    puts "#{child.term} - #{child.term_name}"
    
    generated_conf[ conf[:id] ]["options"].push({
      "text"  => term_name,
      "query" => term,
      "slug"  => term_name.gsub(' ','-').gsub('/','-')
    })
  end
end

# puts generated_conf.to_json
