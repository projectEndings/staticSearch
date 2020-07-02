<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 5, 2020</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation crates the ssStems file by parsing the results of the length
            task and create a JSON structure for it. Note that this replaces the createTokensList template in
             all releases of staticSearch pre-v1.</xd:p>
        </xd:desc>
        <xd:param name="stemLines">String passed from ANT that provides all of the stems and their sizes.</xd:param>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>Include the generated, global config stylesheet that contains all of the necessary parameters.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
    
    <xd:doc>
        <xd:desc>The stem lines parameter, which is a string passed from ANT which gives a full URI and the file's byte length.</xd:desc>
    </xd:doc>
    <xsl:param name="stemLines" as="xs:string?"/>
    
    <xd:doc>
        <xd:desc>Root, drive template where all the work happens. It creates a simple JSON file for all of the stems and their sizes
        in order to prevent massive, browser-breaking wildcard searches.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:if test="exists($stemLines)">
            <xsl:message>Creating <xsl:value-of select="concat($outDir, '/ssStems',$versionString,'.json')"/></xsl:message>
            <xsl:result-document href="{$outDir}/ssStems{$versionString}.json" method="text">
                <!--First stash the results in a map-->
                <xsl:variable name="map">
                    <map:map>
                            <!--Iterate through the tokens-->
                            <xsl:for-each select="tokenize($stemLines,'\n')">
                                <!--Quickly sort them in case that has any effect on efficiency-->
                                <xsl:sort select="lower-case(hcmc:getStemFromUri(tokenize(.,'\s*:\s*')[1]))"/>
                                <xsl:sort select="string-length(hcmc:getStemFromUri(tokenize(.,'\s*:\s*')[1]))"/>
                                
                                <!--Now parse the results from the length task-->
                                <xsl:variable name="thisLine" select="." as="xs:string"/>
                                <xsl:variable name="thisPair" select="tokenize($thisLine,'\s*:\s*')" as="xs:string+"/>
                                <xsl:variable name="thisUri" select="$thisPair[1]" as="xs:string"/>
                                <xsl:variable name="thisSize" select="$thisPair[2]" as="xs:string"/>
                                
                                <!--Get the stem from the URI-->
                                <xsl:variable name="thisStem" select="hcmc:getStemFromUri($thisUri)" as="xs:string"/>
                                
                                <!--Now make a simple array with the stem as the key, and a number-->
                                <map:array key="{$thisStem}">
                                    <map:number><xsl:value-of select="$thisSize"/></map:number>
                                </map:array>
                            </xsl:for-each>
                    </map:map>
                </xsl:variable>
                
                <!--Now create the actual JSON-->
                <xsl:value-of select="xml-to-json($map)"/>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:getStemFromUri" type="function">hcmc:getStemFromUri</xd:ref> takes in the URI of a JSON file and returns
        the token name from the URI.</xd:desc>
        <xd:param name="jsonUri">The URI of the JSON file from which to derive the token.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getStemFromUri" as="xs:string">
        <xsl:param name="jsonUri" as="xs:string"/>
        
        <!--Simply tokenize the file on the path separator and get the last one-->
        <xsl:variable name="baseUri" select="tokenize($jsonUri,'/')[last()]" as="xs:string"/>
        
        <!--And then trim off the versionString and the JSON suffix-->
        <xsl:value-of select="replace($baseUri,$versionString || '\.json$','')"/>
    </xsl:function>

    
    
    
    
</xsl:stylesheet>