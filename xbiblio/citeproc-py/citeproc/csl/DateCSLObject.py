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
DateCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## date
# div {
#   date =
#     element cs:date {
#       attribute variable {
#         list { cs-date-tokens+ }
#       },
#       formatting,
#       delimiter,
#       date-part+
#     }
#   date-part = element cs:date-part { formatting, (month | day | year-other) }
#   
#   ## Month formats:
#   ##     long (default): January
#   ##     short: Jan
#   ##     numeric: 1
#   ##     numeric-leading-zeros: 01
#   month =
#     attribute name { "month" },
#     (attribute form { "long" | "short" | "numeric" | "numeric-leading-zeros" }?,
#      include-period)
#   
#   ## Day formats:
#   ##     numeric (default): 5
#   ##     numeric-leading-zeros: 05
#   ##     ordinal: 5th
#   day =
#     attribute name { "day" },
#     attribute form { "numeric" | "numeric-leading-zeros" | "ordinal" }?
#   
#   ## Year formats:
#   ##     long (default): 2005
#   ##     short: 05
#   ## Other represents any non-month/day/year date part
#   year-other =
#     attribute name { "year" | "other" },
#     attribute form { "short" | "long" }?
#   cs-date-tokens = "issued" | "event" | "accessed" | "container" | "original-date"
# }

from FormattingCSLObject import FormattingCSLObject
from DelimiterCSLObject import DelimiterCSLObject
from ParentCSLObject import ParentCSLObject
#from reference import Date # FIXME Import Date

class DateCSLObject(FormattingCSLObject, DelimiterCSLObject, ParentCSLObject):
    def __init__(self, attrs):
         super(DateCSLObject, self).__init__(attrs)
         self.variable = attrs["variable"]
    
    def formatted_text(self, reference, options):
        dates = []
        for variable in self.variable.split(" "):            
            date = None
            variable = self.variable.replace("-","_") # python can't have - in attributes, replaced by _
            # work around for clashing names in reference attributes
            if variable == "event":
                variable = "event_date"
            date = reference.__getattribute__(variable)
               
            if isinstance(date, str):
                raise Exception, "Date was passed a non-Date object for the variable "+variable+"."
            
            formatted_text = []
            for child in self.children:
                 formatted_text.append(child.formatted_text(date, options))
            dates.append(u"".join(formatted_text))
        
        text = self.group(dates)
        return self.format(text)

    def xml(self):
        return "<date variable=\"%s\"%s%s>\n%s\n</date>\n" % (quoteattr(self.variable), FormattingCSLObject.xml(self), DelimiterCSLObject.xml(self), ParentCSLObject.xml(self))


class DateCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()