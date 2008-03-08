#! /usr/bin/env pythons
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

_debug = 0

class Citation:
    def __init__(self, citekey="", prefix="", suffix="", occurence_index=None, first_occurence_index=None, reference=None):
        self.citekey = citekey
        self.prefix = prefix
        self.suffix = suffix
        self.occurence_index = None # used to indicate the index of this citation in all citations in the text (0-based)
        self.first_occurence_index = None # used to indicate the index of the citation in which this reference was first cited in the text
        
        # internal use!
        self.reference = reference
    
    def position(self):
        """Used to indicate wether this is the first occurence of a citation of this reference in the text.
        
        Returns boolean"""
        if self.occurence_index == self.first_occurence_index:
            return "first"
        return "subsequent"
    

class CitationGroup:
    def __init__(self, citations=[]):
        self.citations = citations # objects of class Citation
        
    


