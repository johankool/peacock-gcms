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
FormattingCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

## Formatting attributes.
# div {
#   delimiter = attribute delimiter { text }?
#   
#   ## attributes are drawn directly from CSS and FO where possible
#   formatting =
#     attribute prefix { text }?,
#     attribute suffix { text }?,
#     attribute font-family { text }?,
#     attribute font-style { "italic" | "normal" | "oblique" }?,
#     attribute font-variant { "normal" | "small-caps" }?,
#     attribute font-weight { "normal" | "bold" | "light" }?,
#     attribute text-decoration { "none" | "underline" }?,
#     attribute vertical-align { "baseline" | "sup" | "sub" }?,
#     attribute text-case {
#       
#       ## display all text as lowercase
#       "lowercase"
#       | 
#         ## display all text as uppercase
#         "uppercase"
#       | 
#         ## capitalize first character; other characters
#         ## displayed as is
#         "capitalize-first"
#       | 
#         ## capitalize first character of every word;
#         ## other characters displayed lowercase
#         "capitalize-all"
#       | 
#         ## display as title case (the Chicago Manual
#         ## of Style calls this "headline style")
#         "title"
#       | 
#         ## display as sentence case/sentence style
#         "sentence"
#     }?,
#     
#     ## For examples such as abstracts and notes in annotated bibliographies 
#     ## use the "block" display value. Otherwise, content is displayed inline.
#     attribute display { "block" }?,
#     attribute quotes { xsd:boolean }?
# }


import sys
import os
import unittest

import string

class FormattingCSLObject(object):
    def __init__(self, attrs):
        super(FormattingCSLObject, self).__init__(attrs)
        self.prefix = u""
        if "prefix" in attrs:
            self.prefix = unicode(attrs["prefix"])
        
        self.suffix = u""
        if "suffix" in attrs:
            self.suffix = unicode(attrs["suffix"])
        
        self.font_family = ""
        if "font-family" in attrs:
            self.font_family = attrs["font-family"]
        
        self.font_style = ""
        if "font-style" in attrs:
            self.font_style = attrs["font-style"]
        
        self.font_variant = ""
        if "font-variant" in attrs:
            self.font_variant = attrs["font-variant"]
        
        self.font_weight = ""
        if "font-weight" in attrs:
            self.font_weight = attrs["font-weight"]
        
        self.text_decoration = ""
        if "text-decoration" in attrs:
            self.text_decoration = attrs["text-decoration"]
        
        self.vertical_align = ""
        if "vertical-align" in attrs:
            self.vertical_align = attrs["vertical-align"]
        
        self.text_case = ""
        if "text-case" in attrs:
            self.text_case = attrs["text-case"]
            
        self.display = ""
        if "display" in attrs:
            self.display = attrs["display"]
        
        self.quotes = ""
        if "quotes" in attrs:
            self.quotes = attrs["quotes"]
    
    def format(self, text):     
        if isinstance(text, str):
            raise Exception, "text needs to be unicode"
        
        if text == "":
            return u"";
        
        # add prefix
        text = self.prefix + text
        
        # add suffix
        text = text + self.suffix
        
        # apply text case
        text = self.applyTextCase(text)
        
        # apply font attributes
        text = self.applyFontAttributes(text)
        
        # apply baseline shift
        text = self.applyBaselineShift(text)
        
        return text
    
    def applyTextCase(self, text):
        # FIXME should only be applied to text, not to html that might already be present
        
        # apply text case
        if self.text_case == "lowercase":
            # text to lowercase
            text = string.lower(text)
        elif self.text_case == "uppercase":
            # text to uppercase
            text = string.upper(text)
        elif self.text_case == "capitalize-first":
            # capitalize first letter (leave rest as is)
            text = string.capitalize(text) # TODO check if output is as expected
        elif self.text_case == "capitalize-all":
            text = string.capitalize(text) # TODO check if output is as expected
        elif self.text_case == "title":
            text = string.capwords(text) # TODO check if output is as expected
        elif self.text_case == "sentence":
            text = string.capitalize(text) # TODO check if output is as expected
        
        return text
    
    def applyFontAttributes(self, text):
        # TODO check if this is all valid CSS
        attributes = ""
        if self.font_family <> "":
            attributes += "font-family: " + self.font_family + ";"
        if self.font_style <> "":
            attributes += "font-style: " + self.font_style + ";"
        if self.font_variant <> "":
            attributes += "font-variant: " + self.font_variant + ";"
        if self.font_weight <> "":
            attributes += "font-weight: " + self.font_weight + ";"
        if self.text_decoration <> "":
            attributes += "text-decoration: " + self.text_decoration + ";"
            
        # do not insert span if no attributes are added
        if attributes == "":
            return text
        else:
            return "<span style=\"" + attributes + "\">" + text + "</span>"
    
    def applyBaselineShift(self, text):
        if self.vertical_align == "baseline":
            text = text # TODO what is meant with baseline? same as normal?
        elif self.vertical_align == "sub":
            text = "<sub>" + text + "</sub>"
        elif self.vertical_align == "sup":
            text = "<sup>" + text + "</sup>"
        
        return text
        
    def xml(self):
        attributes = ""
        if self.prefix <> "":
            attributes += " prefix=\"%s\"" % (quoteattr(self.prefix),)
        if self.suffix <> "":
            attributes += " suffix=\"%s\"" % (quoteattr(self.suffix),)
        if self.font_family <> "":
            attributes += " font-family=\"%s\"" % (quoteattr(self.font_family),)
        if self.font_style <> "":
            attributes += " font-style=\"%s\"" % (quoteattr(self.font_style),)
        if self.font_variant <> "":
            attributes += " font-variant=\"%s\"" % (quoteattr(self.font_variant),)
        if self.font_weight <> "":
            attributes += " font-weight=\"%s\"" % (quoteattr(self.font_weight),)
        if self.text_decoration <> "":
            attributes += " text-decoration=\"%s\"" % (quoteattr(self.text_decoration),)
        if self.text_case <> "":
            attributes += " text-case=\"%s\"" % (quoteattr(self.text_case),)
        if self.vertical_align <> "":
            attributes += " vertical-align=\"%s\"" % (quoteattr(self.vertical_align),)
        if self.display <> "":
            attributes += " display=\"%s\"" % (quoteattr(self.display),)
        if self.quotes <> "":
            attributes += " quotes=\"%s\"" % (quoteattr(self.quotes),)
        
        return attributes

