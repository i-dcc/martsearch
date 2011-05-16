# encoding: utf-8

load 'deploy' if respond_to?(:namespace) # cap2 differentiator

require 'rubygems'
require 'railsless-deploy'
require 'bundler/capistrano'

load 'config/deploy'

set :stages, ['staging', 'production']
set :default_stage, 'staging'

require 'capistrano/ext/multistage'

PATH = File.expand_path(File.dirname(__FILE__))
require "#{PATH}/config/deploy/natcmp.rb"
require "#{PATH}/config/deploy/gitflow.rb"
