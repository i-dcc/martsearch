require 'rubygems'
require 'test/unit'
require 'vcr'
require 'shoulda'

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'martsearch'

# Set-up VCR for mocking up web requests.
VCR.config do |c|
  c.cassette_library_dir     = 'test/vcr_cassettes'
  c.http_stubbing_library    = :fakeweb
  c.default_cassette_options = { 
    :record            => :new_episodes, 
    :match_requests_on => [:uri, :method]
  }
end
