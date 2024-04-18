<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> February 14, 2022</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation is used to automatically convert a configuration
            file crafted for a pre-2.0 staticSearch to the configuration format for 2.0.</xd:p>
            <xd:p>For more information on changes, see the documentation and GitHub issues.</xd:p>            
        </xd:desc>
    </xd:doc>

    
    <xd:doc>
        <xd:desc>Since much of the configuration has not been changed,
                 this transform can be an identity transformation.</xd:desc>
    </xd:doc>
    <xsl:mode on-no-match="shallow-copy"/>
    
    
    <xd:doc>
        <xd:desc>Root template: if the config is already set to 2.0, this transformation just ends
        and produces no results; otherwise, it creates a new configuration file (with v2 appended).</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="config[xs:integer(@version) = 2]">
                <xsl:message>WARNING: Configuration file <xsl:value-of select="document-uri(.)"/>
                    is already set to version=2, so this transformation will do nothing.
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{replace(document-uri(.),'\.xml$','_v2.xml')}">
                    <xsl:apply-templates/>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Verbose has been removed; use the ant parameter ssVerbose instead.</xd:desc>
    </xd:doc>
    <xsl:template match="verbose">
        <xsl:if test="matches(normalize-space(.),'^(t|true|1|y|yes)$','i')">
            <xsl:message>WARNING: verbose has been removed; to add verbose messages to 
            the console during the build process, use the ant parameter ssVerbose.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>indentJSON has been removed since the option was meant purely for
        debugging the output JSON files, which can be better handled by external tools.</xd:desc>
    </xd:doc>
    <xsl:template match="indentJSON">
        <xsl:if test="matches(normalize-space(.),'^(t|true|1|y|yes)$','i')">
            <xsl:message>WARNING: indentJSON has been removed and output files will no
            longer be indented.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>linkToFragmentId has been removed; it was experimental to begin with
            and is still not widely supported.</xd:desc>
    </xd:doc>
    <xsl:template match="linkToFragmentId">
        <xsl:if test="not(matches(normalize-space(.),'^(t|true|1|y|yes)$','i'))">
            <xsl:message>WARNING: linkToFragmentId is no longer configurable; by default,
            all results will link to their nearest ancestor id. You can hide those links
            by targeting the .fidLink class in your CSS (e.g. .fidLink{ display:none; }).</xsl:message>
        </xsl:if>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>scrollToTextFragment has been removed; it was experimental to begin with
            and is still not widely supported.</xd:desc>
    </xd:doc>
    <xsl:template match="scrollToTextFragment">
        <xsl:if test="matches(normalize-space(.),'^(t|true|1|y|yes)$','i')">
            <xsl:message>WARNING: scrollToTextFragment has been removed due to lack of
            browser support. See the documentation for alternative approaches for in-page
            highlighting, including the use of the ssHighlight.js across your document
            collection.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    
    
</xsl:stylesheet>