#! /usr/bin/env python
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

"""CiteProc-Py Copyright (c) 2006, 2008  Johan Kool

This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING. This is free software, and you are welcome to redistribute it under certain conditions; for details see COPYING.

CiteProc-Py version 0.1
Generates citations and references for DocBook and MarkDown documents according to a CSL file from reference data stored in MODS, RDF and/or BIBTEX file format and/or on the website CiteULike.org.

Usage: python citeproc.py [options]
Usage: python -m citeproc [options]

Options:

NOTE: CiteProc is still in development. Not all options work yet as described here.

> citation style file (required)
  -c ..., --csl=...       use specified csl file or URL

> reference file (at least one option required)
  -m ..., --mods=...      use specified mods file or URL
  -r ..., --rdf=...       use specified rdf file or URL
  -b ..., --bibtex=...    use specified bibtex file or URL
  -w ..., --citeulike-username=...   your username at CiteULike.org

> document file (one option only required)
  --bibliography          all references in reference file are exported as HTML
  -d ..., --docbook=...   use specified docbook file or URL
  -j ..., --markdown=...  use specified markdown file or URL

> output file (optional)
  -o ..., --output=...    save result specified output path

> miscellaneous (optional)
  -h, --help              show this help
  -l                      log debugging information while parsing

Examples:
  python citeproc.py -c ./apa.csl -m ./references.mods -d ./docbook.xml -o output.xml
  python citeproc.py -c http://server/harvard1 -r ./references.rdf -j ./text.markdown -o output.markdown
  python citeproc.py -c ./nar.csl -w johankool -j ./text.markdown -o output.markdown

More info:
  http://xbiblio.sf.net
"""
from xml.sax import handler, make_parser

from xml.dom import minidom
import random
import sys
import getopt
import codecs

import dircache # used for debugging

# import utilitary functions
import misc.toolbox
                          
# import custom objects   
from citation import Citation, CitationGroup
from reference import Reference, Name, Date
                          
# import drivers          
from drivers.driver_rdf import RDFDriver
from drivers.driver_mods import MODSDriver
# from drivers.driver_bibtex import *
# from drivers.driver_citeulike import *
# note-to-self: have a look at RISImport.py for adding RIS support
# http://www.openoffice.org/files/documents/124/3078/RISImport.py
from drivers.driver_docbook import DocBookDriver
# from drivers.driver_markdown import *

from csl.CSLDocumentHandler import CSLDocumentHandler
from csl.StyleCSLObject import StyleCSLObject

class SourceError(Exception): pass
class NoSourceError(SourceError): pass
class TextDocumentSourceError(Exception): pass
class ReferenceSourceError(Exception): pass

