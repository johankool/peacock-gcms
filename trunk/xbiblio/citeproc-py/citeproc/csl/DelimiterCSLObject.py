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
DelimiterCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest


class DelimiterCSLObject(object):
    def __init__(self, attrs):
        super(DelimiterCSLObject, self).__init__(attrs)
        self.delimiter = ""
        if "delimiter" in attrs:
            self.delimiter = attrs["delimiter"]
    
    def group(self, array):
        for text in array:
            if text == "":
                array.remove(text)
        return unicode(self.delimiter.join(array))
    
    def xml(self):
        if self.delimiter == "":
            return ""
        else:
            return " delimiter=\"%s\"" %  (quoteattr(self.delimiter),)  

class DelimiterCSLObjectTests(unittest.TestCase):
    def setUp(self):
        self.testObject = DelimiterCSLObject(attrs={})
    
    def testInsertDelimiter(self):
        """should insert delimiter between strings in array"""
        testArray = ["test 1", "test 2", "test 3"]
        self.testObject.delimiter = ", "
        result = self.testObject.group(testArray)
        self.assertEqual(result, "test 1, test 2, test 3")
 
    def testInsertNoDelimiter(self):
        """should insert no delimiter between strings in array if not set"""
        testArray = ["test 1", "test 2", "test 3"]
        self.testObject.delimiter = ""
        result = self.testObject.group(testArray)
        self.assertEqual(result, "test 1test 2test 3")
    
    def testReturnEmptyString(self):
        """should return empty string for empty array"""
        testArray = ()
        self.testObject.delimiter = ", "
        result = self.testObject.group(testArray)
        self.assertEqual(result, "")
    
    def testReturnString(self):
        """should return empty string for empty array"""
        testArray = ["test 1"]
        self.testObject.delimiter = ", "
        result = self.testObject.group(testArray)
        self.assertEqual(result, "test 1")


if __name__ == '__main__':
    unittest.main()