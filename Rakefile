# Add the lib directory to the search path
$:.unshift( "#{File.dirname(__FILE__)}/lib" )

require 'bundler/setup'

desc 'Default task: run all tests'
task :default => [:test]

# Load rake tasks from the tasks directory
Dir["#{File.dirname(__FILE__)}/tasks/*.task"].each { |t| load t }