class CiteProcessor:
    """generates citations and references"""
    
    # INIT/LOAD METHODS
    
    def __init__(self, csl, referenceSource, referenceType, documentSource, documentType, output):  
        csldir = csl
        cslfiles = dircache.listdir(csl)
        for csl in cslfiles:
            if csl == ".svn" or csl == ".DS_Store":
                continue
            csl = csldir + csl
            print csl    
            # load CSL file
            self.CSLStyle = self.loadCSL(csl)
        
            # # export to out.csl for verification during debug
            # if _debug == 1:
            #     f=open(output, 'w')
            #     f.write(u"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"+self.CSLStyle.xml().encode('utf8'))
            #     f.close()
        
            # # load input files
            # self.referenceType = referenceType
            # self.loadReferenceSource(referenceSource)
            # self.documentType = documentType
            # self.loadDocumentSource(documentSource)
            # 
            # # load textDocDriver
            # if documentType == "docbook":
            #     textDocDriver = DocBookDriver(self.documentSource)
            # else:
            #     raise TextDocumentSourceError, "Document type not recognized or not yet implemented."
            #     
            # # find citations groups
            # citationGroups = textDocDriver.citationGroups()
            # 
            # # get unique citations
            # uniqueCitations = self.uniqueCitations(citationGroups)
            # 
            # # load referenceDocDriver
            # if referenceType == "rdf":
            #     referenceDocDriver = RDFDriver(self.referenceSource)
            # elif referenceType == "mods":
            #     referenceDocDriver = MODSDriver(self.referenceSource)
            # else:
            #     raise ReferenceSourceError, "Reference type not recognized or not yet implemented."
            # 
            # # find references for citations
            # references = referenceDocDriver.referencesForCitations(uniqueCitations)
        
            # TODO implement reference source drivers
        
            if _debug:
                Citation1 = Citation(citekey="id1")
                Citation2 = Citation(citekey="id2")
                Citation3 = Citation(citekey="id3")
                Citation4 = Citation(citekey="id1")
                Citation5 = Citation(citekey="id4")
                Citation6 = Citation(citekey="id5")
                Citation7 = Citation(citekey="id6")
                Citation8 = Citation(citekey="id7")
                Citation9 = Citation(citekey="id8")
                Citation10 = Citation(citekey="id4")
                
                Date1 = Date(2007)
                Name1 = Name(given_name=u"Johan", family_name=u"Kool")
                Name2 = Name(prefix=u"Pope", given_name=u"John Paul", suffix=u"II")
                Name3 = Name(given_name=u"Klaas", articular=u"de", family_name=u"Vries")
                Name4 = Name(family_name=u"丁", given_name=u"力波", natural_display_order="family-given")
                Name5 = Name(family_name="Ding", given_name="Libo", natural_display_order="family-given")

                Reference1 = Reference(
                    citekey="id1", 
                    reftype="article-journal", 
                    title=u"Article-journal title", 
                    issued=Date1,
                    volume = u"33",
                    page=u"76-95",
                    issue=u"4",
                    container_title=u"Journal of Same Kind",
                    authors=[Name1,Name4,Name3,Name5],
                    editors=[Name3,Name2,Name1]
                )
                
                Reference2 = Reference(
                    citekey="id2",
                    reftype="book",
                    authors=[Name3,Name2,Name1],
                    title=u"Book title",
                    editors=[Name1,Name3],
                    issued=Date1,
                    URL=u"http://johankool.nl",
                    accessed=Date1
                )
                
                Reference3 = Reference(
                    citekey="id3",
                    reftype="article",
                    authors=[Name5,Name2],
                    title=u"Article title",
                    issued=Date1,
                    volume = u"33",
                    page=u"76-95",
                    issue=u"4",
                    container_title=u"Journal of Some Kind"
                )
            
                Reference4 = Reference(
                    citekey = "id4", 
                    reftype = "article-newspaper", 
                    issued = Date(year=2007, month=1, day=1), 
                    title = u"Some Title", 
                    container_title = u"Journal News", 
                    page = u"A5", 
                    URL = u"http://ex.net/1", 
                    accessed = Date(year=2007, month=11, day=12)
                )
            
                Reference5 = Reference(
                    citekey = "id5", 
                    reftype = "book",
                    issued = Date(year=2000),
                    title = u"Splitting the Difference",
                    publisher = u"University of Chicago Press",
                    publisher_place = u"Chicago",
                    authors = [Name(family_name=u"Doniger", given_name=u"Wendy")],
                    edition = "3"
                )
            
                Reference6 = Reference(
                    citekey = "id6",
                    reftype = "book",
                    issued = Date(year=1994),
                    title = u"The social organization of sexuality: Sexual practices in the United States",
                    publisher = u"University of Chicago Press",
                    publisher_place = u"Chicago",
                    authors = [
                       Name(family_name=u"Laumann", given_name=u"Edward O."),
                       Name(family_name=u"Gagnon", given_name=u"John H."),
                       Name(family_name=u"Michael", given_name=u"Robert T."),
                       Name(family_name=u"Michaels", given_name=u"Stuart")
                    ]
                )
            
                Reference7 = Reference(
                    citekey = "id7",
                    reftype = "article-journal",
                    issued = Date(year=1998),
                    title = u"The origin of altruism",
                    container_title = u"Nature",
                    issue = u"393",
                    page = u"639–640",
                    authors = [
                        Name(family_name=u"Smith", given_name=u"John Maynard")
                    ]
                )
            
                Reference8 = Reference(
                    citekey = "id8",
                    reftype = "chapter",
                    issued = Date(year=2000),
                    title = u"Introduction: A Chapter Title",
                    container_title = u"Edited Book Title",
                    collection_title = u"Series Title",
                    publisher = u"ABC Books",
                    publisher_place = u"New York",
                    authors = [
                        Name(family_name=u"Doe", given_name=u"Jane"),
                        Name(family_name=u"Smith", given_name=u"John")
                     ],
                    editors = [
                        Name(family_name=u"Doe", given_name=u"Jane"),
                        Name(family_name=u"Smith", given_name=u"John")
                     ]
                )
                
                citationGroups = [
                    CitationGroup([Citation1, Citation2]),
                    CitationGroup([Citation3,]),
                    CitationGroup([Citation4,]),
                    CitationGroup([Citation5,Citation6]),
                    CitationGroup([Citation7,]),
                    CitationGroup([Citation8,]),
                    CitationGroup([Citation9,]),
                    CitationGroup([Citation10,])]
                
                references = [
                    Reference1,
                    Reference2,
                    Reference3,
                    Reference4,
                    Reference5,
                    Reference6,
                    Reference7,
                    Reference8]
                
                reference_keys = {}
                for reference in references:
                    reference_keys[reference.citekey] = reference
                
                i = 0
                for citationGroup in citationGroups:
                    for citation in citationGroup.citations:
                        citation.occurence_index = i
                        citation.reference = reference_keys[citation.citekey]
                        if citation.reference.citation_number <> "":
                            reference.citation_number = str(i+1)
                        i += 1
                    
            # format
            self.CSLStyle.formatText(citationGroups, references)
        
            # fetch results
            if _debug:
                print "--- Start Citations ---"
                for index in range(len(citationGroups)):
                    print self.CSLStyle.formatted_text_for_citationgroup_at_index(index).encode('utf8')
                print "--- End Citations ---\n"
                print "--- Start Bibliography ---"
                print self.CSLStyle.formatted_text_for_bibliography.encode('utf8')
                print "--- End Bibliography ---\n"
        
            # TODO export as bibliography html
            if documentType == "bibliography":
                html = """<html></html>"""
        
            # # merge into source document and save to output
            #  textDocDriver.placeCitations(formattedCitationGroups)
            # 
            #  # merge into source document and save to output
            #  textDocDriver.placeBibliography(formattedCitationGroups)
            #  
            #  # save
            #  textDocDriver.save(output)
        
    
    
    def loadCSL(self, csl):
        """load XML input source, return parsed XML document
        
        - a URL of a remote XML file ("http://diveintopython.org/kant.xml")
        - a filename of a local XML file ("~/diveintopython/common/py/kant.xml")
        - standard input ("-")
        - the actual XML document, as a string
        """
        # see http://www.rexx.com/~dkuhlman/pyxmlfaq.html for xml parse ideas
        # Create an instance of the Handler.
        handler = CSLDocumentHandler()
        # Create an instance of the parser.
        parser = make_parser()
        # Set the content handler.
        parser.setContentHandler(handler)
        # open whatever it is that we got
        sock = misc.toolbox.openAnything(csl)
        # Start the parse.  
        parser.parse(sock)
        # Close the sock
        sock.close()
        # return the root
        return handler.root
    
    def loadReferenceSource(self, source):
        """load referenceSource (file containing MODS records)"""
        self.referenceSource = self._load(source)
        return
    
    def loadDocumentSource(self, source):
        """load source (file containing citations)"""
        self.documentSource = self._load(source)
    
    def uniqueCitations(self, citationGroups):
        return ["id1", "id2", "id3"]
    
    def output(self):
        """output generated text"""
        return ""
        



