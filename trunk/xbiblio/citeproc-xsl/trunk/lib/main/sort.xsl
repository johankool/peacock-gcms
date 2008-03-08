<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xdoc="http://www.pnp-software.com/XSLTdoc" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mods="http://www.loc.gov/mods/v3" 
  xmlns:course="http://purl.org/net/xbiblio/course"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" 
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:biblio="http://purl.org/net/biblio#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/" 
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:cs="http://purl.org/net/xbiblio/csl" 
  xmlns:cp="http://purl.org/net/xbiblio/citeproc"
  xmlns="http://purl.org/net/xbiblio/citeproc" 
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="db xdoc xhtml mods xs cs exist xlink cp course dc dcterms biblio prism foaf rdf">
  <!-- === licensed under CC-GNU GPL; see http://creativecommons.org/licenses/GPL/2.0 === -->
  <xdoc:doc type="stylesheet">
    <xdoc:short>Handles sorting.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2006, Bruce D’Arcus</xdoc:copyright>
  </xdoc:doc>
  <!-- =================================================================== -->
  <!-- |    begin bibliography templates                                 | -->
  <!-- =================================================================== -->
  <xdoc:doc>Grouping, sorting and parameter setting to properly handle the
    author-year class bibliographies.</xdoc:doc>
  <xsl:template match="rdf:RDF" mode="sort_author-date">
    <xsl:variable name="bibref" select="*"/>
    <xsl:for-each-group select="$bibref" group-by="cp:grouping-key(.)">
      <xsl:sort select="current-grouping-key()"/>
      <xsl:variable name="bibrefs-for-author-sorted-by-year"
        as="element()*">
        <xsl:perform-sort select="current-group()">
          <xsl:sort select="cp:year(.)"/>
          <!-- add third-level sort on month-day -->
        </xsl:perform-sort>
      </xsl:variable>
      <xsl:variable name="first-bibref-for-author" as="element()"
        select="$bibrefs-for-author-sorted-by-year[1]"/>
      <xsl:variable name="sort-on" select="current-grouping-key()"/>
      <xsl:for-each-group select="$bibrefs-for-author-sorted-by-year"
        group-adjacent="cp:year(.)">
        <xsl:for-each select="current-group()">
          <xsl:variable name="year-suffix">
            <xsl:if test="last() > 1">
              <xsl:number value="position()" format="a"/>
            </xsl:if>
          </xsl:variable>
          <xsl:variable name="shorten-author" as="xs:boolean"
            select="$style-biblio/@subsequent-author-substitute and not(. is $first-bibref-for-author)"/>
          <xsl:apply-templates select="." mode="enhance">
            <xsl:with-param name="year" select="current-grouping-key()"/>
            <xsl:with-param name="year-suffix" select="$year-suffix"/>
            <xsl:with-param name="shorten-author" select="$shorten-author" as="xs:boolean"/>
            <xsl:with-param name="sort-on" select="$sort-on"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:for-each-group>
    </xsl:for-each-group>
  </xsl:template>
  <xsl:template match="rdf:RDF" mode="sort_cited">
    <xsl:variable name="sort-on" 
        select="$cite-position/cp:refs/cp:unique/cp:ref[@key='{@rdf:about}']/@position"/>
    <xsl:for-each select="*">
      <xsl:sort select="$sort-on"/>
      <xsl:apply-templates select="." mode="enhance">
        <xsl:with-param name="year" select="cp:year(.)"/>
        <xsl:with-param name="sort-on" select="$sort-on"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="rdf:RDF" mode="sort_citekey">
    <xsl:for-each select="*">
      <xsl:sort select="@rdf:ID|@rdf:about"/>
      <xsl:apply-templates select="." mode="enhance">
        <xsl:with-param name="year" select="cp:year(.)"/>
         <!-- TODO: fix -->
        <xsl:with-param name="sort-on" select="@ID"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>
  <xdoc:doc>Adds data necessary for further processing to the in-memory
    bibliographic list, so it need not be calcuated subsequently.</xdoc:doc>
  <xsl:template match="rdf:RDF/*" mode="enhance">
    <xsl:param name="shorten-author"/>
    <xsl:param name="year"/>
    <xsl:param name="year-suffix"/>
    <xsl:param name="sort-on"/>
    <biblio:Reference rdf:about="{@rdf:about}" cp:shorten-author="{$shorten-author}"
      cp:refclass="{cp:refclass(.)}" cp:reftype="{cp:reftype(.)}"
      cp:use-reftype="{cp:use_csl-reftype(.)}" cp:sort-on="{$sort-on}"
      cp:biblist-position="{position()}">
      <cp:year>
        <xsl:value-of select="$year"/>
      </cp:year>
      <xsl:if test="$year-suffix">
        <cp:year-suffix>
          <xsl:value-of select="$year-suffix"/>
        </cp:year-suffix>
      </xsl:if>
      <xsl:if
        test="not(biblio:authors or foaf:maker)">
        <cp:noname-substitute>
          <xsl:value-of select="cp:grouping-key(.)"/>
        </cp:noname-substitute>
      </xsl:if>
      <xsl:copy-of select="*"/>
    </biblio:Reference>
  </xsl:template>
  <!-- =================================================================== -->
  <!-- |    begin citation templates                                     | -->
  <!-- =================================================================== -->
  <xdoc:doc>Grouping/sorting author-year class citations.</xdoc:doc>
  <xsl:template match="db:citation" mode="sort_citation_author-year">
    <!-- store citation for future use -->
    <xsl:variable name="citation" select="." as="element()"/>
    <xsl:variable name="local-cite-style" select="db:biblioref/@xrefstyle" as="node()?"/>
    <xsl:variable name="idref"
       select="db:biblioref/(@linkend|@xlink:href), course:reading/@refid"/>
    <xsl:variable name="bibref"
       select="$enhanced-biblist/rdf:RDF/*[@rdf:about=$idref]"/>
      <xsl:for-each-group select="$bibref" group-by="@cp:sort-on">
        <xsl:sort select="current-grouping-key()"/>
        <xsl:variable name="refs-for-author-sorted-by-year"
          as="element()*">
          <xsl:perform-sort select="current-group()">
            <xsl:sort select="cp:year"/>
          </xsl:perform-sort>
        </xsl:variable>
        <xsl:variable name="first-ref-for-author" as="element()"
          select="$refs-for-author-sorted-by-year[1]"/>
        <xsl:variable name="last-ref-for-author" as="element()"
          select="$refs-for-author-sorted-by-year[position() = last()]"/>
        <xsl:for-each-group select="$refs-for-author-sorted-by-year"
          group-adjacent="cp:year">
          <xsl:for-each select="current-group()">
            <xsl:variable name="first-in-author-group"
              select=". is $first-ref-for-author" as="xs:boolean"/>
            <xsl:variable name="last-in-author-group"
              select=". is $last-ref-for-author" as="xs:boolean"/>
            <xsl:variable name="id" select="@rdf:about"/>
            <!-- earlier the cite-ref variable was defined as just element(), but
            for some reason this yielded an empty-sequence error in one case -->
            <xsl:variable name="cite-ref" as="node()">
               <xsl:sequence select="$citation/db:biblioref[(@linkend|@xlink:href)=$id]"/>
            </xsl:variable>
            <xsl:apply-templates select="$style-citation">
              <xsl:with-param name="first-in-author-group"
                    select="$first-in-author-group" as="xs:boolean" tunnel="yes"/>
              <xsl:with-param name="last-in-author-group"
                    select="$last-in-author-group" as="xs:boolean" tunnel="yes"/>
              <xsl:with-param name="local-cite-style" select="$local-cite-style" as="node()?" tunnel="yes"/>
              <xsl:with-param name="cite-ref" select="$cite-ref" as="node()" tunnel="yes"/>
              <xsl:with-param name="cp:source" select="." as="element()" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:for-each-group>
        <!-- FIX ME: config in CSL -->
        <xsl:if test="position() != last()">; </xsl:if>
      </xsl:for-each-group>
  </xsl:template>
  <xsl:template match="db:citation" mode="sort_cited">
    XXXX
  </xsl:template>
</xsl:stylesheet>
