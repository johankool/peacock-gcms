#! /usr/bin/env python
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

"""Read DOCBOOK function"""

from citation import Citation, CitationGroup
from xml.dom import minidom
# from amara import binderytools

class DocBookDriver(object):
    def __init__(self, source):
        self.source = source
        
    def citationGroups(self):
        source = self.source
        citationGroupsFound = []
        citationsFound = []
        keysFound = []
        for citationGroupEntry in source.getElementsByTagName("citation"):
            citationsFound = []
            citationGroup = CitationGroup()
            for citationEntry in citationGroupEntry.getElementsByTagName('biblioref'):
                citation = Citation()
                # key
                citation.key = citationEntry.attributes['linkend'].value
                # start/end/units 
                if citationEntry.hasAttribute('begin'):
                    citation.begin = citationEntry.attributes['begin'].value
                if citationEntry.hasAttribute('end'):
                    citation.end = citationEntry.attributes['end'].value
                if citationEntry.hasAttribute('units'):
                    citation.units = citationEntry.attributes['units'].value
                # firstOccurence
                if citation.key in keysFound:
                    citation.firstOccurence = 0
                else:
                    citation.firstOccurence = 1
                keysFound.append(citation.key) 
                citationsFound.append(citation)
            citationGroup.citations = citationsFound
            citationGroupsFound.append(citationGroup)  
              
        return citationGroupsFound

    def placeCitations(self, citationGroups):
        inDocBookCitationGroups = self.source.getElementsByTagName("citation")
        for i in range(len(citationGroups)):
            newElement = minidom.Text()
            newElement.nodeValue = citationGroups[i].formattedCitationGroup
            inDocBookCitationGroups[i].parentNode.replaceChild(newElement, inDocBookCitationGroups[i])
        return source
        
    def placeBibliography(self, bibliography):
        pass
        
    def save(self, output):
        pass
        
    
