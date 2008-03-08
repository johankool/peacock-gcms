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

"""Read RDF references"""

from reference import Reference


class RDFDriver(object):
    def findReferencesInRDFForCitations(source, citations):
        references = []
        keysFound = []
        sourceEntries = source.getElementsByTagName('Reference')
        for citationGroup in citations:
            for citation in citationGroup.citations:
                for sourceEntry in sourceEntries:
                    if citation.key == sourceEntry.attributes['rdf:about'].value and not citation.key in keysFound:
                        keysFound.append(citation.key)
                        reference = Reference()
                        reference.key = citation.key
                        reference.reftype = findDataInRDFForKey("reftype", sourceEntry)
                        reference.author = findDataInRDFForKey("author", sourceEntry)
                        reference.editor = findDataInRDFForKey("editor", sourceEntry)
                        reference.translator = findDataInRDFForKey("translator", sourceEntry)
                        reference.publisher = findDataInRDFForKey("publisher", sourceEntry)
                        reference.container = findDataInRDFForKey("container", sourceEntry)
                        reference.collection = findDataInRDFForKey("collection", sourceEntry)
                        reference.title = findDataInRDFForKey("title", sourceEntry)
                        reference.short_title = findDataInRDFForKey("short_title", sourceEntry)
                        reference.volume = findDataInRDFForKey("volume", sourceEntry)
                        reference.issue = findDataInRDFForKey("issue", sourceEntry)
                        reference.number = findDataInRDFForKey("number", sourceEntry)
                        reference.pages = findDataInRDFForKey("pages", sourceEntry)
                        reference.year = findDataInRDFForKey("year", sourceEntry)
                        reference.access = findDataInRDFForKey("access", sourceEntry)
                        reference.pages = findDataInRDFForKey("pages", sourceEntry)
                        references.append(reference)
        return references
    
    def findDataInRDFForKey(key, sourceEntry):
        if key == "reftype":
            refType = sourceEntry.getElementsByTagName('rdf:type')[0].attributes['rdf:resource'].value
            return refType[27:].lower() # strip http://purl.org/net/biblio# and lowercase
        elif key == "title":
            try:
                result = sourceEntry.getElementsByTagName('dc:title')[0].childNodes[0].wholeText
            except:
                return ""
            return result
        elif key =="author":
            authors = []
            for child in sourceEntry.childNodes:
                if child.nodeName == "authors":
                    for child2 in child.childNodes:
                        if child2.nodeType ==1:
                            for child3 in child2.childNodes:
                                if child3.nodeType ==1:
                                    author = nameForKeyInRDF(child3.attributes['rdf:resource'].value, sourceEntry.parentNode)
                                    authors.append(author)
            return authors
        elif key =="editor":
            # FIXME should read editors! not authors (but don't know where those are in RDF)
            editors = []
            for child in sourceEntry.childNodes:
                if child.nodeName == "authors":
                    for child2 in child.childNodes:
                        if child2.nodeType ==1:
                            for child3 in child2.childNodes:
                                if child3.nodeType ==1:
                                    editor = nameForKeyInRDF(child3.attributes['rdf:resource'].value, sourceEntry.parentNode)
                                    editors.append(editor)
            return editors
        elif key =="year":
            for child in sourceEntry.childNodes:
                if child.nodeName == "dc:date":
                    return child.childNodes[0].nodeValue[0:4]
            # print "WARNING: No year for sourceEntry"
            return ''
        elif key =="volume":
            try:
                result = sourceEntry.getElementsByTagName("prism:volume")[0].childNodes[0].wholeText            
            except:
                return ""
            return result
        elif key =="issue":
            try:
                result = sourceEntry.getElementsByTagName("prism:issue")[0].childNodes[0].wholeText            
            except:
                return ""
            return result
        elif key =="number":
            try:
                result = sourceEntry.getElementsByTagName("prism:number")[0].childNodes[0].wholeText            
            except:
                return ""
            return result
        elif key =="pages":
            try:
                result = sourceEntry.getElementsByTagName("pages")[0].childNodes[0].wholeText            
            except:
                return ""
            return result
        elif key =="access":
            try:
                result = sourceEntry.getElementsByTagName("electronicCopy")[0].getElementsByTagName("dcterms:dateAccessed")[0].childNodes[0].wholeText            
            except:
                return ""
            return result
        elif key =="container":
             # <dcterms:isPartOf rdf:resource="cs"/>
             containerKey = ""
             for child in sourceEntry.childNodes:
                 if child.nodeName == "isPartOf":
                     containerKey = child.attributes['rdf:resource'].value
             for containerSourceEntry in sourceEntry.parentNode.childNodes:
                 if containerSourceEntry.nodeType == 1: # 1 = ELEMENT_NODE
                     if containerSourceEntry.hasAttribute('rdf:about'):
                         if containerKey == containerSourceEntry.attributes['rdf:about'].value:         
                            container = Reference()
                            container.key = containerKey
                            container.reftype = findDataInRDFForKey("reftype", container)
                            container.author = findDataInRDFForKey("author", container)
                            container.editor = findDataInRDFForKey("editor", container)
                            container.translator = findDataInRDFForKey("translator", container)
                            container.publisher = findDataInRDFForKey("publisher", container)
                            container.container = findDataInRDFForKey("container", container)
                            container.collection = findDataInRDFForKey("collection", container)
                            container.title = findDataInRDFForKey("title", container)
                            container.short_title = findDataInRDFForKey("short_title", container)
                            container.volume = findDataInRDFForKey("volume", container)
                            container.issue = findDataInRDFForKey("issue", container)
                            container.number = findDataInRDFForKey("number", container)
                            container.pages = findDataInRDFForKey("pages", container)
                            container.year = findDataInRDFForKey("year", container)
                            container.access = findDataInRDFForKey("access", container)
                            return container
        else:
            print "WARNING: Unknown key " + key + ". Incomplete RDF implementation of CiteProc."
            return key + " "

    def nameForKeyInRDF(key, source):
        for person in source.getElementsByTagName('foaf:Person'):
            if person.attributes['rdf:about'].value == key:
                name = Name()
                result = ''
                for givenname in person.getElementsByTagName('foaf:givenname'):
                    result += givenname.childNodes[0].nodeValue + ' '
                name.given_name = result
            
                result = ''            
                for surname in person.getElementsByTagName('foaf:surname'):
                     result += surname.childNodes[0].nodeValue
                name.family_name = result

        return name
