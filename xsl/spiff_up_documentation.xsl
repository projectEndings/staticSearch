<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> March 2, 2018</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This is a utility identity transform which tweaks the default output
      of the standard TEI documentation build process to make for a more human-
      friendly document.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output method="xhtml" html-version="5.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>


<!-- Root template. -->
  <xsl:template match="/">
    <!--<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;&#x0a;</xsl:text>-->
    <xsl:apply-templates/>
  </xsl:template>

<!-- Identity transform. -->
  <xsl:template match="@*|node()" priority="-1">
    <xsl:copy><xsl:apply-templates select="@*|node()" mode="#current"/></xsl:copy>
  </xsl:template>
  
<!-- Switch to our own css file. -->
  <xsl:template match="link[not(@media)]">
    <link rel="stylesheet" href="documentation.css" type="text/css"/>
  </xsl:template>
  
<!-- Get rid of empty ul elements. -->
  <xsl:template match="ul[not(li)]"/>
  
<!-- Get rid of pointless itemprop attribute.  -->
  <xsl:template match="@itemprop"/>
  
<!-- Section headers should be h2s.  -->
  <xsl:template match="section/header/h1 | section/h1">
    <h2><xsl:apply-templates select="@*|node()"/></h2>
  </xsl:template>
  
<!-- Subsection headings should be h3s. -->
  <xsl:template match="section/div/h2">
    <h3><xsl:apply-templates select="@*|node()"/></h3>
  </xsl:template>
  
<!-- Get rid of the meta charset element, since we already 
     get the http-equiv one from Saxon and both should not 
     be present. -->
  <xsl:template match="meta[@charset]"/>
  
  <!-- Regenerate the title element, cos it gets borked. -->
  <xsl:template match="title">
    <xsl:copy>
      <xsl:value-of select="//div[@class='titlePart'][1]"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="string-join((//div[@class='docAuthor']), ', ')"/>
      <xsl:text>)</xsl:text>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>