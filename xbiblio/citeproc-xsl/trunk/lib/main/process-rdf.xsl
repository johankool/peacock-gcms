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
  xmlns:vcard="http://nwalsh.com/rdf/vCard"
  xmlns:biblio="http://purl.org/net/biblio#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/" 
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:cs="http://purl.org/net/xbiblio/csl" 
  xmlns:cp="http://purl.org/net/xbiblio/citeproc"
  xmlns="http://purl.org/net/xbiblio/citeproc" 
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  exclude-result-prefixes="db xdoc xhtml mods xs vcard cs exist cp course dc dcterms biblio prism foaf rdf">
  <!-- === licensed under CC-GNU GPL; see http://creativecommons.org/licenses/GPL/2.0 === -->
  <xdoc:doc type="stylesheet">
    <xdoc:short>Processes RDF content into a formatted intermediate representation.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2006, Bruce D’Arcus</xdoc:copyright>
  </xdoc:doc>
  <xsl:key name="nodeID" match="*" use="@rdf:nodeID"/>
  <xsl:key name="about" match="*" use="@rdf:about"/>
  <!-- punctuation variables -->
  <xsl:variable name="bibref-before">
    <xsl:text> </xsl:text>
  </xsl:variable>
  <xsl:variable name="bibref-after">
    <xsl:text>.</xsl:text>
  </xsl:variable>
  <xsl:template match="cp:noname-substitute">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <span class="creator">
      <xsl:value-of select="$prefix"/>
      <xsl:value-of select="."/>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
  <xdoc:doc>A wrapper to call the cp:get-rdf function.</xdoc:doc>
  <xsl:template name="property">
    <xsl:apply-templates select="if (@rdf:resource or @rdf:nodeID) then cp:get-rdf(.) else *"/>
  </xsl:template>
  <xsl:template match="biblio:authors">
    <span class="authors">
      <xsl:call-template name="contributors"/>
    </span>
  </xsl:template>
  <xsl:template match="biblio:editors">
    <span class="editors">
      <xsl:call-template name="contributors"/>
    </span>
  </xsl:template>
  <xsl:template name="contributors">
    <xsl:param name="sort-order" tunnel="yes"/>
    <xsl:param name="alternate" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="main-level" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="prefix" tunnel="yes"/>
    <xsl:param name="suffix" tunnel="yes"/>
    <xsl:param name="multi-authors" as="element()?" tunnel="yes"/>
    <xsl:variable name="multi-author-min" 
	select="if ($multi-authors/@min-authors) then ($multi-authors/@min-authors) else xs:integer('99')" as="xs:integer"/>
    <xsl:variable name="use-multi-author-handling"
      select="xs:integer(count(*/rdf:li)) ge $multi-author-min" as="xs:boolean"/>
    <xsl:value-of select="$prefix"/>
    <xsl:for-each select="*/rdf:li">
      <xsl:variable name="name-as-sort" as="xs:boolean"
        select="$sort-order='all' or ($sort-order='first-author' and position()=1) and $main-level"/>
      <xsl:variable name="role" select="substring-before(name(../../.), 's')" as="xs:string"/>
      <span class="{$role}">
        <xsl:choose>
          <xsl:when test="$alternate"/>
          <xsl:when test="$use-multi-author-handling">
            <xsl:choose>
              <xsl:when test="position() le xs:integer($multi-authors/@use-first)">
                <xsl:apply-templates select="." mode="name">
                  <xsl:with-param name="name-as-sort" tunnel="yes" as="xs:boolean" select="$name-as-sort"/>
                </xsl:apply-templates>
                <xsl:choose>
                  <xsl:when test="position() = last()"/>
                  <!-- FIX ME: I think the below should not apply to last of names before et al, but doesn't work. -->
                  <xsl:otherwise>, </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="position() = last()">
                  <xsl:value-of select="$style-general/cs:names/@et-al"/>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="name">
              <xsl:with-param name="name-as-sort" tunnel="yes" as="xs:boolean" select="$name-as-sort"/>
            </xsl:apply-templates>
            <xsl:choose>
              <xsl:when test="position() = last()"/>
              <xsl:when test="position() = last() - 1"> and </xsl:when>
              <xsl:otherwise>, </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </span>
    </xsl:for-each>
    <xsl:value-of select="$suffix"/>
  </xsl:template>

  <xsl:template match="rdf:li" mode="name">
    <xsl:call-template name="property"/>
    <xsl:choose>
      <xsl:when test="position() = last()"/>
      <xsl:when test="position() = last() - 1"> and </xsl:when>
      <xsl:otherwise>, </xsl:otherwise>
    </xsl:choose>  
  </xsl:template>

  <xsl:template match="foaf:Person">
    <xsl:param name="short-names" as="xs:boolean" tunnel="yes"/>
    <xsl:param name="name-as-sort" as="xs:boolean" tunnel="yes"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:value-of select="$prefix"/> 
    <xsl:choose>
      <xsl:when test="$short-names">
        <xsl:apply-templates select="foaf:surname"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$name-as-sort">
            <xsl:apply-templates select="foaf:surname"/>
            <!-- TODO: config in CSL -->
            <xsl:value-of select="$style-general/cs:contributor/cs:name/@sort-separator"/>
            <xsl:apply-templates select="foaf:givenname"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="foaf:givenname"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="foaf:surname"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$suffix"/>
  </xsl:template>
   
  <xsl:template match="foaf:Organization">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:value-of select="$prefix"/> 
    <xsl:value-of select="foaf:name"/>    
    <xsl:value-of select="$suffix"/> 
  </xsl:template>
   
  <xsl:template match="foaf:Organization" mode="place">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <span class="publisher place">
      <xsl:value-of select="$prefix"/> 
      <xsl:value-of select="vcard:adr/vcard:Address/vcard:locality"/>  
      <xsl:value-of select="$suffix"/> 
    </span>
  </xsl:template>
   
  <xsl:template match="foaf:givenname">
    <span class="given-name">
    <xsl:choose>
      <xsl:when test="$style-general/cs:contributor/cs:name/@initialize-with">
        <!-- to initialize properly, givennames must simply be space-separated -->
        <xsl:for-each select="tokenize(., ' ')">
          <xsl:value-of select="substring(.,1,1)"/>
          <xsl:value-of select="$style-general/cs:contributor/cs:name/@initialize-with"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
    </span>
  </xsl:template>
  <xsl:template match="foaf:surname">
    <span class="family-name">
    <xsl:value-of select="."/>
    </span>
  </xsl:template>
  <xsl:template match="cp:year">
    <xsl:param name="source"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <span class="year">
      <xsl:value-of select="$prefix"/>
      <xsl:apply-templates/>
      <!-- we can access newly creatod key element to append suffix -->
      <xsl:apply-templates select="../cp:year-suffix"/>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
  <xsl:template match="cp:year-suffix">
    <xsl:apply-templates/>
  </xsl:template>
  <xdoc:doc>Renders complete title/subtitle combination.</xdoc:doc>
  <xsl:template match="dc:title">
    <xsl:param name="alternate" as="xs:boolean?"/>
    <xsl:param name="relation"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:choose>
      <!-- check; delicate -->
      <xsl:when test="$alternate=true"/>
      <xsl:otherwise>
        <xsl:value-of select="$prefix"/>
        <span class="{$relation} title">
          <xsl:if test="$font-weight">
            <xsl:attribute name="font-weight">
              <xsl:value-of select="$font-weight"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="$font-style">
            <xsl:attribute name="font-style">
              <xsl:value-of select="$font-style"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:value-of select="."/>
        </span>
        <xsl:value-of select="$suffix"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the following templates need to be combined -->
  <xsl:template match="prism:volume">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:variable name="type" select="@type"/>
    <span class="volume">
      <xsl:if test="$font-weight">
        <xsl:attribute name="font-weight">
          <xsl:value-of select="$font-weight"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$font-style">
        <xsl:attribute name="font-style">
          <xsl:value-of select="$font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$prefix"/>
      <xsl:value-of select="$style-general/cs:terms/cs:locator[@type=$type]/@cs:renderas-single"/>
      <xsl:value-of select="."/>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
  <xsl:template match="prism:number">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:variable name="type" select="@type"/>
    <span class="issue">
      <xsl:if test="$font-weight">
        <xsl:attribute name="font-weight">
          <xsl:value-of select="$font-weight"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$font-style">
        <xsl:attribute name="font-style">
          <xsl:value-of select="$font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$prefix"/>
      <xsl:value-of select="$style-general/cs:terms/cs:locator[@type=$type]/@cs:renderas-single"/>
      <xsl:value-of select="."/>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
  <xsl:template match="prism:startingPage">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <xsl:variable name="unit" select="@unit"/>
    <span class="locator">
      <xsl:if test="$font-weight">
        <xsl:attribute name="font-weight">
          <xsl:value-of select="$font-weight"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$font-style">
        <xsl:attribute name="font-style">
          <xsl:value-of select="$font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$prefix"/>
      <xsl:value-of select="$style-general/cs:terms/cs:locator[@type=$unit]/@cs:renderas-multiple"/>
      <xsl:value-of select="."/>
      <xsl:if test="../prism:endingPage">
        <xsl:text>–</xsl:text>
        <xsl:value-of select="cp:number-condense(.,../prism:endingPage)"/>
      </xsl:if>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
  <xsl:template match="biblio:note">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="font-style"/>
    <xsl:param name="font-weight"/>
    <span class="note">
      <xsl:if test="$font-weight">
        <xsl:attribute name="font-weight">
          <xsl:value-of select="$font-weight"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$font-style">
        <xsl:attribute name="font-style">
          <xsl:value-of select="$font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$prefix"/>
      <xsl:value-of select="."/>
      <xsl:value-of select="$suffix"/>
    </span>
  </xsl:template>
</xsl:stylesheet>
