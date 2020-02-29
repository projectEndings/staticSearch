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
            <xd:p><xd:b>Created on:</xd:b> June 26, 2019</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
            <xd:p>This transformation takes a collection of tokenized and stemmed documents (tokenized
            via the process described in <xd:a href="tokenize.xsl">tokenize.xsl</xd:a>) and creates
            a JSON file for each stemmed token. It also creates a separate JSON file for the project's
            stopwords list, for all the document titles in the collection, and for each of the filter facets.
            Finally, it creates a single JSON file listing all the tokens, which may be used for glob searches.</xd:p>
        </xd:desc>
        <xd:param name="ellipses">A string parameter to denote what sorts of ellipses one wants in the KWIC.</xd:param>
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
    
    <xsl:variable name="jsonDirPath" select="concat($tempDir,'/new/')"/>
    
    
    <xsl:variable name="jsonURIs" select="uri-collection(concat($jsonDirPath,'?select=*.xml;recurse=yes'))"/>
    
    
    <xsl:template match="/">
        <xsl:message><xsl:copy-of select="$jsonURIs"/></xsl:message>
        <xsl:for-each-group select="$jsonURIs" group-by="replace(substring-after(.,$jsonDirPath),'/[^/]+\.xml$','')">
            <xsl:variable name="term" select="tokenize(current-grouping-key(),'/')[last()]"/>
            <!--Now glom:-->
            <xsl:variable name="result" as="element(map:map)">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    
                    <!--            The token is the top level string key for this map; it should be
                the same as the JSON file name.-->
                    <string key="token">
                        <xsl:value-of select="$term"/>
                    </string>
                    
                    <!--            Start instances array -->
                    <array key="instances">
                        <xsl:for-each select="for $doc in current-group() return document($doc)">
                            <xsl:sort select="//map:number[@key='score']/xs:integer(.)" order="descending"/>
                            <xsl:copy-of select="."/>
                        </xsl:for-each>
                    </array>
                </map>
            </xsl:variable>
            <xsl:result-document href="{$outDir}/{if (matches($term,'^[A-Z]')) then 'upper' else 'lower'}/{$term || $versionString}.json" method="text">
                <xsl:value-of select="xml-to-json($result)"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    
</xsl:stylesheet>
