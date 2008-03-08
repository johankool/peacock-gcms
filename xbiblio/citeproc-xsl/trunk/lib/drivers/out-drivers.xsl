<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cite="http://purl.org/net/xbiblio/cite"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:cp="http://purl.org/net/xbiblio/citeproc"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xdoc xs cp cite" version="2.0">
  <xsl:preserve-space elements="cp:*"/>
  <xsl:include href="out-driver-fo.xsl"/>
  <xsl:include href="out-driver-latex.xsl"/>
  <xsl:include href="out-driver-xhtml.xsl"/>
  <xdoc:doc type="stylesheet">
    <xdoc:short>Output driver stylesheet.</xdoc:short>
    <xdoc:detail>
      <p>Templates to take the content of the bib:formatted-biblist variable
        (which is xhtml) and transform it into final output.</p>
    </xdoc:detail>
    <xdoc:svnId>$Id: out-drivers.xsl 14 2006-02-25 13:20:27Z bdarcus $</xdoc:svnId>
  </xdoc:doc>
</xsl:stylesheet>
