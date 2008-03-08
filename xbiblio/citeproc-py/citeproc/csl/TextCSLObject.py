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
TextCSLObject.py

Created by Johan Kool on 2008-02-02.
Copyright (c) 2008 Johan Kool. All rights reserved.
"""

import sys
import os
import unittest

# ## The text element is used to print simple property variables (titles and such) or 
# ## constant texts.
# div {
#   
#   ## There are four types of <text> element:
#   ##     <text variable="(variable")/> - adds a variable belonging to this item
#   ##          (see below for a list)
#   ##     <text macro="(macro)"/> - adds a macro, specified using a <macro> element
#   ##          in the main body of the CSL
#   ##     <text term="(term)"/> - adds a localized term
#   ##     <text value="(text)"/> - adds the text in the value field. use sparingly.
#   ##          when dealing with localizable text, <text term="(term)"/> should be
#   ##          used, even if this means defining a new term.
#   cs-text =
#     element cs:text {
#       formatting,
#       ((((attribute variable {
#             list { variables+ }
#           }
#           & delimiter)
#          | attribute macro { token }),
#         attribute form { "short" | "long" }?)
#        | (attribute term { cs-terms },
#           attribute form { cs-term-forms }?,
#           include-period,
#           attribute plural { xsd:boolean }?)
#        | attribute value { text })
#     }
#   
#   ## The number markup directive matches the first number found in a field, 
#   ## and returns only that component. If no number is detected, the result 
#   ## is empty. A non-empty number may be subject to further formatting consisting 
#   ## of a form attribute whose value may be numeric, ordinal or roman to format 
#   ## it as a simple number (the default), an ordinal number (1st, 2nd, 3rd etc) 
#   ## or roman (i, ii, iii, iv etc). The text-case can also apply to capitalize 
#   ## the roman numbers for instance. The other normal formatting rules apply 
#   ## too (font-style, ...). When used in a conditional, number tests if 
#   ## there is a number present, allowing conditional formatting.
#   cs-number =
#     element cs:number {
#       formatting,
#       attribute variable { "edition" | "volume" | "issue" | "number" | "number-of-volumes" },
#       attribute form { "numeric" | "ordinal" | "roman" }?
#     }
#   variables =
#     
#     ## the primary title for the cited item
#     "title"
#     | 
#       ## the secondary title for the cited item; for a book chapter, this 
#       ## would be a book title, for an article the journal title, etc.
#       "container-title"
#     | 
#       ## the tertiary title for the cited item; for example, a series title
#       "collection-title"
#     | 
#       ## collection number; for example, series number
#       "collection-number"
#     | 
#       ## title of a related original version; often useful in cases of translation
#       "original-title"
#     | 
#       ## the name of the publisher
#       "publisher"
#     | 
#       ## the location of the publisher
#       "publisher-place"
#     | 
#       ## the name of the archive
#       "archive"
#     | 
#       ## the location of the archive
#       "archive-place"
#     | 
#       ## the location within an archival collection (for example, box and folder)
#       "archive_location"
#     | 
#       ## the name or title of a related event such as a conference or hearing
#       "event"
#     | 
#       ## the location or place for the related event
#       "event-place"
#     | 
#       ##
#       "page"
#     | 
#       ## a description to locate an item within some larger container or 
#       ## collection; a volume or issue number is a kind of locator, for example.
#       "locator"
#     | 
#       ## version description
#       "version"
#     | 
#       ## volume number for the container periodical
#       "volume"
#     | 
#       ## refers to the number of items in multi-volume books and such
#       "number-of-volumes"
#     | 
#       ## the issue number for the container publication
#       "issue"
#     | 
#       ##
#       "chapter-number"
#     | 
#       ## medium description (DVD, CD, etc.)
#       "medium"
#     | 
#       ## the (typically publication) status of an item; for example "forthcoming"
#       "status"
#     | 
#       ## an edition description
#       "edition"
#     | 
#       ## a section description (for newspapers, etc.)
#       "section"
#     | 
#       ##
#       "genre"
#     | 
#       ## a short inline note, often used to refer to additional details of the resource
#       "note"
#     | 
#       ## notes made by a reader about the content of the resource
#       "annote"
#     | 
#       ##
#       "abstract"
#     | 
#       ##
#       "keyword"
#     | 
#       ## a document number; useful for reports and such
#       "number"
#     | 
#       ## for related referenced resources; this is here for legal case 
#       ## histories, but may be relevant for other contexts.
#       "references"
#     | 
#       ##
#       "URL"
#     | 
#       ##
#       "DOI"
#     | 
#       ##
#       "ISBN"
#     | 
#       ## the number used for the in-text citation mark in numeric styles
#       "citation-number"
#     | 
#       ## the label used for the in-text citation mark in label styles
#       "citation-label"
# }

from FormattingCSLObject import FormattingCSLObject

class TextCSLObject(FormattingCSLObject):
    def __init__(self, attrs):
        super(TextCSLObject, self).__init__(attrs)


class TextCSLObjectTests(unittest.TestCase):
    def setUp(self):
        pass


if __name__ == '__main__':
    unittest.main()