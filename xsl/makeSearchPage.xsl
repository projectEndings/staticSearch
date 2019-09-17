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

    <xsl:include href="config.xsl"/>
    <!--Identity transform-->
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:output method="xhtml" encoding="UTF-8" normalization-form="NFC"
        exclude-result-prefixes="#all" omit-xml-declaration="yes" html-version="5.0"/>

    <xsl:template match="div[@id='staticSearch']">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if
                test="* or node()[string-length(normalize-space(string-join(descendant::text(), ''))) gt 0]">
                <xsl:message>WARNING: Contents of div/@id='staticSearch' will be
                    overwritten</xsl:message>
            </xsl:if>

            <script src="staticSearch/ssPorter2Stemmer.js"/>
            <script src="staticSearch/ssSearch.js"/>
            <script>
                var Sch;
                window.addEventListener('load', function(){Sch = new StaticSearch();});
            </script>


            <xsl:variable name="docsJSON"
                select="
                    concat($outDir, '/docs.json')
                    => unparsed-text()
                    => json-to-xml()"
                as="document-node()"/>

       

            <form accept-charset="UTF-8" id="ssForm"
                data-allowPhrasal="{if ($phrasalSearch) then 'yes' else 'no'}"
                onsubmit="return false;">
                <xsl:if test="$docsJSON/descendant::map:array[@key]">
                    
                    <xsl:for-each-group select="$docsJSON//map:array[@key]" group-by="@key">
                        <xsl:variable name="filterName" select="current-grouping-key()"/>
                        <fieldset>
                            <xsl:variable name="grpPos" select="position()"/>
                            <legend><xsl:value-of select="$filterName"/></legend>
           
                            <ul class="checkboxList">
                                <xsl:for-each-group select="current-group()" group-by="map:string/text()">
                                    <xsl:variable name="thisPos" select="position()"/>
                                    <xsl:variable name="filterVal" select="current-grouping-key()"/> 
                                    <li><input type="checkbox" title="{$filterName}" value="{$filterVal}" id="opt_{$grpPos}_{$thisPos}" class="ssFilter"/> <label for="opt_{$grpPos}_{$thisPos}"><xsl:value-of select="$filterVal"/></label></li>
                                </xsl:for-each-group>
                            </ul>
                        </fieldset>
                    </xsl:for-each-group>
                </xsl:if>
                <input type="text" id="ssQuery"/>
                <button id="ssDoSearch">Search</button>





                <!--IF THERE ARE FILTERS...-->
                <!--    
            <label>Document type</label>
            <ul class="checkboxList">
                <li><input type="checkbox" title="Document type" value="Timeline articles" class="ssFilter"/> <label>Timeline articles</label></li>
                <li><input type="checkbox" title="Document type" value="Chronology pages" class="ssFilter"/> <label>Chronology pages</label></li>
                <li><input type="checkbox" title="Document type" value="Poems" class="ssFilter"/> <label>Poems</label></li>
                <li><input type="checkbox" title="Document type" value="Other pages" class="ssFilter"/> <label>Other pages</label></li>
            </ul>
            
            -->

            </form>
            <div id="ssResults">
                <!--...results here...-->
            </div>

        </xsl:copy>

    </xsl:template>



</xsl:stylesheet>
