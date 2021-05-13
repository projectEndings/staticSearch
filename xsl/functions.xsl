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
  
  <!--**************************************************************
       *                                                            *
       *                         Variables                          *
       *                                                            *
       **************************************************************-->  
  
  <xd:doc>
    <xd:desc>Various apostrophes for use in regexes across the processes.</xd:desc>
  </xd:doc>
  <xsl:variable name="curlyAposOpen">‘</xsl:variable>
  <xsl:variable name="curlyAposClose">’</xsl:variable>
  <xsl:variable name="straightSingleApos">'</xsl:variable>
  <xsl:variable name="curlyDoubleAposOpen">“</xsl:variable>
  <xsl:variable name="curlyDoubleAposClose">”</xsl:variable>
  <xsl:variable name="straightDoubleApos">"</xsl:variable>
  
  <xsl:variable name="allSingleApos" 
    select="($straightSingleApos, $curlyAposOpen, $curlyAposClose)"
    as="xs:string+"/>
  
  <xsl:variable name="allSingleAposCharClassRex" 
    select="'[' || string-join($allSingleApos) || ']'" 
    as="xs:string"/>
  
  <xsl:variable name="allDoubleApos" 
    select="($curlyDoubleAposClose, $curlyDoubleAposOpen, $straightDoubleApos)" 
    as="xs:string+"/>
  
  <xsl:variable name="allDoubleAposCharClassRex"
    select="'[' || string-join($allDoubleApos) || ']'"
    as="xs:string"/>
  
  
  <xsl:variable name="allApos" select="($allSingleApos, $allDoubleApos)" as="xs:string+"/>
  
  
  <xd:doc>
    <xd:desc>All of the available types of filters in staticSearch.</xd:desc>
  </xd:doc>
  <xsl:variable name="ssFilters" select="('desc','num','bool','date', 'feat')" as="xs:string+"/>
  
  <xd:doc>
    <xd:desc>Special document metadata classes that must have a name and class match</xd:desc>
  </xd:doc>
  <xsl:variable name="docMetas" select="('docTitle', 'docSortKey','docImage')" as="xs:string+"/>

  
  <!--**************************************************************
       *                                                           *
       *                         Functions                         *
       *                                                           *
       *************************************************************-->  
  
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
  
  <xd:doc>
    <xd:desc><xd:ref name="hcmc:makeRelativeUri">hcmc:makeRelativeUri</xd:ref> receives
    two fully-qualified filesystem URIs, and creates a relative path from the first one to the 
    second. The first might be a document in the root of a collection, and the second an
    image in a subfolder below it, for example.</xd:desc>
    <xd:param name="rootFileUri">The base file from which the relative path needs to be calculated.</xd:param>
    <xd:param name="targetFileUri">The file whose path relative to the base file needs to be calculated.</xd:param>
  </xd:doc>
  <xsl:function name="hcmc:makeRelativeUri" as="xs:string*">
    <xsl:param name="rootFileUri" as="xs:string"/>
    <xsl:param name="targetFileUri" as="xs:string"/>
    <xsl:variable name="rootPathBits" as="xs:string*" select="tokenize($rootFileUri, '/')"/>
    <xsl:variable name="targetPathBits" as="xs:string*" select="tokenize($targetFileUri, '/')"/>
    <xsl:value-of select="string-join(($targetPathBits ! (if (position() lt count($rootPathBits) and $rootPathBits[position()] = .) then () else .)), '/')"/>
  </xsl:function>
  
  
  
  <xd:doc>
    <xd:desc><xd:ref name="hcmc:isForeign">hcmc:isForeign</xd:ref> determiners
      whether or not an element is foreign (i.e. its declared language differs from the root language).</xd:desc>
    <xd:param name="node">The node to check.</xd:param>
    <xd:return>A boolean for whether or not the word is foreign.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:isForeign" new-each-time="no" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    
    <!--Get the root HTML element-->
    <xsl:variable name="root" select="$node/ancestor::html" as="element(html)"/>
    
    <!--Has a root language been declared?-->
    <xsl:variable name="rootLangDeclared" select="boolean($root[@lang or @xml:lang])" as="xs:boolean"/>
    
    <!--Return the node's first ancestor with a declared language, if available-->
    <xsl:variable name="langAncestor" select="$node/ancestor::*[not(self::html)][@*:lang][1]" as="element()?"/>
    
    <xsl:choose>
      <!--If there is a declared language at the top and theres a lang ancestor
                    then return the negation of whether or not they are equal
                i.e. if they are equal, then return false (since it is NOT foreign)
                -->
      <xsl:when test="$rootLangDeclared and $langAncestor">
        <xsl:value-of select="not(boolean($root/@*:lang = $langAncestor/@*:lang))"/>
      </xsl:when>
      
      <!--If there is a lang ancestor but no root lang declared,
                    then we must assume that it is foreign-->
      <xsl:when test="$langAncestor and not($rootLangDeclared)">
        <xsl:value-of select="true()"/>
      </xsl:when>
      
      <!--Otherwise, just make it false-->
      <xsl:otherwise>
        <xsl:value-of select="false()"/>
      </xsl:otherwise>
    </xsl:choose>            
  </xsl:function>
  
  
  <xd:doc>
    <xd:desc><xd:ref name="hcmc:cleanWordForStemming">hcmc:cleanWordForStemming</xd:ref> takes the input word
      and tidies it up to make it more amenable for the stemming process.</xd:desc>
    <xd:param name="word">The input word</xd:param>
    <xd:return>A cleaned version of the word.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:cleanWordForStemming" as="xs:string">
    <xsl:param name="word" as="xs:string"/>
    <xsl:value-of select="
      replace($word, $allDoubleAposCharClassRex, '') (: Remove all quotation marks :)
      => replace($allSingleAposCharClassRex, $straightSingleApos) (: Normalize all apostrophes to straight :)
      => replace('\.$','') (: Remove trailing period :)
      => replace('^' || $straightSingleApos, '') (: Remove leading apostrope :)
      => replace($straightSingleApos || '$', '') (: Remove trailing apostrophe :)
      => translate('ſ','s') (: Normalize long-s to regular s :)
      "/>
  </xsl:function>
  
  
  

</xsl:stylesheet>