class FormattingCSLObjectTests(unittest.TestCase):
    def setUp(self):
        self.testObject = FormattingCSLObject(attrs={})
    
    def testPrefix(self):
        """should insert prefix"""
        self.testObject.prefix = "prefix"
        result = self.testObject.format("test string")
        self.assertEqual(result, "prefixtest string")

    def testSuffix(self):
        """should insert suffix"""
        self.testObject.suffix = "suffix"
        result = self.testObject.format("test string")
        self.assertEqual(result, "test stringsuffix")
    
    def testApplyTextCase(self):
        """should apply proper text case"""
        self.testObject.text_case = ""
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "lOrEm IpSuM")
        
    def testApplyTextCaseLowercase(self):
        """should apply proper text case for lowercase"""
        self.testObject.text_case = "lowercase"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "lorem ipsum")
        
    def testApplyTextCaseUppercase(self):
        """should apply proper text case for uppercase"""
        self.testObject.text_case = "uppercase"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "LOREM IPSUM")
        
    def testApplyTextCaseCapitalizeFirst(self):
        """should apply proper text case for capitalize-first"""
        self.testObject.text_case = "capitalize-first"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "LOrEm IpSuM")
        
    def testApplyTextCaseCapitalizeAll(self):
        """should apply proper text case for capitalize-all"""
        self.testObject.text_case = "capitalize-all"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "LOrEm IpSuM")
        
    def testApplyTextCaseTitle(self):
        """should apply proper text case for title"""
        self.testObject.text_case = "title"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "Lorem Ipsum")
        
    def testApplyTextCaseSentence(self):
        """should apply proper text case for sentence"""
        self.testObject.text_case = "sentence"
        result = self.testObject.applyTextCase("lOrEm IpSuM")
        self.assertEqual(result, "Lorem ipsum")
        
    def testApplyFontAttributes(self):
        """should apply font attributes"""
        self.testObject.font_family = "Times New Roman"
        self.testObject.text_decoration = "underline"
        self.testObject.font_variant = "small-caps"
        self.testObject.font_style = "italic"
        self.testObject.font_weight = "bold"
        result = self.testObject.applyFontAttributes("test string")
        self.assertEqual(result, "<span style=\"font-family: Times New Roman;font-style: italic;font-variant: small-caps;font-weight: bold;text-decoration: underline;\">test string</span>")
    
    def testApplyFontAttributes(self):
        """should not insert span tag if no font attributes"""
        self.testObject.font_family = ""
        self.testObject.text_decoration = ""
        self.testObject.font_variant = ""
        self.testObject.font_style = ""
        self.testObject.font_weight = ""
        result = self.testObject.applyFontAttributes("test string")
        self.assertEqual(result, "test string")

if __name__ == '__main__':
    unittest.main()