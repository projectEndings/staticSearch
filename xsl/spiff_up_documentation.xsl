<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
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
  
  <xsl:include href="process_schema_for_config.xsl"/>
  
  <xsl:output method="xhtml" html-version="5.0" encoding="UTF-8" indent="yes" 
    omit-xml-declaration="yes" include-content-type="no"/>


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
  
  <!-- Get rid of obsolete script/@type attribute.  -->
  <xsl:template match="script/@type"/>
  
<!-- Section headers should be h2s.  -->
  <xsl:template match="section/header/h1 | section/h1">
    <h2><xsl:apply-templates select="@*|node()"/></h2>
  </xsl:template>
  
<!-- Subsection headings should be h3s. -->
  <xsl:template match="section/div/h2">
    <h3><xsl:apply-templates select="@*|node()"/></h3>
  </xsl:template>
  
<!-- Get rid of the meta[@http-equiv="Content-Type"] in favour of 
     a cleaner meta[@charset]. -->
  <xsl:template match="meta[@http-equiv='Content-Type']"/>
  
  <!-- Insert meta[@charset] if it is not there. -->
  <xsl:template match="head">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="not(child::meta[@charset])">
        <meta charset="UTF-8"/>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Regenerate the title element, cos it gets borked. Also add the viewport meta tag. -->
  <xsl:template match="title">
    <xsl:copy>
      <xsl:value-of select="//div[@class='titlePart'][1]"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="string-join((//div[@class='docAuthor']), ', ')"/>
      <xsl:text>)</xsl:text>
    </xsl:copy>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  </xsl:template>
  
  <!-- The forced whitespace-pre structures with &nbsp; characters
       really get in the way of responsive design. -->
  <xsl:template match="text()[ancestor::pre or ancestor::div[matches(@class, '(\s|^)pre(\s|$)')]]">
    <xsl:sequence select="replace(., '&#160;', ' ')"/>
  </xsl:template>
  
  <!--Add a little control before the egXML-->
  <xsl:template match="div[@id = 'configQuickstart_egXML']">
    <input type="checkbox" id="configQuickstart_egXML_control"/><label for="configQuickstart_egXML_control">Show/Hide fillable inputs</label>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!--For the special quickstart egXML, make the attribute values editable-->
  <xsl:template match="span[contains-token(@class,'attributevalue')][ancestor::div[@id = 'configQuickstart_egXML']]">
    <xsl:variable name="element" select="parent::span[contains-token(@class, 'element')]" as="element(span)"/>
    <xsl:variable name="value" select="normalize-space(string(.))" as="xs:string"/>
    <xsl:variable name="gi" select="replace($element/text()[1],'[^A-Za-z]+','')" as="xs:string"/>
    <xsl:variable name="att" 
      select="normalize-space(preceding-sibling::span[contains-token(@class,'attribute')][1]/text())"
      as="xs:string"/>
    <xsl:variable name="key" select="$gi || '.' || $att" as="xs:string"/>
    <xsl:variable name="thisElementSpec" select="$paramElementSpecs[@ident = $gi]" as="element(tei:elementSpec)?"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!--Stash the initial value just in case for now;
              we hide this with CSS -->
      <span class="initial-value">
        <xsl:apply-templates select="node()"/>
      </span>
      <!--If this isn't one of the parameters, don't do anything-->
      <!--Otherwise, create the special fillable inputs,
              which change depending on their type-->
      <xsl:if test="not(empty($thisElementSpec))">
        <xsl:variable name="type" select="$paramTypes($key)" as="xs:string?"/>
        <xsl:variable name="attDef" 
          select="$thisElementSpec/tei:attList/tei:attDef[@ident = $att]" 
          as="element(tei:attDef)?"/>

        <span class="fillable-attval">
          <xsl:choose>
            <xsl:when test="matches($type, 'boolean')">
              <select>
                <xsl:for-each select="('true','false')">
                  <!--Options need to be sorted, since the first one is the default-->
                  <xsl:sort select=". = $value" order="descending"/>
                  <option value="{.}"><xsl:value-of select="."/></option>
                </xsl:for-each>
              </select>
            </xsl:when>
            <xsl:when test="$type = 'nonNegativeInteger'">
              <input type="number" min="0" value="{$value}"/>
            </xsl:when>
            <!--If there's a configured valList (e.g. as it is 
                  for scoringAlgorithm), then create a select list-->
            <xsl:when test="$attDef/tei:valList">
              <select>
                <xsl:for-each select="$attDef/tei:valList/tei:valItem">
                  <xsl:sort select="@ident = $value" order="descending"/>
                  <option value="{@ident}"><xsl:value-of select="@ident"/></option>
                </xsl:for-each>
              </select>
            </xsl:when>
            <!--Otherwise, just assume it's text-->
            <xsl:otherwise>
              <input type="text" value="{$value}"/>
            </xsl:otherwise>
          </xsl:choose>
        </span>
      </xsl:if>
      
    </xsl:copy>
  </xsl:template>
    
</xsl:stylesheet>