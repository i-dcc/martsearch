require 'singleton'
require 'logger'

require 'rubygems'
require 'bundler/setup'

require 'biomart'
require 'sinatra/base'
require 'erubis'
require 'sinatra/static_assets'
require 'hoptoad_notifier'
require 'newrelic_rpm'
require 'json'
require 'parallel'
require 'tree'
require 'sequel'
require 'yui/compressor'
require 'closure-compiler'
require 'active_support/core_ext/hash' unless Hash.respond_to?(:symbolize_keys!) # Rails 3
require 'will_paginate/collection'
require 'will_paginate/view_helpers'
require 'mongo'
require 'mongo_store'

require 'ap'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{MARTSEARCH_PATH}/lib/martsearch/array"
require "#{MARTSEARCH_PATH}/lib/martsearch/hash"
require "#{MARTSEARCH_PATH}/lib/martsearch/marker"
require "#{MARTSEARCH_PATH}/lib/martsearch/file_store_patch"

# Module housing all of the classes and code that make up the MartSearch portal framework.
#
# @author Darren Oakley
module MartSearch
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigError < StandardError; end
  
  class MongoCache < ActiveSupport::Cache::MongoStore
    include ::MongoStore::Cache::Rails3
  end
  
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

require "#{MARTSEARCH_PATH}/lib/martsearch/project_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers"
require "#{MARTSEARCH_PATH}/lib/martsearch/server"
