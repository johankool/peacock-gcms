<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cs="http://purl.org/NET/xbiblio/csl"
  xmlns:bib="http://purl.org/NET/xbiblio/citeproc"
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  exclude-result-prefixes="db xdoc xhtml mods xs cs exist bib">
  <xsl:import href="../citeproc.xsl"/>
  <xsl:output method="xhtml" encoding="utf-8" indent="yes"/>
  <xsl:strip-space elements="db:*"/>
  <xdoc:doc type="stylesheet">
    <xdoc:short>Stylesheet to transform DocBook NG to FO.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2005, Bruce D’Arcus</xdoc:copyright>
    <xdoc:detail>
      <p>To integrate CiteProc formatting into other stylesheets, import the
        "citeproc.xsl" file. To format the bibliography, add a template that
        does a xsl:call-template of the "bib:format-bibliography" template, with
        an output-format parameter. Likewise, to format the citations, add a
        template that does a xsl:call-template of the "bib:format-citation"
        template.</p>
    </xdoc:detail>
  </xdoc:doc>
  <xsl:variable name="title">
    <xsl:value-of select="db:*/db:info/db:title"/>
    <xsl:if test="db:*/db:info/db:subtitle">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="db:*/db:info/db:subtitle"/>
    </xsl:if>
  </xsl:variable>
  <xsl:template match="/">
    <fo:root>
      <fo:layout-master-set>
        <fo:simple-page-master master-name="default" margin="1in">
          <fo:region-body margin="0.5in"/>
        </fo:simple-page-master>
      </fo:layout-master-set>
      <fo:page-sequence master-reference="default" initial-page-number="1">
        <fo:flow flow-name="xsl-region-body">
          <xsl:apply-templates/>
        </fo:flow>
      </fo:page-sequence>
    </fo:root>
  </xsl:template>
  <xsl:template match="db:article">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="db:citation">
    <xsl:call-template name="bib:format-citation">
      <xsl:with-param name="output-format" select="'fo'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:info">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="db:title">
    <fo:block font-weight="bold" font-family="'Myriad Pro', sans-serif"
      margin-bottom="24pt" text-align="center">
      <xsl:apply-templates/>
      <xsl:if test="../db:subtitle">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
      </xsl:if>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:subtitle"/>
  <xsl:template match="db:chapter">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="db:section">
    <xsl:choose>
      <xsl:when test="not(parent::db:section)">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="db:section/db:title | db:section/db:info/db:title">
    <xsl:variable name="depth" select="count(ancestor::db:section)"/>
    <xsl:choose>
      <xsl:when test="$depth=0">
        <fo:block font-weight="bold" font-family="'Myriad Pro', sans-serif"
          margin-top="18pt">
          <xsl:apply-templates/>
          <xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
        </fo:block>
      </xsl:when>
      <xsl:when test="$depth=1">
        <fo:block font-weight="bold" font-family="'Myriad Pro', sans-serif"
          margin-top="18pt">
          <xsl:apply-templates/>
          <xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
        </fo:block>
      </xsl:when>
      <xsl:when test="$depth=2">
        <fo:block font-weight="bold" font-family="'Myriad Pro', sans-serif"
          margin-top="18pt">
          <xsl:apply-templates/>
          <xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
        </fo:block>
      </xsl:when>
      <xsl:when test="$depth=3">
        <fo:block font-weight="bold" font-family="'Myriad Pro', sans-serif"
          margin-top="18pt">
          <xsl:apply-templates/>
          <xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
        </fo:block>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="db:section/db:subtitle | db:section/db:info/db:subtitle"
    mode="subtitle">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="db:section/db:subtitle | db:section/db:info/db:subtitle"/>
  <xsl:template match="db:author">
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:firstname"/>
      <xsl:text/>
      <xsl:apply-templates select="db:surname"/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:affiliation">
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:orgname"/>
    </fo:block>
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:orgdiv"/>
    </fo:block>
    <xsl:apply-templates select="address"/>
  </xsl:template>
  <xsl:template match="db:address">
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:street"/>
    </fo:block>
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:city"/>
      <xsl:text>, </xsl:text>
      <xsl:apply-templates select="db:state"/>
      <xsl:text/>
      <xsl:apply-templates select="db:postcode"/>
    </fo:block>
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates select="db:email"/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:abstract">
    <fo:block font-family="'Myriad Pro', sans-serif">Abstract</fo:block>
    <fo:block font-family="'Hoefler Text', serif">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:blockquote">
    <fo:block font-family="'Hoefler Text', serif" margin-left="0.5in"
      margin-right="0.5in">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:phrase">
    <xsl:text>“</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>”</xsl:text>
  </xsl:template>
  <xsl:template match="db:citetitle">
    <fo:inline font-family="'Hoefler Text', serif" font-style="italic">
      <xsl:value-of select="."/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="db:quote">
    <xsl:text>“</xsl:text>
    <xsl:apply-templates select="text() | db:nq"/>
    <xsl:text>”</xsl:text>
    <xsl:if test="db:citation">
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="db:citation"/>
    </xsl:if>
  </xsl:template>
  <xsl:template match="db:nq">
    <xsl:text>”</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>“</xsl:text>
  </xsl:template>
  <xsl:template match="db:footnote">
    <xsl:variable name="inc">
      <xsl:number level="any" count="db:footnote"/>
    </xsl:variable>
    <xsl:text>[</xsl:text>
    <fo:basic-link internal-destination="#fn{$inc}">
      <xsl:value-of select="$inc"/>
    </fo:basic-link>
    <xsl:text>]</xsl:text>
  </xsl:template>
  <xsl:template match="db:footnote" mode="footnote-list">
    <xsl:variable name="incr">
      <xsl:number level="any" count="db:footnote"/>
    </xsl:variable>
    <fo:block id="fn{$incr}">
      <fo:basic-link internal-destination="#fnm{$incr}">
        <xsl:value-of select="$incr"/>
      </fo:basic-link>
      <xsl:text>. &#xa0;</xsl:text>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:acronym">
    <fo:block font-family="'Hoefler Text', serif" font-variant="smallcap">
      <xsl:value-of select="."/>
    </fo:block>
  </xsl:template>
  <xsl:template match="db:orderedlist">
    <fo:list-block>
      <xsl:apply-templates select="db:listitem"/>
    </fo:list-block>
  </xsl:template>
  <xsl:template match="db:listitem">
    <fo:list-item>
      <xsl:value-of select="db:para"/>
    </fo:list-item>
  </xsl:template>
  <xsl:template
    match="db:section/db:para | db:chapter/db:para | db:article/db:para">
    <xsl:choose>
      <xsl:when test="position() = 1">
        <fo:block font-family="'Hoefler Text', serif" line-height="17pt">
          <xsl:apply-templates/>
        </fo:block>
      </xsl:when>
      <xsl:otherwise>
        <fo:block font-family="'Hoefler Text', serif" first-indent="0.5in"
          line-height="17pt">
          <xsl:apply-templates/>
        </fo:block>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
