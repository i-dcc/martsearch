#rails environment for the unicorn
rails_env = ENV['RAILS_ENV'] || 'development'

## Set the number of worker processes which can be spawned
worker_processes 4

## Preload the application into master for fast worker spawn
## times.
preload_app true

## Restart any workers which haven't responded for 30 seconds.
timeout 90

## Store the pid file safely away in the pids folder
logger Logger.new(File.join(File.expand_path('../../', __FILE__), 'log', 'unicorn.log'))
pid File.join(File.expand_path('../../', __FILE__), 'tmp', 'pids', 'unicorn.pid')

## Listen on a unix data socket
listen File.join(File.expand_path('../../', __FILE__), 'tmp', 'sockets', 'unicorn.sock')

before_fork do |server, worker|
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = File.join(File.expand_path('../../', __FILE__), 'tmp', 'pids', 'unicorn.pid.oldbin')
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end