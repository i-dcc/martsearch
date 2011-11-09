# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

require 'singleton'
require 'logger'
require 'date'
require 'digest/md5'

require 'biomart'
require 'ols'
require 'sinatra/base'
require 'rack/mime'
require 'erubis'
require 'sinatra/static_assets'
require 'hoptoad_notifier'
require 'json'
require 'parallel'
require 'yui/compressor'
require 'closure-compiler'
require 'active_support/core_ext/hash' unless Hash.respond_to?(:symbolize_keys!) # Rails 3
require 'will_paginate/collection'
require 'will_paginate/view_helpers'
require 'mongo'
require 'mongo_store'

require 'awesome_print'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.." unless Object.const_defined? :MARTSEARCH_PATH

require "#{MARTSEARCH_PATH}/lib/martsearch/array"
require "#{MARTSEARCH_PATH}/lib/martsearch/hash"
require "#{MARTSEARCH_PATH}/lib/martsearch/string"
require "#{MARTSEARCH_PATH}/lib/martsearch/marker"

module MongoStore
  module Cache
    module Rails3
      # Monkey patch :( - it looks like sometimes we don't get the full object back from the 
      # database so i'm just experimenting with the timeout flag to see if that's causing 
      # the issues (as our cached objects can be fairly big).
      def read_entry(key, options={})
        opts = { 'expires' => {'$gt' => Time.now}, 'timeout' => false }.merge!(options)
        doc  = collection.find_one( opts.merge({ '_id' => key }) )
        ActiveSupport::Cache::Entry.new(doc['value']) if doc
      end
    end
  end
end

# Module housing all of the classes and code that make up the MartSearch portal framework.
#
# @author Darren Oakley
module MartSearch
  
  ENVIRONMENT = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : 'development' unless MartSearch.const_defined? :ENVIRONMENT
  
  # Error class raised when there is an error with the supplied configuration files.
  class InvalidConfigError < StandardError; end
  
  # MongoDB based cache class.  This is entirely ActiveSupport::Cache::MongoStore, but 
  # we have to ovveride it here as we're not running in a Rails environment, and we 
  # need to include some Rails3 mixins for it to work correctly.
  class MongoCache < ActiveSupport::Cache::MongoStore
    include ::MongoStore::Cache::Rails3
  end
  
end

require "#{MARTSEARCH_PATH}/lib/martsearch/utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source_biomart"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source_file_system"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source_dummy"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_set_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_set"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_view"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/controller"

require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder"

require "#{MARTSEARCH_PATH}/lib/martsearch/server_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers/ensembl_links"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers/ucsc_links"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers/gbrowse_links"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers/misc_db_links"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers/order_buttons"
require "#{MARTSEARCH_PATH}/lib/martsearch/server_view_helpers"
require "#{MARTSEARCH_PATH}/lib/martsearch/project_utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/server"
