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
NamesCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## Names is a data type holding a text of authors, editors, or translators.
# div {
#   names-attributes =
#     formatting,
#     delimiter,
#     attribute variable {
#       list { cs-names+ }
#     }
#   names = element cs:names { names-attributes, (name & name-label*), substitute? }
#   
#   ## Short version of "names" element, without children, allowed in <substitute>
#   names-short = element cs:names { names-attributes }
#   name =
#     element cs:name {
#       formatting,
#       
#       ## Indicates long (first name + last name, for Western names) or short
#       ## (last name only, for Western names) form of name. Default is long
#       ## form
#       attribute form { "long" | "short" }?,
#       
#       ## Controls appearance of "and"/"%". To disable, do not specify.
#       attribute and { "text" | "symbol" }?,
#       
#       ## Delimiter between names (delimiter between variables is on <names>
#       ## tag, where it should be). This is ", " in "J. Doe, S. Smith."
#       delimiter,
#       
#       ## The "always" value means that result is "J. Doe, and T. Timmons,"
#       ## while default behavior would be "J. Doe and T. Timmons," but "J. Doe,
#       ## S. Smith, and T. Timmons" (note comma preceding 'and').
#       attribute delimiter-precedes-last { "always" | "never" }?,
#       
#       ## Sets the first-author name order to correspond to the sort order of
#       ## the bibliography; e.g. Doe, John (name-as-sort-order) vs. John Doe (w/o
#       ## attribute).
#       attribute name-as-sort-order { "first" | "all" }?,
#       
#       ## The delimiter for personal name parts where sort order differs from 
#       ## display order (for example, in standard Western names). This is the
#       ## ", " in "Doe, John."
#       attribute sort-separator { text }?,
#       
#       ## Indicates whether given name parts ought to be given as initials
#       ## (e.g., J. K. Rowling) and the text to follow each initial.
#       attribute initialize-with { text }?
#     }
#   
#   ## Similar to label as below, but inherits variable from <names> tag
#   name-label = element cs:label { label-primitives }
#   
#   ## Substitutions, if the name does not exist
#   substitute = element cs:substitute { (names-short | cs-element)+ }
#   cs-names =
#     "author"
#     | "editor"
#     | "translator"
#     | "recipient"
#     | "interviewer"
#     | "publisher"
#     | "series-editor"
#     | "composer"
#     | "original-publisher"
#     | "original-author"
#     | 
#       ## to be used when citing a section of a book, for example, to distinguish the author 
#       ## proper from the author of the containing work
#       "container-author"
#     | 
#       ## a more generic analog for series-editor
#       "collection-editor"
# }

from FormattingCSLObject import FormattingCSLObject
from DelimiterCSLObject import DelimiterCSLObject
from ParentCSLObject import ParentCSLObject
from NameCSLObject import NameCSLObject

class NamesCSLObject(FormattingCSLObject, DelimiterCSLObject, ParentCSLObject):
    def __init__(self, attrs):
        super(NamesCSLObject, self).__init__(attrs)
        self.variable = attrs["variable"]
    
    def formatted_text(self, reference, options):
        formatted_text = []
        for child in self.children:
            if isinstance(child, NameCSLObject):
                names = self.namesForReference(reference)
                # if no names return nothing
                # TODO should take substitute with text into account here!!
                if len(names) == 0:
                    return "";
                formatted_text.append(child.formatted_text(names, options))
            else:
                formatted_text.append(child.formatted_text(reference, options))
        if "".join(formatted_text) == "":
            return ""
        text = self.group(formatted_text)
        return self.format(text)
    
    def namesForReference(self, reference):
        names = []
        variables = self.variable.split(" ")
        for variable in variables:
            variable = variable.replace("-","_")+"s" # python can't have - in attributes, replaced by _
            names += reference.__getattribute__(variable)
        if len(names) == 0:
            # TODO look for substitute
            pass
        return names
        
    
    def xml(self):
        attributes = " variable=\"%s\"" % (quoteattr(self.variable),)
        if len(self.children) == 0:
            return "<names%s%s%s/>\n" % (attributes, FormattingCSLObject.xml(self), DelimiterCSLObject.xml(self),)
        else:
            return "<names%s%s%s>\n%s\n</names>\n" % (attributes, FormattingCSLObject.xml(self), DelimiterCSLObject.xml(self), ParentCSLObject.xml(self))
    
class NamesCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()