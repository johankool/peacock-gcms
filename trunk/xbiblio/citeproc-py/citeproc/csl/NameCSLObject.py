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
NameCSLObject.py

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
from reference import Name

class NameCSLObject(FormattingCSLObject, DelimiterCSLObject):
    def __init__(self, attrs):
        super(NameCSLObject, self).__init__(attrs)
        self.form = ""
        self.root = None
        if attrs.has_key("form"):
            self.form = attrs["form"]
        self.and_appearance = ""
        if attrs.has_key("and"):
            self.and_appearance = attrs["and"]
        self.delimiter_precedes_last = ""
        if attrs.has_key("delimiter-precedes-last"):
            self.delimiter_precedes_last = attrs["delimiter-precedes-last"]
        self.name_as_sort_order = ""
        if attrs.has_key("name-as-sort-order"):
            self.name_as_sort_order = attrs["name-as-sort-order"]
        self.sort_separator = ""
        if attrs.has_key("sort-separator"):
            self.sort_separator = attrs["sort-separator"]
        self.initialize_with = ""
        if attrs.has_key("initialize-with"):
            self.initialize_with = attrs["initialize-with"]
    
    def formatted_text(self, names, options):
        # initial values
        formattedNames = []
        et_al_min = 1000 # bogus
        et_al_use_first = 1000 # bogus
        
        # get et-al settings from options
        if "et-al-min" in options:
            et_al_min = int(options["et-al-min"]) # et-al-min: the minimum number of contributors to use "et al"
        if et_al_min < 2:
            raise Exception, "et-al-min should be 2 or higher"
        if "et-al-use-first" in options:
            et_al_use_first = int(options["et-al-use-first"]) # et-al-use-first: the number of contributors to explicitly print under "et al" conditions
        if et_al_use_first < 1:
            raise Exception, "et_al_use_first should be 1 or higher"
        
        if "kind" in options and "position" in options:
            if options["kind"] == "citation" and options["position"] == "subsequent":
            #     et_al_use_first = 1 # et-al-subsequent-*: same as above, but for subsequent references (citation only)
                et_al_min = int(options["et-al-subsequent-min"]) # et-al-min: the minimum number of contributors to use "et al"
                if et_al_min < 2:
                    raise Exception, "et-al-subsequent-min should be 2 or higher"
                et_al_use_first = int(options["et-al-subsequent-use-first"]) # et-al-use-first: the number of contributors to explicitly print under "et al" conditions
                if et_al_use_first < 1:
                    raise Exception, "et-al-subsequent-use-first should be 1 or higher"
        
        #print "et_al_min="+str(et_al_min)+" et_al_use_first="+str(et_al_use_first)+" len(names)="+str(len(names))
        
        if len(names) == 0:
            pass
        elif len(names) == 1:
            formattedNames.append(self.textForName(names[0], 0))
        else:
            # set the number of names to use
            count = len(names)
            use_et_al = False
            # use et al if more names than min, but don't go out of bounds
            if len(names) >= et_al_min and len(names) > et_al_use_first:
                use_et_al = True
                count = et_al_use_first
                #print "using et al"
            
            # loop over the names
            for i in range(count):
                formattedNames.append(self.textForName(names[i],i))
                
                if not use_et_al:
                    # delimiter
                    if i < len(names)-2 : # and i <> et_al_use_first-1: # if not the last object
                        formattedNames.append(self.delimiter)
                
                    # and symbol, do not use when et al follow
                    if i == len(names)-2:
                        # insert delimeter before and if asked, otherwise insert space
                        if self.delimiter_precedes_last == "always":
                            formattedNames.append(self.delimiter)
                        else:
                            formattedNames.append(" ")
                        # insert the and symbol
                        if self.and_appearance == "text":
                            formattedNames.append(self.root.term(name="and")+" ") # TODO fetch and from locales file!
                        elif self.and_appearance == "symbol":
                            formattedNames.append("&amp; ")
                        else:
                            pass # if no and is wanted, do nothing (already inserted delimiter or space above)
                
                if use_et_al:
                    if i < et_al_use_first-1:
                        formattedNames.append(self.delimiter)
            
            # if et al was used, at now
            if use_et_al:
                formattedNames.append(" ")
                formattedNames.append(self.root.term(name="et-al"))
        
        if len(formattedNames) == 0:
            return ""     
        text = "".join(formattedNames)
        text = self.format(text)
        return text
    
    def textForName(self, name, index, order="natural"):
        name_list = []
        
        # name-as-sort-order set order to family-given for first or all
        if self.name_as_sort_order == "first" and index == 0:
            order = "family-given"
        elif self.name_as_sort_order == "all":
            order = "family-given"
        
        # when order is natural choose the order set by the name
        if order == "natural":
            order = name.natural_display_order
        
        # FIXME sort-separator gets space added if it didn't had any
        # FIXME should not initialize given_name if there is no family_name (e.g. some Indonesian people go by only one name, which is given)
        
        # order is given-family with no delimiter
        if (order == "given-family" and order == name.natural_display_order):
            if name.prefix <> "":
                name_list.append(name.prefix)            
            if name.initials <> "":
                name_list.append(name.initials)
            elif name.family_name == "":
                name_list.append(name.given_name)
            elif name.given_name <> "":
                name_list.append(self.initializeGivenName(name.given_name))
            if name.articular <> "":
                name_list.append(name.articular)
            if name.family_name <> "":
                name_list.append(name.family_name)
            if name.suffix <> "":
                name_list.append(name.suffix)
        elif (order == "given-family" and order <> name.natural_display_order):
            if name.prefix <> "":
                name_list.append(name.prefix)
            if name.initials <> "":
                name_list.append(name.initials+self.sort_separator)
            elif name.family_name == "":
                name_list.append(name.given_name)
            elif name.given_name <> "":
                name_list.append(self.initializeGivenName(name.given_name)+self.sort_separator)
            if name.articular <> "":
                name_list.append(name.articular)
            if name.family_name <> "":
                name_list.append(name.family_name)
            if name.suffix <> "":
                name_list.append(name.suffix)
        elif (order == "family-given" and order == name.natural_display_order):
            if name.prefix <> "":
                name_list.append(name.prefix)
            if name.articular <> "":
                name_list.append(name.articular)
            if name.family_name <> "":
                name_list.append(name.family_name)
            if name.initials <> "":
                name_list.append(name.initials)
            elif name.family_name == "":
                name_list.append(name.given_name)
            elif name.given_name <> "":
                name_list.append(self.initializeGivenName(name.given_name))
            if name.suffix <> "":
                name_list.append(name.suffix)
        elif (order == "family-given" and order <> name.natural_display_order):
            if name.articular <> "":
                name_list.append(name.articular)
            if name.family_name <> "":
                name_list.append(name.family_name+self.sort_separator.rstrip(" ")) # strip space from separator to prevent double spacing
            if name.prefix <> "":
                name_list.append(name.prefix)
            if name.initials <> "":
                name_list.append(name.initials)
            elif name.family_name == "":
                name_list.append(name.given_name)
            elif name.given_name <> "":
                name_list.append(self.initializeGivenName(name.given_name))
            if name.suffix <> "":
                name_list.append(name.suffix)
        else:
            raise Exception, "order or natural_display_order has invalid value"
        
        return " ".join(name_list)
        
    def initializeGivenName(self, text):
        # get this first character of each given name
        out = ""
        initials = text.split(" ")
        for name in initials:
            out += name[0:1] + self.initialize_with
        # strip last space on return
        return out.rstrip(" ")
          
    def xml(self):
        attributes = ""
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        if self.and_appearance <> "":
            attributes += " and=\"%s\"" % (quoteattr(self.and_appearance),)
        if self.delimiter_precedes_last <> "":
            attributes += " delimiter-precedes-last=\"%s\"" % (quoteattr(self.delimiter_precedes_last),)
        if self.name_as_sort_order <> "":
            attributes += " name-as-sort-order=\"%s\"" % (quoteattr(self.name_as_sort_order),)
        if self.sort_separator <> "":
            attributes += " sort-separator=\"%s\"" % (quoteattr(self.sort_separator),)
        if self.initialize_with <> "":
            attributes += " initialize-with=\"%s\"" % (quoteattr(self.initialize_with),)
        
        return "<name%s%s%s/>\n" % (attributes, FormattingCSLObject.xml(self),DelimiterCSLObject.xml(self))

