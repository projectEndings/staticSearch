<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  xmlns="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Feb 12, 2021</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This file preprocesses the regular 
      Guidelines pages in order to add metadata 
      elements for staticSearch filters.</xd:p>
      <xd:p>This transformation runs on itself and
      loads the files it needs using collection().</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc>Whatever the form of the Guidelines pages, output 
    plain old XHTML5.</xd:desc>
  </xd:doc>
  <xsl:output method="xhtml" html-version="5.0" omit-xml-declaration="true"
    encoding="UTF-8" normalization-form="NFC" exclude-result-prefixes="#all"
    include-content-type="no"/>
  
  <xd:doc>
    <xd:desc>This is essentially an identity transform.</xd:desc>
  </xd:doc>
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xd:doc>
    <xd:desc>The base directory is a parameter just in case.</xd:desc>
  </xd:doc>
  <xsl:param name="basedir" as="xs:string" select="'../'"/>
  
  <xd:doc>
    <xd:desc>The input files are a collection.</xd:desc>
  </xd:doc>
  <xsl:variable name="inputFiles" as="document-node()*" select="collection($basedir || '/source/doc/tei-p5-doc/?select=*.html;recurse=yes')"/>
  
  <xd:doc>
    <xd:desc>We need the build information from one of the files for our
    search page.</xd:desc>
  </xd:doc>
  <xsl:variable name="buildInfo" as="xs:string" select="$inputFiles//div[@class='mainhead'][1]/p[1]/text()"/>
  
  <xd:doc>
    <xd:desc>Root element match kicks off the process.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:for-each select="$inputFiles">
      <xsl:if test="matches(document-uri(.), 'tei-p5-doc/((en)|(fr)|(es)|(de)|(it))/')">
        <xsl:variable name="sourcePath" as="xs:string" select="document-uri(.)"/>
        <xsl:variable name="outputPath" as="xs:string" select="replace($sourcePath, '/tei/source/doc/tei-p5-doc', '/tei/output')"/>
        <xsl:message>Processing <xsl:value-of select="$sourcePath"/> to <xsl:value-of select="$outputPath"/></xsl:message>
        
        <xsl:variable name="docUri" as="xs:string" select="document-uri(.)"/>
        
        <xsl:variable name="docName" as="xs:string" select="tokenize($docUri, '/')[last()]"/>
        
        <xsl:variable name="lang" as="xs:string" select="if (starts-with($docName, 'readme')) then 'en' else replace($docUri, '^.+/source/doc/tei-p5-doc/([a-z][a-z](-[A-Z][A-Z])?)/html/.+\.html$', '$1')"/>
        
        <xsl:variable name="climbTree" as="xs:string" select="if (starts-with($docName, 'readme')) then '../' else '../../'"/>
        
        <xsl:result-document href="{$outputPath}">
          <xsl:apply-templates>
            <xsl:with-param name="docUri" as="xs:string" select="$docUri" tunnel="yes"/>
            <xsl:with-param name="docName" as="xs:string" select="$docName" tunnel="yes"/>
            <xsl:with-param name="lang" as="xs:string" select="$lang" tunnel="yes"/>
            <xsl:with-param name="climbTree" as="xs:string" select="$climbTree" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:result-document>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>For the head element, we need to add a bunch of
    meta elements based on what type of file this is, and link
    in the highlight lib.</xd:desc>
    
    <xd:param name="docUri" as="xs:string" tunnel="yes">Uri of the host document.</xd:param>
    <xd:param name="docName" as="xs:string" tunnel="yes">Filename of the host document.</xd:param>
    <xd:param name="lang" as="xs:string" tunnel="yes">Determined language of the host document.</xd:param>
    <xd:param name="climbTree" as="xs:string" tunnel="yes">Prefix to append to paths when making links, based on nesting depth of host document.</xd:param>
  </xd:doc>
  <xsl:template match="head">
    <xsl:param name="docUri" as="xs:string" tunnel="yes"/>
    <xsl:param name="docName" as="xs:string" tunnel="yes"/>
    <xsl:param name="lang" as="xs:string" tunnel="yes"/>
    <xsl:param name="climbTree" as="xs:string" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates mode="#current"/>
      <script src="{$climbTree || 'js/ssHighlight.js'}"><xsl:comment>Script to highlight search hits.</xsl:comment></script> 
      
      <meta name="Language"
        class="staticSearch_desc" content="{$lang}"/>
      <xsl:choose>
        <xsl:when test="matches($docName, '^examples-')">
          <meta name="Page type"
            class="staticSearch_desc" content="Examples"/>
        </xsl:when>
        <xsl:when test="matches($docName, '^ref-')">
          <meta name="Page type"
            class="staticSearch_desc" content="Specifications"/>
        </xsl:when>
        <xsl:when test="matches($docName, '^readme-')">
          <meta name="Page type"
            class="staticSearch_desc" content="Readme"/>
        </xsl:when>
        <xsl:when test="matches(child::title[1], '^[iv]+\.\s')">
          <meta name="Page type"
            class="staticSearch_desc" content="Front matter"/>
        </xsl:when>
        <xsl:when test="matches(child::title[1], '^\d+\.?\s')">
          <meta name="Page type"
            class="staticSearch_desc" content="Chapters"/>
        </xsl:when>
        <xsl:when test="matches(child::title[1], '^((Appendix)|(Anhang)|(Apéndice)|(Appendice)|(Annexe)|(付録)|(부록)|(附錄))\s+[A-Z]')">
          <meta name="Page type"
            class="staticSearch_desc" content="Back matter"/>
        </xsl:when>
        <xsl:otherwise>
          <meta name="Page type"
            class="staticSearch_desc" content="Other pages"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Insert a search box as on the original site.</xd:desc>
    <xd:param name="climbTree" as="xs:string" tunnel="yes">Prefix to append to paths when making links, based on nesting depth of host document.</xd:param>
  </xd:doc>
  <xsl:template match="div[@id='container']">
    <xsl:param name="climbTree" as="xs:string" tunnel="yes"/>
    <xsl:next-match/>
    <div id="searchbox" style="float:left;">
      <form action="{$climbTree}search.html" method="get">
        <fieldset>
          <input style="color:#225588;" value="" maxlength="255" size="20" name="q" type="text"/>&#160;
            <input style="font-size:100%; font-weight:bold;    color:#FFFFFF; background-color:#225588; height: 2em;" value="Search" type="submit"/>
        </fieldset>
      </form>
    </div>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Spec pages often don't have id attributes in key locations,
    so let's add them.</xd:desc>
  </xd:doc>
  <xsl:template match="div[contains(@class, 'main-content')][not(@id)]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>This applies only to our search page, and just puts the
    correct build info into it.</xd:desc>
  </xd:doc>
  <xsl:template match="p[@id='ssBuildInfo']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="normalize-space($buildInfo)"/>
    </xsl:copy>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Fix another invalidity. 
      <!-- <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/> -->
    shouldn't be there. XSLT will add the correct meta tag anyway.</xd:desc>
  </xd:doc>
  <xsl:template match="meta[matches(@content, 'charset=UTF-8', 'i')]"/>
    
  
  
</xsl:stylesheet>