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

"""Read MODS references"""

#from amara import binderytools
from reference import Reference
from datetime import datetime

class MODSDriver(object):
    def findReferencesInModsForCitations(source, citations):
        references = []
        keysFound = []
        doc = binderytools.bind_file(source)
        for citationGroup in citations:
            for citation in citationGroup.citations:
                sourceEntries = iter(doc.modsCollection.mods)
                for sourceEntry in sourceEntries:
                    if citation.key == sourceEntry.ID and not citation.key in keysFound:
                        keysFound.append(citation.key)
                        # print sourceEntry.xml()
                        reference = Reference()
                        reference.key = citation.key
                        reference.reftype = findDataInModsEntryForKey("reftype", sourceEntry)
                        reference.authors = findDataInModsEntryForKey("authors", sourceEntry)
                        reference.editors = findDataInModsEntryForKey("editors", sourceEntry)
                        reference.translators = findDataInModsEntryForKey("translators", sourceEntry)
                        reference.publishers = findDataInModsEntryForKey("publishers", sourceEntry)
                        reference.container = findDataInModsEntryForKey("container", sourceEntry)
                        reference.collection = findDataInModsEntryForKey("collection", sourceEntry)
                        reference.titles = findDataInModsEntryForKey("titles", sourceEntry)
                        reference.volume = findDataInModsEntryForKey("volume", sourceEntry)
                        reference.issue = findDataInModsEntryForKey("issue", sourceEntry)
                        reference.number = findDataInModsEntryForKey("number", sourceEntry)
                        reference.pages = findDataInModsEntryForKey("pages", sourceEntry)
                        reference.date = findDataInModsEntryForKey("date", sourceEntry)
                        reference.access = findDataInModsEntryForKey("access", sourceEntry)
                        references.append(reference)
        return references
    
    def findDataInModsEntryForKey(key, sourceEntry):
        result = ""
        # FIXME not all keys are properly mapped yet
        if key == "reftype":
            try:
                result = unicode(sourceEntry.genre)         
            except:
                return ""
            return result
        elif key == "titles":
            titles = {}
            try:
                result = sourceEntry.titleInfo.title
                titles['title'] = unicode(result)
                # TODO short-title etc.      
            except:
                return ""
            return titles
        elif key =="authors":
            authors = []
            try:
                for name in sourceEntry.name:
                    if unicode(name.role.roleTerm) == "author":
                        new_name = Name()
                        for namePart in name.namePart:
                            nameType = namePart.type
                            if nameType== 'given':
                                new_name.given_name += unicode(namePart)
                            elif nameType== 'family':
                                new_name.family_name += unicode(namePart)
                        authors.append(new_name)
            except:
                return []
            return authors
        elif key =="editors":
            editors = []
            try:
                for name in sourceEntry.name:
                    if unicode(name.role.roleTerm) == "editor":
                        new_name = Name()
                        for namePart in name.namePart:
                            nameType = namePart.type
                            if nameType== 'given':
                                new_name.given_name += unicode(namePart)
                            elif nameType== 'family':
                                new_name.family_name += unicode(namePart)
                        editors.append(new_name)
            except:
                return []
            return editors
        elif key =="translators":
            translators = []
            try:
                for name in sourceEntry.name:
                    if unicode(name.role.roleTerm) == "translator":
                        new_name = Name()
                        for namePart in name.namePart:
                            nameType = namePart.type
                            if nameType== 'given':
                                new_name.given_name += unicode(namePart)
                            elif nameType== 'family':
                                new_name.family_name += unicode(namePart)
                        translators.append(new_name)
            except:
                return []
            return translators
        elif key =="publishers":
            publishers = []
            try:
                for name in sourceEntry.name:
                    if unicode(name.role.roleTerm) == "publisher":
                        new_name = Name()
                        for namePart in name.namePart:
                            nameType = namePart.type
                            if nameType== 'given':
                                new_name.given_name += unicode(namePart)
                            elif nameType== 'family':
                                new_name.family_name += unicode(namePart)
                        publishers.append(new_name)
            except:
                return []
            return publishers
        elif key =="date":
            try:
                result = unicode(sourceEntry.originInfo.dateIssued)
                print result     
            except:
                return ""
            return result
        elif key =="volume":
            try:
                for detail in sourceEntry.relatedItem.part.detail:
                    if detail.type == "volume":
                        result = unicode(detail.number) 
            except:
                return ""
            return result
        elif key =="issue":
            try:
                for detail in sourceEntry.relatedItem.part.detail:
                    if detail.type == "issue":
                        result = unicode(detail.number) 
            except:
                return ""
            return result
        elif key =="number":
            try:
                for detail in sourceEntry.relatedItem.part.detail:
                    if detail.type == "number":
                        result = unicode(detail.number) 
            except:
                return ""
            return result
        elif key =="pages":
            try:
                for extent in sourceEntry.relatedItem.part.extent:
                    result += unicode(extent.start) + "-"
                    result += unicode(extent.end)
            except:
                return ""
            return result
        elif key =="access":
            return 'test-value-for-access'
        elif key =="container":
            if hasattr(sourceEntry,'relatedItem'):
                container = sourceEntry.relatedItem
                if hasattr(container,'type_'):
                    if unicode(container.type_) == "host":
                        containerReference = Reference()
                        containerReference.reftype = findDataInModsEntryForKey("reftype", container)
                        containerReference.authors = findDataInModsEntryForKey("authors", container)
                        containerReference.editors = findDataInModsEntryForKey("editors", container)
                        containerReference.translators = findDataInModsEntryForKey("translators", container)
                        containerReference.publishers = findDataInModsEntryForKey("publishers", container)
                        containerReference.container = findDataInModsEntryForKey("container", container)
                        containerReference.collection = findDataInModsEntryForKey("collection", container)
                        containerReference.titles = findDataInModsEntryForKey("titles", container)
                        containerReference.volume = findDataInModsEntryForKey("volume", container)
                        containerReference.issue = findDataInModsEntryForKey("issue", container)
                        containerReference.number = findDataInModsEntryForKey("number", container)
                        containerReference.pages = findDataInModsEntryForKey("pages", container)
                        containerReference.date = findDataInModsEntryForKey("date", container)
                        containerReference.access = findDataInModsEntryForKey("access", container)                
                        return containerReference
            return None
        elif key =="collection":
            # FIXME what is a collection?
            return ""
        else:
            print "WARNING: Unknown key " + key + ". Incomplete MODS implementation of CiteProc."
            return key + " "

