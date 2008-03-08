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
CSLDocumentHandler.py

Created by Johan Kool on 2008-02-17.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest
import string

from xml.sax import handler, make_parser

from InfoCSLObject import InfoCSLObject
from InfoIDCSLObject import InfoIDCSLObject
from InfoTitleCSLObject import InfoTitleCSLObject
from InfoUpdatedCSLObject import InfoUpdatedCSLObject
from InfoAuthorCSLObject import InfoAuthorCSLObject
from InfoNameCSLObject import InfoNameCSLObject
from InfoEmailCSLObject import InfoEmailCSLObject
from InfoCategoryCSLObject import InfoCategoryCSLObject
from InfoContributorCSLObject import InfoContributorCSLObject
from InfoLinkCSLObject import InfoLinkCSLObject
from InfoPublishedCSLObject import InfoPublishedCSLObject
from InfoRightsCSLObject import InfoRightsCSLObject
from InfoSourceCSLObject import InfoSourceCSLObject
from InfoSummaryCSLObject import InfoSummaryCSLObject
from CitationCSLObject import CitationCSLObject
from BibliographyCSLObject import BibliographyCSLObject
from MacroCSLObject import MacroCSLObject
from ChooseCSLObject import ChooseCSLObject
from IfCSLObject import IfCSLObject
from DateCSLObject import DateCSLObject
from DatePartCSLObject import DatePartCSLObject
from GroupCSLObject import GroupCSLObject
from LabelCSLObject import LabelCSLObject
from LayoutCSLObject import LayoutCSLObject
from NameCSLObject import NameCSLObject
from NamesCSLObject import NamesCSLObject
from NumberCSLObject import NumberCSLObject
from SubstituteCSLObject import SubstituteCSLObject
from MacroTextCSLObject import MacroTextCSLObject
from TermTextCSLObject import TermTextCSLObject
from ValueTextCSLObject import ValueTextCSLObject
from VariableTextCSLObject import VariableTextCSLObject
from ParentCSLObject import ParentCSLObject
from StyleCSLObject import StyleCSLObject
from OptionCSLObject import OptionCSLObject
from SortCSLObject import SortCSLObject
from KeyCSLObject import KeyCSLObject

class ParsingError(Exception): pass

# TODO check if also works if csl-namespace is not the default

