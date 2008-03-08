<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:xdoc="http://www.pnp-software.com/XSLTdoc"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:db="http://docbook.org/ns/docbook"
	xmlns:cs="http://purl.org/net/xbiblio/csl"
	xmlns:cp="http://purl.org/net/xbiblio/citeproc"
	xmlns:exist="http://exist.sourceforge.net/NS/exist"
   xmlns:xlink="http://www.w3.org/1999/xlink"
	exclude-result-prefixes="db xdoc xhtml mods xs cs xlink exist cp">
	<xsl:import href="../citeproc.xsl"/>
	<xsl:output method="xhtml" encoding="utf-8" indent="yes"/>
  <!-- === licensed under CC-GNU GPL; see http://creativecommons.org/licenses/GPL/2.0 === -->
	<xdoc:doc type="stylesheet">
		<xdoc:short>Transforms DocBook NG to XHTML.</xdoc:short>
		<xdoc:author>Bruce D’Arcus</xdoc:author>
		<xdoc:copyright>2004, Bruce D’Arcus</xdoc:copyright>
		<xdoc:detail>
			<p>To integrate CiteProc formatting into other stylesheets, import the
				"citeproc.xsl" file. To format the bibliography, add a template that
				does a xsl:call-template of the "bib:format-bibliography" template,
				with an output-format parameter. Likewise, to format the citations,
				add a template that does a xsl:call-template of the
				"bib:format-citation" template.</p>
		</xdoc:detail>
	</xdoc:doc>
	<xsl:param name="include-bib">yes</xsl:param>
  <xsl:param name="bibdb">flatfile</xsl:param>
  <!--
   <xsl:param name="bibinfile">/Users/darcusb/projects/bibdb/allrdf.xml</xsl:param>
  -->
	<xsl:variable name="title">
		<xsl:value-of select="db:*/db:info/db:title"/>
		<xsl:if test="db:*/db:info/db:subtitle">
			<xsl:text>: </xsl:text>
			<xsl:value-of select="db:*/db:info/db:subtitle"/>
		</xsl:if>
	</xsl:variable>
	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="$title"/>
				</title>
				<meta name="generator"
					content="CiteProc XSL Stylesheets v{$CP-VERSION}"/>
				<link rel="stylesheet" href="forprint.css" type="text/css"
					media="print"/>
				<link rel="stylesheet" href="screen.css" type="text/css"
					media="screen"/>
			</head>
			<body>
				<div id="content">
					<div id="main-content">
						<div class="label">
							<xsl:value-of select="db:*/@label"/>
						</div>
						<xsl:apply-templates/>
					  <xsl:if test="//db:footnote or $citeclass='note-nobib' or $citeclass='note-bib'">
							<div id="notes">
								<h3>Notes</h3>
							  <xsl:choose>
							    <xsl:when test="$citeclass='note-nobib' or $citeclass='note-bib'">
							      <xsl:apply-templates select="//db:footnote | //db:citation[not(ancestor::db:footnote)]"
							        mode="footcite-list"/>
							    </xsl:when>
							    <xsl:otherwise>
							      <xsl:apply-templates select="//db:footnote" mode="footnote-list"/>
							    </xsl:otherwise>
							  </xsl:choose>
							</div>
						</xsl:if>
						<xsl:if test="$include-bib='yes' and not($citeclass='note-nobib')">
							<div id="bibliography">
								<h3>References</h3>
								<xsl:call-template name="cp:format-bibliography">
									<xsl:with-param name="output-format" select="'xhtml'"/>
								</xsl:call-template>
							</div>
						</xsl:if>
					</div>
				</div>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="db:article">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="db:citation">
	  <xsl:choose>
	    <xsl:when test="$citeclass='note-bib' or $citeclass='note-nobib'">
	      <xsl:variable name="footnote-number">
	        <xsl:value-of select="cp:number-footcite(.)"/>
	      </xsl:variable>
	      <xsl:text>[</xsl:text>
	      <a href="#fn{$footnote-number}" name="fnm{$footnote-number}" class="footnote-mark">
	        <xsl:value-of select="$footnote-number"/>
	      </a>
	      <xsl:text>]</xsl:text>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:call-template name="cp:format-citation">
	        <xsl:with-param name="output-format" select="'xhtml'"/>
	      </xsl:call-template>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:template>
  <xsl:template match="db:citation" mode="footcite-entry">
    <xsl:call-template name="cp:format-citation">
      <xsl:with-param name="output-format" select="'xhtml'"/>
    </xsl:call-template>
  </xsl:template>
	<xsl:template match="db:info">
		<div class="head">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="db:title">
		<h1 class="title">
			<xsl:apply-templates/>
			<xsl:if test="../db:subtitle">
				<xsl:text>: </xsl:text>
			</xsl:if>
			<xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
		</h1>
	</xsl:template>
	<xsl:template match="db:subtitle"/>
	<xsl:template match="db:chapter">
		<div id="chapter">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="db:section">
		<xsl:choose>
			<xsl:when test="not(parent::db:section)">
				<div class="section">
					<xsl:apply-templates/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="db:section/db:title | db:section/db:info/db:title">
		<xsl:variable name="depth" select="count(ancestor::db:section)"/>
		<xsl:choose>
			<xsl:when test="$depth=0">
				<h2>
					<xsl:apply-templates/>
					<xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
				</h2>
			</xsl:when>
			<xsl:when test="$depth=1">
				<h3>
					<xsl:apply-templates/>
					<xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
				</h3>
			</xsl:when>
			<xsl:when test="$depth=2">
				<h4>
					<xsl:apply-templates/>
					<xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
				</h4>
			</xsl:when>
			<xsl:when test="$depth=3">
				<h5>
					<xsl:apply-templates/>
					<xsl:apply-templates select="../db:subtitle" mode="subtitle"/>
				</h5>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="db:section/db:subtitle | db:section/db:info/db:subtitle"
		mode="subtitle">
		<xsl:text>: </xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="db:section/db:subtitle | db:section/db:info/db:subtitle"/>
	<xsl:template match="db:author">
		<div id="author">
                  <xsl:apply-templates select="db:personname"/>
                  <xsl:apply-templates select="db:affiliation"/>
		</div>
	</xsl:template>
	<xsl:template match="db:personname">
	   <p class="name">
		<xsl:value-of select="db:firstname"/>
                <xsl:text> </xsl:text>
		<xsl:value-of select="db:surname"/>
	   </p>
	</xsl:template>
	<xsl:template match="db:copyright">
		<p class="copyright">
                        <xsl:text>© </xsl:text>
			<span class="holder name">
				<xsl:value-of select="db:holder"/>
			</span>
			<span class="year">
                                <xsl:text>, </xsl:text>
				<xsl:value-of select="db:year"/>
			</span>
		</p>
	</xsl:template>
	<xsl:template match="db:affiliation">
		<div id="affiliation organization">
			<p class="name">
				<xsl:apply-templates select="db:orgname"/>
			</p>
			<p class="department">
				<xsl:apply-templates select="db:orgdiv"/>
			</p>
			<xsl:apply-templates select="address"/>
		</div>
	</xsl:template>
	<xsl:template match="db:address">
		<div id="address">
			<p class="affiliation">
				<xsl:apply-templates select="db:street"/>
			</p>
			<p class="affiliation">
				<xsl:apply-templates select="db:city"/>
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="db:state"/>
				<xsl:text/>
				<xsl:apply-templates select="db:postcode"/>
			</p>
			<p class="address">
				<xsl:apply-templates select="db:email"/>
			</p>
		</div>
	</xsl:template>
	<xsl:template match="db:abstract">
		<div id="abstract">
			<h4>Abstract</h4>
			<p class="abstract">
				<xsl:apply-templates/>
			</p>
		</div>
	</xsl:template>
	<xsl:template match="db:blockquote">
		<blockquote>
			<xsl:apply-templates/>
		</blockquote>
	</xsl:template>
	<xsl:template match="db:phrase|db:wordasword">
		<xsl:text>“</xsl:text>
	  <xsl:apply-templates/>
		<xsl:text>”</xsl:text>
	</xsl:template>
  <xsl:template match="db:date">
    <xsl:choose>
      <xsl:when test=". castable as xs:date">
        <xsl:choose>
          <xsl:when test="@role='month-day'">
            <xsl:value-of select="format-date(., '[D] [MNn]')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="format-date(., '[D] [MNn] [Y]')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="db:citetitle">
		<em>
			<xsl:apply-templates/>
		</em>
	</xsl:template>
	<xsl:template match="db:quote">
		<xsl:text>“</xsl:text>
		<xsl:apply-templates select="text()|db:phrase|db:quote|db:nq|db:emphasis"/>
		<xsl:text>”</xsl:text>
		<xsl:if test="db:citation">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="db:citation"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="db:nq">
		<xsl:text>”</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>“</xsl:text>
	</xsl:template>
  <!-- footnote handling -->
  <xsl:function name="db:number-footnote" as="xs:string">
    <xsl:param name="footnote" as="element(db:footnote)"/>
    <xsl:choose>
      <xsl:when test="$chapters/db:chapter">
        <xsl:number level="any" select="$footnote" from="db:chapter"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number level="any" select="$footnote"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:template match="db:footnote">
    <xsl:variable name="footnote-number">
      <xsl:choose>
        <xsl:when test="$citeclass='note-bib' or $citeclass='note-nobib'">
          <xsl:sequence select="cp:number-footcite(.)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="db:number-footnote(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>[</xsl:text>
    <a href="#fn{$footnote-number}" name="fnm{$footnote-number}" class="footnote-mark">
      <xsl:value-of select="$footnote-number"/>
    </a>
    <xsl:text>]</xsl:text>
  </xsl:template>
  <xsl:template match="db:footnote" mode="footnote-list">
    <xsl:variable name="footnote-number" select="db:number-footnote(.)"/>
    <p id="fn{$footnote-number}">
      <a href="#fnm{$footnote-number}" class="footnote-anchor">
        <xsl:sequence select="$footnote-number"/>
      </a>
      <xsl:text>. &#xa0;</xsl:text>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="db:footnote | db:citation[not(ancestor::db:footnote)]" mode="footcite-list">
    <xsl:variable name="number" select="cp:number-footcite(.)"/>
    <p id="fn{$number}">
      <a href="#fnm{$number}" class="footnote-anchor">
        <xsl:value-of select="$number"/>
      </a>
      <xsl:text>. &#xa0;</xsl:text>
      <xsl:apply-templates select="if (self::db:footnote) then * else ." mode="footcite-entry"/>
    </p>
  </xsl:template>
	<xsl:template match="db:acronym">
		<acronym>
			<xsl:value-of select="."/>
		</acronym>
	</xsl:template>
	<xsl:template match="db:orderedlist">
		<ol>
			<xsl:apply-templates select="db:listitem"/>
		</ol>
	</xsl:template>
	<xsl:template match="db:listitem">
		<li>
			<xsl:apply-templates/>
		</li>
	</xsl:template>
	<xsl:template match="db:section/db:para | db:chapter/db:para | db:article/db:para">
	  <xsl:for-each-group select="node()" 
	      group-adjacent="self::db:orderedlist or self::db:unorderedlist or self::db:blockquote">
	    <xsl:choose>
	      <xsl:when test="current-grouping-key()">
	        <xsl:apply-templates select="current-group()"/>  
	      </xsl:when>
	      <xsl:otherwise>
	        <p class="body text">
	          <xsl:apply-templates select="current-group()"/>
	        </p>
	      </xsl:otherwise>  
	    </xsl:choose>
	  </xsl:for-each-group>
	</xsl:template>
  <xsl:template match="db:blockquote/db:para">
    <p class="blockquote">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
	<xsl:template match="db:figure">
		<div class="image">
			<xsl:apply-templates select="db:mediaobject/db:imageobject"/>
		</div>
	</xsl:template>
	<xsl:template match="db:imageobject">
		<img src="images/{db:imagedata/@fileref}" alt="{../../db:title}"/>
		<p class="caption">
			<xsl:value-of select="../../db:title"/>
		</p>
	</xsl:template>
	<xsl:template match="db:epigraph">
		<div class="epigraph">
			<xsl:apply-templates select="db:para"/>
			<xsl:apply-templates select="db:attribution"/>
		</div>
	</xsl:template>
	<xsl:template match="db:attribution">
		<p class="epigraph">
			<xsl:text>— </xsl:text>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	<xsl:template match="db:emphasis">
		<em>
			<xsl:apply-templates/>
		</em>
	</xsl:template>
  <xsl:template match="db:foreignphrase">
    <i class="foreignphrase">
      <xsl:apply-templates/>
    </i>
  </xsl:template>
</xsl:stylesheet>
