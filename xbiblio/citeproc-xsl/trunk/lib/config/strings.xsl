<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  
  <xsl:param name="lang">en</xsl:param>
  
  <xsl:variable name="date-accessed">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">accessed</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="in">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">In</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="and">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">and</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- ==== contributors ==== -->
  
  <xsl:variable name="editor">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Editor</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="editors">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Editors</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="editor-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Ed</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="editors-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Eds</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="edited-by">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Edited By</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="translator">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Translator</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="translators">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Translators</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="translator-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Tran</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="translators-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Trans</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="translated-by">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Translated By</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- ==== locators ==== -->
  
  <xsl:variable name="page">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">page</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="pages">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">pages</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="page-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">p</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="pages-short">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">pp</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="volume">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">v</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="number">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">n</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- ==== genres ==== -->
  
  <xsl:variable name="phd-thesis">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">PhD Thesis</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="ma-thesis">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">MA Thesis</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- ==== headings ==== -->
  
  <xsl:variable name="references">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">References</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="works-cited">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Works Cited</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="bibliography">
    <xsl:choose>
      <xsl:when test="$lang = 'en'">Bibliography</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
</xsl:stylesheet>