class CSLDocumentHandler(handler.ContentHandler):
    def __init__(self):
        self.level = -1
        self.buffer = u""
        self.elements = []
        self.isInInfo = False
    
    def startDocument(self):
        pass
    
    def endDocument(self):
        pass
    
    def startElement(self, name, attrs):
        if string.strip(self.buffer) <> "":
            # insert as child to parent node
            if isinstance(self.elements[self.level], ParentCSLObject):
                self.elements[self.level].children.append(self.buffer)
            else:
                raise ParsingError, "Content (text) found for tag " + name + " which cannot have any."
        self.buffer = u""
        
        element = u""
        self.level += 1
        if name == "info":
            element = InfoCSLObject(attrs)
            self.isInInfo = True
        elif name == "id":
            element = InfoIDCSLObject(attrs)
        elif name == "title":
            element = InfoTitleCSLObject(attrs)
        elif name == "updated":
            element = InfoUpdatedCSLObject(attrs)
        elif name == "author":
            element = InfoAuthorCSLObject(attrs)
        elif name == "email":
            element = InfoEmailCSLObject(attrs)
        elif name == "category":
            element = InfoCategoryCSLObject(attrs)
        elif name == "contributor":
            element = InfoContributorCSLObject(attrs)
        elif name == "link":
            element = InfoLinkCSLObject(attrs)
        elif name == "published":
            element = InfoPublishedCSLObject(attrs)
        elif name == "rights":
            element = InfoRightsCSLObject(attrs)
        elif name == "source":
            element = InfoSourceCSLObject(attrs)
        elif name == "summary":
            element = InfoSummaryCSLObject(attrs)
        elif name == "citation":
            element = CitationCSLObject(attrs)
        elif name == "bibliography":
            element = BibliographyCSLObject(attrs)
        elif name == "macro":
            element = MacroCSLObject(attrs)
        elif name == "choose":
            element = ChooseCSLObject(attrs)
        elif name == "if":
            element = IfCSLObject(attrs)
        elif name == "else-if":
            element = IfCSLObject(attrs)
            element.if_type = "else-if"
        elif name == "else":
            element = IfCSLObject(attrs)
            element.if_type = "else"
        elif name == "date":
            element = DateCSLObject(attrs)
        elif name == "date-part":
            element = DatePartCSLObject(attrs)
            element.root = self.root
        elif name == "group":
            element = GroupCSLObject(attrs)
        elif name == "label":
            element = LabelCSLObject(attrs)
            element.root = self.root
            element.parent = self.elements[self.level-1]
        elif name == "layout":
            element = LayoutCSLObject(attrs)
        elif name == "option":
            element = OptionCSLObject(attrs)
        elif name == "sort":
            element = SortCSLObject(attrs)
        elif name == "key":
            element = KeyCSLObject(attrs)
        elif name == "name": 
            if self.isInInfo:
                element = InfoNameCSLObject(attrs)
            else:
                element = NameCSLObject(attrs)
                element.root = self.root
        elif name == "names":
            element = NamesCSLObject(attrs)
        elif name == "number":
            element = NumberCSLObject(attrs)
        elif name == "substitute":
            element = SubstituteCSLObject(attrs)
        elif name == "text":
            if "macro" in attrs:
                element = MacroTextCSLObject(attrs)
                element.root = self.root
            elif "term" in attrs:
                element = TermTextCSLObject(attrs)
                element.root = self.root
            elif "value" in attrs:
                element = ValueTextCSLObject(attrs)
            elif "variable" in attrs:
                element = VariableTextCSLObject(attrs)
            else:
                raise ParsingError, "Invalid text tag encountered. Required tags missing."
        elif name == "style":
            element = StyleCSLObject(attrs)
            self.root = element #this might break
        # elif name in self.ignoredTags:
        #     print "Ignoring tag: " + name
        #     self.level -= 1
        #     return
        else:
           raise ParsingError, "Invalid tag encountered. Unknown name: " + name
        
        #print "Adding tag: " + name
        if name <> "style":
            # insert as child to parent node
            if isinstance(self.elements[self.level-1], ParentCSLObject):
                self.elements[self.level-1].children.append(element)
            else:
                raise ParsingError, "Tag " + name +" found as child of tag" + str(self.elements[self.level-1]) + " which cannot have children."
        # insert into array that keeps track of our path
        self.elements.insert(self.level, element)
    
    def endElement(self, name):
        if string.strip(self.buffer) <> "":
            # insert as child to parent node
            if isinstance(self.elements[self.level], ParentCSLObject):
                self.elements[self.level].children.append(self.buffer)
            else:
                raise ParsingError, "Content (text) found for tag " + name + " which cannot have any."
        self.buffer = u""
        
        if name == "info":
            self.isInInfo = False
        #print "Closing tag: " + name
        self.elements.pop(self.level)
        self.level -= 1

    
    def characters(self, data):
        self.buffer += data
        
    def root(self):
        return self.root

def test(inFileName):
    # TODO move this method to proper test
    # Create an instance of the Handler.
    handler = CSLDocumentHandler()
    # Create an instance of the parser.
    parser = make_parser()
    # Set the content handler.
    parser.setContentHandler(handler)
    inFile = open(inFileName, 'r')
    # Start the parse.
    parser.parse(inFile)                                        # [10]
    # Alternatively, we could directly pass in the file name.
    #parser.parse(inFileName)
    inFile.close()

def main():
    # TODO remove this method
    # csl = '/Users/jkool/Developer/Biblio2/csl/styles/asa.csl'
    #  print csl
    # test(csl)
    args = sys.argv[1:]
    if len(args) != 1:
        print 'usage: python test.py infile.xml'
        sys.exit(-1)
    test(args[0])

if __name__ == '__main__':
    main()


class CSLDocumentHandlerTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()