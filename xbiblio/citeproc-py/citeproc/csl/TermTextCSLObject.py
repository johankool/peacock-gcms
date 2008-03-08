#!/usr/bin/env python
# encoding: utf-8
# 
# CiteProc-Py 
# Generates citations and references.
# 
# Copyright 2006, 2008 Johan Kool
# 
# This file is part of CiteProc-Py.
# 
# CiteProc-Py is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# CiteProc-Py is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with CiteProc-Py.  If not, see <http://www.gnu.org/licenses/>.
# 
# Contact the author(s) if you wish to use CiteProc-Py under another
# license, e.g. for inclusion in (commercial) closed source applications.
# It is explicitly forbidden to use CiteProc-Py in such applications
# under the GPL license.
#

"""
TermTextCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

#   cs-text =
#     element cs:text {
#       formatting,
#       ([...] | (attribute term { cs-terms },
#           attribute form { cs-term-forms }?,
#           include-period,
#           attribute plural { xsd:boolean }?)
#        | [...])
#     }

from TextCSLObject import TextCSLObject
from FormattingCSLObject import FormattingCSLObject

from xml.etree.ElementTree import ElementTree

class TermTextCSLObject(TextCSLObject):
    def __init__(self, attrs):
        super(TermTextCSLObject, self).__init__(attrs)
        self.root = None
        self.term = attrs["term"]
        self.form = ""
        if "form" in attrs:
            self.form = attrs["form"]
        self.include_period = ""
        if "include-period" in attrs: # TODO isn't this one required?
            self.include_period = attrs["include-period"]
        self.plural = ""
        if "plural" in attrs:
            self.plural = attrs["plural"]
    
    def formatted_text(self, reference, options):
        # TODO delimiter?    
        text = self.root.term(name=self.term, form=self.form, plural=self.plural)
        #print "term with name "+self.term+" = "+text+"."
        if text == "": # TODO should raise exception?
            return ""
        if self.include_period == "true":
            text += "."
        return self.format(text)
    
    def xml(self):
        attributes = " term=\"%s\"" % (quoteattr(self.term),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        if self.include_period <> "":
            attributes += " include-period=\"%s\"" % (quoteattr(self.include_period),)
        if self.plural <> "":
            attributes += " plural=\"%s\"" % (quoteattr(self.plural),)
        return "<text%s%s/>\n" % (attributes, FormattingCSLObject.xml(self))

class TermTextCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()