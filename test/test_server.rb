require 'test_helper'

require 'capybara'
require 'capybara/dsl'

class MartSearchServerTest < Test::Unit::TestCase
  include Capybara
  # Capybara.default_driver = :selenium
  
  def setup
    Capybara.app = MartSearch::Server.new
    @controller  = MartSearch::Controller.instance()
    @server_conf = @controller.config[:server]
  end
  
  context "A MartSearch::Server web app inatance" do
    should "have 'home', 'about' and 'help' pages" do
      ['/','/about','/help'].each do |path|
        visit path
        assert_equal( path, current_path )
        assert( page.has_content?( @server_conf[:portal_name] ) )
      end
    end
  end
  
end