require 'uri'
require 'net/http'
require 'cgi'
require 'singleton'
require 'logger'

require 'rubygems'
require 'bundler/setup'

require 'biomart'
require 'sinatra/base'
require 'sinatra/static_assets'
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
require 'will_paginate/collection'
require 'will_paginate/view_helpers'
require 'hoptoad_notifier'

require 'ap'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{MARTSEARCH_PATH}/lib/martsearch/array"
require "#{MARTSEARCH_PATH}/lib/martsearch/hash"

# Module housing all of the classes and code that make up the MartSearch portal framework.
#
# @author Darren Oakley
module MartSearch
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigError < StandardError; end
  
end

require "#{MARTSEARCH_PATH}/lib/martsearch/utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/mock"
require "#{MARTSEARCH_PATH}/lib/martsearch/index"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_set_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_set"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_view"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller"
require "#{MARTSEARCH_PATH}/lib/martsearch/ontology_term"

require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder"

require "#{MARTSEARCH_PATH}/lib/martsearch/server_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers"
require "#{MARTSEARCH_PATH}/lib/martsearch/server"
