<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cite="http://purl.org/NET/xbiblio/cite"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:bib="http://purl.org/NET/xbiblio/citeproc"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xdoc xs bib cite" version="2.0">
  <xsl:preserve-space elements="bib:*"/>
  <xdoc:doc type="stylesheet">
    <xdoc:short>Output driver for WordML. Needs to be written.</xdoc:short>
    <xdoc:svnId>$Id: out-driver-wordml.xsl 14 2006-02-25 13:20:27Z bdarcus $</xdoc:svnId>
  </xdoc:doc>
  <xsl:template match="bib:p[@class='bibref']" mode="output-wordml">
    <fo:block id="{@id}" class="bibref">
      <xsl:apply-templates mode="output-wordml"/>
    </fo:block>
  </xsl:template>
  <xsl:template match="bib:span" mode="output-wordml">
    <fo:inline class="{@class}">
      <xsl:apply-templates select="@font-weight" mode="output-wordml"/>
      <xsl:apply-templates select="@font-style" mode="output-wordml"/>
      <xsl:apply-templates mode="output-wordml"/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="bib:a" mode="output-wordml">
    <fo:basic-link class="{@class}" internal-destination="{@href}">
      <xsl:apply-templates select="@font-weight" mode="output-wordml"/>
      <xsl:apply-templates select="@font-style" mode="output-wordml"/>
      <xsl:apply-templates mode="output-wordml"/>
    </fo:basic-link>
  </xsl:template>
  <xsl:template match="bib:span/@font-weight" mode="output-wordml">
    <xsl:attribute name="font-weight">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="bib:span/@font-style" mode="output-wordml">
    <xsl:attribute name="font-style">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
</xsl:stylesheet>
