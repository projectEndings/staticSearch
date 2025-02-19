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
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="#all"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 18, 2020</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This is a small preprocessing file to expand constructs
        and patch bugs in TEI 
        ODD processing (see https://github.com/TEIC/Stylesheets/issues/241
        and https://github.com/TEIC/TEI/issues/1970). If/when the TEI
        fixes processing of sequence[@preserveOrder="false"], the interleave templates
        can be removed.
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc>Include the schema processing code, which handles all
    of the logic for determining default values for the schema.</xd:desc>
  </xd:doc>
  <xsl:include href="process_schema_for_config.xsl"/>
  
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
    <xd:desc>Expands the sample configuration divGen to use default values.</xd:desc>
  </xd:doc>
  <xsl:template match="divGen[@xml:id = 'paramsExample_withDefaults']">
    <xsl:variable name="orderedSequence"
      select="//elementSpec[@ident='params']/content/descendant::elementRef/@key" 
      as="xs:string+"/>
    <egXML xmlns="http://www.tei-c.org/ns/Examples">
      <xsl:variable name="temp" as="element()">
        <params>
          <xsl:for-each-group select="map:keys($defaultParams)" group-by="tokenize(.,'\.')[1]">
            <xsl:sort select="(index-of($orderedSequence, current-grouping-key()),99)[1]"/>
            <xsl:element name="{current-grouping-key()}">
              <xsl:for-each select="current-group()">
                <xsl:variable name="att" select="tokenize(.,'\.')[2]" as="xs:string"/>
                <xsl:attribute name="{$att}" select="$defaultParams(.)"/>
              </xsl:for-each>
            </xsl:element>
          </xsl:for-each-group>
        </params>
      </xsl:variable>
      <!--An annoying hack to try and get indentation working-->
      <xsl:sequence 
        select="serialize($temp, map{'method': 'xml', 'indent': true()}) => parse-xml-fragment()"/>
    </egXML>
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