# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/lib" )

require 'martsearch'
require 'rack/contrib'

use Rack::ETag

log = File.new("#{File.dirname(__FILE__)}/lib/martsearch/server/logs/martsearch.log", "a+")
err = File.new("#{File.dirname(__FILE__)}/lib/martsearch/server/logs/martsearch.err", "a+")
$stdout.reopen(log)
$stderr.reopen(err)

map '/' do
  run MartSearch::Server
end