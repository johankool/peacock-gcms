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
LabelCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## The label element is used to print text terms that depend on document content
# ## for pluralization. For labeling pages, this is preferable, as pages may be
# ## either singular or plural (p. or pp.)
# div {
#   label =
#     element cs:label {
#       label-primitives,
#       attribute variable { "page" | "locator" }
#     }
#   label-primitives =
#     formatting,
#     include-period?,
#     attribute form { cs-term-forms }
# }

from FormattingCSLObject import FormattingCSLObject
from NamesCSLObject import NamesCSLObject

class LabelCSLObject(FormattingCSLObject):
    def __init__(self, attrs): # TODO what is proper default for include-period?
        super(LabelCSLObject, self).__init__(attrs)
        # root is used to fetch the term from the locales file
        self.root = None
        # if label is a name-label we need to ask the parent for the variable, parent can only be a names tag in this case, otherwise we use the variable set
        self.parent = None
        self.variable = ""
        if "variable" in attrs:
            self.variable = attrs["variable"]
        self.include_period = ""
        if "include-period" in attrs:
            self.include_period = attrs["include-period"]
        self.form = ""
        if "form" in attrs:
            self.form = attrs["form"]
    
    def formatted_text(self, reference, options):
        if isinstance(self.parent, NamesCSLObject):
            variable = self.parent.variable
        else:
            variable = self.variable
        # find out if we are plural or not
        plural = reference.is_plural(variable+"s")
        text = self.root.term(name=variable, form=self.form, plural=plural)
        if text == u"":
            return u""
        if self.include_period == "true":
            if text[:1] <> ".": # do not add period if period already present
                text += "."
        return self.format(text)
    
    def xml(self):
        attributes = ""
        if self.variable <> "":
            attributes += " variable=\"%s\"" % (quoteattr(self.variable),)
        if self.include_period <> "":
            attributes += " include-period=\"%s\"" % (quoteattr(self.include_period),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        return "<label%s%s/>\n" % (attributes, FormattingCSLObject.xml(self))
    

class LabelCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()