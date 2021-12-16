<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  version="3.0"
  xmlns:ss="http://hcmc.uvic.ca/ns/ssStemmer">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Started on:</xd:b> July 16, 2020.</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This is an "identity stemmer"; in other words, it
        does nothing, returning the input token unchanged. This
        is useful for the case of languages where stemming is 
        inappropriate or impractical, and wildcard searching is
        more effective.
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:stem" type="function">ss:stem</xd:ref> is the core function that
      takes a single token and returns its stemmed version. This function should be deterministic
      (same results every time from same input), so we mark it as new-each-time="no".
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:result>The stemmed version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:stem" as="xs:string" new-each-time="no">
    <xsl:param name="token" as="xs:string"/>
    <xsl:sequence select="normalize-unicode($token, 'NFC')"/>
  </xsl:function>
  
  
</xsl:stylesheet>