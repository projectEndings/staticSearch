<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:j="http://www.w3.org/2005/xpath-functions"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
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
    
    <xd:doc>
        <xd:desc>Include the captions set and the associated function.</xd:desc>
    </xd:doc>
    <xsl:include href="captions.xsl"/>

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
      <xd:desc><xd:ref name="dateRegex">dateRegex</xd:ref> is used for date matching/recognition
        when creating date filters.</xd:desc>
    </xd:doc>
    <xsl:variable name="dateRegex" select="'^\d\d\d\d(-((((01)|(03)|(05)|(07)|(08)|(10)|(12))-((0[1-9])|([12][0-9])|(3[01])))|(((04)|(06)|(09)|(11))-((0[1-9])|([12][0-9])|(30)))|(02-((0[1-9])|([12][0-9]))))|(-((0[123456789])|(1[012]))))?$'" as="xs:string"/>
  
    <xd:doc>
      <xd:desc><xd:ref name="pageLang">pageLang</xd:ref> is the language of the search page (if specified)
      or "en" if not. This is used for sorting filter items.</xd:desc>
    </xd:doc>
  <xsl:variable name="pageLang" as="xs:string" select="if (/html/@*:lang) then /html/@*:lang[1] else 'en'"/>

    <!--**************************************************************
       *                                                            *
       *                         Templates                          *
       *                                                            *
       **************************************************************-->

   <xd:doc>
       <xd:desc>Root template just for checking to see whether or not the document has
       the require an element with @id='staticSearch' (preferably a div).</xd:desc>
   </xd:doc>
    <xsl:template match="/">

        <!--Warning message if there is no staticSearch elements in the document. -->
        <xsl:if test="not(descendant::*[@id='staticSearch'])">
            <xsl:message>ERROR: Document does not contain an HTML element with @id='staticSearch' and thus this transformation will not do anything.</xsl:message>
        </xsl:if>
      
      <!--Warning message if there are multiple elements with @id='staticSearch'. -->
      <xsl:if test="count(descendant::*[@id='staticSearch']) gt 1">
        <xsl:message>WARNING: Document contains multiple HTML elements with @id='staticSearch'. 
        This transformation will use the first one found.</xsl:message>
      </xsl:if>
      
      <!--Warning message if the first element with @id='staticSearch' is not a div. -->
      <xsl:if test="descendant::*[@id='staticSearch'] and 
        local-name(descendant::*[@id='staticSearch'][1]) ne 'div'">
        <xsl:message>WARNING: The element with @id='staticSearch' is not a div element.
        This may result in invalid HTML or unpredictable layout behaviour.</xsl:message>
      </xsl:if>
      
        <!--Now apply templates-->
        <xsl:apply-templates/>
    </xsl:template>

    <xd:doc>
        <xd:desc>This  template replaces an existing style element with the id ssCss (old approach)
            or a link element with the same id (2020-01-21 onward)
            with a link element pointing to the CSS file.</xd:desc>
    </xd:doc>
    <xsl:template match="style[@id='ssCss'] | link[@id='ssCss']">
        <link rel="stylesheet" href="{$outputFolder}/ssSearch.css" id="ssCss"/>
        <!--<style id="ssCss">
            <xsl:comment>
                <xsl:value-of select="$css" disable-output-escaping="yes"/>
            </xsl:comment>
        </style>-->
    </xsl:template>

    <xd:doc>
        <xd:desc>This  template detects an HTML head element which does not contain an
            existing style element with the id ssCss, and injects one containing the code in
            the <xd:ref name="css">$css</xd:ref> parameter. We place it first in the head element
            so that any subsequent style element provided by the user can override it.</xd:desc>
    </xd:doc>
    <xsl:template match="head[not(*[@id='ssCss'])]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <link rel="stylesheet" href="{$outputFolder}/ssSearch.css" id="ssCss"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>This is the main template for matching the staticSearch element
          (which under normal circumstances should be a div, but which may be 
          any element). This is where all the work happens for create the search 
          box and the filter options. This is also where we load in the Javasript; 
          we do this here rather than in the head of the document so not to 
          interfere with existing Javascript in the header of document.</xd:desc>
    </xd:doc>
    <xsl:template match="*[@id='staticSearch'][not(preceding::*[@id='staticSearch'])]">
        
        <!--Get the language we should be using for retrieving captions, defaulting to 'en'
            if no language is specified-->
        <xsl:variable name="captionLang" as="xs:string">
            <xsl:variable name="declaredLang" select="string(ancestor-or-self::*[@xml:lang or @lang][1]/(@xml:lang, @lang)[1])" as="xs:string?"/>
            <xsl:choose>
                <xsl:when test="exists($declaredLang)">
                    <xsl:sequence select="$declaredLang"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$verbose">
                        <xsl:message>WARNING: No language declared for element with @id='staticSearch' to determine captions. Using 'en' by default.</xsl:message>
                    </xsl:if>
                    <xsl:sequence select="'en'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!--First, copy out the div-->
        <xsl:copy>

            <!--Copy out attributes-->
            <xsl:copy-of select="@*"/>

            <!--Warn if there is anything contained within the element, since it will be wiped out-->
            <xsl:if test="* or node()[string-length(normalize-space(string-join(descendant::text(), ''))) gt 0]">
                <xsl:message>WARNING: Contents of element with @id='staticSearch' will be overwritten</xsl:message>
            </xsl:if>

            <!--Now add the script for the staticSearch library. -->

            <script src="{$outputFolder}/ssSearch.js"><!-- Don't self-close script tags. --></script>
          
            <xsl:comment>
              Note that if you want to debug a problem with the JavaScript, you can
              change "ssSearch.js" to "ssSearch-debug.js" to link the uncompressed, 
              unminified code instead.
            </xsl:comment>
          
            <!--Now add the script that initializes the search object. -->
          
            <script src="{$outputFolder}/ssInitialize.js"><!-- Don't self-close script tags. --></script>
            <noscript><xsl:value-of select="hcmc:getCaption('ssScriptRequired', $captionLang)"/></noscript>

            <!--Now create the form-->
            <form accept-charset="UTF-8" id="ssForm"
                data-allowphrasal="{if ($phrasalSearch) then 'yes' else 'no'}"
                data-allowwildcards="{if ($wildcardSearch) then 'yes' else 'no'}"
                data-minwordlength="{if ($minWordLength) then $minWordLength else '3'}"
                data-scrolltotextfragment="{if ($scrollToTextFragment) then 'yes' else 'no'}"
                data-maxkwicstoshow="{if ($maxKwicsToShow) then $maxKwicsToShow else 10}"
                data-resultsperpage="{$resultsPerPage}"
                onsubmit="return false;"
                data-versionstring="{$versionString}"
                data-ssfolder="{$outputFolder}"
                data-kwictruncatestring="{$kwicTruncateString}"
                data-resultslimit="{$resultsLimit}"
                >
                
                <!--Standard inputs-->
                <span class="ssQueryAndButton">
                    <!-- NOTE: We no longer use a validation pattern because
                         browser behaviour is too variable. -->
                    <!--<xsl:variable name="validationPattern" as="xs:string">\s*(.*([^\*\?\[\]\s]+[^\s]*){3})+\s*</xsl:variable>
                    <input type="text" id="ssQuery" pattern="{$validationPattern}"/>-->
                    <input type="text" id="ssQuery" aria-label="{hcmc:getCaption('ssDoSearch', $captionLang)}"/>
                    <button id="ssDoSearch"><xsl:sequence select="hcmc:getCaption('ssDoSearch', $captionLang)"/></button>
                </span>
                
                <xsl:if test="not(empty($filterJSONURIs)) or not(empty($ssContextMap))">
                    <xsl:variable name="descFilters" select="$filterJSONURIs[matches(.,'ssDesc\d+.*\.json')]"/>
                    <xsl:variable name="featFilters" select="$filterJSONURIs[matches(.,'ssFeat\d+.*\.json')]"/>
                    <xsl:variable name="dateFilters" select="$filterJSONURIs[matches(.,'ssDate\d+.*\.json')]"/>
                    <xsl:variable name="boolFilters" select="$filterJSONURIs[matches(.,'ssBool\d+.*\.json')]"/>
                    <xsl:variable name="numFilters" select="$filterJSONURIs[matches(.,'ssNum\d+.*\.json')]"/>
                    
                    <!--If there are filters, then add a clear button-->
                    <span class="clearButton">
                        <button id="ssClear">
                            <xsl:sequence select="hcmc:getCaption('ssClear', $captionLang)"/>
                        </button>
                    </span>
                    
                    <!--Add the "search in" control, which isn't a document filter
                        in the same way-->
                    <xsl:if test="not(empty($ssContextMap))">
                        <xsl:variable name="caption" select="hcmc:getCaption('ssSearchIn', $captionLang)"/>
                        <div class="ssSearchInFilters">
                            <fieldset class="ssFieldset" title="{$caption}">
                                <legend><xsl:value-of select="$caption"/></legend>
                                <ul class="ssSearchInCheckboxList">
                                    <xsl:for-each select="map:keys($ssContextMap)">
                                        <!--Sort the context keys by their value-->
                                        <xsl:sort select="."/>
                                        <xsl:variable name="currLabel" select="."
                                            as="xs:string"/>
                                        <xsl:variable name="id" select="$ssContextMap(.)"
                                            as="xs:string"/>
                                        <li>
                                            <input type="checkbox"
                                                title="{$currLabel}" value="{$currLabel}" id="{$id}"
                                                class="staticSearch_searchIn"/>
                                            <label for="{$id}">
                                                <xsl:value-of select="$currLabel"/>
                                            </label>
                                        </li>
                                    </xsl:for-each>
                                    
                                </ul>
                            </fieldset>
                        </div>
                    </xsl:if>
                    
                    <!--Now handle all of the actual document filters-->
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
                                    <xsl:variable name="filterName" select="$jsonDoc//j:string[@key='filterName']"/>
                                    <xsl:variable name="filterId" select="$jsonDoc//j:string[@key='filterId']"/>
                                    
                                    <!--And now create the fieldset and legend-->
                                    <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                        <legend><xsl:value-of select="$filterName"/></legend>
                                        
                                        <!--And create a ul from each of the embedded maps-->
                                        <ul class="ssDescCheckboxList">
                                            <!-- Before sorting checkbox items, we need to know
                                              whether they're numeric or not. -->
                                            <xsl:variable name="notNumeric" select="some $n in (for $s in $jsonDoc//j:map[@key]/j:string[@key='sortKey'] return $s castable as xs:decimal) satisfies $n = false()"/>
                                            <xsl:variable name="sortedMaps" as="element(j:map)+">
                                                <xsl:choose>
                                                    <xsl:when test="$notNumeric">
                                                        <xsl:for-each select="$jsonDoc//j:map[@key]">
                                                          <!-- Note: the article-stripping here is crude and limited to a couple of languages. For anything important, users should provide a sort key. -->
                                                            <xsl:sort select="replace(j:string[@key='sortKey'], '^((the)|(a)|(an)|(l[ea]s?)|(de[nrs]?)|([ie]l)|(un[oe]?))\s+', '', 'i')" lang="{$pageLang}"/>
                                                            <xsl:sequence select="."/>
                                                        </xsl:for-each>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:for-each select="$jsonDoc//j:map[@key]">
                                                            <xsl:sort select="j:string[@key='sortKey']" data-type="number"/>
                                                            <xsl:sequence select="."/>
                                                        </xsl:for-each>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            
                                            <xsl:for-each select="$sortedMaps">
                                                <!--<xsl:sort select="if ($notNumeric)  then replace(j:string[@key='name'], '^((the)|(a)|(an))\s+', '', 'i') else xs:decimal(j:string[@key='name'])"/>-->
                                                <!--And create the input item: the input item contains:
                                            * an @title that specifies the filter name (e.g. Genre)
                                            * an @value that specifies the filter value (e.g. Poem)
                                            * an @id to associate the label for A11Y-->
                                                <xsl:variable name="thisOptId" select="@key"/>
                                                <xsl:variable name="thisOptName" select="j:string[@key='name']"/>
                                                <li>
                                                    <!--REMOVE staticSearch.desc after deprecation period?-->
                                                    <input type="checkbox" title="{$filterName}" value="{$thisOptName}" id="{$thisOptId}"
                                                        class="staticSearch.desc staticSearch_desc"/>
                                                    <label for="{$thisOptId}"><xsl:value-of select="$thisOptName"/></label>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                    </fieldset>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                                <xsl:sort select="normalize-space(lower-case(legend))" lang="{$pageLang}"/>
                                <xsl:sequence select="."/>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                  
                  <!-- Now create feature filters. -->
                  <xsl:if test="not(empty($featFilters))">
                    <div class="ssFeatFilters">
                      <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                      <xsl:variable name="fieldsets" as="element(fieldset)*">
                        <xsl:for-each select="$featFilters">
                          
                          <!--Get the document-->
                          <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()" as="document-node()"/>
                          
                          <!--And its name and id -->
                          <xsl:variable name="filterName" select="$jsonDoc//j:string[@key='filterName']"/>
                          <xsl:variable name="filterId" select="$jsonDoc//j:string[@key='filterId']"/>
                          
                          <!--And now create the fieldset and legend-->
                          <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                            <legend><xsl:value-of select="$filterName"/></legend>
                            
                            <!--And create a simple text box for the feature.-->
                            <input type="text" title="{$filterName}" placeholder="{hcmc:getCaption('ssStartTyping', $captionLang)}"
                              class="staticSearch.feat staticSearch_feat"/>
                            
                          </fieldset>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:for-each select="$fieldsets">
                        <xsl:sort select="normalize-space(lower-case(legend))" lang="{$pageLang}"/>
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
                                    <xsl:variable name="filterName" select="$jsonDoc//j:string[@key='filterName']"/>
                                    <xsl:variable name="filterId" select="$jsonDoc//j:string[@key='filterId']"/>
                                    
                                    <!--Get the minimum from the date regex-->
                                    <xsl:variable name="minDate" as="xs:date" 
                                        select="min((for $d in $jsonDoc//j:string[1][matches(., $dateRegex)] return hcmc:normalizeDateString($d, true())))"/>
                                    
                                    <!--And the maximum date-->
                                    <xsl:variable name="maxDate" as="xs:date" 
                                        select="max((for $d in $jsonDoc//j:string[1][matches(., $dateRegex)] return hcmc:normalizeDateString($d, false())))"/>
                                    
                                    <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                        <!--And add the filter name as the legend-->
                                        <legend><xsl:value-of select="$filterName"/></legend>
                                        <span>
                                            <label for="{$filterId}_from">From: </label>
                                            <input type="text" maxlength="10" pattern="{$dateRegex}" title="{$filterName}" id="{$filterId}_from" class="staticSearch.date staticSearch_date" placeholder="{format-date($minDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/>
                                        </span>
                                        
                                        <span>
                                            <label for="{$filterId}_to">To: </label>
                                            <input type="text" maxlength="10" pattern="{$dateRegex}" title="{$filterName}" id="{$filterId}_to" class="staticSearch.date staticSearch_date" placeholder="{format-date($maxDate, '[Y0001]-[M01]-[D01]')}" onchange="this.reportValidity()"/>
                                        </span>
                                    </fieldset>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                              <xsl:sort select="normalize-space(lower-case(legend))" lang="{$pageLang}"/>
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
                                    <xsl:variable name="filterName" select="$jsonDoc//j:string[@key='filterName']"/>
                                    <xsl:variable name="filterId" select="$jsonDoc//j:string[@key='filterId']"/>
                                    <xsl:variable name="vals" select="$jsonDoc//j:string[not(@key)][. castable as xs:decimal]/xs:decimal(.)"/>
                                    <xsl:variable name="minVal" select="min($vals)"/>
                                    <xsl:variable name="maxVal" select="max($vals)"/>
                                    
                                    
                                    <fieldset class="ssFieldset" title="{$filterName}" id="{$filterId}">
                                        <!--And add the filter name as the legend-->
                                        <legend><xsl:value-of select="$filterName"/></legend>
                                        <span>
                                            <label for="{$filterId}_from">From: </label>
                                            <input type="number" min="{$minVal}" max="{$maxVal}" placeholder="{$minVal}" step="any"
                                                title="{$filterName}" id="{$filterId}_from" 
                                                class="staticSearch.num staticSearch_num"/>
                                        </span>
                                        
                                        <span>
                                            <label for="{$filterId}_to">To: </label>
                                            <input type="number" min="{$minVal}" max="{$maxVal}" placeholder="{$maxVal}" step="any"
                                                title="{$filterName}" id="{$filterId}_to" 
                                                class="staticSearch.num staticSearch_num"/>
                                        </span>
                                    </fieldset>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each select="$fieldsets">
                              <xsl:sort select="normalize-space(lower-case(legend))" lang="{$pageLang}"/>
                                <xsl:sequence select="."/>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                    
                    <!--And now handle booleans-->
                    <xsl:if test="not(empty($boolFilters))">
                        <div class="ssBoolFilters">
                            <!-- We create a single fieldset for all these filters, since they're individual. -->
                            <fieldset class="ssFieldset">
                                <!--Add a legend here to make this pass accessibility validation-->
                                <legend class="sr-only">Boolean filters</legend>
                                <!-- We stash these in a variable so we can output them 
                                      sorted alphabetically based on their names, which we
                                      don't know until they're created. -->
                                <xsl:variable name="spans" as="element(span)*">
                                    <xsl:for-each select="$boolFilters">
                                        <xsl:variable name="jsonDoc" select="unparsed-text(.) => json-to-xml()" as="document-node()"/>
                                        <xsl:variable name="filterName" select="$jsonDoc//j:string[@key='filterName']"/>
                                        <xsl:variable name="filterId" select="$jsonDoc//j:string[@key='filterId']"/>
                                        <span>
                                            <label for="{$filterId}"><xsl:value-of select="$filterName"/>: </label>
                                            <select id="{$filterId}" title="{$filterName}" class="staticSearch.bool staticSearch_bool">
                                                <option value="">?</option>
                                                <!-- Check mark = true -->
                                                <option value="true">&#x2714;</option>
                                                <!-- Cross = false -->
                                                <option value="false">&#x2718;</option>
                                            </select>
                                        </span>
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:for-each select="$spans">
                                  <xsl:sort select="normalize-space(lower-case(label))" lang="{$pageLang}"/>
                                    <xsl:sequence select="."/>
                                </xsl:for-each>
                            </fieldset>
                        </div>
                    </xsl:if>
                    <span class="postFilterSearchBtn">
                        <button id="ssDoSearch2">
                            <xsl:sequence select="hcmc:getCaption('ssDoSearch', $captionLang)"/>
                        </button>
                    </span>
               
                </xsl:if>

            </form>
            
            <!-- Popup message to show that search is being done. -->
            <div id="ssSearching">
                <xsl:sequence select="hcmc:getCaption('ssSearching', $captionLang)"/>
            </div>
          
          
          <!-- Splash screen / loading message, only added if there are typeahead feature filters. -->
          
          <xsl:if test="not(empty($filterJSONURIs[matches(.,'ssFeat\d+.*\.json')]))">
            <div id="ssSplashMessage">
              <xsl:sequence select="hcmc:getCaption('ssLoading', $captionLang)"/>
            </div>
          </xsl:if>
          

            <!--And now create the results div in the document-->
            <div id="ssResults">
                <!--...results here...-->
            </div>
            
            <!-- Next, we add our logo and powered-by message. -->
            <div id="ssPoweredBy">
                
                <p>
                    <xsl:sequence select="hcmc:getCaption('ssPoweredBy', $captionLang)"/>
                </p> <a href="https://github.com/projectEndings/staticSearch" aria-label="{hcmc:getCaption('ssPoweredBy', $captionLang)} staticSearch"><xsl:apply-templates select="doc($svgLogoFile)" mode="svgLogo"/></a>
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
        <!--<xsl:message>Processing date <xsl:value-of select="$dateString"/></xsl:message>-->
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
