<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mods="http://www.loc.gov/mods/v3" xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cs="http://purl.org/NET/xbiblio/csl"
  xmlns:bib="http://purl.org/NET/xbiblio/citeproc"
  xmlns:exist="http://exist.sourceforge.net/NS/exist" exclude-result-prefixes="db xdoc xhtml mods xs cs exist bib">
<xsl:include href="../citeproc.xsl"/>
<xsl:output method="text" version="1.0" encoding="utf-8" indent="no"/>
<xsl:strip-space elements="*"/>
<xdoc:doc type="stylesheet">
  <xdoc:short>Stylesheet to transform DocBook NG to LaTeX.</xdoc:short>
  <xdoc:author>Bruce D’Arcus</xdoc:author>
  <xdoc:copyright>2004, Bruce D’Arcus</xdoc:copyright>
  <xdoc:svnId>$Id: dbng-latex.xsl 14 2006-02-25 13:20:27Z bdarcus $</xdoc:svnId>
  <xdoc:detail>
    <p>This is to be a demo of the multi-output format capabilities of CiteProc.</p>
  </xdoc:detail>
</xdoc:doc>
<xsl:template match="/">
<xsl:if test="db:article">\documentclass[10pt]{amsart}</xsl:if>
<xsl:if test="db:book|db:chapter">\documentclass[10pt]{amsbook}</xsl:if>
<xsl:text>
\usepackage[utf8]{inputenc}
\usepackage{url}
\usepackage{lettrine}
  
\usepackage{hyperref}

\usepackage[LY1]{fontenc}
\usepackage{CronosProOSF}
\usepackage{WarnockProOSF}
%\usepackage{palatino}

\input protcode.tex
  
\catcode`\$=12

\setcounter{secnumdepth}{0}

\linespread{1.2}

\begin{document}
</xsl:text>
<xsl:apply-templates select="/*/db:info"/>
<xsl:apply-templates select="//db:section | /*/db:para"/>
\section*{References}

\pagestyle{empty}

{\everypar = {\hangafter=1 \parindent 0pt \hangindent 15pt\parskip 5pt}
  
<xsl:call-template name="bib:format-bibliography">
  <xsl:with-param name="output-format" select="'latex'"/>
</xsl:call-template>
<xsl:text>

\end{document}</xsl:text>
</xsl:template>

<xsl:template match="db:info">
<xsl:text>\title{</xsl:text><xsl:value-of select="db:title"/><xsl:text>}
</xsl:text>
<xsl:text>\author{</xsl:text><xsl:apply-templates select="db:author"/><xsl:text>}</xsl:text>
<xsl:text>\address{</xsl:text><xsl:apply-templates select="db:author/db:affiliation"/><xsl:text>}</xsl:text>

<xsl:if test="db:abstract">
<xsl:text>\begin{abstract}</xsl:text>
<xsl:apply-templates select="db:abstract/db:para"/>
<xsl:text>\end{abstract}</xsl:text>
</xsl:if>
<xsl:text>
\setprotcode\font 
 {\it \setprotcode \font} 
 {\bf \setprotcode \font} 
 {\bf \it \setprotcode \font} 
 \pdfprotrudechars=2

\maketitle

</xsl:text>
</xsl:template>

<xsl:template match="db:author">
<xsl:value-of select="db:firstname"/><xsl:text> </xsl:text><xsl:apply-templates select="db:surname"/>
</xsl:template>

<xsl:template match="db:affiliation">
  <xsl:apply-templates select="db:orgname"/><xsl:text>\\
  </xsl:text>
  <xsl:apply-templates select="db:orgdiv"/><xsl:text>\\
  </xsl:text>
  <xsl:apply-templates select="db:address/db:street"/><xsl:text>\\
  </xsl:text>
  <xsl:apply-templates select="db:address/db:city"/><xsl:text>, </xsl:text>
  <xsl:apply-templates select="db:address/db:state"/><xsl:text> </xsl:text>
  <xsl:apply-templates select="db:addess/db:postcode"/><xsl:text>\\
  </xsl:text>
  <xsl:text>\url{</xsl:text><xsl:apply-templates select="db:address/db:email"/><xsl:text>}</xsl:text>
</xsl:template>

  <xsl:template match="db:section">
    <xsl:variable name="depth" select="count(ancestor::db:section)"/>
    <xsl:choose>
      <xsl:when test="$depth=0">
        <xsl:text>\section{</xsl:text><xsl:apply-templates select="db:title"/><xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="$depth=1">
        <xsl:text>\subsection{</xsl:text><xsl:apply-templates select="db:title"/><xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="$depth=2">
        <xsl:text>\subsubsection{</xsl:text><xsl:apply-templates select="db:title"/><xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x000A;</xsl:text>
        <xsl:text>% Sections nested too deeply for default output</xsl:text>
        <xsl:text>&#x000A;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="db:para"/>
  </xsl:template>

<xsl:template match="db:footnote">
  <xsl:text>\footnote{</xsl:text>
  <xsl:apply-templates select="db:para"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="db:citation">
  <xsl:if test="($citeclass='note-bib' or $citeclass='note-nobib') and not(ancestor::db:footnote)">\footnote{</xsl:if>
  <xsl:call-template name="bib:format-citation">
    <xsl:with-param name="output-format" select="'latex'"/>
  </xsl:call-template>
  <xsl:if test="($citeclass='note-bib' or $citeclass='note-nobib') and not(ancestor::db:footnote)">}</xsl:if>
</xsl:template>

<xsl:template match="db:para">
  <xsl:choose>
    <xsl:when test="parent::db:footnote">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>&#x000A;</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>&#x000A;</xsl:text>    
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- inlines -->

<xsl:template match="db:emphasis">
  <xsl:text>\emph{</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="db:blockquote">
  <xsl:text>\begin{quote}</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>\end{quote}</xsl:text>
</xsl:template>
  
<xsl:template match="db:foreignphrase | db:citetitle">
  <xsl:text>\emph{</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>}</xsl:text>
</xsl:template>
  
<xsl:template match="db:acronym">
  <xsl:text>\textsc{</xsl:text>
  <xsl:value-of select="lower-case(.)"/>
  <xsl:text>}</xsl:text>
</xsl:template>
  
<xsl:template match="db:phrase[@role='socalled']">
  <xsl:text>“</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>” </xsl:text>
</xsl:template>
  
<xsl:template match="db:quote">
  <xsl:text>“</xsl:text>
  <xsl:apply-templates select="text() | db:emphasis | db:nq"/>
  <xsl:text>” </xsl:text>
  <xsl:apply-templates select="db:citation"/>
</xsl:template>

</xsl:stylesheet>