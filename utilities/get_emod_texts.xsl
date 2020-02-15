<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 15, 2020</xd:p>
            <xd:p><xd:b>Author:</xd:b> joeytakeda</xd:p>
            <xd:p>This stylesheet gets the mayoral shows from MoEML and cleans them up to make them a bit more generic
            for use in testing Early Modern stemming.</xd:p>
        </xd:desc>
    </xd:doc>
    
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:variable name="listOfShows" select="('FAME2','DEVI3','INTE1','EMPO1','VERT2','GOLD4','SCAT1','TROI1','PECA1','PIET2','HIMA1','ARIE1','SPEC1','BRIT4','CHRU1','SINU1','TESI1','CHRY1','LOVE8','HEAL2','MONU1','JUSH1','TRIU2','TRIU3','METR1','TRIU1','SIDE1','TEMP3','DECE1','CAMP3','DIXI2')" as="xs:string+"/>
    
    <xsl:template name="go">
        <xsl:for-each select="$listOfShows">
            <xsl:result-document href="../emod/{.}.htm">
                <xsl:apply-templates select="document('https://jenkins.hcmc.uvic.ca/job/MoEML/lastSuccessfulBuild/artifact/static/site/' || . ||'.htm')"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    
    <!--Delete chrome-->
    <xsl:template match="div[@id=('footer','leftCol','topBanner')]"/>
    
    <!--Delete draft doc warning-->
    <xsl:template match="div[@id=('draftDoc', 'draftWarning')]"/>
    
    <!--Delete facs link-->
    <xsl:template match="div[@class='facsimileLink']"/>
    
    <!--Delete appendix and breadcrumbs-->
    <xsl:template match="div[@class=('appendix','breadCrumbs')]"/>
    
    <!--Just process the contents of links,
    since they won't go anywhere anyway-->
    <xsl:template match="a">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <!--All links and scripts can be removed-->
    <xsl:template match="link | script"/>
    
    <!--And we can get rid of all of the project specific metadata-->
    <xsl:template match="meta[@name]"/>
    
    <!--Remove long, unwieldy attribute text-->
    <xsl:template match="@data-link | @data-link-text"/>
    
</xsl:stylesheet>