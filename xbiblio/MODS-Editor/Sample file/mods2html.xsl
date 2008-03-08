<?xml version='1.0' encoding='utf-8'?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mods="http://www.loc.gov/mods/v3"
    version="1.0">

<xsl:output method='html' version='1.0' encoding='utf-8' indent='yes'/>

<xsl:strip-space elements="*"/>

<xsl:template match="/">
  <html>
    <header>
      <title>Test1</title>
      <style type="text/css">
body {
	background-color: silver;
	font: 12pt "Lucida Grande", "lucida sans", verdana;
}

table.details {
	background-color: white;
	width: 400px;
	padding: 20px;
}

td.details_heading {
	font-weight: bold;
	background-color: silver;
	text-align: right;
	vertical-align: baseline;
}

.mods_abstract {
	font-size: 10px;
	padding: 20px;
	width: 360px;
	height: 200px;
	overflow: auto;
}

td {
	padding-left: 5px;
	padding-right: 5px;
	font-size: 10px;
	padding-top: 3px;
	padding-bottom: 3px;
}



      </style>
    </header>
    <body>  
    <p>
Version:
<xsl:value-of select="system-property('xsl:version')" />
<br />
Vendor:
<xsl:value-of select="system-property('xsl:vendor')" />
<br />
Vendor URL:
<xsl:value-of select="system-property('xsl:vendor-url')" />
</p>
      <xsl:apply-templates/>
    </body>
  </html>
</xsl:template>
    


