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
IfCSLObject.py

Created by Johan Kool on 2008-02-17.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest
import string

from ParentCSLObject import ParentCSLObject

class IfCSLObject(ParentCSLObject):
    def __init__(self, attrs):
        super(IfCSLObject, self).__init__(attrs)
        self.type = ""
        if "type" in attrs:
            self.type = attrs["type"]
        self.variable = ""
        if "variable" in attrs:
            self.variable = attrs["variable"]
        self.is_numeric = ""
        if "is-numeric" in attrs:
            self.is_numeric = attrs["is-numeric"]
        self.is_date = ""
        if "is-date" in attrs:
            self.is_date = attrs["is-date"]
        self.position = ""
        if "position" in attrs:
            self.position = attrs["position"]
        self.disambiguate = ""
        if "disambiguate" in attrs:
            self.disambiguate = attrs["disambiguate"]
        self.locator = ""
        if "locator" in attrs:
            self.locator = attrs["locator"]
        self.match = ""
        if "match" in attrs:
            self.match = attrs["match"]
        self.if_type = "if"
    
    def formatted_text(self, reference, options):
        formatted_text = []
        for child in self.children:
            formatted_text.append(child.formatted_text(reference, options))
        text = "".join(formatted_text) # TODO same as macro, why more than one child?
        return text
    
    def evaluate(self, reference, options):
        # TODO actually evaluate for other kinds of comparisons too!
        # FIXME variable = self.variable.replace("-","_")
        # FIXME       <if variable="volume" type="book" match="all">
        
        # always true if type is else
        if self.if_type == "else":
            return True
        
        found_all = False
        found_any = False
        found_none = False
        
        # true if the references is one of the space delimited types
        if self.type <> "":
            if reference.reftype in self.type.split(" "):
                found_any = True
                if not found_none:
                    found_all = True
                found_none = False
            else:
                if not found_any:
                    found_none = True
                found_all = False
        
        # true if reference contains the variable
        if self.variable <> "":
            # gather variables
            found_something = False
            for variable in self.variable.split(" "):
                variable = variable.replace("-","_")
                if variable in reference.__dict__.keys():
                    if reference.__getattribute__(variable) <> "":
                        found_something = True
            # store result
            if found_something:
                found_any = True
                if not found_none:
                    found_all = True
                found_none = False
            else:
                if not found_any:
                    found_none = True
                found_all = False
        
        # true if the variable of the reference contains numeric data
        if self.is_numeric <> "":
            found_something = False
            for variable in self.is_numeric.split(" "):
                if reference.__getattribute__(variable).isdigit():
                    found_something = True
            # store result
            if found_something:
                found_any = True
                if not found_none:
                    found_all = True
                found_none = False
            else:
                if not found_any:
                    found_none = True
                found_all = False
        
        # true if the variable of the reference contains date data
        if self.is_date <> "":
            raise Exception, "is-date not yet implemented"
            found_something = False
            for variable in self.is_date.split(" "):
                if isinstance(reference.__getattribute__(self.is_date), Date): # FIXME incorrect?
                    found_something = True
            # store result
            if found_something:
                found_any = True
                if not found_none:
                    found_all = True
                found_none = False
            else:
                if not found_any:
                    found_none = True
                found_all = False
        
        # true if the citations position matches
        if self.position <> "":
            if options["position"] in self.position.split(" "):
                found_any = True
                if not found_none:
                    found_all = True
                found_none = False
            else:
                if not found_any:
                    found_none = True
                found_all = False
                        
        # disambiguate
        if self.disambiguate <> "":
            raise Exception, "is-date not yet implemented"
            if self.disambiguate == "true":
                pass
                # return true if kids return text that would make use different from another reference
                # TODO if disambiguate
                # this one is going to be a pain to implement
            
        # true if we match all, any or none of the locators
        if self.locator <> "":
            pass # FIXME locators not yet supported
        
        # return based on match setting
        if self.match == "any":
            return found_any
        if self.match == "none":
            return found_none
        
        # match "all" by default
        return found_all
    
    def xml(self):
        attributes = ""
        if self.type <> "":
             attributes += " type=\"%s\"" % (quoteattr(self.type),)
        if self.variable <> "":
             attributes += " variable=\"%s\"" % (quoteattr(self.variable),)
        if self.is_numeric <> "":
             attributes += " is-numeric=\"%s\"" % (quoteattr(self.is_numeric),)
        if self.is_date <> "":
             attributes += " is-date=\"%s\"" % (quoteattr(self.is_date),)
        if self.position <> "":
             attributes += " position=\"%s\"" % (quoteattr(self.position),)
        if self.disambiguate <> "":
             attributes += " disambiguate=\"%s\"" % (quoteattr(self.disambiguate),)
        if self.locator <> "":
             attributes += " locator=\"%s\"" % (quoteattr(self.locator),)
        if self.match <> "":
             attributes += " match=\"%s\"" % (quoteattr(self.match),)
        # can have no kids
        if len(self.children) == 0:
            return "<%s%s/>\n" % (self.if_type, attributes)
        else:
            return "<%s%s>\n%s\n</%s>\n" % (self.if_type, attributes,  ParentCSLObject.xml(self),self.if_type)
        

class IfCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()