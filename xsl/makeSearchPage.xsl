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
            div.ssFilters, div.ssDates{
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
        }
        div.ssFilters fieldset, div.ssDates fieldset{
            margin: 0.25em auto;
            flex-grow: 1;
        }
        ul.ssCheckboxList{
            list-style-type: none;
            max-height: 8em;
            overflow-y: auto;
        }
        ul.ssCheckboxList li{
            display: flex;
            flex-direction: row;
            flex-wrap: nowrap;
            align-items: flex-start;
        }
        div.ssDates fieldset.ssFieldset span{
            padding-left: 2em;
        }
    </xsl:param>

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

                <!--And if the docsJson actually has useful content, create the filter selection-->
                <xsl:if test="$docsJSON/descendant::map:array[@key]">
                    <!--  First we handle the regular filters. We contain them in a div for layout purposes. -->
                    <xsl:if test="$docsJSON//map:map[@key = 'descFilters']/map:array[@key]">
                        <div class="ssDescFilters">
                            <!--Group these by keys (aka the name of the filter)-->
                            <xsl:for-each-group select="$docsJSON//map:map[@key = 'descFilters']/map:array[@key]" group-by="@key">
                                <xsl:variable name="filterName" select="current-grouping-key()"/>

                                <!--For each of those groups, create a fieldset-->
                                <fieldset class="ssFieldset">
                                    <xsl:variable name="grpPos" select="position()"/>
                                    <!--And add the filter name as the legend-->
                                    <legend><xsl:value-of select="$filterName"/></legend>
                                    
                                    <!--And now make the checkbox list-->
                                    <ul class="ssDescCheckboxList">

                                        <!--Now loop through the current set of arrays and determine all of the distinct
                                    values for that array-->
                                        <xsl:for-each-group select="current-group()" group-by="map:string/text()">
                                            <xsl:sort select="replace(current-grouping-key(), '^The\s+', '')"/>
                                            <xsl:variable name="thisPos" select="position()"/>
                                            <xsl:variable name="filterVal" select="current-grouping-key()"/>
                                            <!--And create the input item: the input item contains:
                                        * an @title that specifies the filter name (e.g. Genre)
                                        * an @value that specifies the filter value (e.g. Poem)
                                        * an @id to associate the label for A11Y; we just make the ids arbitrary
                                          based off group numbers-->
                                            <li>
                                                <input type="checkbox" title="{$filterName}" value="{$filterVal}" id="opt_{$grpPos}_{$thisPos}" class="staticSearch.desc"/>
                                                <label for="opt_{$grpPos}_{$thisPos}"><xsl:value-of select="$filterVal"/></label>
                                            </li>
                                        </xsl:for-each-group>
                                    </ul>
                                </fieldset>
                            </xsl:for-each-group>
                        </div>
                    </xsl:if>

                    <!--  Next we handle the date filters. We contain them in a div. -->
                    <xsl:if test="$docsJSON//map:map[@key = 'dateFilters']/map:array[@key]">
                        <div class="ssDateFilters">
                        <!--Group these by keys (aka the name of the filter)-->
                            <xsl:for-each-group select="$docsJSON//map:map[@key = 'dateFilters']/map:array[@key]" group-by="@key">
                                <xsl:variable name="filterName" select="replace(current-grouping-key(), '^The\s+', '')"/>

                                <!--For each of those groups, create a fieldset-->
                                <fieldset class="ssFieldset">
                                    <xsl:variable name="grpPos" select="position()"/>
                                    <!--And add the filter name as the legend-->
                                    <legend><xsl:value-of select="$filterName"/></legend>
                                    <!--  Create two input elements, a from date and a to date.  -->
                                    <!-- TODO: FIGURE OUT HOW TO HANDLE THE CAPTIONS REQUIRED HERE, instead of hard-coding them. -->
                                    <!--<xsl:message>Dates found in the docs.json: <xsl:value-of select="string-join()"/></xsl:message>-->
                                    <xsl:variable name="minDate" as="xs:date" select="min((for $d in $docsJSON//map:map[@key = 'dateFilters']/map:array[@key = current-grouping-key()]/map:string[1][matches(., '^\d\d\d\d(-[01]\d(-\d\d)?)?$')] return hcmc:normalizeDateString($d, true())))"/>
                                    <xsl:variable name="maxDate" as="xs:date" select="max((for $d in $docsJSON//map:map[@key = 'dateFilters']/map:array[@key = current-grouping-key()]/map:string[1][matches(., '^\d\d\d\d(-[01]\d(-\d\d)?)?$')] return hcmc:normalizeDateString($d, false())))"/>
                                    <span><label for="date_{$grpPos}_from">From: </label> <input type="text" maxlength="10" pattern="\d\d\d\d(-[01]\d(-\d\d)?)?" title="{$filterName}" id="date_{$grpPos}_from" class="staticSearch.date" placeholder="{format-date($minDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/></span>
                                    <span><label for="date_{$grpPos}_to">To: </label> <input type="text" maxlength="10" pattern="\d\d\d\d(-[01]\d(-\d\d)?)?" title="{$filterName}" id="date_{$grpPos}_to" class="staticSearch.date" placeholder="{format-date($maxDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/></span>
                                </fieldset>
                            </xsl:for-each-group>
                        </div>
                    </xsl:if>
                    
                    <!--  Next we do the boolean filters. We contain them in a div. -->
                    <xsl:if test="$docsJSON//map:map[@key = 'boolFilters']/map:boolean[@key]">
                        <div class="ssBoolFilters">
                            <!-- We create a single fieldset for all these filters, since they're individual. -->
                            <fieldset class="ssFieldset">
                                <!--For each group, we create a single label and select element.-->
                                <xsl:for-each-group select="$docsJSON//map:map[@key = 'boolFilters']/map:boolean[@key]" group-by="@key">
                                    <xsl:variable name="filterName" select="replace(current-grouping-key(), '^The\s+', '')"/>
                                    <xsl:variable name="grpPos" select="position()"/>
                                    <span>
                                        <label for="bool_{$grpPos}"><xsl:value-of select="$filterName"/>: </label>
                                        <select id="bool_{$grpPos}" title="{$filterName}" class="staticSearch.bool">
                                            <option value="">?</option>
                                            <option value="true">true</option>
                                            <option value="false">false</option>
                                        </select>
                                    </span>
                                </xsl:for-each-group>
                            </fieldset>
                            
                        </div>
                    </xsl:if>
                </xsl:if>
            </form>

            <!--And now create the results div in the document-->
            <div id="ssResults">
                <!--...results here...-->
            </div>
        </xsl:copy>
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
