require 'uri'
require 'net/http'
require 'cgi'
require 'singleton'

require 'rubygems'
require 'json'
require 'biomart'
require 'parallel'

require 'ap'

MARTSEARCH_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

puts "Running in #{MARTSEARCH_PATH}"

# Load utils modules first
require "#{MARTSEARCH_PATH}/lib/martsearch/utils"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder_utils"

# Now load classes
require "#{MARTSEARCH_PATH}/lib/martsearch/config"
require "#{MARTSEARCH_PATH}/lib/martsearch/data_source"
require "#{MARTSEARCH_PATH}/lib/martsearch/index_builder"

module MartSearch
  
end
