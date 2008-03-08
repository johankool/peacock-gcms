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
MacroTextCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

#   cs-text =
#     element cs:text {
#       formatting,
#       ([...]
#          | attribute macro { token }),
#         attribute form { "short" | "long" }?)
#        | [...])
#     }

from TextCSLObject import TextCSLObject
from FormattingCSLObject import FormattingCSLObject

class MacroTextCSLObject(TextCSLObject):
    def __init__(self, attrs):
        super(MacroTextCSLObject, self).__init__(attrs)
        self.macro = attrs["macro"]
        self.form = ""
        if "form" in attrs:
            self.form = attrs["form"]
        self.root = None
    
    def formatted_text(self, reference, options):
        # find macro
        macro = self.root.macro(self.macro)
        text = macro.formatted_text(reference, options)
        if text == "":
            return ""
        return self.format(text)
    
    def xml(self):
        attributes = " macro=\"%s\"" % (quoteattr(self.macro),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        return "<text%s%s/>\n" % (attributes, FormattingCSLObject.xml(self))


class MacroTextCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()