def usage():
    print __doc__

def main(argv):
    global _debug
    _debug = 1
        
    if _debug == 1:
        # should be emptied upon release (for debug convenience only)
        csl = "/Users/jkool/Developer/xbiblio-related/Zotero CSL Repository/"
        referenceType = "rdf"
        referenceSource = "../../citeproc-xsl/trunk/data/data.rdf"
        referenceType = "mods"
        referenceSource = "../test/Test.mods"
        documentType = "bibliography"
        documentSource = None #"../test/docbook-test.xml"
    # this is a default
    output = "output.xml"
    # print sys.path
    try:
        opts, args = getopt.getopt(argv, "hc:m:r:d:j:o:l", ["help", "csl=", "mods=", "rdf=", "docbook=", "markdown=", "output"])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt == '-l':
            #global _debug
            _debug = 1
        elif opt in ("-c", "--csl"):
            csl = arg
        elif opt in ("-m", "--mods"):
            referenceType = "mods"
            referenceSource = arg
        elif opt in ("-r", "--rdf"):
            referenceType = "rdf"
            referenceSource = arg
        elif opt in ("-b", "--bibtex"):
            referenceType = "bibtex"
            referenceSource = arg
        elif opt in ("--bibliography"):
            documentType = "bibliography"
            documentSource = None            
        elif opt in ("-d", "--docbook"):
            documentType = "docbook"
            documentSource = arg
        elif opt in ("-j", "--markdown"):
            documentType = "markdown"
            documentSource = arg
        elif opt in ("-o", "--output"):
            output = arg
    
    source = "".join(args)
    
    # TODO: we should allow multiple referenceSources (of mixed types) and figure out ourselves in which source a certain needed citekey is available
    k = CiteProcessor(csl, referenceSource, referenceType, documentSource, documentType, output)
    print k.output()


if __name__ == "__main__":
    main(sys.argv[1:])
