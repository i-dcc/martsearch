require 'uri'
require 'net/http'
require 'cgi'
require 'singleton'
require 'logger'

require 'rubygems'

gem 'sinatra', '>=1.0'
gem 'biomart', '>=0.2.0'

require 'biomart'
require 'sinatra/base'

require 'json'
require 'parallel'
require 'tree'
require 'sequel'
require 'builder'
require 'erubis'
require 'yui/compressor'
require 'closure-compiler'
require 'active_support'
require 'active_support/core_ext/hash' unless Hash.respond_to?(:symbolize_keys!) # Rails 3

require 'ap'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{MARTSEARCH_PATH}/lib/martsearch/array"
require "#{MARTSEARCH_PATH}/lib/martsearch/hash"

# Module housing all of the classes and code that make up the MartSearch portal framework.
#
# @author Darren Oakley
module MartSearch
end

require "#{MARTSEARCH_PATH}/lib/martsearch/utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller"
require "#{MARTSEARCH_PATH}/lib/martsearch/ontology_term"

require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder"

require "#{MARTSEARCH_PATH}/lib/martsearch/server_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server"
