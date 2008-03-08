<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"  xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"  xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:bib="http://purl.org/NET/xbiblio/citeproc"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xdoc xs bib cite" version="2.0">
  <xsl:preserve-space elements="bib:*"/>
  <xdoc:doc type="stylesheet">
    <xdoc:short>Output driver for the OASIS Open Document file format. This needs to be written!</xdoc:short>
    <xdoc:svnId>$Id: out-driver-open_document.xsl 14 2006-02-25 13:20:27Z bdarcus $</xdoc:svnId>
  </xdoc:doc>
  <xsl:template match="bib:p[@class='bibref']" mode="output-open_document">
    <text:block id="{@id}" class="bibref">
      <xsl:apply-templates mode="output-open_document"/>
    </text:block>
  </xsl:template>
  <xsl:template match="bib:span" mode="output-open_document">
    <text:inline class="{@class}">
      <xsl:apply-templates select="@font-weight" mode="output-open_document"/>
      <xsl:apply-templates select="@font-style" mode="output-open_document"/>
      <xsl:apply-templates mode="output-open_document"/>
    </text:inline>
  </xsl:template>
  <xsl:template match="bib:a" mode="output-open_document">
    <text:basic-link class="{@class}" internal-destination="{@href}">
      <xsl:apply-templates select="@font-weight" mode="output-open_document"/>
      <xsl:apply-templates select="@font-style" mode="output-open_document"/>
      <xsl:apply-templates mode="output-open_document"/>
    </text:basic-link>
  </xsl:template>
  <xsl:template match="bib:span/@font-weight" mode="output-open_document">
    <xsl:attribute name="font-weight">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="bib:span/@font-style" mode="output-open_document">
    <xsl:attribute name="font-style">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
</xsl:stylesheet>