class NameCSLObjectTests(unittest.TestCase):
    def setUp(self):
        self.testObject = NameCSLObject(attrs={"and":"symbol"})
        self.Name1 = Name(given_name="Jan Willem", family_name="Bakker", articular="de", suffix="Jr.")
        self.Name2 = Name(given_name="Given", family_name="Family", natural_display_order="family-given")

    def testName1(self):
        """should return given-family name as natural name"""
        result = self.testObject.textForName(self.Name1,1)
        self.assertEqual(result, "Jan Willem de Bakker Jr.")

    def testName2(self):
        """should return given-family name as family-given"""
        result = self.testObject.textForName(self.Name1,1)
        self.assertEqual(result, "de Bakker Jr., Jan Willem")

    def testName3(self):
        """should return given-family name as given-family"""
        result = self.testObject.textForName(self.Name1,1)
        self.assertEqual(result, "Jan Willem de Bakker Jr.")

    def testName4(self):
        """should return family-given name as natural name"""
        result = self.testObject.textForName(self.Name2,1)
        self.assertEqual(result, "Family Given")

    def testName5(self):
        """should return family-given name as family-given"""
        result = self.testObject.textForName(self.Name2,1)
        self.assertEqual(result, "Family Given")

    def testName6(self):
        """should return family-given name as given-family"""
        result = self.testObject.textForName(self.Name2,1)
        self.assertEqual(result, "Given, Family")
    
    def testTextForNames(self):
        """ """
        result = self.testObject.textForNames([self.Name1,self.Name2])
        self.assertEqual(result, "Jan Willem de Bakker Jr. and Family Given")

if __name__ == '__main__':
    unittest.main()