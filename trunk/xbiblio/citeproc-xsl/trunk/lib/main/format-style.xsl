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
    <xdoc:short>Process CSL files to configure formatting.</xdoc:short>
    <xdoc:author>Bruce D’Arcus</xdoc:author>
    <xdoc:copyright>2006, Bruce D’Arcus</xdoc:copyright>
  </xdoc:doc>
  <xsl:variable name="refclass-partInSerial" select="('article-newspaper','legal
    case','bill','article','conference paper')"/>
  <xsl:variable name="refclass-partInMonograph" select="('song','chapter')"/>
  <xsl:variable name="refclass-monograph" select="('report','personal
    communication','book')"/>
  <xsl:variable name="genres" select="('thesis', 'newsletter', 'dissertation')"/>
  
  <xsl:template match="cs:citation">
    <xsl:param name="cite-ref" as="node()" tunnel="yes"/>
    <xsl:param name="last-in-author-group" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="cp:source" as="element()?" tunnel="yes"/>
    <cp:a class="citation" href="#{$cp:source/@ID}">
      <xsl:choose>
        <xsl:when test="cs:layout/cs:item[@position]">
          <xsl:choose>
            <xsl:when test="cp:first-reference($cite-ref)">
              <xsl:apply-templates select="cs:layout/cs:item[not(@position)]">
                <xsl:with-param name="use_reftype" select="$cp:source/@cp:use-reftype" tunnel="yes"/>
              </xsl:apply-templates>      
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="cs:layout/cs:item[@position]">
                <xsl:with-param name="use_reftype" select="$cp:source/@cp:use-reftype" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="cs:layout/cs:item[not(@position)]">
            <xsl:with-param name="use_reftype" select="$cp:source/@cp:use-reftype" tunnel="yes"/>
          </xsl:apply-templates>        
        </xsl:otherwise>
      </xsl:choose>
    </cp:a>
    <xsl:if test="not($last-in-author-group)">, </xsl:if>
  </xsl:template>
  
  <!-- FIX ME: move below code to CSL templates 
      <xsl:value-of select="cp:year-suffix"/>
  -->
  <xsl:template match="cs:citation//cs:locator">
    <xsl:param name="cite-ref" as="node()" tunnel="yes"/>
    <xsl:if test="$cite-ref/@begin">
      <xsl:apply-templates select="@prefix"/>
      <xsl:value-of select="$cite-ref/@begin"/>
      <xsl:if test="$cite-ref/@end">
        <xsl:text>–</xsl:text>
        <xsl:value-of select="cp:number-condense($cite-ref/@begin, $cite-ref/@end)"/>
      </xsl:if>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="cs:bibliography/cs:layout/cs:item[not(@position)]">
    <xsl:apply-templates>
      <xsl:with-param name="multi-authors" select="../cs:et_al[not(@position='subsequent')]" 
        as="element(cs:et_al)?" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  <!--
  <xsl:template match="cs:citation/cs:item-layout">
    <xsl:param name="use_reftype" tunnel="yes"/>
    <xsl:apply-templates select="if (cs:reftype) then (cs:reftype[@name=$use_reftype]) else *"/>
  </xsl:template>
  -->
  <xsl:template match="cs:citation/cs:layout/cs:item[@position='subsequent']">
    <xsl:apply-templates>
      <xsl:with-param name="multi-authors" select="if (../cs:et_al[@position='subsequent']) then (../cs:et_al[@position='subsequent']) 
        else (../cs:et_al[1])" as="element(cs:et_al)?" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="cs:citation/cs:layout/cs:item[not(@position)]">
    <!-- with the change in et al config, this gets messed up; need to fix -->
    <xsl:apply-templates>
      <xsl:with-param name="multi-authors" select="../cs:et_al[not(@position='subsequent')]" 
        as="element(cs:et_al)?" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="cs:citenumber">
    <xsl:param name="cite-ref" as="node()" tunnel="yes"/>
    <span class="mark">
       <xsl:value-of select="$cp:formatted-biblist/cp:item[@id=$cite-ref/(@linkend|@xlink:href)]/@cp:biblist-number"/>
    </span>
  </xsl:template>
  
  <xsl:template match="cs:citekey">
    <xsl:param name="cite-ref" as="node()" tunnel="yes"/>
    <span class="mark">
       <xsl:value-of select="$cite-ref/(@linkend|@xlink:href)"/>
    </span>
  </xsl:template>
  
  <!-- change citeproc to apply-templates here with use-reftype parameter -->
  <xsl:template match="cs:bibliography">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:param name="use_reftype" as="xs:string" tunnel="yes"/>
    <xsl:apply-templates select="cs:layout/cs:item/cs:choose/cs:type[@name=$use_reftype]">
      <xsl:with-param name="multi-authors" select="cs:et_al" as="element(cs:et_al)?" tunnel="yes"/>
      <xsl:with-param name="em-dash-author" 
        select="self::cs:bibliography and $cp:source/@cp:shorten-author='true'" tunnel="yes" as="xs:boolean?"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cs:type">
    <!-- needed to change the below to optional; may need to check this again later -->
    <xsl:param name="cp:number" as="xs:string?" tunnel="yes"/>
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <item class="bibref" id="{$cp:source/(@rdf:about|rdf:ID)}" cp:biblist-number="{$cp:number}">
      <xsl:if test="$citeclass='number'">
        <span class="mark">
          <xsl:value-of select="$cp:number"/>
        </span>
        <xsl:text>. </xsl:text>
      </xsl:if>
      <xsl:if test="$citeclass='citekey'">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="$cp:source/(@rdf:ID|@rdf:about)"/>
        <xsl:text>] </xsl:text>
      </xsl:if> 
      <xsl:apply-templates>
        <xsl:with-param name="cp:source" select="$cp:source"/>
      </xsl:apply-templates>
      <xsl:value-of select="$bibref-after"/>  
    </item>
  </xsl:template>
  
  <xsl:template match="cs:author">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:param name="em-dash-author" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="first-in-author-group" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="local-cite-style" as="node()?" tunnel="yes"/>
    <xsl:variable name="main-level" as="xs:boolean"
      select="cp:source(., $cp:source)/(@rdf:about|@rdf:ID)=$cp:source/(@rdf:about|@rdf:ID)"/>
    <xsl:variable name="alternate" as="xs:boolean" 
      select="if (preceding-sibling::cs:author[@alternate='editor']) then true() else false()"/>
    <xsl:choose>
      <xsl:when test="$first-in-author-group=false()"/>
      <xsl:when test="$local-cite-style='year'"/>
      <xsl:when test="$em-dash-author">
        <xsl:value-of select="$style-biblio/@subsequent-author-substitute"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- TODO: ?? -->
        <xsl:choose>
          <xsl:when test="cp:source(., $cp:source)/biblio:authors">
            <xsl:apply-templates select="cp:source(., $cp:source)/biblio:authors">
              <xsl:with-param name="alternate" as="xs:boolean" select="$alternate" tunnel="yes"/>
              <xsl:with-param name="short-names" as="xs:boolean" select="@form='short'" tunnel="yes"/>
              <xsl:with-param name="prefix" select="@prefix" tunnel="yes"/>
              <xsl:with-param name="suffix" select="@suffix" tunnel="yes"/>
              <xsl:with-param name="main-level" select="$main-level" as="xs:boolean" tunnel="yes"/>
              <!-- TODO: need to create a function for name display order -->
              <xsl:with-param name="sort-order" 
                  select="$style-general/cs:contributor/@name-as-sort-order" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="cp:source(., $cp:source)/foaf:maker">
            <xsl:variable name="name-as-sort" as="xs:boolean"
              select="$style-general/cs:contributor/@name-as-sort-order='all' or ($style-general/cs:contributor/@name-as-sort-order='first') and $main-level"/>
            <span class="author">
              <xsl:apply-templates select="cp:get-rdf(cp:source(., $cp:source)/foaf:maker)">
                <xsl:with-param name="alternate" as="xs:boolean" select="$alternate"/>
                <xsl:with-param name="short-names" as="xs:boolean" select="@form='short'" tunnel="yes"/>
                <xsl:with-param name="prefix" select="@prefix"/>
                <xsl:with-param name="suffix" select="@suffix"/>
                <xsl:with-param name="main-level" select="$main-level" as="xs:boolean"/>
                <xsl:with-param name="sort-order" 
                    select="$style-general/cs:contributor/@name-as-sort-order"/>
                <xsl:with-param name="name-as-sort" tunnel="yes" as="xs:boolean" select="$name-as-sort"/>
              </xsl:apply-templates>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="cp:source(., $cp:source)/cp:noname-substitute">
              <xsl:with-param name="prefix" select="@cs:prefix"/>
              <xsl:with-param name="suffix" select="cs:suffix"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
   
   <xsl:template match="cs:editor">
      <xsl:param name="cp:source" as="element()" tunnel="yes"/>
      <xsl:param name="em-dash-author" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="main-level" as="xs:boolean"
         select="cp:source(., $cp:source)/(@rdf:about|@rdf:ID)=$cp:source/(@rdf:about|@rdf:ID)"/>
      <xsl:variable name="alternate" as="xs:boolean" 
         select="if (preceding-sibling::cs:author[@alternate='editor'] and not($cp:source/biblio:authors|$cp:source/foaf:maker)) then true() else false()"/>
      <xsl:choose>
         <xsl:when test="$em-dash-author and $alternate">
           <xsl:value-of select="$style-biblio/@subsequent-author-substitute"/>
         </xsl:when>
        <!-- TODO: fix -->
         <xsl:otherwise>
            <xsl:apply-templates select="cp:source(., $cp:source)/cp:noname-substitute">
               <xsl:with-param name="prefix" select="@cs:prefix"/>
               <xsl:with-param name="suffix" select="cs:suffix"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="cp:source(., $cp:source)/biblio:editors">
               <xsl:with-param name="alternate" as="xs:boolean" select="$alternate"/>
               <xsl:with-param name="short-names" as="xs:boolean" select="@form='short'" tunnel="yes"/>
               <xsl:with-param name="prefix" select="@prefix"/>
               <xsl:with-param name="suffix" select="@suffix"/>
               <xsl:with-param name="main-level" select="$main-level" as="xs:boolean"/>
              <xsl:with-param name="sort-order" select="$style-general/cs:contributor/@name-as-sort-order"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
  
  <!-- TODO: fix -->
  <xsl:template match="cs:titles">
    <xsl:param name="cp:source" as="element()"/>
    <xsl:variable name="alternate" as="xs:boolean" 
      select="if (preceding-sibling::cs:author[(@alternate='title' or @alternate='container-title')]) then true() else false()"/>
    <xsl:apply-templates select="cp:source(., $cp:source)/dc:title">
      <!-- TODO: alternate param needs refinement (to handle editors and such) -->
      <xsl:with-param name="alternate" as="xs:boolean" 
        select="$alternate and not(cp:source(., $cp:source)/biblio:authors)"/>
      <xsl:with-param name="relation" select="@relation"/>
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:function name="cp:source" as="element()?">
    <xsl:param name="csl" as="element()"/>
    <xsl:param name="source" as="element()"/>
    <xsl:choose>
      <xsl:when test="$csl/@type='container'">
        <xsl:for-each select="$source/dcterms:isPartOf">
          <xsl:sequence select="cp:get-rdf(.)"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$csl/@type='series'">
        <xsl:variable name="container">
          <xsl:for-each select="$source/dcterms:isPartOf">
            <xsl:sequence select="cp:get-rdf(.)"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="$container/dcterms:isPartOf">
          <xsl:sequence select="cp:get-rdf(.)"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$source"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--
  <xsl:template match="@cs:prefix | @cs:suffix">
    <xsl:value-of select="."/>
  </xsl:template>
  -->

  <xsl:template match="cs:access-date">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:if test="$cp:source/biblio:accessed">
      <span class="date accessed">
        <xsl:if test="@font-weight">
          <xsl:attribute name="font-weight">
            <xsl:value-of select="@font-weight"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@font-style">
          <xsl:attribute name="font-style">
            <xsl:value-of select="@font-style"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="@prefix"/>
        <xsl:value-of select="$cp:source/biblio:accessed"/>
        <xsl:value-of select="@suffix"/>
      </span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="cs:url">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <!-- url only gets printed if there is an access date property; could change to test for 'http://' instead -->
    <xsl:if test="$cp:source/@rdf:about and $cp:source/biblio:accessed">
      <span class="url">
        <xsl:if test="@font-weight">
          <xsl:attribute name="font-weight">
            <xsl:value-of select="@font-weight"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@font-style">
          <xsl:attribute name="font-style">
            <xsl:value-of select="@font-style"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="@prefix"/>
        <xsl:value-of select="$cp:source/@rdf:about"/>
        <xsl:value-of select="@suffix"/>
      </span>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="cs:issue">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:apply-templates select="$cp:source/prism:number">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cs:volume">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:apply-templates select="$cp:source/prism:volume">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  <!--
  <xsl:template match="cs:medium">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:apply-templates select="$cp:source/mods:physicalDescription">
      <xsl:with-param name="prefix" select="@cs:prefix"/>
      <xsl:with-param name="suffix" select="cs:suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  -->
  
  <xsl:template match="cs:pages">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:if test="$cp:source/prism:startingPage">
      <span class="pages">
        <xsl:if test="@font-weight">
          <xsl:attribute name="font-weight">
            <xsl:value-of select="@font-weight"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@font-style">
          <xsl:attribute name="font-style">
            <xsl:value-of select="@font-style"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="@prefix"/>
        <xsl:value-of select="$style-general/cs:terms/cs:locator[@type='page']/@cs:renderas-multiple"/>
        <xsl:value-of select="$cp:source/prism:startingPage|$cp:source/biblio:pages"/>
        <xsl:if test="$cp:source/prism:endingPage">
          <xsl:text>–</xsl:text>
          <xsl:value-of select="cp:number-condense($cp:source/prism:startingPage, $cp:source/prism:endingPage)"/>
        </xsl:if>
        <xsl:value-of select="cs:suffix"/>
      </span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="cs:publisher">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
     <xsl:variable name="publisher" as="element()?">
        <xsl:sequence select="cp:source(., $cp:source)/dc:publisher"/>
     </xsl:variable>
     <xsl:if test="$publisher">
       <span class="publisher name">
         <xsl:apply-templates select="cp:get-rdf($publisher)">
           <xsl:with-param name="prefix" select="@prefix"/>
           <xsl:with-param name="suffix" select="@suffix"/>
           <xsl:with-param name="font-style" select="@font-style"/>
           <xsl:with-param name="font-weight" select="@font-weight"/>
         </xsl:apply-templates>
       </span>
     </xsl:if>
  </xsl:template>

   <xsl:template match="cs:publisher-place">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
      <xsl:variable name="publisher" as="element()?">
         <xsl:sequence select="cp:source(., $cp:source)/dc:publisher"/>
      </xsl:variable>
     <xsl:if test="$publisher">
       <xsl:apply-templates select="cp:get-rdf($publisher)" mode="place">
         <xsl:with-param name="prefix" select="@prefix"/>
         <xsl:with-param name="suffix" select="@suffix"/>
         <xsl:with-param name="font-style" select="@font-style"/>
         <xsl:with-param name="font-weight" select="@font-weight"/>
       </xsl:apply-templates>
     </xsl:if>
  </xsl:template>
  
  <xsl:template match="cs:date">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <!-- the below conditional seems a bit of a hack; need to reconsider later -->
    <xsl:variable name="date" select="$cp:source/(dc:date|dcterms:issued)"/>
    <xsl:variable name="date-form" as="xs:string">
      <xsl:choose>
        <xsl:when test="@form">
          <xsl:value-of select="@form"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'full'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <span class="date">
      <xsl:apply-templates select="@prefix"/>
      <xsl:value-of select="cp:format-date($date, $date-form)"/>
      <xsl:apply-templates select="@suffix"/>
    </span>
  </xsl:template>
  
  <xsl:template match="cs:year">
    <!-- I'm not sure why requiring the cp:source parameter fails in some cases -->
    <xsl:param name="cp:source" as="element()?" tunnel="yes"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:apply-templates select="$cp:source/cp:year">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cs:month">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <!-- select statement is a problem; probably need to move this into a function -->
    <xsl:apply-templates
      select="($cp:source/mods:originInfo/mods:dateIssued|$cp:source/mods:part/mods:date)[1]"
      mode="month">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cs:day">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:apply-templates
      select="$cp:source"
      mode="day">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>
  <!-- end dates -->
  
  <xsl:template match="cs:month-day">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:apply-templates select="$prefix"/>
    <span class="month-day">
      <xsl:apply-templates select="$cp:source/(dc:date|dcterms:issued)" mode="date">
        <xsl:with-param name="prefix" select="@prefix"/>
        <xsl:with-param name="suffix" select="@suffix"/>
        <xsl:with-param name="font-style" select="@font-style"/>
        <xsl:with-param name="font-weight" select="@font-weight"/>
      </xsl:apply-templates>
    </span>
    <xsl:apply-templates select="$suffix"/>
  </xsl:template>
  
  <xsl:template match="cs:note">
    <xsl:param name="cp:source" as="element()" tunnel="yes"/>
    <xsl:apply-templates select="$cp:source/biblio:note">
      <xsl:with-param name="prefix" select="@prefix"/>
      <xsl:with-param name="suffix" select="@suffix"/>
      <xsl:with-param name="font-style" select="@font-style"/>
      <xsl:with-param name="font-weight" select="@font-weight"/>
    </xsl:apply-templates>
  </xsl:template>

</xsl:stylesheet>
