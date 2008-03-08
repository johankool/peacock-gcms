#! /usr/bin/env python

from citeproc import CiteProcessor

class TestReference:
    
    def test_setup():
        data = {"title":"Some Title", "year":"1999"}    
    
    def test_reference_create():
        ref = Reference(title=data["title"], year=data["year"])
        assert ref.title == "Some Title"
    
