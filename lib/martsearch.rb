require 'uri'
require 'net/http'
require 'cgi'
require 'singleton'

require 'rubygems'
require 'json'

gem 'biomart', '>=0.1.5'
require 'biomart'

require 'ap'

MARTSEARCH_PATH = File.expand_path(File.dirname(__FILE__))

# Load utils modules first
require "#{MARTSEARCH_PATH}/martsearch/utils"

# Now load classes
require "#{MARTSEARCH_PATH}/martsearch/config"
require "#{MARTSEARCH_PATH}/martsearch/data_source"

module MartSearch
  @martsearch_config = MartSearch::Config.instance()
end
