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
VariableTextCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

#   cs-text =
#     element cs:text {
#       formatting,
#       ((((attribute variable {
#             list { variables+ }
#           }
#           & delimiter)
#          | [...])
#     }

from reference import Reference

from TextCSLObject import TextCSLObject
from DelimiterCSLObject import DelimiterCSLObject
from FormattingCSLObject import FormattingCSLObject

class VariableTextCSLObject(TextCSLObject, DelimiterCSLObject):
    def __init__(self, attrs):
        super(VariableTextCSLObject, self).__init__(attrs)
        self.variable = ""
        if "variable" in attrs:
            self.variable =  attrs["variable"]
        self.form = ""
        if "form" in attrs:
            self.form =  attrs["form"]
    
    def formatted_text(self, reference, options):
        # TODO use form attribute properly
        variables = []
        for variable in self.variable.split(" "):
            variable = variable.replace("-","_") # python can't have - in attributes, replaced by _
            if variable in reference.__dict__.keys():
                variables.append(reference.__getattribute__(variable))
            if self.form <> "":
                print "Ignored form "+self.form+" for variable "+variable+"."
        
        text = self.group(variables)
        return self.format(text)
    
    def xml(self):
        attributes = ""
        if self.variable <> "":
            attributes += " variable=\"%s\"" % (quoteattr(self.variable),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        return "<text%s%s%s/>\n" % (attributes, DelimiterCSLObject.xml(self), FormattingCSLObject.xml(self))

class VariableTextCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()