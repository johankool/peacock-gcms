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
NumberCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## The number markup directive matches the first number found in a field, 
# ## and returns only that component. If no number is detected, the result 
# ## is empty. A non-empty number may be subject to further formatting consisting 
# ## of a form attribute whose value may be numeric, ordinal or roman to format 
# ## it as a simple number (the default), an ordinal number (1st, 2nd, 3rd etc) 
# ## or roman (i, ii, iii, iv etc). The text-case can also apply to capitalize 
# ## the roman numbers for instance. The other normal formatting rules apply 
# ## too (font-style, ...). When used in a conditional, number tests if 
# ## there is a number present, allowing conditional formatting.
# cs-number =
#   element cs:number {
#     formatting,
#     attribute variable { "edition" | "volume" | "issue" | "number" | "number-of-volumes" },
#     attribute form { "numeric" | "ordinal" | "roman" }?
#   }

from FormattingCSLObject import FormattingCSLObject

class NumberCSLObject(FormattingCSLObject):
    def __init__(self, attrs):
        super(NumberCSLObject, self).__init__(attrs)
        self.variable = ""
        if "variable" in attrs:
            self.variable = attrs["variable"]
        self.form = ""
        if "form" in attrs:
            self.form = attrs["form"]
    
    def formatted_text(self, reference, options):
         # TODO delimiter?
         # TODO use form attribute
         
        text = ""
        variable = self.variable.replace("-","_") # python can't have - in attributes, replaced by _
        if not isinstance(reference, str): # FIXME this check should not be needed
            text = unicode(reference.__getattribute__(variable))
        if text == "":
            return ""
        # else:
        #     print "n"+text+"n"
        return self.format(text) # "{number "+self.variable+"}")
    
    def xml(self):
        attributes = ""
        if self.variable <> "":
            attributes += " variable=\"%s\"" % (quoteattr(self.variable),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        return "<number%s%s/>\n" % (attributes, FormattingCSLObject.xml(self))

class NumberCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()