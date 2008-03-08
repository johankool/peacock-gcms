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
BibliographyCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

import operator

from ParentCSLObject import ParentCSLObject
from LayoutCSLObject import LayoutCSLObject
from OptionCSLObject import OptionCSLObject
from SortCSLObject import SortCSLObject

class BibliographyCSLObject(ParentCSLObject):
    def __init__(self, attrs):
        super(BibliographyCSLObject, self).__init__(attrs)
        
    def formatted_text_for_bibliography(self, references):
        """Uses the passed references to create the formatted text (in html) to be returned.
        
        Returns string."""
        
        # gather options
        options = {}
        options["kind"] = "reference"
        for child in self.children:
            if isinstance(child, OptionCSLObject):
                options[child.name] = child.value
        
        # gather sort instructions
        sort_keys = []
        for child in self.children:
            if isinstance(child, SortCSLObject):
                for sortchild in child.children:
                    if sortchild.variable <> "":
                        sort_keys.append({"variable":sortchild.variable, "sort":sortchild.sort}) # FIXME sort can also be by macro(?) 
                    else:
                        print "Sorting on macro not yet supportted"
        
        # perform sort
        if len(sort_keys) > 0:
            print sort_keys
            references.sort(ReferenceSorter(sort_keys))
        
        for child in self.children:
            if isinstance(child, LayoutCSLObject):
                return child.formatted_text_for_references(references, options)
        
        raise Exception, "No layout tag found in bibliography tag."
    
    def xml(self):
        return "<bibliography>\n%s\n</bibliography>\n" % (ParentCSLObject.xml(self),)


class ReferenceSorter:
    def __init__(self, sort_keys):
        self.sort_keys = sort_keys
        
    def __call__(self, x, y):
        for sort_key in self.sort_keys:
            variable = sort_key["variable"].replace("-","_") # python can't have - in attributes, replaced by _
            if sort_key["sort"] == "ascending":
                result = cmp(getattr(x, variable), getattr(y, variable))
            else:
                result = cmp(getattr(y, variable), getattr(x, variable))
            if result <> 0:
                return result
        return 0


class BibliographyCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()