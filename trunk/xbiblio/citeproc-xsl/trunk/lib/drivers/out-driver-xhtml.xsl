<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cite="http://purl.org/NET/xbiblio/cite"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:cp="http://purl.org/net/xbiblio/citeproc"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xdoc xs cp xhtml cite" version="2.0">
  <xsl:preserve-space elements="cp:*"/>
  <xdoc:doc type="stylesheet">Output driver for XHTML.</xdoc:doc>
  <xsl:template match="cp:item[@class='bibref']" mode="output-xhtml">
    <p id="{@id}" class="bibref">
      <xsl:apply-templates mode="output-xhtml"/>
    </p>
  </xsl:template>
  <xsl:template match="cp:span" mode="output-xhtml">
    <span class="{@class}">
      <xsl:if test="@font-weight or @font-style">
        <xsl:attribute name="style">
          <xsl:apply-templates select="@font-weight"/>
          <xsl:apply-templates select="@font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="output-xhtml"/>
    </span>
  </xsl:template>
  <xsl:template match="cp:a" mode="output-xhtml">
    <a class="{@class}" href="{@href}">
      <xsl:if test="@font-weight or @font-style">
        <xsl:attribute name="style">
          <xsl:apply-templates select="@font-weight"/>
          <xsl:apply-templates select="@font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  <xsl:template match="cp:span/@font-weight">
    <xsl:text>font-weight: </xsl:text>
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="cp:span/@font-style">
    <xsl:text>font-style: </xsl:text>
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
