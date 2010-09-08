require 'rubygems'
require 'test/unit'
require 'vcr'
require 'shoulda'

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'martsearch'

# Set-up VCR for mocking up web requests.
VCR.config do |c|
  c.http_stubbing_library    = :fakeweb
  c.default_cassette_options = { 
    :record            => :new_episodes, 
    :match_requests_on => [:uri, :method]
  }
  
  if /^1\.8/ === RUBY_VERSION
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.8'
  else
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9'
  end
end

# Setup the connection parameters for our OLS database...
env = ENV['RACK_ENV']
env = 'development' if env.nil?
dbc = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/../config/ols_database.yml")[env]
OLS_DB = Sequel.connect("mysql://#{dbc['username']}:#{dbc['password']}@#{dbc['host']}:#{dbc['port']}/#{dbc['database']}")