<xsl:template name="resolver" >
  <xsl:for-each select="ancestor-or-self::*">
    <xsl:variable name="id"   
	select="generate-id(.)" />
    <xsl:variable name="name" select="name()" />
    <xsl:value-of select="concat('/',name())"/>
    <xsl:for-each select="../*[name()=$name]" >
      <xsl:if test="generate-id(.)=$id">
        <xsl:text>[</xsl:text>
        <xsl:value-of 
	select="format-number(position(),'0000')"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each>
  <xsl:if test="not(self::*)">
    <xsl:value-of select="concat('/@',name())" />
  </xsl:if> 
</xsl:template>

<xsl:template match="mods:mods">
  <table class="details">
<xsl:call-template name="resolver" />
     <xsl:variable name="citekey" select="mods:identifier[@type]"/>
    <caption> <a name="{$citekey}">Caption: <xsl:value-of select="$citekey"/></a></caption>
    <xsl:apply-templates select="mods:titleInfo[not(@type)]"/>
    <xsl:apply-templates select="mods:name"/>
    <xsl:apply-templates select="mods:typeOfResource"/>
    <xsl:apply-templates select="mods:identifier"/>
    <xsl:apply-templates select="mods:originInfo"/>
    <xsl:apply-templates select="mods:relatedItem"/>
    <xsl:apply-templates select="mods:abstract"/>
    <xsl:apply-templates select="mods:subject"/>
  </table>
</xsl:template>

<xsl:template match="mods:abstract">
 <tr>
  <td class="details_heading">Abstract:</td>
  <td><xsl:apply-templates/></td>
 </tr>
</xsl:template>

<xsl:template match="mods:subject">
 <tr>
  <td class="details_heading">Keywords:</td>
  <td><xsl:for-each select="subject">
      <xsl:value-of select="topic"/>, 
      </xsl:for-each>
   </td>
 </tr>
</xsl:template>

<xsl:template match="mods:genre">
 <tr>
  <td class="details_heading">Genre:</td>
  <td><xsl:apply-templates/></td>
 </tr>
</xsl:template> 	

<xsl:template match="mods:originInfo">
 <tr>
  <td class="details_heading">Issuance:</td>
  <td><xsl:apply-templates select="issuance"/></td>
 </tr>
</xsl:template>

<xsl:template match="mods:detail[@type='volume']">
 <tr>
  <td class="details_heading">Volume:</td>
  <td><xsl:apply-templates select="mods:number"/></td>
 </tr>
</xsl:template>

<xsl:template match="mods:detail[@type='issue']">
 <tr>
  <td class="details_heading">Issue:</td>
  <td><xsl:apply-templates select="mods:number"/></td>
 </tr>
</xsl:template>


<xsl:template match="mods:detail[@type='page']">
 <tr>
  <td class="details_heading">Page:</td>
  <td><xsl:apply-templates select="mods:number"/></td>
 </tr>
</xsl:template>


<xsl:template match="mods:extent[@unit='page']">
 <tr>
  <td class="details_heading">Pages:</td>
  <td>
	<xsl:apply-templates select="mods:start"/>
	<xsl:text>–</xsl:text>
    <xsl:apply-templates select="mods:end"/>
  </td>
 </tr>
</xsl:template>


<xsl:template match="mods:part">
 <xsl:apply-templates select="mods:detail"/>
 <xsl:apply-templates select="mods:extent"/>
</xsl:template>

<xsl:template match="mods:relatedItem[@type='host']">
  <xsl:apply-templates select="mods:genre"/>
  <xsl:apply-templates select="mods:part"/>
  <xsl:apply-templates select="mods:titleInfo"/>
  <xsl:apply-templates select="mods:originInfo"/>
</xsl:template>


  <xsl:template match="mods:titleInfo[not(@type)]">
   <xsl:choose>
     <xsl:when test="../../../mods:mods">
       <xsl:choose>
         <xsl:when test="../mods:genre='academic journal'">
           <td class="details_heading">Journal Title:</td>
         </xsl:when>
         <xsl:otherwise>
           <td class="details_heading">Container Title:</td>
         </xsl:otherwise>
	   </xsl:choose>
     </xsl:when>
     <xsl:when test="../../mods:mods">
       <td class="details_heading">Title:</td>
     </xsl:when>
   </xsl:choose>
   <td class="title">
     <xsl:apply-templates select="mods:nonSort"/>
     <xsl:apply-templates select="mods:title"/>
     <xsl:apply-templates select="mods:subTitle"/>
   </td>
  </xsl:template>

  <xsl:template match="mods:nonSort">
    <xsl:apply-templates/>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="mods:title">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="mods:subTitle">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="mods:titleInfo[@type]"/>

  <xsl:template match="mods:name">
    <tr>
     <td class="details_heading">Creator:</td>
      <td class="title">
      <xsl:call-template name="resolver" />

        <xsl:if test="position() &gt; 1">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="mods:namePart[not(@type)]">
               <xsl:apply-templates select="mods:namePart[not(@type)]"/>
            </xsl:when>
            <xsl:when test="mods:namePart[@type='family']">
                <xsl:variable name="name">
                    <xsl:value-of select="mods:namePart[@type='family']"/>,
                    <xsl:value-of select="mods:namePart[@type='given']"/>
                </xsl:variable>
                <xsl:value-of select="$name"/>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="mods:namePart[@type='date']">
            <xsl:text> [</xsl:text>
            <xsl:value-of select="mods:namePart[@type='date']"/>
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="mods:role">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="mods:role/mods:roleTerm"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
       </td>
      </tr>
    </xsl:template>

    <xsl:template match="mods:typeOfResource">
        <tr>
            <td class="details_heading">Type of Resource:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>


    <xsl:template match="mods:subject">
        <xsl:apply-templates select="mods:topic"/>
    </xsl:template>

    <xsl:template match="mods:topic">
        <xsl:if test="position() != 1">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="mods:originInfo">
        <xsl:apply-templates select="mods:edition"/>
        <xsl:apply-templates select="mods:publisher"/>
        <xsl:apply-templates select="mods:place"/>
        <xsl:apply-templates select="mods:copyrightDate"/>
        <xsl:apply-templates select="mods:dateIssued[1]"/>
    </xsl:template>

    <xsl:template match="mods:dateIssued">
        <tr>
            <td class="details_heading">Date Issued:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>

    <xsl:template match="mods:copyrightDate">
        <tr>
            <td class="details_heading">Copyright Date:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>

    <xsl:template match="mods:edition">
        <tr>
            <td class="details_heading">Edition:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>

    <xsl:template match="mods:place">
        <xsl:apply-templates select="mods:placeTerm[@type='text']"/>
    </xsl:template>

    <xsl:template match="mods:placeTerm">
        <tr>
            <td class="details_heading">Place:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>

    <xsl:template match="mods:publisher">
        <tr>
            <td class="details_heading">Publisher:</td>
            <td><xsl:apply-templates/></td>
        </tr>
    </xsl:template>




    <xsl:template match="mods:identifier">
        <tr>
            <td class="details_heading">
                Identifier (<xsl:value-of select="@type"/>)
            </td>
            <td>
                <xsl:choose>
                    <xsl:when test="@type='uri'">
                        <a href="{text()}">
                            <xsl:apply-templates/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

</xsl:stylesheet>

