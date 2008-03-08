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
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns="http://purl.org/net/xbiblio/citeproc" 
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  exclude-result-prefixes="db xdoc xhtml xlink mods xs cs exist cp course dc dcterms biblio prism foaf rdf">
  <xsl:include href="config/CONFIG"/>
  <xsl:include href="config/strings.xsl"/>
  <xsl:include href="main/format-style.xsl"/>
  <xsl:include href="main/functions.xsl"/>
  <xsl:include href="main/sort.xsl"/>
  <xsl:include href="main/process-rdf.xsl"/>
  <xsl:include href="drivers/in-driver.xsl"/>
  <xsl:include href="drivers/out-drivers.xsl"/>
  <xsl:include href="VERSION"/>
  <!-- === licensed under CC-GNU GPL; see http://creativecommons.org/licenses/GPL/2.0 === -->
  <xsl:output name="xml" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="cs:*"/>
  <xdoc:doc type="stylesheet">
    <xdoc:short>Main CiteProc stylesheet.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2006, Bruce D’Arcus</xdoc:copyright>
  </xdoc:doc>
  <xdoc:doc>Sort order for bibliography.<xdoc:param type="string"/>
  </xdoc:doc>
  <xsl:param name="sort_order-bib" as="xs:string">
    <xsl:choose>
      <xsl:when test="$style-biblio/cs:sort/@algorithm">
        <xsl:value-of select="$style-biblio/cs:sort/@algorithm"/>
      </xsl:when>
      <xsl:otherwise>author-date</xsl:otherwise>
    </xsl:choose>
  </xsl:param>
  <xdoc:doc>A required parameter that specifies the CSL file to use for processing (minus the csl
      extension).<xdoc:param type="string"/>
  </xdoc:doc>
  <xsl:param name="citation-style" select="'apa'" as="xs:string"/>
  <xsl:variable name="styles" as="document-node()" select="doc(concat('../../../csl/styles/',$citation-style,'.csl'))"/>
  <xdoc:doc>Class of formatting type, drawn from the CSL file.<xdoc:param type="string"/>
  </xdoc:doc>
  <xsl:param name="citeclass" select="$styles/cs:style/@class"/>
  <xsl:variable name="style-citation" select="$styles/cs:style/cs:citation"/>
  <xsl:variable name="style-biblio" select="$styles/cs:style/cs:bibliography"/>
  <xsl:variable name="style-general" select="$styles/cs:style/cs:defaults"/>
  <xdoc:doc>first index the citations</xdoc:doc>
  <xsl:key name="refs" match="db:biblioref" use="@linkend|@xlink:href"/>
  <xdoc:doc>Creates a table against which to measure relative citation position.</xdoc:doc>
  <xsl:variable name="cite-position">
    <cp:refs>
      <cp:all>
        <xsl:for-each select="$citerefs">
          <cp:ref position="{position()}" id="{generate-id()}" key="{.}"/>
        </xsl:for-each>
      </cp:all>
      <cp:unique>
        <xsl:for-each-group select="$citerefs" group-by=".">
          <cp:ref position="{position()}" id="{generate-id()}" key="{.}"/>
        </xsl:for-each-group>
      </cp:unique>
    </cp:refs>
  </xsl:variable>
  <xdoc:doc>Constructs a list of unique references to pass to a query.</xdoc:doc>
  <xsl:variable name="citekeys">
    <xsl:if test="$bibdb='exist-xmldb'">(</xsl:if>
    <xsl:if test="$bibdb='sru'">%22</xsl:if>
    <xsl:for-each-group select="$citerefs" group-by=".">
      <xsl:if test="position() gt 1">
        <xsl:choose>
          <xsl:when test="$bibdb='exist-xmldb'">,%20</xsl:when>
          <xsl:otherwise>%20</xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:if test="$bibdb='exist-xmldb'">'</xsl:if>
      <xsl:value-of select="."/>
      <xsl:if test="$bibdb='exist-xmldb'">'</xsl:if>
    </xsl:for-each-group>
    <xsl:if test="$bibdb='sru'">%22</xsl:if>
    <xsl:if test="$bibdb='exist-xmldb'">)</xsl:if>
  </xsl:variable>

  <xsl:variable name="allrdf">
    <xsl:copy-of select="document($bibinfile)"/>
  </xsl:variable>
  <xsl:variable name="raw-biblist">
    <rdf:RDF>
      <xsl:for-each select="distinct-values($citerefs)">
        <xsl:message>
          <xsl:value-of select="."/>
        </xsl:message>
        <xsl:copy-of select="$allrdf/rdf:RDF/*[@rdf:about=current()]"/>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:variable>
  <xdoc:doc>Groups, sorts, and enhances content for processing; this is where most of the logic
    lies.</xdoc:doc>
  <xsl:variable name="enhanced-biblist">
    <rdf:RDF xmlns:cp="http://purl.org/net/xbiblio/citeproc">
      <xsl:choose>
        <xsl:when test="$sort_order-bib='citekey'">
          <xsl:apply-templates select="$raw-biblist" mode="sort_citekey"/>
        </xsl:when>
        <xsl:when test="$sort_order-bib='cited'">
          <xsl:apply-templates select="$raw-biblist" mode="sort_cited"/>
        </xsl:when>
        <xsl:when test="$sort_order-bib='author-date'">
          <xsl:apply-templates select="$raw-biblist" mode="sort_author-date"/>
        </xsl:when>
      </xsl:choose>
    </rdf:RDF>
  </xsl:variable>
  
  <xdoc:doc>Creates final formatted bibliography list. Depending on output format, transforms or
    just copies contents of the bib:formatted-biblist variable.</xdoc:doc>
  <xsl:template name="cp:format-bibliography">
    <xsl:param name="output-format" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$output-format='latex'">
        <xsl:apply-templates select="$cp:formatted-biblist" mode="output-latex"/>
      </xsl:when>
      <xsl:when test="$output-format='xhtml'">
        <xsl:apply-templates select="$cp:formatted-biblist" mode="output-xhtml"/>
      </xsl:when>
      <xsl:when test="$output-format='fo'">
        <xsl:apply-templates select="$cp:formatted-biblist" mode="output-fo"/>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="$biboutfile">
      <xsl:result-document href="{$biboutfile}" format="xml">
        <xsl:copy-of select="$enhanced-biblist"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>
  
  <xdoc:doc>In conjunction with bib:format-bib templates, formats bibliography list into an
    intermediate representation. The intermediate representation is similar to xhtml, but in the
    citeproc namespace.</xdoc:doc>
  <xsl:variable name="cp:formatted-biblist">
    <xsl:apply-templates select="$enhanced-biblist/rdf:RDF/*"
      mode="temp-placeholder"/>
  </xsl:variable>
  
  <xdoc:doc>Formats bibliography list into an intermediate representation.</xdoc:doc>
  <xsl:template match="/rdf:RDF/*" mode="temp-placeholder">
    <xsl:variable name="shorten-author" select="@cp:shorten-author"/>
    <xsl:variable name="use_reftype" select="@cp:use-reftype"/>
    <xsl:variable name="id" select="@rdf:about"/>
    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$sort_order-bib='author-year'">
          <xsl:value-of select="position()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$cite-position/cp:refs/cp:unique/cp:ref[@key=$id]/@position"/>
        </xsl:otherwise>
      </xsl:choose> 
    </xsl:variable>
    <xsl:apply-templates select="$style-biblio">
      <xsl:with-param name="cp:source" select="." as="element()" tunnel="yes"/>
      <xsl:with-param name="use_reftype" select="@cp:use-reftype" as="xs:string" tunnel="yes"/>
      <xsl:with-param name="cp:number" select="$number" as="xs:string" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xdoc:doc>formats citations</xdoc:doc>
  <xsl:template name="cp:format-citation">
    <xsl:param name="output-format" as="xs:string"/>
    <!-- create a temporary tree to hold the processing citations -->
    <xsl:variable name="intermediate-citation">
      <cp:span class="citation">
        <xsl:value-of select="$style-citation/@prefix"/>
        <xsl:choose>
          <xsl:when test="$sort_order-bib='author-date' or $citeclass='note-nobib'">
            <xsl:choose>
              <!-- FIX: add additional conditional for @ibid, configure formatting in CSL -->
              <xsl:when test="cp:ibid(.) and count(db:biblioref)=1">
                <cp:a class="citation" href="#{db:biblioref/@linkend}">
                  <xsl:text>ibid.</xsl:text>
                </cp:a>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="." mode="sort_citation_author-year"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="db:biblioref" mode="otherwise"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$style-citation/@suffix"/>
      </cp:span>
    </xsl:variable>
    <!-- 
    create formatted output by running appropriate output mode on the temporary
    tree in the intermediate-citation variable 
    -->
    <xsl:choose>
      <xsl:when test="$output-format='latex'">
        <xsl:apply-templates select="$intermediate-citation" mode="output-latex"/>
      </xsl:when>
      <xsl:when test="$output-format='xhtml'">
        <xsl:apply-templates select="$intermediate-citation" mode="output-xhtml"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="db:biblioref" mode="otherwise">
    <xsl:apply-templates select="$style-citation">
      <xsl:with-param name="cite-ref" select="." as="node()" tunnel="yes"/>
    </xsl:apply-templates>
    <xsl:if test="position() != last()">
      <xsl:value-of select="$style-citation/@delimiter"/>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
