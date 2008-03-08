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
GroupCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## The cs:group element. Used to provide delimiters and a common prefix/suffix. If
# ## an item has no fields contained in a group, any <text term="(term)"> elements
# ## will not be printed.
# div {
#   group =
#     element cs:group {
#       formatting,
#       delimiter,
#       attribute class { token }?,
#       cs-element+
#     }
# }

from FormattingCSLObject import FormattingCSLObject
from DelimiterCSLObject import DelimiterCSLObject
from ParentCSLObject import ParentCSLObject

from TermTextCSLObject import TermTextCSLObject
from ValueTextCSLObject import ValueTextCSLObject
from LabelCSLObject import LabelCSLObject

class GroupCSLObject(FormattingCSLObject, DelimiterCSLObject, ParentCSLObject):
    def __init__(self, attrs):
        super(GroupCSLObject, self).__init__(attrs)
        # TODO figure out what class does/means
        self.class_attr = ""
        if "class" in attrs:
            self.class_attr = attrs["class"]
    
    def formatted_text(self, reference, options):
        formatted_text = []
        got_text = False
        for child in self.children:
            text = child.formatted_text(reference, options)
            if text <> "":
                if not (isinstance(child, TermTextCSLObject) or isinstance(child, ValueTextCSLObject) or isinstance(child, LabelCSLObject)):
                    got_text = True
            formatted_text.append(text)
        if not got_text: # text-term|value should not be printed if no value is returned from other children
            return ""
        text = self.group(formatted_text)
        return self.format(text)
    
    def xml(self):
        attributes = ""
        if self.class_attr <> "":
            attributes += " class=\"%s\"" % (quoteattr(self.class_attr),)
        return "<group%s%s%s>\n%s\n</group>\n" % (attributes,  FormattingCSLObject.xml(self), DelimiterCSLObject.xml(self), ParentCSLObject.xml(self))
    

class GroupCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()