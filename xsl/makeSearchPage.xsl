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
       *                         Variables and parameters                         *
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
    
    <xsl:variable name="filterJSONURIs" select="
        uri-collection(concat($outDir,'/filters/?select=*.json'))"/>

    <xd:doc>
        <xd:desc><xd:ref name="css" type="parameter">$css</xd:ref> is a pre-populated
        parameter containing the CSS code that applies to the search form components.
        It is provided as a parameter so that it can be overridden if required.</xd:desc>
    </xd:doc>
    <xsl:param name="css" as="xs:string">
        span.ssQueryAndButton{
            display: flex;
            flex-direction: row;
            margin: 0.25em auto;
        }
        input#ssQuery{
            flex: 1;
        }
        div.ssDescFilters, div.ssDateFilters, div.ssBoolFilters{
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
        }
        div.ssDescFilters fieldset, div.ssDateFilters fieldset, div.ssBoolFilters fieldset{
            margin: 0.25em auto;
            flex-grow: 1;
            display: flex;
            flex-wrap: wrap;
        }
        ul.ssDescCheckboxList{
            list-style-type: none;
            max-height: 8em;
            overflow-y: auto;
        }
        ul.ssDescCheckboxList li{
            display: flex;
            flex-direction: row;
            flex-wrap: nowrap;
            align-items: flex-start;
        }
        div.ssDateFilters fieldset.ssFieldset span, div.ssBoolFilters fieldset.ssFieldset span{
            padding: 0.5em 1em;
        }
        div#ssSearching{
            background-color: #000000;
            color: #ffffff;
            font-size: 1.5rem;
            padding: 1rem;
            border-radius: 0.25rem 0.25rem;
            position: fixed;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            display: none;
    </xsl:param>
    
    <xsl:variable name="dateRegex" select="'^\d\d\d\d(-((((01)|(03)|(05)|(07)|(08)|(10)|(12))-((0[1-9])|([12][0-9])|(3[01])))|(((04)|(06)|(09)|(11))-((0[1-9])|([12][0-9])|(30)))|(02-((0[1-9])|([12][0-9]))))|(-((0[123456789])|(1[012]))))?$'" as="xs:string"/>

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
        <xd:desc>This  template replaces an existing style element with the id ssCss
            with another one containing the code in the <xd:ref name="css">$css</xd:ref>
            parameter.</xd:desc>
    </xd:doc>
    <xsl:template match="style[@id='ssCss']">
        <style id="ssCss">
            <xsl:value-of select="$css"/>
        </style>
    </xsl:template>

    <xd:doc>
        <xd:desc>This  template detects an HTML head element which does not contain an
            existing style element with the id ssCss, and injects one containing the code in
            the <xd:ref name="css">$css</xd:ref> parameter. We place it first in the head element
            so that any subsequent style element provided by the user can override it.</xd:desc>
    </xd:doc>
    <xsl:template match="head[not(style[@id='ssCss'])]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <style id="ssCss">
                <xsl:value-of select="$css"/>
            </style>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
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
                <span class="ssQueryAndButton">
                    <input type="text" id="ssQuery"/>
                    <button id="ssDoSearch">Search</button>
                </span>
                
                <xsl:if test="not(empty($filterJSONURIs))">
                    <xsl:variable name="descFilters" select="$filterJSONURIs[matches(.,'ssDesc\d+\.json')]"/>
                    <xsl:variable name="dateFilters" select="$filterJSONURIs[matches(.,'ssDate\d+\.json')]"/>
                    <xsl:variable name="boolFilters" select="$filterJSONURIs[matches(.,'ssBool\d+\.json')]"/>
                    
                    
                    <!--First, handle the desc filters-->
                    <xsl:if test="not(empty($descFilters))">
                        <div class="ssDescFilters">
                            <xsl:for-each select="$descFilters">
                                
                                <!--Get the document-->
                                <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()" as="document-node()"/>
                               
                               <!--And its name and id -->
                                <xsl:variable name="filterName" select="$jsonDoc//map:string[@key='filterName']"/>
                                <xsl:variable name="filterId" select="$jsonDoc//map:string[@key='filterId']"/>
                                
                                <!--And now create the fieldset and legend-->
                                <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                    <legend><xsl:value-of select="$filterName"/></legend>
                                    
                                    <!--And create a ul from each of the embedded maps-->
                                    <ul class="ssDescCheckboxList">
                                        <xsl:for-each select="$jsonDoc//map:map[@key]">
                                            <xsl:sort select="replace(map:string[@key='name'], '^((the)|(a)|(an))\s+', '', 'i')"/>
                                            <!--And create the input item: the input item contains:
                                            * an @title that specifies the filter name (e.g. Genre)
                                            * an @value that specifies the filter value (e.g. Poem)
                                            * an @id to associate the label for A11Y-->
                                            <xsl:variable name="thisOptId" select="@key"/>
                                            <xsl:variable name="thisOptName" select="map:string[@key='name']"/>
                                            <li>
                                                <input type="checkbox" title="{$filterName}" value="{$thisOptName}" id="{$thisOptId}" class="staticSearch.desc"/>
                                                <label for="{$thisOptId}"><xsl:value-of select="$thisOptName"/></label>
                                            </li>
                                        </xsl:for-each>
                                    </ul>
                                </fieldset>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <!--Now create date boxes, if necessary-->
                    
                    <xsl:if test="not(empty($dateFilters))">
                        <div class="ssDateFilters">
                            <xsl:for-each select="$dateFilters">
                                <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()" as="document-node()"/>
                                <xsl:variable name="filterName" select="$jsonDoc//map:string[@key='filterName']"/>
                                <xsl:variable name="filterId" select="$jsonDoc//map:string[@key='filterId']"/>
                                
                                <!--Get the minimum from the date regex-->
                                <xsl:variable name="minDate" as="xs:date" 
                                    select="min((for $d in $jsonDoc//map:string[1][matches(., $dateRegex)] return hcmc:normalizeDateString($d, true())))"/>
                                
                                <!--And the maximum date-->
                                <xsl:variable name="maxDate" as="xs:date" 
                                    select="max((for $d in $jsonDoc//map:string[1][matches(., $dateRegex)] return hcmc:normalizeDateString($d, false())))"/>
                                
                                <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                    <!--And add the filter name as the legend-->
                                    <legend><xsl:value-of select="$filterName"/></legend>
                                    <span>
                                        <label for="{$filterId}_from">From: </label>
                                        <input type="text" maxlength="10" pattern="{$dateRegex}" title="{$filterName}" id="{$filterId}_from" class="staticSearch.date" placeholder="{format-date($minDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/>
                                    </span>
                                    
                                    <span>
                                        <label for="{$filterId}_to">To: </label>
                                        <input type="text" maxlength="10" pattern="{$dateRegex}" title="{$filterName}" id="{$filterId}_to" class="staticSearch.date" placeholder="{format-date($maxDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/>
                                    </span>
                                </fieldset>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <!--And now handle booleans-->
                    <xsl:if test="not(empty($boolFilters))">
                        <div class="ssBoolFilters">
                            <!-- We create a single fieldset for all these filters, since they're individual. -->
                            <fieldset class="ssFieldset">
                                
                                <xsl:for-each select="$boolFilters">
                                    <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()" as="document-node()"/>
                                    <xsl:variable name="filterName" select="$jsonDoc//map:string[@key='filterName']"/>
                                    <xsl:variable name="filterId" select="$jsonDoc//map:string[@key='filterId']"/>
                                    <span>
                                        <label for="{$filterId}"><xsl:value-of select="$filterName"/>: </label>
                                        <select id="{$filterId}" title="{$filterName}" class="staticSearch.bool">
                                            <option value="">?</option>
                                            <option value="true">true</option>
                                            <option value="false">false</option>
                                        </select>
                                    </span>
                                </xsl:for-each>
                            </fieldset>
                            
                        </div>
                    </xsl:if>
               
                </xsl:if>

            </form>
            
            <!-- Popup message to show that search is being done. -->
            <div id="ssSearching">Searching...</div>

            <!--And now create the results div in the document-->
            <div id="ssResults">
                <!--...results here...-->
            </div>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Repeated running of this process over the same document can 
        result in excessive quantities of whitespace. Rather than try to figure out
        where to preserve whitespace and where not, we just constrain it with this
        template.</xd:desc>
    </xd:doc>
    <xsl:template match="text()[matches(., '^(\s*\n\s*\n\s*)+$')][not(ancestor::script or ancestor::style)]">
        <xsl:text>&#x0a;&#x0a;</xsl:text>
    </xsl:template>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:normalizeDateString" type="function">hcmc:normalizeDateString</xd:ref>
        converts truncated dates (yyyy, or yyyy-mm) to fully-specified dates. It ignores leap years.
        </xd:desc>
        <xd:param name="dateString">dateString is the incoming string representation of a date.</xd:param>
        <xd:param name="earliest">earliest is a boolean parameter specifying whether
            it should be the earliest possible date or the latest.</xd:param>
        <xd:return>An xs:date or the null sequence</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:normalizeDateString" as="xs:date?">
        <xsl:param name="dateString" as="xs:string"/>
        <xsl:param name="earliest" as="xs:boolean"/>
        <xsl:message>Processing date <xsl:value-of select="$dateString"/></xsl:message>
        <xsl:choose>
            <xsl:when test="matches($dateString, '^\d\d\d\d$')">
                <xsl:choose>
                    <xsl:when test="$earliest"><xsl:sequence select="xs:date(concat($dateString, '-01-01'))"/></xsl:when>
                    <xsl:otherwise><xsl:sequence select="xs:date(concat($dateString, '-12-31'))"/></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="matches($dateString, '^\d\d\d\d-\d\d$')">
                <xsl:choose>
                    <xsl:when test="$earliest"><xsl:sequence select="xs:date(concat($dateString, '-01'))"/></xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="matches($dateString, '^\d\d\d\d-((01)|(03)|(05)|(07)|(08)|(10)|(12))$')">
                                <xsl:sequence select="xs:date(concat($dateString, '-31'))"/>
                            </xsl:when>
                            <xsl:when test="matches($dateString, '^\d\d\d\d-((04)|(06)|(09)|(11))$')">
                                <xsl:sequence select="xs:date(concat($dateString, '-30'))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="xs:date(concat($dateString, '-28'))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="matches($dateString, '^\d\d\d\d-\d\d-\d\d$')">
                <xsl:sequence select="xs:date($dateString)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
