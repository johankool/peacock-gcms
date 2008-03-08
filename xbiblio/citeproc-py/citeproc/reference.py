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


class Reference(object):
    def __init__(self, citekey="", reftype="", authors=[], editors=[], translators=[], recipients=[], interviewers=[], publishers=[], composers=[], original_publishers=[], original_authors=[], container_authors=[], collection_editors=[], issued=None, event_date=None, accessed=None, container=None, original_date=None, title="", container_title="", collection_title="", collection_number="", original_title="", publisher="", publisher_place="", archive="", archive_place="", archive_location="", event="", event_place="", page="", locator="", version="", volume="", number_of_volumes="", issue="", chapter_number="", medium="", status="", edition="", section="", genre="", note="", annote="", abstract="", keyword="", number="", references="", URL="", DOI="", ISBN="", citation_number="", citation_label=""):
        
        self.citekey = citekey
        self.reftype = reftype
        
        self.authors = authors
        self.editors = editors
        self.translators = translators
        self.recipients = recipients
        self.interviewers = interviewers
        self.publishers = publishers
        self.composers = composers
        self.original_publishers = original_publishers
        self.original_authors = original_authors
        self.container_authors = container_authors
        self.collection_editors = collection_editors
             
        self.issued = issued
        self.event_date = event_date
        self.accessed = accessed
        self.container = container
        self.original_date = original_date
        
        self.title = title
        self.container_title = container_title
        self.collection_title = collection_title
        self.collection_number = collection_number
        self.original_title = original_title
        self.publisher = publisher
        self.publisher_place = publisher_place
        self.archive = archive
        self.archive_place = archive_place
        self.archive_location = archive_location
        self.event = event
        self.event_place = event_place
        self.page = page
        self.locator = locator
        self.version = version
        self.volume = volume
        self.number_of_volumes = number_of_volumes
        self.issue = issue
        self.chapter_number = chapter_number
        self.medium = medium
        self.status = status
        self.edition = edition
        self.section = section
        self.genre = genre
        self.note = note
        self.annote = annote
        self.abstract = abstract
        self.keyword = keyword
        self.number = number
        self.references = references
        self.URL = URL
        self.DOI = DOI
        self.ISBN = ISBN
        
        # internal use!
        self.citation_number = citation_number
        self.citation_label = citation_label
    
    
    def is_plural(self, key):
        # return string not a boolean, because that is what we get from the attribute in the other cases
        if not key in self.__dict__.keys():
            return "false"
        # for pages
        if key == "page":
            if len(self.page.split("-")) == 1:
                return "false"
            else:
                return "true"
        # for authors, editors and such
        if isinstance(self.__getattribute__(key), list):
            if len(self.__getattribute__(key)) == 1:
                return "false"
            else:
                return "true"
        # otherwise, singular by default
        return "false"


class Date(object):
    def __init__(self, year=None, month=None, day=None, other=""):
        self.year = year
        self.month = month
        self.day = day
        self.other = other
    
    # def __cmp__(self, other):
    #     if not isinstance(other, Date):
    #         return -1 #object.__cmp__(other)
    #         
    #     if int(self.year) > int(other.year):
    #         return +1
    #     elif int(self.year) < int(other.year):
    #         return -1
    #     else:
    #         if int(self.month) > int(other.month):
    #             return +1
    #         elif int(self.month) < int(other.month):
    #             return -1
    #         else:
    #             if int(self.day) > int(other.day):
    #                 return +1
    #             elif int(self.day) < int(other.day):
    #                 return -1
    #             else:
    #                 if self.other > other.other:
    #                     return +1
    #                 elif self.other < other.other:
    #                     return -1
    #                 else:
    #                     return 0


class Name(object):
    def __init__(self, given_name="", initials="", family_name="", natural_display_order="given-family", articular="", prefix="", suffix=""):
        self.prefix = prefix                # E.g. "Pope"
        self.given_name = given_name        # E.g. "John" or "J.W." or "Johan Willem"
        self.initials = initials
        self.articular = articular          # E.g. "van" or "de" or "d'"
        self.family_name = family_name      # E.g. "Arcus"
        self.suffix = suffix                # E.g. "junior"
        self.natural_display_order = natural_display_order  # family-given|given-family
    

