<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:svg="http://www.w3.org/2000/svg"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xd:doc>
        <xd:desc>A map of captions to use for building the search page. We organize this
        similarly to the Javascript, indexed by language first. NOTE: We should make this
        on the fly from the JavaScript somehow.</xd:desc>
    </xd:doc>
    <xsl:param name="captions" as="map(*)" select="map{
        'en':
            map{
                'ssDoSearch': 'Search',
                'ssSearching': 'Searching...',
                'ssLoading': 'Loading...',
                'ssClear': 'Clear',
                'ssPoweredBy': 'Powered by',
                'ssStartTyping': 'Start typing...',
                'ssSearchIn': 'Search only in',
                'ssScriptRequired': 'This page requires JavaScript.'
            },
        'fr': 
            map{
                'ssDoSearch': 'Chercher',
                'ssSearching': 'Recherche en cours...',
                'ssLoading': 'Chargement en cours...',
                'ssClear': 'Effacer',
                'ssPoweredBy': 'Réalisé par',
                'ssStartTyping': 'Commencez à taper...',
                'ssSearchIn': 'Recherchez seulement dans',
                'ssScriptRequired': 'Cette page a besoin de Javascript.'
             },
         'de': 
            map{
                'ssDoSearch': 'Suche',
                'ssSearching': 'Suche…',
                'ssLoading': 'Lade…',
                'ssClear': 'Leeren',
                'ssPoweredBy': 'Bereitgestellt von',
                'ssStartTyping': 'Zu tippen beginnen…',
                'ssSearchIn': 'Suche nur in',
                'ssScriptRequired': 'Diese Seite benötigt JavaScript.'
            }
        }"/>
    
    
    <xd:doc>
        <xd:desc>Function to get a caption for the search page by language. If the caption doesn't
        exist for a given language, we try to use the English one; if a caption doesn't exist
        for the English, then we fail.</xd:desc>
        <xd:param name="name">The name of the caption that we want to use.</xd:param>
        <xd:param name="lang">The language code to use.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getCaption">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="lang" as="xs:string"/>
        
        <xsl:variable name="langToUse" 
            select="if (string-length($lang) gt 0) then $lang else 'en'"
        as="xs:string"/>
        
        <!--Get the default english caption set-->
        <xsl:variable name="englishCaptionSet" 
            select="$captions('en')" 
            as="map(xs:string, xs:string)"/>
        
        <!--Get a caption set for the language, which may not exist-->
        <xsl:variable name="thisCaptionSet" 
            select="$captions($lang)"
            as="map(xs:string, xs:string)?"/>
        
        <xsl:choose>
            <xsl:when test="exists($thisCaptionSet) and map:contains($thisCaptionSet, $name)">
                <xsl:sequence select="$thisCaptionSet($name)"/>
            </xsl:when>
            <xsl:when test="map:contains($englishCaptionSet, $name)">
                <xsl:message>WARNING: No <xsl:value-of select="$name"/> caption available for lang <xsl:value-of select="$lang"/>. Using English caption instead.</xsl:message>
                <xsl:sequence select="$englishCaptionSet($name)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">ERROR: No caption found for <xsl:value-of select="$name"/> in any language.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    
    
    
</xsl:stylesheet>