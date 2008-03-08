#! /usr/bin/env python

from citeproc import CiteProcessor

class TestCitationStyle:
    # base can be local or remote; should automaticallly
    # look at remote if a style not found locally
    base = "http://xbiblio.sourceforge.net/csl/repo/"

    def test_list():
        # method to list available styles
        list = citation_styles
        assert list

    def test_create():
        csl = CitationStyle("apa", "en")
        assert csl.info.short_title == "APA"
        assert csl.bibliography.sort_order == "author-date"
        assert csl.bibliography.item_layout.types["book"][2].name == "title"

    def test_create_first():
        csl = CitationStyle(name="chicago", variant="note_nobib", language="en")
        assert csl.info.short_title == "Chicago"
        assert csl.citation.item_layout.first.types["book"][2].name == "title"
 
