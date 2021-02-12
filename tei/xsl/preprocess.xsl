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
  <xsl:output method="xhtml" html-version="5" omit-xml-declaration="true"
    encoding="UTF-8" normalization-form="NFC" exclude-result-prefixes="#all"/>
  
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
    <xd:desc>Root element match kicks off the process.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:for-each select="$inputFiles">
      <xsl:variable name="sourcePath" as="xs:string" select="document-uri(.)"/>
      <xsl:variable name="outputPath" as="xs:string" select="replace($sourcePath, '/tei/source/doc/tei-p5-doc', '/tei/output')"/>
      <xsl:message>Processing <xsl:value-of select="$sourcePath"/> to <xsl:value-of select="$outputPath"/></xsl:message>
      <xsl:result-document href="${$outputPath}">
        <xsl:apply-templates/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  
  
</xsl:stylesheet>