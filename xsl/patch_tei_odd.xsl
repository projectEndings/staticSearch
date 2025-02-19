<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xi="http://www.w3.org/2001/XInclude" 
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
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
    <xd:desc>Global variable for elementSpecs, just for ease of retrieval</xd:desc>
  </xd:doc>
  <xsl:variable name="elementSpecs" select="//elementSpec" as="element(elementSpec)+"/>
  
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
  <xsl:template match="divGen[@xml:id = 'configQuickstart_egXML']">
    <xsl:variable name="orderedSequence"
      select="$elementSpecs[@ident='params']/content/descendant::elementRef/@key" 
      as="xs:string+"/>
    <egXML xmlns="http://www.tei-c.org/ns/Examples">
      <config xmlns="http://hcmc.uvic.ca/ns/staticSearch" version="2">
        <xsl:sequence select="hcmc:makeCommentForElement('params')"/>
        <params>
          <xsl:for-each-group select="map:keys($defaultParams)" group-by="tokenize(.,'\.')[1]">
            <xsl:sort select="(index-of($orderedSequence, current-grouping-key()),99)[1]"/>
            <xsl:sequence select="hcmc:makeCommentForElement(current-grouping-key())"/>
            <xsl:element name="{current-grouping-key()}">
              <xsl:for-each select="current-group()">
                <xsl:variable name="att" select="tokenize(.,'\.')[2]" as="xs:string"/>
                <xsl:attribute name="{$att}" select="$defaultParams(.)"/>
              </xsl:for-each>
            </xsl:element>
          </xsl:for-each-group>
        </params>
        <xsl:sequence select="hcmc:makeCommentForElement('rules')"/>
        <rules>
          <rule weight="0" match="script | style"/>
          <rule weight="2" match="h1 | h2 | h3 | h4 | h5 | h6"/>
        </rules>
        <xsl:sequence select="hcmc:makeCommentForElement('contexts')"/>
        <contexts>
        </contexts>
      </config>
    </egXML>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Function to create a comment based on an elementSpec's gloss; useful
    for egXMLs</xd:desc>
    <xd:param name="elName">The name of the element</xd:param>
  </xd:doc>
  <xsl:function name="hcmc:makeCommentForElement" as="item()+">
    <xsl:param name="elName" as="xs:string"/>
    <xsl:variable name="thisElSpec" select="$elementSpecs[@ident = $elName]" as="element(elementSpec)"/>
    <xsl:sequence select="codepoints-to-string(10)"/>
    <xsl:comment expand-text="yes">
      {$elName}: {string-join($thisElSpec/gloss/descendant::text())}
    </xsl:comment>
    <xsl:sequence select="codepoints-to-string(10)"/>
  </xsl:function>
  
  
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