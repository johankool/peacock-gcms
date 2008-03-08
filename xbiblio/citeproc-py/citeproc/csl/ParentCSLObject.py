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
ParentCSLObject.py

Created by Johan Kool on 2008-02-16.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest


class ParentCSLObject(object):
    def __init__(self, attrs):
        super(ParentCSLObject, self).__init__(attrs)
        self.children = [] # can be either CSLObjects or strings!
    
    def children(self):
        return self.children
    
    def xml(self):
        text = ""
        if len(self.children) == 0:
            return text
        
        for child in self.children:
            if isinstance(child, str) or isinstance(child, unicode):
                text += escape(child)
            else:
                text += child.xml()
        
        # add four spaces for each line for identation
        # should not indent when first or last child is string (unicode actually)
        if not isinstance(self.children[0], str) and not isinstance(self.children[0], unicode):
            text = "    " + "\n    ".join(text.splitlines(False))
        return text

class ParentCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()