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
StyleCSLObject.py

Created by Johan Kool on 2008-02-08.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest
import string
import xml.dom.minidom

from ParentCSLObject import ParentCSLObject
from CitationCSLObject import CitationCSLObject
from BibliographyCSLObject import BibliographyCSLObject
from MacroCSLObject import MacroCSLObject

class StyleCSLObject(ParentCSLObject):
    def __init__(self, attrs):
        super(StyleCSLObject, self).__init__(attrs)
        self.xmlns = attrs["xmlns"]
        self.style_class = attrs["class"]
        self.lang = "en"
        if "xml:lang" in attrs:
            self.lang = attrs["xml:lang"]
        self.formatted_textForBibliography = ""
        self.formatted_text_for_citationgroups = []
        
        # TODO find out user's locale automatically?
        # TODO let user select locale
        # TODO include locales in package
        document = "../../csl/locales/locales-en-US.xml"
        terms_root = xml.dom.minidom.parse(document)
        terms_tag = terms_root.getElementsByTagName("terms")[0]
        locale_tag = terms_tag.getElementsByTagName("locale")[0]
        self.term_tags = locale_tag.getElementsByTagName("term")
        
    def formatText(self, citationGroups, references):
        # format text for each citation group 
        self.formatted_text_for_citationgroups = []
        for child in self.children:
            if isinstance(child, CitationCSLObject):
                for citationGroup in citationGroups:
                    self.formatted_text_for_citationgroups.append(child.formatted_text_for_citationgroup(citationGroup, references))
        
        # format text for bibliography
        self.formatted_textForBibliography = u""
        for child in self.children:
            if isinstance(child, BibliographyCSLObject):
                self.formatted_text_for_bibliography = child.formatted_text_for_bibliography(references)
    
    def formatted_text_for_citationgroup_at_index(self, index):
        return self.formatted_text_for_citationgroups[index]
    
    def formatted_textForBibliography(self):
        return self.formatted_textForBibliography
    
    # TODO option to get bibliography entry per reference (e.g. when needed to wrap it into html)
    
    def macro(self, name):
        for child in self.children:
            if isinstance(child, MacroCSLObject):
                if child.name == name:
                    return child
        
        raise Exception, "No macro found with name " + name
    
    def term(self, name, form="", plural=""):        
        # FIXME replicated code, this section should be possible more compact
        # FIXME term with same name can occur with and without multiple and single tags, for example "edition"
        for term_tag in self.term_tags:
            if term_tag.attributes["name"].value == name:
                if "form" in term_tag.attributes.keys():
                    if term_tag.attributes["form"].value == form: 
                        if plural == "true":
                            children = term_tag.getElementsByTagName("multiple")
                            if len(children) > 0:
                                return unicode(self.getText(children[0].childNodes))
                        if plural == "false":
                            children = term_tag.getElementsByTagName("single")
                            if len(children) > 0:
                                return unicode(self.getText(children[0].childNodes))
                        else:
                            if len([e for e in term_tag.childNodes if e.nodeType == e.ELEMENT_NODE]) == 0:
                                return unicode(self.getText(term_tag.childNodes))
                        
                elif form == "":
                    if plural == "true":
                        children = term_tag.getElementsByTagName("multiple")
                        if len(children) > 0:
                            return unicode(self.getText(children[0].childNodes))
                    if plural == "false":
                        children = term_tag.getElementsByTagName("single")
                        if len(children) > 0:
                            return unicode(self.getText(children[0].childNodes))
                    else:
                        if len([e for e in term_tag.childNodes if e.nodeType == e.ELEMENT_NODE]) == 0:
                            return unicode(self.getText(term_tag.childNodes))

        print "Term not found for name "+name+" ("+form+" "+plural+")"
        return ""

    def getText(self, nodelist):
        rc = ""
        for node in nodelist:
            if node.nodeType == node.TEXT_NODE:
                rc = rc + node.data
        return rc
    
    
    def xml(self):
        attributes = " xmlns=\"%s\"" % (quoteattr(self.xmlns),)
        attributes += " class=\"%s\"" % (quoteattr(self.style_class),)
        if self.lang <> "":
            attributes += " xml:lang=\"%s\"" % (quoteattr(self.lang),)
        return "<style%s>\n%s\n</style>\n" % (attributes, ParentCSLObject.xml(self))

class StyleCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass
    
def main():
   pass

if __name__ == '__main__':
    unittest.main()

    
