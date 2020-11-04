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
        <xd:p><xd:b>Started on:</xd:b> Oct 31, 2020</xd:p>
        <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
        <xd:p>This is an implementation of the French Snowball stemmer
          described at 
          <xd:a href="https://snowballstem.org/algorithms/french/stemmer.html">snowballstem.org</xd:a>. 
          It follows the pattern of the English stemmer in this project.
        </xd:p>
      </xd:desc>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            * 
       *                    Parameters                              *
       *                                                            *
       **************************************************************-->
    
    <!-- None so far. -->
    
    <!--**************************************************************
       *                                                            * 
       *                    Variables                               *
       *                                                            *
       **************************************************************-->
  
    <xd:doc scope="component">
      <xd:desc>The <xd:ref name="vowel">vowel</xd:ref> variable is a character 
        class of vowels [aeiouyâàëéêèïîôûù].</xd:desc>
    </xd:doc>
    <xsl:variable name="vowel" as="xs:string">[aeiouyâàëéêèïîôûù]</xsl:variable>
    
    <xd:doc>
      <xd:desc>The <xd:ref name="nonVowel">nonVowel</xd:ref> variable is 
        a character class of non-vowels.</xd:desc>
    </xd:doc>
    <xsl:variable name="nonVowel">[^aeiouyâàëéêèïîôûù]</xsl:variable>
    
    
    
    <!--**************************************************************
       *                                                            * 
       *                         Functions                          *
       *                                                            *
       **************************************************************-->
  
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
      <!-- TODO, of course. -->
      <xsl:sequence select="$token"/>
    </xsl:function>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:preflight" type="function">ss:preflight</xd:ref> does a couple of simple
        replacements that need to precede the actual stemming process.
      </xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>The treated version of the token.</xd:result>
    </xd:doc>
    <xsl:function name="ss:preflight" as="xs:string">
      <xsl:param name="token" as="xs:string"/>
      <xsl:value-of select="replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace($token, 
                                    '(' || $vowel || ')i(' || $vowel || ')', '$1I$2'),
                                    '(' || $vowel || ')u(' || $vowel || ')', '$1U$2'),
                                    '(' || $vowel || ')y', '$1Y'),
                                    'y(' || $vowel || ')', 'Y$1'),
                                    'qu', 'qU'),
                                    'ë', 'He'),
                                    'ï', 'Hi')
        "/>
    </xsl:function>
  
  
</xsl:stylesheet>