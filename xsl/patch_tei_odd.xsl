<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xi="http://www.w3.org/2001/XInclude" 
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  exclude-result-prefixes="#all"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 18, 2020</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This is a small patch file to work around bugs in TEI 
        ODD processing (see https://github.com/TEIC/Stylesheets/issues/241
        and https://github.com/TEIC/TEI/issues/1970). If/when the TEI
        fixes processing of sequence[@preserveOrder="false"], this file
        and the preprocessing step it handles can be removed.
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc>This is an identity transform.</xd:desc>
  </xd:doc>
  <xsl:mode exclude-result-prefixes="#all" on-no-match="shallow-copy"/>
  
  <xd:doc>
    <xd:desc>This simply replaces the TEI sequence element with its
    effective equivalent in RNG, after which subsequent processing using
    the TEI stylesheets should do the right thing.</xd:desc>
  </xd:doc>
  <xsl:template match="sequence[@preserveOrder='false']">
    <rng:interleave>
      <xsl:apply-templates/>
    </rng:interleave>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>This template simply imports any remarks content from 
    an elementSpec into any context where the element is cited using
    a specDesc.</xd:desc>
  </xd:doc>
  <xsl:template match="specList">
    <xsl:next-match/>
    <xsl:for-each select="child::specDesc">
      <xsl:variable name="elName" select="@key"/>
      <xsl:copy-of select="//elementSpec[@ident=$elName]/remarks/node()"/>
    </xsl:for-each>
  </xsl:template>
  
  
</xsl:stylesheet>