<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> February 29, 2020</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
            <xd:p>This transformation takes the collection of stemmed tokens that have been generated 
                per document, created by json_docbydoc.xsl,
                and creates a single JSON file from the directories.</xd:p>
        </xd:desc>
    </xd:doc>

    <!--**************************************************************
       *                                                            *
       *                         Includes                           *
       *                                                            *
       **************************************************************-->

    <xd:doc>
        <xd:desc>Include the generated configuration file. See
        <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a> for
        full documentation of how the configuration file is created.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
    
    
    <!--The base JSON path; right now, it's "new" but that should change
        if/when this code is out of the testing/experimental stage-->
    <xsl:variable name="jsonDirPath" select="concat($tempDir,'/new/')"/>
    
    
    
    
    <xsl:template match="/">
        <xsl:message>Combining JSON files...</xsl:message>
        <xsl:call-template name="combineJsons"/>
        <xsl:call-template name="createWordListJson"/>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>This template combines all of the JSONs via directory into a full JSON
        file for use within the static search. It does so by iterating in two loops to construct
        a path to a subdirectory that contains a number of stem folders. We do these via looping
        rather than the full JSON directory, since loading all of the files for the JSON directory
        can cause Saxon to bail with out of memory errors.</xd:desc>
    </xd:doc>
    <xsl:template name="combineJsons">
        <xsl:for-each select="('upper','lower')">
            <xsl:variable name="case" select="."/>
            
            <!--Iterating from 97 to 122 is the same as iterating from a-z, 123 is added for the special
                "0" directory, which contains all stems that do not begin with [a-z]-->
            <xsl:for-each select="97 to 123">
                <xsl:variable name="dir" select="if (.=123) then '0' else codepoints-to-string(.)"/>
                
                <!--Let us know where you are-->
                <xsl:message>Processing dir: <xsl:value-of select="$dir"/></xsl:message>
                <xsl:variable name="path" select="$jsonDirPath || $case || '/' || $dir"/>
                
                <!--Now get the smaller collection path-->
                <xsl:variable name="collectionPath" select="concat($path,'?select=*.json;recurse=yes')"/>
                
                <!--And get the collection-->
                <xsl:variable name="collection" select="uri-collection($collectionPath)"/>
                
                <!--And now group each collection via its sub directories-->
                    <xsl:for-each-group select="$collection" group-by="replace(substring-after(.,$path),'/[^/]+\.json$','')">
                        
                        <!--The current grouping key is the final part of the path-->
                        <xsl:variable name="term" select="tokenize(current-grouping-key(),'/')[last()]"/>
                        <xsl:message>Processing <xsl:value-of select="$term"/></xsl:message>
                        
                        <!--Create a temporary map-->
                        <xsl:variable name="result" as="element(map:map)">
                            <map xmlns="http://www.w3.org/2005/xpath-functions">
                                
                                <!--            The token is the top level string key for this map; it should be
                the same as the JSON file name.-->
                                <string key="token">
                                    <xsl:value-of select="$term"/>
                                </string>
                                
                                <!--            Start instances array -->
                                <array key="instances">
                                    
                                    <!--And now just sort and add the JSON to the map structure-->
                                    
                                    
                                    <xsl:for-each select="for $doc in current-group() return json-to-xml(unparsed-text($doc))">
                                        <xsl:sort select="//map:number[@key='score']/xs:integer(.)" order="descending"/>
                                        <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                </array>
                            </map>
                        </xsl:variable>
                        
                        <!--And place it as a new result JSON-->
                        <xsl:result-document href="{$outDir}/{if (matches($term,'^[A-Z]')) then 'upper' else 'lower'}/{$term || $versionString}.json" method="text">
                            <xsl:value-of select="xml-to-json($result)"/>
                        </xsl:result-document>
                    </xsl:for-each-group>    
            </xsl:for-each>
        </xsl:for-each>
        
    </xsl:template>
    
    
    <!--TO DO: DOCUMENT THE BELOW (OR THINK ABOUT SPLITTING THEM INTO SEPARATE MODULES)-->
    
    
    
    
    <xd:doc>
        <xd:desc><xd:ref name="createWordListJson">createWordListJson</xd:ref> 
            creates a list of the all of the tokens that have been
            created by the process; primarily, this JSON will be used 
            for wildcard searches.</xd:desc>
    </xd:doc>
    <xsl:template name="createWordListJson">
        <xsl:message>Creating word list JSON...</xsl:message>
        <xsl:variable name="lowerWords" select="uri-collection(concat($outDir,'/lower?select=*.json'))"/>
        <xsl:variable name="upperWords" select="uri-collection(concat($outDir,'/upper?select=*.json'))"/>
        <xsl:variable name="map" as="element(map:map)">
            <map:map>
                <map:array key="tokens">
                    <xsl:for-each select="($lowerWords,$upperWords)">
                        <xsl:sort select="lower-case(.)"/>
                        <xsl:sort select="string-length(.)"/>
                        <map:string><xsl:value-of select="tokenize(.,'/')[last()] => substring-before('.json') => normalize-space()"/></map:string>
                    </xsl:for-each>
                </map:array>
            </map:map>
        </xsl:variable>
        <xsl:result-document href="{$outDir}/ssTokens{$versionString}.json" method="text">
            <xsl:value-of select="xml-to-json($map, map{'ident': $indentJSON})"/>
        </xsl:result-document>
    </xsl:template>
    
    
</xsl:stylesheet>
