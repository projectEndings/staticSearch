<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 1, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
            <xd:p>Stylesheet that provides constants as parameters, which can be used
            within shadow attributes.</xd:p>
        </xd:desc>
    </xd:doc>
    
    
    <xsl:param name="PRIORITY_FIRST" as="xs:integer" static="yes" select="100"/>
    <xsl:param name="PRIORITY_SECOND" as="xs:integer" static="yes" select="50"/>
    <xsl:param name="PRIORITY_THIRD" as="xs:integer" static="yes" select="25"/>
    <xsl:param name="PRIORITY_FOURTH" as="xs:integer" static="yes" select="10"/>
    <xsl:param name="PRIORITY_FIFTH" as="xs:integer" static="yes" select="5"/>
    <xsl:param name="PRIORITY_LAST" as="xs:integer" static="yes" select="1"/>
    
    <xsl:param name="KEY_WEIGHTS" as="xs:string" static="yes" select="'weights'"/>
    <xsl:param name="KEY_CONTEXTS" as="xs:string" static="yes" select="'contexts'"/>
    <xsl:param name="KEY_CONTEXT_IDS" as="xs:string" static="yes" select="'contextIds'"/>
    <xsl:param name="KEY_EXCLUDES" as="xs:string" static="yes" select="'excludes'"/>
    
</xsl:stylesheet>