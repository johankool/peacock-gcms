<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:xi="http://www.w3.org/2001/XInclude"
	xmlns:cs="http://purl.org/NET/xbiblio/csl"
	xmlns:cp="http://purl.org/net/xbiblio/citeproc"
	xmlns:exist="http://exist.sourceforge.net/NS/exist"
	exclude-result-prefixes="xdoc xhtml mods xs cp cs exist xi">
	<xsl:import href="../citeproc.xsl"/>
	<xsl:output method="xhtml" omit-xml-declaration="yes" encoding="utf-8"
	indent="yes"/>
	<xdoc:doc type="stylesheet">
		<xdoc:short>Stylesheet to transform XHTML-MMD (MultiMarkDown) to XHTML.</xdoc:short>
		<xdoc:author>Johan Kool</xdoc:author>
		<xdoc:copyright>2006, Johan Kool</xdoc:copyright>
		<xdoc:detail>
			<p>MultiMarkDown (MMD) formatted XHTML comes in, formatted XHTML goes out.</p>
		</xdoc:detail>
	</xdoc:doc>
	<xsl:param name="include-bib">yes</xsl:param>
	<xsl:param name="bibdb">flatfile</xsl:param>
	<xsl:param name="bibinfile">rdfdata.xml</xsl:param>
	
	<!-- Make a complete (almost) copy of the xhtml file -->
	<!-- FIXME: make the copy also include DOCTYPE etc. -->
	<xsl:template match="@*|node()">
	   <xsl:copy>
		  <xsl:apply-templates select="@*|node()"/>
	   </xsl:copy>
	</xsl:template>
	
	<!-- Format and insert citations -->
	<xsl:template match="//xhtml:span[@class='markdowncitation']">
			<xsl:call-template name="cp:format-citation">
				<xsl:with-param name="output-format" select="'xhtml'"/>
			</xsl:call-template>
	</xsl:template>
	<xsl:template match="//xhtml:span[@class='externalcitation']">
			<xsl:call-template name="cp:format-citation">
			    <xsl:with-param name="refid" select="./a[1]/@id" tunnel="yes"/>
				<xsl:with-param name="output-format" select="'xhtml'"/>
			</xsl:call-template>
	</xsl:template>
	
	<!-- Replace MMD bibliography section with CiteProc's equivalent -->
	<xsl:template match="//xhtml:div[@class='bibliography']">
		<div class="bibliography">
			<h2>References</h2>
			<xsl:call-template name="cp:format-bibliography">
				<xsl:with-param name="output-format" select="'xhtml'"/>
			</xsl:call-template>
		</div>
	</xsl:template>
	
</xsl:stylesheet>
