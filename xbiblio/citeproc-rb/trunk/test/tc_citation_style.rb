#! /usr/bin/env ruby
require File.dirname(__FILE__) + '/../lib/citeproc'
require 'test/unit'

class TestCitationStyle < Test::Unit::TestCase
  
  include CiteProc

  # base can be local or remote; should automaticallly
  # look at remote if a style not found locally, and 
  # then cache the style
  base = "http://www.users.muohio.edu/darcusb/citations/csl/styles/"

  def setup
    @csl = CitationStyle.new("apa", "en")
  end

  def test_list_styles
    # list available styles
    list = list_styles
    assert_not_null(list)
  end
    
  def test_create_style
    assert_not_nil(@csl.info.title)
  end

  def test_csl_info
    assert(@csl.info.short_title == "APA")
  end

  def test_bib_item_layout
    assert(@csl.bibliography.sort_order == "author-date")
    assert(@csl.bibliography.item_layout.types["book"][2].name == "title")
  end
  
  def test_citation_item_layout
    assert(@csl.citation.sort_order == "author-date")
    assert(@csl.citation.item_layout.types["book"][0].name == "author")
  end

end

