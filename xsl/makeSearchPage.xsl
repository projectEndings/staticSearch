<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:svg="http://www.w3.org/2000/svg"
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
        <xd:desc><xd:ref name="hasFilters">$hasFilters</xd:ref> is used to specify whether
        the site build process has discovered any filter metadata in the collection. If so, then
        we need to create appropriate form controls.</xd:desc>
    </xd:doc>
    <xsl:param name="hasFilters" as="xs:string" select="'false'"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="docsJSON" type="variable">$docsJSON</xd:ref> is the previously created
        JSON file from the filters specified in the document metadata; we load this and then parse it
        as XML, since we create the filter selector from it.</xd:desc>
    </xd:doc>
    <xsl:variable name="docsJSON"
                select="concat($outDir, '/docs.json') => unparsed-text() => json-to-xml()"
                as="document-node()"/>
    
    <xsl:variable name="filterJSONURIs" select="if ($hasFilters = 'true') then
        uri-collection(concat($outDir,'/filters/?select=*.json')) else ()"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="svgLogoFile">svgLogoFile</xd:ref> is the relative path
        from this XSLT to the file to be used as the staticSearch logo.</xd:desc>
    </xd:doc>
    <xsl:variable name="svgLogoFile" as="xs:string" select="'../images/logo_01.svg'"/>

    <xd:doc>
        <xd:desc><xd:ref name="css" type="parameter">$css</xd:ref> is a pre-populated
        parameter containing the CSS code that applies to the search form components.
        It is provided as a parameter so that it can be overridden if required.</xd:desc>
    </xd:doc>
    <xsl:param name="css" as="xs:string">
        form#ssForm{
            display: flex;
            flex-direction: column;
        }
        span.ssQueryAndButton{
            display: flex;
            flex-direction: row;
            margin: 0.25em auto;
            width: 100%;
        }
        input#ssQuery{
            flex: 1;
        }
        div.ssDescFilters, div.ssDateFilters, div.ssNumFilters, div.ssBoolFilters{
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
        }
        div.ssDescFilters fieldset, div.ssDateFilters fieldset, div.ssNumFilters fieldset, div.ssBoolFilters fieldset{
            margin: 0.25em auto;
            padding: 0.25em;
            /* Chromium bug means flex doesn't work in fieldsets. Curses. :-( */
            flex-grow: 1;
            display: flex;
            flex-wrap: wrap;
        }
        ul.ssDescCheckboxList{
            list-style-type: none;
            max-height: 8em;
            overflow-y: auto;
            min-width: 90%;
        }
        ul.ssDescCheckboxList li{
            display: flex;
            flex-direction: row;
            flex-wrap: nowrap;
            align-items: flex-start;
        }
        div.ssDateFilters fieldset.ssFieldset span, div.ssNumFilters fieldset.ssFieldset span, div.ssBoolFilters fieldset.ssFieldset span{
            padding: 0.5em 1em;
        }
        fieldset.ssFieldset > span {
            background-color: #ddd;
            border: solid 1px #aaa;
            margin: 0.2em;
        }
        div.ssNumFilters input[type="number"], div.ssDateFilters input[type="text"]{
            padding: 0.5em;
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
        }
        div#ssResults{
          min-height: 50vh;
        }
        div#ssResults>ul>li{
            display: flex;
            flex-direction: row;
            flex-wrap: nowrap;
            margin-top: 0.75em;
        }
        div#ssResults>ul>li>a{
            flex-grow: 0;
        }
        div#ssResults>ul>li>div{
          flex-grow: 1;
        }
        div#ssResults>ul>li>a>img{
            max-width: 10em;
            margin-right: 1em;
            min-width: 3em;
            min-height: 3em;
        }
        div#ssResults>ul>li{
        padding: 0.5em 0.25em;
        }
        
        /* Alternate bg colour. */
        div#ssResults>ul>li:nth-child(2n) {
            background-color: rgb(240, 240, 240);
            transition: background-color .5s;
            border-top: 1px solid rgb(230, 230, 230);
            border-bottom: 1px solid rgb(230, 230, 230);
        }
        /* Larger document titles */
        div#ssResults>ul>li>div>a{
            font-size: 1.2em;
        }
        
        /* No list markers for kwics */
        div#ssResults>ul>li>div>ul.kwic{
            list-style-type: none;
        }
        /* kwics laid out with flex */
        div#ssResults>ul>li>div>ul.kwic>li{
            display: flex;
            flex-direction: row;
            align-items: center;
            justify-content: space-between;
            margin-top: 0.5em;
            border-top: solid 1pt lightgray;
            padding: 0.2em;
        }
        
        div#ssResults>ul>li>div>ul.kwic>li>span{
            display: block;
        }
        
        /* Larger kwic link. */
        div#ssResults>ul>li>div>ul.kwic>li>a{
            font-size: 2.0em;
            line-height: 0.50;
        }
        
        a.fidLink{
            text-decoration: none;
        }
        div#ssPoweredBy{
            font-size: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        div#ssPoweredBy>* {
            margin: 0;
        }
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
            <xsl:comment>
                <xsl:value-of select="$css" disable-output-escaping="yes"/>
            </xsl:comment>
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
                <xsl:comment>
                    <xsl:value-of select="$css" disable-output-escaping="yes"/>
                </xsl:comment>
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
            <script src="{$outputFolder}/ssStemmer.js"><!-- Don't self-close script tags. --></script>
            <script src="{$outputFolder}/ssSearch.js"><!-- Don't self-close script tags. --></script>

            <!--Special on script onload to the start up the StaticSearch-->
            <script>
                var Sch;
                window.addEventListener('load', function(){Sch = new StaticSearch();});
            </script>

            <!--Now create the form-->
            <form accept-charset="UTF-8" id="ssForm"
                data-allowphrasal="{if ($phrasalSearch) then 'yes' else 'no'}"
                data-allowwildcards="{if ($wildcardSearch) then 'yes' else 'no'}"
                data-scrolltotextfragment="{if ($scrollToTextFragment) then 'yes' else 'no'}"
                data-maxkwicstoshow="{if ($maxKwicsToShow) then $maxKwicsToShow else 10}"
                onsubmit="return false;"
                data-versionstring="{$versionString}"
                data-ssfolder="{$outputFolder}"
                data-kwictruncatestring="{$kwicTruncateString}"
                >
                
                <!--Standard inputs-->
                <span class="ssQueryAndButton">
                    <!-- NOTE: We no longer use a validation pattern because
                         browser behaviour is too variable. -->
                    <!--<xsl:variable name="validationPattern" as="xs:string">\s*(.*([^\*\?\[\]\s]+[^\s]*){3})+\s*</xsl:variable>
                    <input type="text" id="ssQuery" pattern="{$validationPattern}"/>-->
                    <input type="text" id="ssQuery"/>
                    <button id="ssDoSearch">Search</button>
                </span>
                
                <xsl:if test="not(empty($filterJSONURIs))">
                    <xsl:variable name="descFilters" select="$filterJSONURIs[matches(.,'ssDesc\d+.*\.json')]"/>
                    <xsl:variable name="dateFilters" select="$filterJSONURIs[matches(.,'ssDate\d+.*\.json')]"/>
                    <xsl:variable name="boolFilters" select="$filterJSONURIs[matches(.,'ssBool\d+.*\.json')]"/>
                    <xsl:variable name="numFilters" select="$filterJSONURIs[matches(.,'ssNum\d+.*\.json')]"/>
                    
                    <!--If there are filters, then add a clear button-->
                    <span class="clearButton"><button id="ssClear">Clear</button></span>
                    <!--First, handle the desc filters-->
                    <xsl:if test="not(empty($descFilters))">
                        <div class="ssDescFilters">
                            <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                            <xsl:variable name="fieldsets" as="element(fieldset)*">
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
                                            <!-- Before sorting checkbox items, we need to know
                                              whether they're numeric or not. -->
                                            <xsl:variable name="notNumeric" select="some $n in (for $s in $jsonDoc//map:map[@key]/map:string[@key='sortKey'] return $s castable as xs:decimal) satisfies $n = false()"/>
                                            <xsl:variable name="sortedMaps" as="element(map:map)+">
                                                <xsl:choose>
                                                    <xsl:when test="$notNumeric">
                                                        <xsl:for-each select="$jsonDoc//map:map[@key]">
                                                            <xsl:sort select="replace(map:string[@key='sortKey'], '^((the)|(a)|(an))\s+', '', 'i')"/>
                                                            <xsl:sequence select="."/>
                                                        </xsl:for-each>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:for-each select="$jsonDoc//map:map[@key]">
                                                            <xsl:sort select="map:string[@key='sortKey']" data-type="number"/>
                                                            <xsl:sequence select="."/>
                                                        </xsl:for-each>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            
                                            <xsl:for-each select="$sortedMaps">
                                                <!--<xsl:sort select="if ($notNumeric)  then replace(map:string[@key='name'], '^((the)|(a)|(an))\s+', '', 'i') else xs:decimal(map:string[@key='name'])"/>-->
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
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                                <xsl:sort select="normalize-space(lower-case(legend))"/>
                                <xsl:sequence select="."/>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <!--Now create date boxes, if necessary-->
                    
                    <xsl:if test="not(empty($dateFilters))">
                        <div class="ssDateFilters">
                            <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                            <xsl:variable name="fieldsets" as="element(fieldset)*">
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
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                                <xsl:sort select="normalize-space(lower-case(legend))"/>
                                <xsl:sequence select="."/>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <xsl:if test="not(empty($numFilters))">
                        <div class="ssNumFilters">
                            <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                            <xsl:variable name="fieldsets" as="element(fieldset)*">
                            
                                <xsl:for-each select="$numFilters">
                                    <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()"
                                        as="document-node()"/>
                                    <xsl:variable name="filterName" select="$jsonDoc//map:string[@key='filterName']"/>
                                    <xsl:variable name="filterId" select="$jsonDoc//map:string[@key='filterId']"/>
                                    <xsl:variable name="vals" select="$jsonDoc//map:string[not(@key)][. castable as xs:decimal]/xs:decimal(.)"/>
                                    <xsl:variable name="minVal" select="min($vals)"/>
                                    <xsl:variable name="maxVal" select="max($vals)"/>
                                    
                                    
                                    <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                        <!--And add the filter name as the legend-->
                                        <legend><xsl:value-of select="$filterName"/></legend>
                                        <span>
                                            <label for="{$filterId}_from">From: </label>
                                            <input type="number" min="{$minVal}" max="{$maxVal}" placeholder="{$minVal}" step="any"
                                                title="{$filterName}" id="{$filterId}_from" 
                                                class="staticSearch.num"/>
                                        </span>
                                        
                                        <span>
                                            <label for="{$filterId}_to">To: </label>
                                            <input type="number" min="{$minVal}" max="{$maxVal}" placeholder="{$maxVal}" step="any"
                                                title="{$filterName}" id="{$filterId}_to" 
                                                class="staticSearch.num"/>
                                        </span>
                                    </fieldset>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                                <xsl:sort select="normalize-space(lower-case(legend))"/>
                                <xsl:sequence select="."/>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <!--And now handle booleans-->
                    <xsl:if test="not(empty($boolFilters))">
                        <div class="ssBoolFilters">
                            <!-- We create a single fieldset for all these filters, since they're individual. -->
                            <fieldset class="ssFieldset">
                                <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                                <xsl:variable name="spans" as="element(span)*">
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
                                </xsl:variable>
                                <xsl:for-each select="$spans">
                                    <xsl:sort select="normalize-space(lower-case(label))"/>
                                    <xsl:sequence select="."/>
                                </xsl:for-each>
                            </fieldset>
                        </div>
                    </xsl:if>
                    <span class="postFilterSearchBtn">
                        <button id="ssDoSearch2">Search</button>
                    </span>
               
                </xsl:if>

            </form>
            
            <!-- Popup message to show that search is being done. -->
            <div id="ssSearching">Searching...</div>

            <!--And now create the results div in the document-->
            <div id="ssResults">
                <!--...results here...-->
            </div>
            
            <!-- Finally, we add our logo and powered-by message. -->
            <div id="ssPoweredBy">
                
                <p>Powered by</p> <a href="https://github.com/projectEndings/staticSearch"><xsl:apply-templates select="doc($svgLogoFile)" mode="svgLogo"/></a>
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
    
    <!--**************************************************************
       *                                                            *
       *        Templates for cleaning up and simplifying SVG       *
       *                                                            *
       **************************************************************-->
    <xd:doc>
        <xd:desc>We create a mode for svg templates to keep it separate.</xd:desc>
    </xd:doc>
    <xsl:mode name="svgLogo" exclude-result-prefixes="#all" on-no-match="shallow-copy"/>
    <xd:doc>
        <xd:desc>We eliminate a few elements.</xd:desc>
    </xd:doc>
    <xsl:template match="svg:defs | svg:metadata" mode="svgLogo"/>
    <xd:doc>
        <xd:desc>We need to prevent the proliferation of namespaces which 
        make things invalid.</xd:desc>
    </xd:doc>
    <xsl:template match="svg:*" mode="svgLogo" exclude-result-prefixes="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="#current" select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the size to something reasonable for a logo.</xd:desc>
    </xd:doc>
    <xsl:template match="svg:svg" mode="svgLogo">
        <xsl:copy exclude-result-prefixes="#all" copy-namespaces="no">
            <xsl:copy-of select="@*[local-name() != ('width', 'height')]"/>
            <xsl:variable name="proportion" select="ceiling(xs:float(@width) div 40)"/>
            <xsl:attribute name="width" select="round(xs:float(@width) div $proportion)"/>
            <xsl:attribute name="height" select="round(xs:float(@height) div $proportion)"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
