<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cite="http://purl.org/NET/xbiblio/cite"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:bib="http://purl.org/NET/xbiblio/citeproc"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xdoc cite xs bib" version="2.0">
  <xdoc:doc type="stylesheet">Output driver for LaTeX.</xdoc:doc>
  <xsl:template match="bib:item" mode="output-latex">
    <xsl:text>\noindent&#xA;</xsl:text>
    <xsl:apply-templates mode="output-latex"/>
    <xsl:text>&#xA;&#xA;</xsl:text>
  </xsl:template>
  <xsl:template match="bib:span" mode="output-latex">
    <xsl:if test="@font-style='italic'">\textit{</xsl:if>
    <xsl:if test="@font-weight='bold'">\bold{</xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="@font-style='italic'">}</xsl:if>
    <xsl:if test="@font-weight='bold'">}</xsl:if>
  </xsl:template>
</xsl:stylesheet>
