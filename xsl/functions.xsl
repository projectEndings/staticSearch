<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 13, 2019</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This module contains generic functions
      that may be used in multiple processes.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc><xd:ref name="hcmc:makeNCName" type="function">hcmc:makeNCName</xd:ref>
    is designed to generate a valid NCName that can be used as an identifier from
    a string which may contain anything (normally a descriptive label string taken
    from a user document).</xd:desc>
    <xd:param name="label">a source string which may contain characters not 
    permitted in NCName.</xd:param>
    <xd:param name="prefix">an optional prefix (may be empty). This is not a 
    namespace prefix, merely a plain string.</xd:param>
  </xd:doc>
  <xsl:function name="hcmc:makeNCName" as="xs:string">
    <xsl:param name="label" as="xs:string"/>
    <xsl:param name="prefix" as="xs:string"/>
    <xsl:variable name="prefixToUse" as="xs:string" select=" 
      if (matches($prefix, '^\i')) then $prefix else concat('n', $prefix)"/>
    <xsl:variable name="result" as="xs:string" select="replace(concat($prefixToUse, $label), '([^\c]|:)+', '_')"/> 
    
    <!--<xsl:value-of select="$result"/>-->
    <xsl:try>
      <xsl:value-of select="xs:NCName($result)"/>
      <xsl:catch>
        <xsl:message terminate="yes">Unable to create NCName from input 
          <xsl:value-of select="$label"/>, <xsl:value-of select="$prefix"/>.
          Got result <xsl:value-of select="$result"/>
        </xsl:message>
      </xsl:catch>
      </xsl:try>
  </xsl:function>
  
</xsl:stylesheet>