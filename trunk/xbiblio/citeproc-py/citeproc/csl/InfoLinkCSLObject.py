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
InfoLinkCSLObject.py

Created by Johan Kool on 2008-02-18.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

class InfoLinkCSLObject:
    def __init__(self, attrs):
        self.href = attrs["href"]
        self.rel = ""
        if "rel" in attrs:
            self.rel = attrs["rel"]
        self.type = ""
        if "type" in attrs:
            self.type = attrs["type"]
        self.hreflang = ""
        if "hreflang" in attrs:
            self.hreflang = attrs["hreflang"]
        self.title = ""
        if "title" in attrs:
            self.title = attrs["title"]
        self.length = ""
        if "length" in attrs:
            self.length = attrs["length"]
    
    def xml(self):
        attributes = " href=\"%s\"" % (quoteattr(self.href),)
        if self.rel <> "":
            attributes += " rel=\"%s\"" % (quoteattr(self.rel),)
        if self.type <> "":
            attributes += " type=\"%s\"" % (quoteattr(self.type),)
        if self.hreflang <> "":
            attributes += " hreflang=\"%s\"" % (quoteattr(self.hreflang),)
        if self.title <> "":
            attributes += " title=\"%s\"" % (quoteattr(self.title),)
        if self.length <> "":
            attributes += " length=\"%s\"" % (quoteattr(self.length),)
        return "<link%s/>\n" % (attributes,)


class InfoLinkCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()