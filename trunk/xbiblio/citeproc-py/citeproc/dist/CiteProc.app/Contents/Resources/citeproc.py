#! /usr/bin/env python
# Copyright 2006-2008 Johan Kool

"""CiteProc for Python (version 0.1 (c) 2006-2008 Johan Kool)

Generates citations and references for DocBook and MarkDown documents according to a CSL file from reference data stored in MODS, RDF and/or BIBTEX file format and/or on the website CiteULike.org.

Usage: python citeproc.py [options]

Options:

NOTE: CiteProc is still in development. Not all options work yet as described here.

> citation style file (required)
  -c ..., --csl=...       use specified csl file or URL

> reference file (at least one option required)
  -m ..., --mods=...      use specified mods file or URL
  -r ..., --rdf=...       use specified rdf file or URL
  -b ..., --bibtex=...    use specified bibtex file or URL
  -w ..., --citeulike-username   your username at CiteULike.org

> document file (one option only required)
  -d ..., --docbook=...   use specified docbook file or URL
  -j ..., --markdown=...  use specified markdown file or URL

> output file (optional)
  -o ..., --output=...    save result specified output path

> miscellaneous (optional)
  -h, --help              show this help
  -l                      log debugging information while parsing

Examples:
  python citeproc.py -c ./apa.csl -m ./references.mods -d ./docbook.xml -o output.xml
  python citeproc.py -c ./apa.csl -r ./references.rdf -j ./text.markdown -o output.markdown
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

# import utilitary functions
import misc.toolbox
                          
# import custom objects   
from citation import Citation, CitationGroup
from reference import Reference  
                          
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
        # load CSL file
        self.CSLStyle = self.loadCSL(csl)
        
        # load input files
        self.referenceType = referenceType
        self.loadReferenceSource(referenceSource)
        self.documentType = documentType
        self.loadDocumentSource(documentSource)
        
        # load textDocDriver
        if documentType == "docbook":
            textDocDriver = DocBookDriver(self.documentSource)
        else:
            raise TextDocumentSourceError, "Document type not recognized or not yet implemented."
            
        # find citations groups
        citationGroups = textDocDriver.citationGroups()
        
        # get unique citations
        uniqueCitations = self.uniqueCitations(citationGroups)
        
        # load referenceDocDriver
        if referenceType == "rdf":
            referenceDocDriver = RDFDriver(self.referenceSource)
        elif referenceType == "mods":
            referenceDocDriver = MODSDriver(self.referenceSource)
        else:
            raise ReferenceSourceError, "Reference type not recognized or not yet implemented."
        
        # find references for citations
        references = referenceDocDriver.referencesForCitations(uniqueCitations)
        
        # format
        self.CSLStyle.formatText(citationGroups, references)
        
        # fetch results
        formattedCitationGroups = self.CSLStyle.formattedCitationGroups
        formattedBibliography = self.CSLStyle.formattedBibliography
        
        # merge into source document and save to output
        textDocDriver.placeCitations(formattedCitationGroups)

        # merge into source document and save to output
        textDocDriver.placeBibliography(formattedCitationGroups)
        
        # save
        textDocDriver.save(output)
        
        # TODO clean up
        
        if _debug == 1:
            self.printCitations()
            self.printReferences()
            print self.formattedCitations()
            if self.CSLStyle.formattedTextForBibliography():
                print "\n\nBIBLIOGRAPHY:\n\n"
                print self.CSLStyle.formattedTextForBibliography().encode('utf-8')
            print "\n\nXML OUTPUT:\n\n"
            myfile = open(output, 'r')
            
            # Print out and number each line
            count =  0
            while 1:
                lineStr = myfile.readline()
                if not(lineStr):
                    break
                
                count = count + 1
                print "#:",count,lineStr.rstrip()
                
            myfile.close()
    
    def _load(self, source):
        """load XML input source, return parsed XML document
        
        - a URL of a remote XML file ("http://diveintopython.org/kant.xml")
        - a filename of a local XML file ("~/diveintopython/common/py/kant.xml")
        - standard input ("-")
        - the actual XML document, as a string
        """
        sock = misc.toolbox.openAnything(source)
        # see http://www.rexx.com/~dkuhlman/pyxmlfaq.html for xml parse ideas
        xmldoc = minidom.parse(sock).documentElement
        sock.close()
        return xmldoc
    
    def loadCSL(self, csl):
        # Create an instance of the Handler.
        handler = CSLDocumentHandler()
        # Create an instance of the parser.
        parser = make_parser()
        # Set the content handler.
        parser.setContentHandler(handler)
        inFile = open(csl, 'r')
        # Start the parse.
        parser.parse(inFile)                                        # [10]
        # Alternatively, we could directly pass in the file name.
        #parser.parse(inFileName)
        inFile.close()
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
    
    # DEBUG METHODS
    
    def printCitations(self):
        print "\n\nCITATIONS:\n\n"
        for citationGroup in self.CSLStyle.citationGroups:
            # print "Citation group:",
            # for citation in citationGroup.citations:
            #     print citation.key + str(citation.firstOccurence),
            # print
            print citationGroup.formattedCitationGroup
    
    def formattedCitations(self):
        result = ""
        for citationGroup in self.citations:
            result += self.textForCitationGroup(citationGroup) + "\n"
        return result
    
    def printReferences(self):
        print "\n\nREFERENCES:\n\n"
        for reference in self.CSLStyle.references:
            if reference.formattedReference:
                print reference.formattedReference.encode('utf-8')



def usage():
    print __doc__

def main(argv):
    global _debug
    _debug = 1
    
    if _debug == 1:
        # should be emptied upon release (for debug convenience only)
        csl = "/Users/jkool/Developer/Biblio2/citeproc-py/misc/cfb.csl"
        referenceType = "rdf"
        referenceSource = "../../citeproc-xsl/trunk/data/data.rdf"
        referenceType = "mods"
        referenceSource = "../test/Test.mods"
        documentType = "docbook"
        documentSource = "../test/docbook-test.xml"
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
