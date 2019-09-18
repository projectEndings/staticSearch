<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
            <xd:p><xd:b>Created on:</xd:b> Sep 16, 2019</xd:p>
            <xd:p><xd:b>Author:</xd:b> joeytakeda</xd:p>
            <xd:p>This stylesheet transforms the search page into a workable one, based off of
                filters etc.</xd:p>
        </xd:desc>
    </xd:doc>

    <!--**************************************************************
       *                                                            * 
       *                         Includes                           *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Include the global config XSLT that is derived from the configuration file
        and the create_config.xsl. See <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a>
        for more details.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
    
    <!--**************************************************************
       *                                                            * 
       *                         Modes                              *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>This mode tag (which applies to the default) specifies that this is an
        identity transform (@on-no-match='shallow-copy'). This require XSLT 3.0.</xd:desc>
    </xd:doc>
    <xsl:mode on-no-match="shallow-copy"/>
    
    <!--**************************************************************
       *                                                            * 
       *                         Output                             *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Output as XHTML with HTML version 5.0; this is necessary for adding the
        propery DOCTYPE processing instruction.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" encoding="UTF-8" normalization-form="NFC"
        exclude-result-prefixes="#all" omit-xml-declaration="yes" html-version="5.0"/>

    <!--**************************************************************
       *                                                            * 
       *                         Variables                          *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc><xd:ref name="docsJSON" type="variable">$docsJSON</xd:ref> is the previously created
        JSON file from the filters specified in the document metadata; we load this and then parse it
        as XML, since we create the filter selector from it.</xd:desc>
    </xd:doc>
    <xsl:variable name="docsJSON"
                select="concat($outDir, '/docs.json') => unparsed-text() => json-to-xml()"
                as="document-node()"/>


    <!--**************************************************************
       *                                                            * 
       *                         Templates                          *
       *                                                            *
       **************************************************************-->
    
   <xd:doc>
       <xd:desc>Root template just for checking to see whether or not the document has
       the require div/@id='staticSearch'.</xd:desc>
   </xd:doc>
    <xsl:template match="/">
        
        <!--Warning message if there is no staticSearch div in the document-->
        <xsl:if test="not(descendant::div[@id='staticSearch'])">
            <xsl:message>ERROR: Document does not contain a div/@id='staticSearch' and thus this transformation
                will not do anything.</xsl:message>
        </xsl:if>
        
        <!--Now apply templates-->
        <xsl:apply-templates/>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>This is the main template for matching the staticSearch div;
        this is where all the work happens for create the search box and the filter
        options. This is also where we load in the Javasript; we do this here
        rather than in the head of the document so not to interfere with existing Javascript
        in the header of document.</xd:desc>
    </xd:doc>
    <xsl:template match="div[@id='staticSearch']">
        
        <!--First, copy out the div-->
        <xsl:copy>
            
            <!--Copy out attributes-->
            <xsl:copy-of select="@*"/>
            
            <!--Warn if there is anything contained within the div, since it will be wiped out-->
            <xsl:if test="* or node()[string-length(normalize-space(string-join(descendant::text(), ''))) gt 0]">
                <xsl:message>WARNING: Contents of div/@id='staticSearch' will be overwritten</xsl:message>
            </xsl:if>
            
            <!--Now add the scripts to the staticSearch library-->
            <script src="staticSearch/ssPorter2Stemmer.js"><!-- Don't self-close script tags. --></script>
            <script src="staticSearch/ssSearch.js"><!-- Don't self-close script tags. --></script>
            
            <!--Special on script onload to the start up the StaticSearch-->
            <script>
                var Sch;
                window.addEventListener('load', function(){Sch = new StaticSearch();});
            </script>
            
            <!--Now create the form-->
            <form accept-charset="UTF-8" id="ssForm"
                data-allowPhrasal="{if ($phrasalSearch) then 'yes' else 'no'}"
                onsubmit="return false;">
                
                <!--Standard inputs-->
                <input type="text" id="ssQuery"/>
                <button id="ssDoSearch">Search</button>
                
                <!--And if the docsJson actually has useful content, create the filter selection-->
                <xsl:if test="$docsJSON/descendant::map:array[@key]">
                    
                    <!--Group these by keys (aka the name of the filter)-->
                    <xsl:for-each-group select="$docsJSON//map:array[@key]" group-by="@key">
                        <xsl:variable name="filterName" select="current-grouping-key()"/>
                        
                        <!--For each of those groups, create a fieldset-->
                        <fieldset>
                            <xsl:variable name="grpPos" select="position()"/>
                            <!--And add the filter name as the legend-->
                            <legend><xsl:value-of select="$filterName"/></legend>
                            
                            <!--And now make the checkbox list-->
                            <ul class="checkboxList">
                                
                                <!--Now loop through the current set of arrays and determine all of the distinct
                                    values for that array-->
                                <xsl:for-each-group select="current-group()" group-by="map:string/text()">
                                    <xsl:variable name="thisPos" select="position()"/>
                                    <xsl:variable name="filterVal" select="current-grouping-key()"/> 
                                    <!--And create the input item: the input item contains:
                                        * an @title that specifies the filter name (e.g. Genre)
                                        * an @value that specifies the filter value (e.g. Poem)
                                        * an @id to associate the label for A11Y; we just make the ids arbitrary
                                          based off group numbers-->
                                    <li>
                                        <input type="checkbox" title="{$filterName}" value="{$filterVal}" id="opt_{$grpPos}_{$thisPos}" class="ssFilter"/>
                                        <label for="opt_{$grpPos}_{$thisPos}"><xsl:value-of select="$filterVal"/></label>
                                    </li>
                                </xsl:for-each-group>
                            </ul>
                        </fieldset>
                    </xsl:for-each-group>
                </xsl:if>
            </form>
            
            <!--And now create the results div in the document-->
            <div id="ssResults">
                <!--...results here...-->
            </div>
        </xsl:copy>
    </xsl:template>



</xsl:stylesheet>
