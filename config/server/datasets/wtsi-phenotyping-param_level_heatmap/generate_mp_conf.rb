#!/usr/bin/env ruby

MP_TOP    = 'MP:0000001'
CURR_PATH = File.expand_path(File.dirname(__FILE__))

$:.unshift("#{CURR_PATH}/../../../../lib")
require 'martsearch'

# First hook up to the MIG database to determine which MP terms the 
# phenotyping tests could potentially map to...

MIG_DB = Sequel.connect(
  :adapter  => 'oracle',
  :database => 'migp_ha.world',
  :user     => 'mig',
  :password => 'sau5age5',
  :test     => true
)

MIG_DB[:htgt_param_possible_mp_terms].each do |row|
  
end




