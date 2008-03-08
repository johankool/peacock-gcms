<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dct="http://purl.org/dc/terms/"
  xmlns:m="http://www.loc.gov/mods/v3" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns="http://purl.org/net/biblio#" exclude-result-prefixes="m" version="1.0">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates/>
    </rdf:RDF>
  </xsl:template>
  <xsl:template match="m:mods">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="m:relatedItem[@type='host']/m:genre='academic journal'">JournalArticle</xsl:when>
        <xsl:when test="m:relatedItem[@type='host']/m:genre='book'">Chapter</xsl:when>
        <xsl:when test="m:relatedItem[@type='host']/m:genre='periodical' and
          not(m:relatedItem[@type='host']/m:genre='academic journal')">Article</xsl:when>
        <xsl:otherwise>Book</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$type}">
      <xsl:attribute name="rdf:ID">
        <xsl:value-of select="@ID"/>
      </xsl:attribute>
      <xsl:apply-templates select="m:name"/>
      <xsl:apply-templates select="m:titleInfo"/>
      <xsl:apply-templates select="m:originInfo"/>
      <xsl:apply-templates select="m:relatedItem[@type='host']"/>
      <xsl:apply-templates select="m:part | m:relatedItem[@type='host']/m:part"/>
    </xsl:element>
  </xsl:template>
  <xsl:template name="author-sort-string">
    <xsl:if test="m:name[m:role/m:roleTerm='author']">
      <authorListString>
        <xsl:for-each select="m:name[m:role/m:roleTerm='author']">
          <xsl:call-template name="names-sort-string"/>
          <xsl:if test="position() != last()">
            <xsl:text>; </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </authorListString>
    </xsl:if>
  </xsl:template>
  <xsl:template match="m:titleInfo">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@type='abbreviated'">shortTitle</xsl:when>
        <xsl:otherwise>title</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$type}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="m:title">
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="m:subTitle">
    <xsl:text>: </xsl:text>
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="m:name">
    <xsl:variable name="role">
      <xsl:choose>
        <xsl:when test="m:role/m:roleTerm='editor'">editor</xsl:when>
        <xsl:when test="m:role/m:roleTerm='translator'">translator</xsl:when>
        <xsl:otherwise>creator</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@type='corporate'">Organization</xsl:when>
        <xsl:otherwise>Person</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$role}">
      <Agent>
        <sort-string>
          <xsl:call-template name="names-sort-string"/>
        </sort-string>
        <!--  
        <n>
          <xsl:element name="{$type}">
            <xsl:call-template name="names"/>
          </xsl:element>
        </n>
        -->
      </Agent>
    </xsl:element>
  </xsl:template>
  <xsl:template name="names">
    <givenName>
      <xsl:value-of select="m:namePart[@type='given']"/>
    </givenName>
    <familyName>
      <xsl:value-of select="m:namePart[@type='family']"/>
    </familyName>
  </xsl:template>
  <xsl:template name="names-sort-string">
    <xsl:value-of select="m:namePart[@type='family']"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="m:namePart[@type='given']"/>
  </xsl:template>
  <xsl:template match="m:role|m:genre|m:resourceType"/>
  <xsl:template match="m:originInfo">
    <date>
      <xsl:choose>
        <xsl:when test="m:dateIssued">
          <xsl:value-of select="m:dateIssued"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="m:relatedItem[@type='host']/m:originInfo/m:dateIssued"/>
        </xsl:otherwise>
      </xsl:choose>
    </date>
    <xsl:if test="m:publisher">
      <publisher>
        <Organization>
          <name>
            <xsl:value-of select="m:publisher"/>
          </name>
          <place>
            <xsl:value-of select="m:place/m:placeTerm"/>
          </place>
        </Organization>
      </publisher>
    </xsl:if>
  </xsl:template>
  <xsl:template match="m:relatedItem[@type='host']">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="m:genre='book'">Book</xsl:when>
        <xsl:when test="m:genre='academic journal'">Journal</xsl:when>
        <xsl:otherwise>Periodical</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <partOf>
      <xsl:element name="{$type}">
        <xsl:apply-templates select="m:name"/>
        <xsl:apply-templates select="m:titleInfo"/>
        <xsl:apply-templates select="m:publisher"/>
      </xsl:element>
    </partOf>
  </xsl:template>
  <xsl:template match="m:relatedItem[@type='host']/m:originInfo|//m:date"/>
  <xsl:template match="m:part">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="m:detail">
    <xsl:variable name="type">
      <xsl:value-of select="@type"/>
    </xsl:variable>
    <xsl:element name="{$type}">
      <xsl:value-of select="m:number"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="m:abstract">
    <abstract>
      <xsl:value-of select="."/>
    </abstract>
  </xsl:template>
  <xsl:template match="m:extent[@unit='page']">
    <pages>
      <xsl:value-of select="m:start"/>
      <xsl:text>-</xsl:text>
      <xsl:value-of select="m:end"/>
    </pages>
  </xsl:template>
</xsl:stylesheet>
