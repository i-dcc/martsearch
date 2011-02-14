set :application, 'ikmc_portal'
set :repository,  'git://github.com/i-dcc/martsearch.git'
set :branch, 'ikmc_portal'
set :user, `whoami`.chomp

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, 'etch-dev64.internal.sanger.ac.uk'
role :app, 'etch-dev64.internal.sanger.ac.uk'

set :default_environment, {
  'PATH'      => '/software/team87/brave_new_world/bin:/software/perl-5.8.8/bin:/usr/bin:/bin',
  'PERL5LIB'  => '/software/team87/brave_new_world/lib/perl5:/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi'
}

set :bundle_cmd, '/software/team87/brave_new_world/bin/htgt-env.pl --environment Ruby19 /software/team87/brave_new_world/app/ruby-1.9.2-p0/lib/ruby/gems/1.9/bin/bundle'

namespace :deploy do
  desc 'Restart Passenger'
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  desc 'Symlink shared configs and folders on each release.'
  task :symlink_shared do
    # OLS conf
    run "ln -nfs #{shared_path}/ols_database.yml #{release_path}/config/ols_database.yml"
    
    # /log
    run "rm -rf #{release_path}/log"
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    
    # /tmp
    run "mkdir -m 777 -p #{var_run_path}/tmp"
    run "rm -rf #{release_path}/tmp"
    run "ln -nfs #{var_run_path}/tmp #{release_path}/tmp"
    
    # /public/js - the server needs write access...
    run "rm -rf #{var_run_path}/js"
    run "mv #{release_path}/public/js #{var_run_path}/js"
    run "ln -nfs #{var_run_path}/js #{release_path}/public/js"
    run "chgrp team87 #{var_run_path}/js && chmod g+w #{var_run_path}/js"
    
    # /public/css - the server needs write access...
    run "rm -rf #{var_run_path}/css"
    run "mv #{release_path}/public/css #{var_run_path}/css"
    run "ln -nfs #{var_run_path}/css #{release_path}/public/css"
    run "chgrp team87 #{var_run_path}/css && chmod g+w #{var_run_path}/css"
  end
  
  desc 'Set the permissions of the filesystem so that others in the team can deploy'
  task :fix_perms do
    run "chmod g+w #{release_path}"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:symlink', 'deploy:fix_perms'