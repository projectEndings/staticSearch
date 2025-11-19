<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 18, 2025</xd:p>
            <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
            <xd:p>Module that includes all of the schema processing and defaults for staticSearch v2.0</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:variable name="thisURI" as="xs:anyURI" select="static-base-uri()" />
    
    <xsl:variable name="localSchemaURI" as="xs:anyURI" select="resolve-uri('../schema/staticSearch.odd', $thisURI)"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="schemaURI" type="variable">$schemaURI</xd:ref> is the URI for the static search 
            configuration schema written in the TEI ODD language. We get the URI here during the configuration creation
            process as it can provide useful information as to what the expected values are for various
            configuration options. If, for whatever reason, the schema is not available locally (it is packed
            with the static search distribution), then we check to see if this has been downloaded as a package
            from a formal release; if it hasn't, then we get the latest release. If, for whatever reason, the 
            latest release isn't available, then we just get the latest one from the /dev/ branch.
        </xd:desc>
    </xd:doc>
    <xsl:variable name="schemaURI" as="xs:string">
        <xsl:choose>
            <xsl:when test="doc-available($localSchemaURI)">
                <xsl:value-of select="$localSchemaURI"/>
            </xsl:when>
            <xsl:when test="doc-available('https://raw.githubusercontent.com/projectEndings/staticSearch/' || hcmc:getLatestReleaseNum() || '/schema/staticSearch.odd')">
                <xsl:value-of select="'https://raw.githubusercontent.com/projectEndings/staticSearch/' || hcmc:getLatestReleaseNum() || '/schema/staticSearch.odd'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'https://raw.githubusercontent.com/projectEndings/staticSearch/dev/schema/staticSearch.odd'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="schema" type="variable">$schema</xd:ref> is the loaded
            TEI ODD file that contains the schema available at the URI determined by
            <xd:ref name="schemaURI" type="variable">$schemaURI</xd:ref>.</xd:desc>
    </xd:doc>
    <xsl:variable name="schema" as="document-node()">
      
        <xsl:sequence select="document($schemaURI)"/>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>All of the parameter element specifications as declared in the staticSearch ODD
            file.</xd:desc>
    </xd:doc>
    <xsl:variable name="paramElementSpecs" 
        select="$schema//tei:elementSpec[descendant::tei:memberOf[@key = 'ss.model.param']]"
        as="element(tei:elementSpec)+"/> 
    
    
    <xd:doc>
        <xd:desc><xd:ref name="defaultParams" type="variable">$defaultParams</xd:ref> returns each 
            defined attribute within an elementSpec and creates a map entry based on its default value.</xd:desc>
    </xd:doc>
    <xsl:variable name="defaultParams" as="map(xs:string, item()?)">
        <xsl:map>
            <xsl:for-each-group 
                select="$paramElementSpecs//tei:attDef[@ident]" 
                group-by="ancestor::tei:elementSpec/@ident || '.' || @ident">
                <xsl:variable name="key" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="defaultVal" select="string(current-group()/tei:defaultVal)" as="xs:string?"/>
                <xsl:map-entry 
                    key="current-grouping-key()"
                    select="hcmc:castParam($key, $defaultVal)"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>Mapping of attributes and their types.</xd:desc>
    </xd:doc>
    <xsl:variable name="paramTypes" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:for-each-group 
                select="$paramElementSpecs//tei:attDef[@ident]" 
                group-by="ancestor::tei:elementSpec/@ident || '.' || @ident">
                <xsl:variable name="type" select="(current-group()/tei:datatype/tei:dataRef/(@name | @key))[1]" as="xs:string?"/>
                <xsl:map-entry key="current-grouping-key()" select="($type, 'string')[1]"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>This function takes a parameter (e.g. an element/attribute in
            params) and returns the appropriate casted type.</xd:desc>
    </xd:doc>
    <xsl:function name="hcmc:castParam" as="item()?">
        <xsl:param name="key" as="xs:string"/>
        <xsl:param name="val" as="xs:string"/>
        <xsl:variable name="type" select="$paramTypes($key)" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$val = '' or empty($val)"/>
            <xsl:when test="$type = ('boolean', 'ssdata.boolean')">
                <xsl:sequence select="matches($val,'true','i')"/>
            </xsl:when>
            <xsl:when test="$type = 'nonNegativeInteger'">
                <xsl:sequence select="xs:integer($val)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="string($val)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xd:doc>
        <xd:desc>This function gets the latest release number from Github </xd:desc>
    </xd:doc>
    <xsl:function name="hcmc:getLatestReleaseNum" as="xs:string">
        <xsl:variable name="json" select="unparsed-text('https://api.github.com/repos/projectEndings/staticSearch/releases/latest')"/>
        <xsl:variable name="xml" select="json-to-xml($json)"/>
        <xsl:value-of select="$xml//*:string[@key='tag_name']/text()"/>
    </xsl:function>
    
    
    
</xsl:stylesheet>