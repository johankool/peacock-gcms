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
DatePartCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

from FormattingCSLObject import FormattingCSLObject

class DatePartCSLObject(FormattingCSLObject):
    def __init__(self, attrs):
        super(DatePartCSLObject, self).__init__(attrs)
        self.name = attrs["name"]
        self.form = ""
        if "form" in attrs:
            self.form = attrs["form"]
        self.root = None
    
    def formatted_text(self, date, options):
        if date == None:
            return u""
                
        text = u""
        if self.name == "year":
            if date.year <> "":            
                if self.form == "short":
                    text = unicode(date.year)[2:]
                else: # long by default
                    text = unicode(date.year)
        elif self.name == "month":
            if date.month <> None:
                if date.month < 1 or date.month > 12:
                    raise Exception, "Month out of range."
                if self.form == "short": # Jan
                    text = self.root.term(name="month-"+unicode(date.month).rjust(2,"0"), form="short")
                elif self.form == "numeric": # 1
                    text = unicode(date.month)
                elif self.form == "numeric-leading-zeros": # 01
                    text = unicode(date.month).rjust(2,"0")
                else: # long (default): January
                    text = self.root.term(name="month-"+unicode(date.month).rjust(2,"0"))
        elif self.name == "day":
            if date.day <> None:
                if date.day < 1 or date.day > 31:
                    raise Exception, "Day out of range."
                if self.form == "numeric-leading-zeros": # 05
                    text = unicode(date.day).rjust(2,"0")
                elif self.form == "ordinal": # 5th
                    # FIXME ordinal should be localizable
                    day = date.day
                    if day == 1 or day == 21:
                        text = unicode(day) + u"st"
                    elif day == 2 or day == 22:
                        text = unicode(day) + u"nd"
                    elif day == 3 or day == 23:
                        text = unicode(day) + u"rd"
                    else:
                        text = unicode(day) + u"th"
                else: # self.form == "numeric": # (default): 5
                    text = unicode(date.day)
        elif self.name == "other":
            text = unicode(date.other)
        else:
            raise Exception, "Invalid name for date-part tag."
        
        return self.format(text)
    
    def xml(self):
        attributes = " name=\"%s\"" % (quoteattr(self.name),)
        if self.form <> "":
            attributes += " form=\"%s\"" % (quoteattr(self.form),)
        return "<date-part name=\"%s\"%s%s/>\n" % (attributes, FormattingCSLObject.xml(self), DelimiterCSLObject.xml(self))


class DatePartCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()