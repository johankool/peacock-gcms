<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc" 
  exclude-result-prefixes="xdoc" version="2.0">
  
  <!-- import default document stylesheet -->
  <xsl:import href="dbng-xhtml.xsl"/>
  
  <xdoc:doc type="stylesheet">Demonstrates how to use CiteProc with SRU servers,
    and also how to customize it by using xsl:import to override default parameters.</xdoc:doc>
  
  <!-- then override default paraemters; could also override templates -->
  <xsl:param name="citation-style" select="'apa-en'"/>
  <xsl:param name="bibdb" select="'sru'"/>
  <xsl:param name="server_url"
    select="'http://polaris.ipoe.uni-kiel.de/refs/sru.php?'"/>
  <xsl:param name="email" select="'user@refbase.net'"/>
  
</xsl:stylesheet>
