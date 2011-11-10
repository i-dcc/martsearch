# encoding: utf-8

set :application,       'wtsi_portal'
set :repository,        'git@github.com:i-dcc/martsearch.git'
set :revision,          'origin/wtsi_portal'

set :domain,            'htgt.internal.sanger.ac.uk'
set :service_user,      'team87'
set :service_group,     'team87'
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
  vlad:symlink_ols_cache
  vlad:symlink_wtsi_phenotyping_heatmap
  vlad:symlink_abr_phenotyping_pages
  vlad:start_app
  vlad:fix_perms
  vlad:cleanup
]

# only ever run this ONCE for a server/config
task :setup_new_instance => %w[
  vlad:setup
  vlad:update
  vlad:bundle:install
  vlad:symlink_config
  vlad:symlink_wtsi_phenotyping_heatmap
  vlad:symlink_abr_phenotyping_pages
  vlad:fix_perms
]

namespace :vlad do
  desc "Symlinks the ols_cache directory into tmp/ols_cache"
  remote_task :symlink_ols_cache, :roles => :app do
    run "ln -nfs #{shared_path}/ols_cache #{current_path}/tmp/ols_cache"
  end

  desc "Symlinks the WTSI Phenotyping Heatmap"
  remote_task :symlink_wtsi_phenotyping_heatmap, :roles => :app do
    run "ln -nfs /software/team87/brave_new_world/data/generated/pheno_overview.xls #{current_path}/tmp/pheno_overview.xls"
  end

  desc "Symlink the ABR Phenotyping Pages"
  remote_task :symlink_abr_phenotyping_pages, :roles => :app do
    run "mv #{current_path}/tmp/pheno_abr #{current_path}/tmp/pheno_abr_from_git"
    run "ln -nfs /software/team87/brave_new_world/data/phenotyping-abr-pages #{current_path}/tmp/pheno_abr"
  end

  desc "Fixes the permissions on the 'current' deployment"
  remote_task :fix_perms, :roles => :app do
    fix_perms_you     = "find #{deploy_to}/ -user #{`whoami`.chomp}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
    fix_perms_service = "sudo -u #{service_user} find #{releases_path}/ -user #{service_user}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
    chgrp             = "chgrp -R #{service_group} #{current_path}"

    run fix_perms_you
    run fix_perms_service
    run chgrp
  end

  task :setup do
    Rake::Task['vlad:setup_shared'].invoke
  end

  remote_task :setup_shared, :roles => :app do
    commands = [ "umask #{umask}" ]

    run commands.join(' && ')
  end

  Rake.clear_tasks('vlad:start_app')
  remote_task :start_app, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

