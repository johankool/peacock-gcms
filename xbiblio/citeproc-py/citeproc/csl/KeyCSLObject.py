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
KeyCSLObject.py

Created by Johan Kool on 2008-02-19.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest


class KeyCSLObject:
    def __init__(self, attrs):
        self.variable = ""
        if "variable" in attrs:
            self.variable = attrs["variable"]
        self.macro = ""
        if "macro" in attrs:
            self.macro = attrs["macro"]
        self.sort = "ascending" # default
        if "sort" in attrs:
            self.sort = attrs["sort"]
    
    def xml(self):
        attributes = ""
        if self.variable <> "":
             attributes += " variable=\"%s\"" % (quoteattr(self.variable),)
        if self.macro <> "":
              attributes += " macro=\"%s\"" % (quoteattr(self.macro),)
        if self.sort <> "":
            attributes += " sort=\"%s\"" % (quoteattr(self.sort),)
        return "<key%s/>\n" % (attributes,)

class KeyCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()