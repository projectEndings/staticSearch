<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all" xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:hcmc="http://hcmc.uvic.ca/ns" version="3.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions">
    
    
    <xsl:include href="config.xsl"/>
    
    
    
    <xsl:template match="/">
        <xsl:call-template name="createJson"/>
    </xsl:template>
    
    <xsl:template name="createJson">
        <xsl:message>Found <xsl:value-of select="count($tokenizedDocs)"/> tokenized documents...</xsl:message>
        <xsl:variable name="stems" select="$tokenizedDocs//span[@data-staticSearch-stem]" as="element(span)*"/>
        <xsl:call-template name="createMap">
            <xsl:with-param name="stems" select="$stems"/>   
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="createMap">
        <xsl:param name="stems"/>
        <xsl:for-each-group select="$stems" group-by="tokenize(@data-staticSearch-stem,'\s+')">
            <xsl:sort select="current-grouping-key()" case-order="upper-first"/>
            <xsl:variable name="token" select="current-grouping-key()"/>
                 <xsl:message>Processing <xsl:value-of select="$token"/></xsl:message>
            <xsl:variable name="map" as="element()">
                <xsl:call-template name="makeMap">
                    <xsl:with-param name="term" select="$token"/>
                </xsl:call-template>
            </xsl:variable>
            <!--            <xsl:message>Creating <xsl:value-of select="$token"/>.json</xsl:message>-->
            <xsl:result-document href="{$outDir}/{if (matches($token,'^[A-Z]')) then 'upper' else 'lower'}/{$token}.json" method="text">
                <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    
    <xsl:template name="makeMap">
        <xsl:param name="term"/>
        <xsl:variable name="termRegex" select="concat('(^|\s)',$term,'(\s|$)')"/>
        <map xmlns="http://www.w3.org/2005/xpath-functions">
            <string key="token">
                <xsl:value-of select="$term"/>
            </string>
            <!--                <array key="forms">
                    <xsl:for-each-group select="current-group()" group-by="text()">
                        <string><xsl:value-of select="current-grouping-key()"/></string>
                    </xsl:for-each-group>
                </array>-->
            <array key="instances">
                <xsl:for-each-group select="current-group()" group-by="if (every $h in ancestor::html satisfies $h[@id]) then ancestor::html/@id else document-uri(/)">
                    <xsl:sort select="count(current-group()[1]/ancestor::html/descendant::span[contains-token(@data-staticSearch-stem,$term)])" order="descending"/>
                    <xsl:variable name="docId" select="current-grouping-key()"/>
                    <xsl:variable name="thisDoc" select="current-group()[1]/ancestor::html"/>
                    <xsl:variable name="spans" as="element(span)+" select="$thisDoc//span[@data-staticSearch-stem][contains-token(@data-staticSearch-stem,$term)]"/>
                    <xsl:variable name="docTitle" select="$thisDoc/head/title[1]"/>
                    
                    
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <string key="docId">
                            <xsl:value-of select="$docId"/>
                        </string>
                        <string key="docTitle">
                            <xsl:value-of select="$docTitle"/>
                        </string>
                        
                        <number key="count">
                            <xsl:value-of select="count($spans)"/>
                        </number>
                        
                        <array key="forms">
                            <xsl:for-each select="distinct-values($spans/text())">
                                <string><xsl:value-of select="."/></string>
                            </xsl:for-each>
                        </array>
                        
                        <xsl:if test="$ngrams or $createContexts">
                            <array key="contexts">
                                <xsl:variable name="contexts" as="element(span)+">
                                    <xsl:choose>
                                        <xsl:when test="$ngrams">
                                            <xsl:sequence select="$spans"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="for $n in 1 to $maxContexts return $spans[$n]"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:for-each select="$contexts">
                                    <string><xsl:value-of select="hcmc:returnContext(.)"/></string>
                                </xsl:for-each>
                                
                                <!--                                    <xsl:for-each select="$spans">
                                            <xsl:variable name="term" select="text()"/>
                                            <xsl:variable name="context" select="hcmc:returnContext(.)"/>
                                            <map>
                                                <string key="term"><xsl:value-of select="$term"/></string>
                                                <string key="context"><xsl:value-of select="$context"/></string>
                                            </map>
                                        </xsl:for-each>-->
                                
                            </array>
                        </xsl:if>
                    </map>
                </xsl:for-each-group>
            </array>
        </map>
        
    </xsl:template>
    
    
    
    <xsl:function name="hcmc:returnContext">
        <xsl:param name="span" as="element(span)"/>
        <xsl:variable name="thisTerm" select="$span/text()"/>
        <xsl:variable name="thisTermTagged">
            <xsl:element name="span" namespace="">
                <xsl:attribute name="class">highlight</xsl:attribute>
                <xsl:value-of select="$thisTerm"/>
            </xsl:element>
        </xsl:variable>
        <xsl:variable name="preNodes" select="for $n in 1 to 5 return $span/preceding-sibling::node()[$n]"/>
        <xsl:variable name="folNodes" select="for $n in 1 to 5 return $span/following-sibling::node()[$n]"/>
        
        <xsl:variable name="startString" select="string-join(reverse($preNodes),'')"/>
        <xsl:variable name="endString" select="string-join($folNodes,'')"/>
        
        <xsl:variable name="startTrimmed">
            <xsl:choose>
                <xsl:when test="string-length($startString) gt 50">
                    <xsl:value-of select="replace(substring($startString,string-length($startString) - 50),'^[a-z]+','')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace($startString,'^[a-z]+','')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="endTrimmed">
            <xsl:choose>
                <xsl:when test="string-length($endString) gt 50">
                    <xsl:value-of select="substring($endString,1,50)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$endString"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="out">
            <xsl:value-of select="normalize-space($startTrimmed)"/><xsl:text> </xsl:text><xsl:copy-of select="$thisTermTagged"/><xsl:text> </xsl:text><xsl:value-of select="normalize-space($endTrimmed)"/>
        </xsl:variable>
        <xsl:value-of select="serialize($out)"/>
    </xsl:function>
    
    <xsl:function name="hcmc:getText" as="xs:string">
        <xsl:param name="el"/>
        <xsl:value-of select="normalize-space(string-join($el/descendant::text(),''))"/>
    </xsl:function>
    
</xsl:stylesheet>