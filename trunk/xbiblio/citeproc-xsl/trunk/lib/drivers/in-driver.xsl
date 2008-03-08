<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:db="http://docbook.org/ns/docbook"
  xmlns:cite="http://purl.org/NET/xbiblio/cite"
  xmlns:course="http://purl.org/NET/xbiblio/course"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
  <xdoc:doc type="stylesheet">Input driver stylesheet. To add support for a new
    document type, add the appropriate xpath expression to the citerefs variable
    select statement. Document types should be namespaced.</xdoc:doc>
  <xsl:variable name="chapters" select="/"/>
  <xsl:variable name="citerefs" select="($chapters)//db:biblioref/(@linkend|@xlink:href),
                                        /course:syllabus//course:reading/@refid,
                                        //cite:biblioref/@key"/>
</xsl:stylesheet>
