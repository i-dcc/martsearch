begin
  require 'shoulda'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'shoulda'
end

curr_path = File.expand_path(File.dirname(__FILE__))

$:.unshift( "#{curr_path}/../lib" )

require 'martsearch'
