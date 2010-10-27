#!/usr/bin/env ruby

$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/lib" )
require 'martsearch'

builder = MartSearch::IndexBuilder.new()
builder.fetch_datasets()
builder.process_datasets()