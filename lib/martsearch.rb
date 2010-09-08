require 'uri'
require 'net/http'
require 'cgi'
require 'singleton'
require 'logger'
require 'builder'

require 'rubygems'
require 'json'
require 'biomart'
require 'parallel'
require 'tree'
require 'sequel'

require 'ap'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{MARTSEARCH_PATH}/lib/martsearch/array"

# Module housing all of the classes and code that make up the MartSearch portal framework.
#
# @author Darren Oakley
module MartSearch
end

require "#{MARTSEARCH_PATH}/lib/martsearch/utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source"
require "#{MARTSEARCH_PATH}/lib/martsearch/config_builder"
require "#{MARTSEARCH_PATH}/lib/martsearch/ontology_term"

require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder"
