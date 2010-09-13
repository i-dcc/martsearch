# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/lib" )

require 'martsearch'

map '/' do
  run MartSearch::Server
end