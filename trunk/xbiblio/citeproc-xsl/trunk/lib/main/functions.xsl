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
  exclude-result-prefixes="db xdoc xhtml mods xs xlink cs exist cp course dc dcterms biblio prism foaf rdf">
  <!-- === licensed under CC-GNU GPL; see http://creativecommons.org/licenses/GPL/2.0 === -->
  <xdoc:doc type="stylesheet">
    <xdoc:short>CiteProc functions.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2006, Bruce D’Arcus</xdoc:copyright>
  </xdoc:doc>
  <!-- |||| date functions |||| -->
  <xdoc:doc>when given a bibliographic record, returns its publication year</xdoc:doc>
  <xsl:function name="cp:year">
    <xsl:param name="bibref" as="element()"/>
    <xsl:for-each select="$bibref">
      <xsl:value-of select="substring((dc:date|dcterms:issued),1,4)"/>
    </xsl:for-each>
  </xsl:function>
  <!-- |||| number handling functions |||| -->
  <xdoc:doc>Collapses a page range according to the Chicago algorithm. Probably needs to be
    generalized.</xdoc:doc>
  <xsl:function name="cp:number-condense">
    <xsl:param name="begin"/>
    <xsl:param name="end"/>
    <xsl:choose>
      <xsl:when test="$begin castable as xs:integer">
        <xsl:variable name="begin" select="xs:integer($begin)" as="xs:integer"/>
        <xsl:choose>
          <xsl:when test="$begin gt 100 and $begin mod 100 and $begin idiv 100 eq $end idiv 100">
            <xsl:value-of select="$end mod 100"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$end"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$end"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>Constructs an authors string for grouping and sorting. This function concatenates all
    authors into a string so that multiple-authors get correctly grouped. Where no author exists it
    substitutes based on CSL definitions.</xdoc:doc>
  <xsl:function name="cp:grouping-key" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:variable name="sort-on" select="cp:sort_on($bibref)" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$sort-on='author'">
         <xsl:choose>
            <xsl:when test="$bibref/biblio:authors">
               <xsl:value-of separator=";">
                  <xsl:for-each select="$bibref/biblio:authors/*/rdf:li">
                     <xsl:variable name="agent" as="element()">
                        <xsl:sequence select="if (@rdf:resource or @rdf:nodeID) then cp:get-rdf(.) else *"/>
                     </xsl:variable>
                     <xsl:value-of select="if ($agent/foaf:surname) then (string-join(($agent/foaf:surname, $agent/foaf:givenname), ','))
                            else ($agent/foaf:name)"/>
                  </xsl:for-each>
               </xsl:value-of>
            </xsl:when>
            <xsl:otherwise>
               <!-- TODO : fix -->
               <xsl:variable name="agent" as="element()">
                 <xsl:for-each select="$bibref/foaf:maker[1]">
                   <xsl:sequence select="if (@rdf:resource or @rdf:nodeID) then cp:get-rdf(.) else *"/>
                 </xsl:for-each>
               </xsl:variable>
               <xsl:value-of select="if ($agent/foaf:surname) then (string-join(($agent/foaf:surname, $agent/foaf:givenname), ','))
                            else ($agent/foaf:name)"/>
             </xsl:otherwise>
         </xsl:choose>
      </xsl:when>
      <xsl:when test="$sort-on='container-title'">
        <xsl:for-each select="$bibref/dcterms:isPartOf">
          <xsl:variable name="container" as="element()">
            <xsl:sequence select="cp:get-rdf(.)"/>
          </xsl:variable>
          <xsl:value-of select="$container/dc:title"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$sort-on='title'">
        <xsl:value-of select="$bibref/dc:title"/>
      </xsl:when>
      <xsl:when test="$sort-on='anonymous'">
        <xsl:value-of select="'Anonymous'"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>Determines what to sort on.</xdoc:doc>
  <xsl:function name="cp:sort_on" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:variable name="use-reftype" select="cp:use_csl-reftype($bibref)"/>
    <xsl:variable name="csl_path" select="if ($citeclass='note') then
      $style-citation/cs:layout/cs:item[not(@position='subsequent')]/cs:choose/cs:type[@name=$use-reftype]
      else $style-biblio/cs:layout/cs:item/cs:choose/cs:type[@name=$use-reftype]"/>
    <xsl:choose>
      <xsl:when test="$csl_path/cs:author[1]">
        <xsl:choose>
          <xsl:when test="$bibref/(biblio:authors or foaf:maker)">
            <xsl:value-of select="'author'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$style-general/cs:author/cs:substitute/*/cs:editor and $bibref/(biblio:editors or biblio:editor)">
                <xsl:value-of select="'editor'"/>
              </xsl:when>
              <xsl:when test="$style-general/cs:author/cs:substitute/*/cs:title[@relation='container']">
                <xsl:value-of select="'container-title'"/>
              </xsl:when>
              <xsl:when test="$style-general/cs:author/cs:substitute/*/cs:title[not(@relation)]">
                <xsl:value-of select="'title'"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'anonymous'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$csl_path/cs:title[1]">
        <xsl:value-of select="'title'"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>Determines which CSL definition to use for any given reference record.</xdoc:doc>
  <xsl:function name="cp:use_csl-reftype" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:sequence select="if (cp:csl-reftype($bibref)) then (cp:csl-reftype($bibref)) else
      (cp:csl-fallback($bibref))"/>
  </xsl:function>
  <xdoc:doc>Maps a biblio reference type to a CSL XPATH expression.</xdoc:doc>
  <xsl:function name="cp:csl-reftype" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:variable name="reftype" select="cp:reftype($bibref)"/>
    <xsl:variable name="csl-style" select="if (not($style-biblio)) then
      ($style-citation/cs:layout/cs:item[not(@position='subsequent')]/cs:choose/cs:type) else
      ($style-biblio/cs:layout/cs:item/cs:choose/cs:type)"/>
    <xsl:value-of select="$csl-style/@name[.=$reftype]"/>
  </xsl:function>
  <xdoc:doc>Determines the CSL fallback for a MODS record.</xdoc:doc>
  <xsl:function name="cp:csl-fallback" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:variable name="bibrefclass" select="cp:refclass($bibref)"/>
    <xsl:choose><!-- *** fix this *** -->
      <xsl:when test="$bibrefclass='monograph'">
        <xsl:value-of select="'book'"/>
      </xsl:when>
      <xsl:when test="$bibrefclass='part-inMonograph'">
        <xsl:value-of select="'chapter'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'article'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>This function is central to the formatting logic of the system. The fallback system
    classifies records into one of three structural classes: part-inMongraph, part-inSerial, and
    mongraph. It would be easy to add serial as a fourth, but I have not yet found the need (does
    one ever cite a serial as a whole?).</xdoc:doc>
  <xsl:function name="cp:refclass" as="xs:string">
    <xsl:param name="bibref" as="element()"/>
    <xsl:choose>
      <xsl:when test="$bibref/dcterms:isPartOf">
        <xsl:choose>
          <xsl:when test="$bibref/prism:volume">part-inSerial</xsl:when><!-- ??? -->
          <xsl:otherwise>part-inMonograph</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>monograph</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>Further classifies records into types based on the class. These types then map onto the
    citation style langauge definitions. Article, chapter and book are the default structures and
    generic fallbacks. Most records will be formatted with these "types." Beyond these core types,
    additional types would be defined by both their genre values and their likeness to the core
    types. The value can be multi-level where applicable: e.g. “article-magazine.”</xdoc:doc>
  <xsl:function name="cp:reftype" as="xs:string">
    <xsl:param name="bibref" as="element()?"/>
    <xsl:variable name="type-string" as="xs:string">
      <xsl:value-of select="if ($bibref/rdf:type) then (substring-after($bibref/rdf:type/@rdf:resource, '#'))
        else (name($bibref))"/>
    </xsl:variable>
    <xsl:value-of>
      <xsl:choose>
        <xsl:when test="$bibref/dcterms:isPartOf">
          <xsl:variable name="relation-type-string" as="xs:string">
            <xsl:variable name="relation" as="element()">
              <xsl:sequence select="cp:get-rdf($bibref/dcterms:isPartOf)"/>
            </xsl:variable>
            <xsl:value-of select="if ($relation/rdf:type) then (substring-after($relation/rdf:type/@rdf:resource, '#'))
              else (name($relation))"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$type-string">
              <xsl:value-of select="lower-case($type-string)"/>
              <xsl:if test="$relation-type-string">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="lower-case($relation-type-string)"/>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'article'"/>
              <xsl:if test="$relation-type-string">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="lower-case($relation-type-string)"/>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case($type-string)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:value-of>
  </xsl:function>
  <xdoc:doc>Numbers citations and foot/endnotes together.</xdoc:doc>
  <xsl:function name="cp:number-footcite" as="xs:string">
    <xsl:param name="footcite" as="element()"/>
    <xsl:choose>
      <xsl:when test="$chapters/db:chapter">
        <xsl:for-each select="$footcite">
          <xsl:number level="any" select="." 
            count="db:footnote|db:citation[not(ancestor::db:footnote)]" from="db:chapter"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$footcite">
          <xsl:number level="any" select="." count="db:footnote|db:citation[not(ancestor::db:footnote)]"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xdoc:doc>Determines the first time a reference is cited in the text. Necesary for those styles
    that make a formatting distinction between first and subsequent references.</xdoc:doc>
  <xsl:function name="cp:first-reference" as="xs:boolean">
    <xsl:param name="cite-ref" as="node()"/>
     <xsl:sequence select="$cite-ref is key('refs', $cite-ref/(@linkend|@xlink:href), root($cite-ref))[1]"/>
  </xsl:function>
  <xdoc:doc>Determines when a citation fulfills the "ibid" condition.</xdoc:doc>
  <xsl:function name="cp:ibid" as="xs:boolean">
    <xsl:param name="citation" as="node()"/>
     <xsl:sequence select="$citation/db:biblioref/(@linkend|@xlink:href) = $citation/preceding::db:biblioref[1]/(@linkend|@xlink:href) 
      and count($citation/preceding::db:biblioref) = 1"/>
    <!-- need to fix above to be more precise -->
  </xsl:function>
  <xdoc:doc>When given an rdf property, grabs linked resource. Borrowed from Norm Walsh.</xdoc:doc>
  <xsl:function name="cp:get-rdf" as="element()?">
    <xsl:param name="about" as="node()"/>
    <xsl:choose>
      <xsl:when test="empty($about)">
        <xsl:sequence select="$about"/>
      </xsl:when>
      <xsl:when test="$about instance of element()">
        <xsl:choose>
          <xsl:when test="$about/@rdf:nodeID">
            <xsl:variable name="node" select="key(&apos;nodeID&apos;,
              $about/@rdf:nodeID, $allrdf)"/>
            <xsl:choose>
              <xsl:when test="$node">
                <xsl:sequence select="$node"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$about"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$about/@rdf:resource">
            <xsl:variable name="node" select="key(&apos;about&apos;,
              $about/@rdf:resource, $allrdf)"/>
            <xsl:choose>
              <xsl:when test="$node">
                <xsl:sequence select="$node"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$about"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$about"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="key(&apos;about&apos;,string($about), $allrdf)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="cp:format-date">
    <xsl:param name="date"/>
    <xsl:param name="date-form" as="xs:string?"/>
    <!-- FIX ME -->
    <xsl:variable name="date-config" select="'year'"/>
    <xsl:choose>
      <xsl:when test="$date castable as xs:date">
        <xsl:choose>
          <xsl:when test="$date-form='month-day'">
            <xsl:value-of select="format-date($date, '[Y] [Mn]')"/>
          </xsl:when>
          <xsl:when test="$date-form='year'">
            <xsl:value-of select="format-date($date, '[Y]')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="format-date($date, '[Y] [Mn]')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>
