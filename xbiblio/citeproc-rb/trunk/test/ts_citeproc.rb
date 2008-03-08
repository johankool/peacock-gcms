#! /usr/bin/env ruby
# test suite for citeproc-rb

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'tc_reference'
require 'tc_reference_list'
require 'tc_citation_style'
