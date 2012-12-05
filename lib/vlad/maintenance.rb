require 'vlad'

##
# See the following documents for recipes:
#
# * http://clarkware.com/blog/2007/1/5/custom-maintenance-pages
# * http://blog.nodeta.fi/2009/03/11/stopping-your-rails-application-with-phusion-passenger/
#

namespace :vlad do
  namespace :maintenance do

    desc "Turn on the maintenance web page"

    remote_task :on, :roles => [:web] do
      #run "cp -f #{shared_path}/config/maintenance.html #{shared_path}/public/"
      puts "#### cp -f #{shared_path}/config/maintenance.html #{shared_path}/public/"
    end

    desc "Turn off the maintenance web page"

    remote_task :off, :roles => [:web] do
      #run "rm -f #{shared_path}/public/maintenance.html"
      puts "#### rm -f #{shared_path}/public/maintenance.html"
    end
  end
end
