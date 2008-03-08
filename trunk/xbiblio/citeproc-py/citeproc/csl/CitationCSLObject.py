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
CitationCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

from ParentCSLObject import ParentCSLObject
from LayoutCSLObject import LayoutCSLObject
from OptionCSLObject import OptionCSLObject

class CitationCSLObject(ParentCSLObject):
    def __init__(self, attrs):
        super(CitationCSLObject, self).__init__(attrs)
    
    def formatted_text_for_citationgroup(self, citationGroup, references):
        # gather options
        options = {}
        options["kind"] = "citation"
        for child in self.children:
            if isinstance(child, OptionCSLObject):
                options[child.name] = child.value
        
        for child in self.children:
            if isinstance(child, LayoutCSLObject):
                # format text and pass option set for citation
                return child.formatted_text_for_citationgroup(citationGroup, references, options)
        
        raise Exception, "No layout tag found in citation tag."
        
    def xml(self):
        return "<citation>\n%s\n</citation>\n" % (ParentCSLObject.xml(self),)

    
class CitationCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()