# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/lib" )

require 'martsearch'
require 'rack/contrib'

use Rack::ETag

log = File.new( "#{File.dirname(__FILE__)}/log/martsearch.log", "a+" )
$stdout.reopen(log)
$stderr.reopen(log)
MartSearch::Server.use Rack::CommonLogger, log

map '/' do
  run MartSearch::Server
end