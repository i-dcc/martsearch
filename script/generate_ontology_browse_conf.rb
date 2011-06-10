#!/usr/bin/env ruby
# encoding: utf-8

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )
require 'martsearch'

# Configuration for the builder
CONF = {
  :mp => {
    :id               => 'mammalian-phenotype',
    :index_field      => 'MP',
    :root_term        => 'MP:0000001',
    :display_name     => "Mammalian Phenotype",
    :descriptive_text => "browse for genes that when knocked-out have been annotated as causing a distinct phenotype (as classified by the <a href='http://www.obofoundry.org/cgi-bin/detail.cgi?id=mammalian_phenotype' target='_blank'>mamalian phenotype ontology</a>)",
    :gsub_term_name   => " phenotype"
  },
  :ma => {
    :id               => 'adult-mouse-anatomy',
    :index_field      => 'MA',
    :root_term        => 'MA:0002405',
    :display_name     => "Adult Mouse Anatomy",
    :descriptive_text => "browse for genes that when knocked-out have been annotated as being expressed within a region (as classified by the <a href='http://www.obofoundry.org/cgi-bin/detail.cgi?id=adult_mouse_anatomy' target='_blank'>adult mouse anatomy ontology</a>)",
    :include_children => true
  }
}

generated_conf = {}

raise ArgumentError, "No options given!" if ARGV.empty?
ARGV.each do |cmd|
  raise ArgumentError, "I have no config for '#{cmd}'..." if CONF[cmd.downcase.to_sym].nil?
  
  conf     = CONF[cmd.downcase.to_sym]
  
  generated_conf[ conf[:id] ] = {
    "display_name"     => conf[:display_name],
    "descriptive_text" => conf[:descriptive_text],
    "options"          => {}
  }
  
  ontology        = MartSearch::OntologyTerm.new(conf[:root_term])
  ontology_prefix = conf[:root_term].match(/^(\w+\:)\d+$/)[1]
  
  ontology.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |child|
    term      = child.term.gsub(ontology_prefix,'')
    term_name = child.term_name
    
    term_name.gsub!(conf[:gsub_term_name],'') if conf[:gsub_term_name]
    
    # puts "#{term} - #{term_name}"
    
    generated_conf[ conf[:id] ]["options"][ term_name.gsub(' ','-').gsub('/','-') ] = {
        "text"  => term_name,
        "query" => "#{conf[:index_field]}:#{term}"
    }
    
    
    if conf[:include_children]
      child.children.sort{ |a,b| a.term_name <=> b.term_name }.each do |grand_child|
        term      = grand_child.term.gsub(ontology_prefix,'')
        term_name = grand_child.term_name
        
        term_name.gsub!(conf[:gsub_term_name],'') if conf[:gsub_term_name]
        
        # puts "#{term} - #{term_name}"
        
        generated_conf[ conf[:id] ]["options"][ term_name.gsub(' ','-').gsub('/','-') ] = {
          "text"  => term_name,
          "query" => "#{conf[:index_field]}:#{term}",
          "child" => true
        }
      end
    end
  end
end

puts generated_conf.to_json
