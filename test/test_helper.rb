require 'rubygems'

# Set-up SimpleCov (code coverage tool for Ruby 1.9)
if /^1.9/ === RUBY_VERSION
  begin
    require 'simplecov'
    SimpleCov.start do
      coverage_dir 'simplecov'
    end
  rescue LoadError
    puts "[ERROR] Unable to load 'simplecov' - please run 'bundle install'"
  end
end

# Add the lib directory to the search path
$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'test/unit'
require 'vcr'
require 'shoulda'
require 'martsearch'

# Set-up VCR for mocking up web requests.
VCR.config do |c|
  if /^1\.8/ === RUBY_VERSION
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.8'
  elsif RUBY_VERSION == "1.9.1"
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.1'
  else
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.2+'
  end
  
  c.http_stubbing_library    = :fakeweb
  c.ignore_localhost         = true
  c.default_cassette_options = { 
    :record            => :new_episodes, 
    :match_requests_on => [:uri, :method]
  }
end

# Setup the connection parameters for our OLS database...
env = ENV['RACK_ENV']
env = 'development' if env.nil?
dbc = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/../config/ols_database.yml")[env]
OLS_DB = Sequel.connect("mysql://#{dbc['username']}:#{dbc['password']}@#{dbc['host']}:#{dbc['port']}/#{dbc['database']}")
