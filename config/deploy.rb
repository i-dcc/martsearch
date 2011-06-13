# encoding: utf-8

set :application,       'ikmc_portal'
set :repository,        'git@github.com:i-dcc/martsearch.git'
set :revision,          'origin/ikmc_portal'

# set :domain,            'htgt.internal.sanger.ac.uk'
set :domain,            'localhost'
set :ssh_flags,         '-p 10027'

set :service_user,      'team87'
set :bnw_env,           '/software/bin/perl -I/software/team87/brave_new_world/lib/perl5 -I/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi /software/team87/brave_new_world/bin/htgt-env.pl --live' 
set :bundle_cmd,        "#{bnw_env} bundle"
set :web_command,       "#{bnw_env} sudo -u #{service_user} /software/team87/brave_new_world/services/apache2-ruby19"

##
## Environments
##

task :production do
  set :deploy_to, "/nfs/team87/services/vlad_managed_apps/production/#{application}"
end

task :staging do
  set :deploy_to, "/nfs/team87/services/vlad_managed_apps/staging/#{application}"
end

##
## Tasks
##

desc "Full deployment cycle: update, bundle, symlink, restart, cleanup"
task :deploy => %w[
  vlad:update
  vlad:bundle:install
  vlad:symlink_config
  vlad:start_app
  vlad:fix_perms
  vlad:cleanup
]

namespace :vlad do
  desc "Symlinks the configuration files"
  remote_task :symlink_config, :roles => :app do
    %w[ ols_database.yml ].each do |file|
      run "ln -s #{shared_path}/config/#{file} #{current_path}/config/#{file}"
    end
  end
  
  desc "Fixes the permissions on the 'current' deployment"
  remote_task :fix_perms, :roles => :app do
    fix_perms = "find #{current_path}/ -user #{`whoami`.chomp}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
    run fix_perms
  end
end
