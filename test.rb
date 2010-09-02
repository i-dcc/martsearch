#!/usr/bin/env ruby -w

require 'lib/martsearch'

builder = MartSearch::IndexBuilder.new()
builder.build_index()