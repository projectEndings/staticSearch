<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:j="http://www.w3.org/2005/xpath-functions"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> July 4, 2019</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation, which is a utility transformation, creates various reports
                  from the search creation.</xd:p>
        </xd:desc>
        <xd:param name="hasFilters">Parameter, passed from the ant build, that specifies
        whether filters have been created for the staticSearch.</xd:param>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            *
       *                         Includes                           *
       *                                                            *
       **************************************************************-->  
    <xd:doc>
        <xd:desc>Include the generated config file.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
 
    <xd:doc>
        <xd:desc>Include the functions</xd:desc>
    </xd:doc>
    <xsl:include href="functions.xsl"/>
    
    
    <!--*************************************************************
       *                                                            *
       *                         Parameters                         *
       *                                                            *
       **************************************************************-->  
    
    <xd:doc>
        <xd:desc><xd:ref name="hasFilters">$hasFilters</xd:ref> is used to specify whether
            the site build process has discovered any filter metadata in the collection. If so, then
            we need to create appropriate form controls.</xd:desc>
    </xd:doc>
    <xsl:param name="hasFilters" as="xs:string" select="'false'"/>
  
    <xd:doc>
      <xd:desc><xd:ref name="stemFileCount">$stemFileCount</xd:ref> is a simple 
      count of all the JSON stem files created earlier in the process, provided
      by the calling ant target. This is less resource-intensive than counting
      them ourselves based on the tokenized files.</xd:desc>
    </xd:doc>
    <xsl:param name="stemFileCount" as="xs:string" select="''"/>
  
    <xd:doc>
      <xd:desc><xd:ref name="verboseReport">$verboseReport</xd:ref> is a boolean 
      which controls whether the report contains exhaustive details on 
      word-counts and so on. For large collections a verboseReport report
      can cause an out-of-memory error.</xd:desc>
    </xd:doc>
    <xsl:param name="verboseReport" as="xs:string" select="'false'"/>


    <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->  
    
    <xd:doc>
        <xd:desc>Output as XHTML with HTML version 5.0; this is necessary for adding the
            proper DOCTYPE and to create a valid file.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" encoding="UTF-8" normalization-form="NFC"
        exclude-result-prefixes="#all" omit-xml-declaration="yes" html-version="5.0"/>


    <!--**************************************************************
       *                                                            *
       *                         Variables                          *
       *                                                            *
       **************************************************************-->  
    
    <xd:doc>
        <xd:desc><xd:ref name="spans" type="variable">$spans</xd:ref> are all of the
        search tokens in the document collection, which we need for many of the different
        reports.</xd:desc>
    </xd:doc>
    <xsl:variable name="spans" select="$tokenizedDocs//span[@ss-stem]"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="filterFiles" type="variable">$filterFiles</xd:ref> are all of the filters
        for staticSearch, which are only retrieved if the $hasFilters parameter has been set to true.</xd:desc>
    </xd:doc>
    <xsl:variable name="filterFiles" select="if ($hasFilters = 'true') then
        uri-collection(concat($outDir,'/filters/?select=*.json')) else ()"/>
    
    <!--*************************************************************
       *                                                            *
       *                         Parameters                         *
       *                                                            *
       **************************************************************-->  
    
    
    <xd:doc>
        <xd:desc>Root/driver template to create the reports</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Creating reports...this might take a while</xsl:message>
        <xsl:result-document href="{$ssBaseDir}/{$buildReportFilename}">
            <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
                <head>
                    <title>Static Search Report: <xsl:value-of select="$collectionDir"/></title>
                    <link rel="stylesheet" href="ssReports.css"/>
                </head>
                <body>
                    <div>
                        <h1>Static Search Report: <xsl:value-of select="$collectionDir"/></h1>
                        <h2>Using config file: <xsl:value-of select="$configFile"/></h2>
                        <xsl:call-template name="createStats"/>
                        <xsl:call-template name="createDiagnostics"/>
                        <xsl:call-template name="createFilters"/>
                        <xsl:call-template name="createExcludes"/>
                        <xsl:if test="$verboseReport = 'true'">
                          <xsl:call-template name="createNonDictionaryList"/>
                          <xsl:call-template name="createForeignWordList"/>
                        </xsl:if>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
      <xd:desc>Template creating diagnostic report on documents that may need 
      attention in the tokenized collection.</xd:desc>
    </xd:doc>
  <xsl:template name="createDiagnostics">
        <xsl:variable name="docsWithoutIds" select="$tokenizedDocs//html[not(@id)]"/>
        <xsl:variable name="docsWithoutLang" select="$tokenizedDocs//html[not(@lang)]"/>
        <xsl:variable name="badNumericFilters"
            select="$tokenizedDocs//meta[contains-token(@class,'staticSearch_num')][not(@content castable as xs:decimal)]"/>
        <xsl:variable name="docsWithoutFragmentIds" select="$tokenizedDocs//body[not(descendant::*[@id])]"/>
        
        <xsl:variable name="oneSidedBooleanFilters" as="element(li)*">
            <xsl:if test="$hasFilters = 'true'">
                <xsl:for-each select="$filterFiles[matches(.,'/ssBool\d+[^/]+\.json$')]">
                    <xsl:variable name="thisJDoc" select="json-to-xml(unparsed-text(.))"/>
    
                    <xsl:variable name="fid" select="$thisJDoc//j:string[@key='filterId']/string(.)" as="xs:string"/>
                    <xsl:variable name="fName" select="$thisJDoc//j:string[@key='filterName']/string(.)" as="xs:string"/>
                    <xsl:variable name="trueVal" select="$thisJDoc//j:string[@key='value'][string(.) = 'true']" as="element(j:string)*"/>
                    <xsl:variable name="falseVal" select="$thisJDoc//j:string[@key='value'][string(.) = 'false']" as="element(j:string)*"/>
                    <xsl:if test="not(exists($trueVal) and exists($falseVal))">
                        <li><xsl:value-of select="$fid"/> ("<xsl:value-of select="$fName"/>") contains only <xsl:value-of select="($trueVal,$falseVal)[1]/string(.)"/> values.</li>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        
        <section>
            <h2>Diagnostics</h2>
            <details>
                <summary>Documents without html/@id (<xsl:value-of select="count($docsWithoutIds)"/>)</summary>
                    <xsl:choose>
                        <xsl:when test="count($docsWithoutIds) gt 0">
                            <ul>
                                <xsl:for-each select="$docsWithoutIds">
                                    <li><xsl:value-of select="document-uri(root(.))"/></li>
                                </xsl:for-each>
                            </ul>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>None found!</p>
                        </xsl:otherwise>
                    </xsl:choose>
            </details>
            <details>
                <summary>Documents without html/@lang (<xsl:value-of select="count($docsWithoutLang)"/>)</summary>
                    <xsl:choose>
                        <xsl:when test="count($docsWithoutLang) gt 0">
                            <ul>
                                <xsl:for-each select="$docsWithoutLang">
                                    <li><xsl:value-of select="document-uri(root(.))"/></li>
                                </xsl:for-each>
                            </ul>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>None found!</p>
                        </xsl:otherwise>
                    </xsl:choose>
            </details>
            <details>
                <summary>Bad Numeric Filters (<xsl:value-of select="count($badNumericFilters)"/>)</summary>
                <xsl:choose>
                    <xsl:when test="count($badNumericFilters) gt 0">
                        <ul>
                            <xsl:for-each-group select="$badNumericFilters" group-by="document-uri(root(.))">
                                <li><xsl:value-of select="current-grouping-key()"/>
                                    <ul>
                                        <xsl:for-each select="current-group()">
                                            <li>Name: <xsl:value-of select="@name"/>; Value: <xsl:value-of select="@content"/></li>
                                        </xsl:for-each>
                                    </ul>
                                </li>
                                
                            </xsl:for-each-group>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>None found!</p>
                    </xsl:otherwise>
                </xsl:choose>
            </details>
            <details>
                <summary>One-sided Boolean Filters (<xsl:value-of select="count($oneSidedBooleanFilters)"/>)</summary>
                <xsl:choose>
                    <xsl:when test="count($oneSidedBooleanFilters) = 0">
                        <p>None found!</p>
                    </xsl:when>
                    <xsl:otherwise>
                        <ul>
                            <xsl:sequence select="$oneSidedBooleanFilters"/>
                        </ul>
                    </xsl:otherwise>
                </xsl:choose>
            </details>
            
            <xsl:if test="$linkToFragmentId">
                <details>
                    <summary>Documents without ids within the body (<xsl:value-of select="count($docsWithoutFragmentIds)"/>)</summary>
                   <xsl:choose>
                       <xsl:when test="count($docsWithoutFragmentIds) gt 0">
                           <ul>
                               <xsl:for-each select="$docsWithoutFragmentIds">
                                   <li><xsl:value-of select="document-uri(root(.))"/></li>
                               </xsl:for-each>
                           </ul>
                       </xsl:when>
                   </xsl:choose>
                </details>
            </xsl:if>
            
        </section>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to provide information about filters used and possibly broken filters.</xd:desc>
    </xd:doc>
    <xsl:template name="createFilters">
        <xsl:message>Generating report on search filters...</xsl:message>
        <section>
            <h2>Search Filters</h2>
            <xsl:choose>
                <xsl:when test="count($filterFiles) gt 0">
                    <details>
                        <summary>Total filters: <xsl:value-of select="count($filterFiles)"/></summary>
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Type</th>
                                    <th>Caption</th>
                                </tr>
                            </thead>
                            <tbody>
                               <xsl:for-each select="$filterFiles">
                                   <xsl:variable name="jDoc" select="json-to-xml(unparsed-text(.))"/>
                                   <xsl:variable name="filterId" select="$jDoc//j:string[@key='filterId']"/>
                                   <tr>
                                       <td><xsl:value-of select="$filterId"/></td>
                                       <td><xsl:value-of select="replace($filterId, '^ss([^\d]+)+\d+$', '$1')"/></td>
                                       <td><xsl:value-of select="$jDoc//j:string[@key='filterName']"/></td>
                                   </tr>
                               </xsl:for-each>
                            </tbody>
                        </table>
                    </details>
                </xsl:when>
                <xsl:otherwise>
                    <p>None found!</p>
                </xsl:otherwise>
            </xsl:choose>
        </section>
    </xsl:template>
    
 
    <xd:doc>
        <xd:desc>Template to create a table of statistics about the document collection.</xd:desc>
    </xd:doc>
    <xsl:template name="createStats">
        <xsl:message>Generating statistics...</xsl:message>
        <section>
            <h2>Statistics</h2>
            <table>
                <tbody>
                    <tr>
                        <th>Total HTML Documents Analyzed</th>
                        <td><xsl:value-of select="count($docUris)"/></td>
                    </tr>
                    <xsl:if test="$hasExclusions">
                        <tr>
                            <th>HTML Documents Excluded</th>
                            <td><xsl:value-of select="count($docUris) - count($tokenizedDocs)"/></td>
                        </tr>
                    </xsl:if>
                  
                    <xsl:if test="$verboseReport = 'true'">
                      <tr>
                        <th>Total Tokens Stemmed</th>
                        <td><xsl:value-of select="count($spans)"/></td>
                      </tr>
                    </xsl:if>

                    <tr>
                        <th>Total Unique Tokens (= Number of JSON files created)</th>
                      <td><xsl:value-of select="$stemFileCount"/></td>
                    </tr>
                </tbody>
            </table>
        </section>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to report on any documents/filters that have been excluded.</xd:desc>
    </xd:doc>
    <xsl:template name="createExcludes">
        <xsl:message>Generating exclusion stats...</xsl:message>
        <xsl:if test="doc($configFile)//*:exclude">
            <section>
                <h2>Exclusions</h2>
                <details>
                    <summary>Documents and filters excluded from this search...</summary>
                    <xsl:variable name="docExcludes" select="$tokenizedDocs//html[@ss-excld]" as="element(html)*"/>
                    <xsl:variable name="filterExcludes" select="$tokenizedDocs//meta[@ss-excld]" as="element(meta)*"/>
                    <table>
                        <tbody>
                            <tr>
                                <td>
                                    Documents excluded (<xsl:value-of select="count($docExcludes)"/>)
                                </td>
                                <td>
                                    <xsl:if test="not(empty($docExcludes))">
                                        <ul>
                                            <xsl:for-each select="$docExcludes">
                                                <li><xsl:value-of select="@id"/></li>
                                            </xsl:for-each>
                                        </ul>
                                    </xsl:if>
                                </td>
                                
                            </tr>
                            <tr>
                                <td>
                                    Filters excluded (<xsl:value-of select="count($filterExcludes)"/>)
                                </td>
                                <td>
                                    <xsl:if test="not(empty($filterExcludes))">
                                        <ul>
                                            <xsl:for-each-group select="$filterExcludes" group-by="@name">
                                                <li><xsl:value-of select="current-grouping-key()"/> (<xsl:value-of select="count(current-group())"/> instances)</li>
                                            </xsl:for-each-group>
                                            
                                        </ul>
                                    </xsl:if>
                                </td>
                            </tr>
                            
                        </tbody>
                    </table>
                </details>
            </section>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template for creating the "Not in Dictionary" list. While a term's exclusion
        from the dictionary doesn't change the search results, this report is helpful for catching
        typos in your document collection. </xd:desc>
    </xd:doc>
    <xsl:template name="createNonDictionaryList">
        <xsl:message>Creating Not-in-Dictionary list...</xsl:message>
        <section>
            <h2>Words Not In Dictionary</h2>
            
            <!--Only check stems that are words-->
            <xsl:variable name="stemsToCheck" select="$spans[not(matches(@ss-stem,'\d'))][not(hcmc:isForeign(.))]" as="element(span)*"/>
            
            <!--Retrieve the outermost spans so we don't include the nested spans from hyphenated terms 
                (we process those a bit differently) -->
            <xsl:variable name="outermostStems" select="outermost($stemsToCheck)" as="element(span)*"/>
            
            <xsl:variable name="wordsNotInDictionaryMap" as="map(xs:string, element(span)*)">
                <xsl:map>
                    <!--Group by whether or not it has descendant spans-->
                    <xsl:for-each-group select="$outermostStems" group-by="exists(child::span[@ss-stem])">
                        <xsl:choose>
                            <!--If this thing has child stems, it's a hyphenated construct
                            and so we check each child term individually-->
                            <xsl:when test="current-grouping-key()">
                                <!--Now iterate through all of the hyphenated spans-->
                                <xsl:for-each-group select="current-group()" group-by="string(.)">
                                    <!--Stash the word-->                                
                                    <xsl:variable name="term" select="current-grouping-key()"/>
                                    <!--Stash the current context-->
                                    <xsl:variable name="hyphenatedSpan" select="current-group()[1]" as="element(span)"/>
                                    
                                    <!--Not in dictionary spans-->
                                    <xsl:variable name="words" 
                                        select="for $s in $hyphenatedSpan/span[@ss-stem] return lower-case(string($s))" 
                                        as="xs:string*"/>
                                    
                                    <xsl:variable name="cleanedWords" 
                                        select="for $w in $words return hcmc:cleanWordForStemming($w)"
                                        as="xs:string*"/>
                                    
                                    <xsl:variable name="allTermsNotInDictionary" 
                                        select="every $cw in $cleanedWords satisfies not(hcmc:isInDictionary($cw))" as="xs:boolean"/>
                                    
                                    <xsl:if test="$allTermsNotInDictionary">
                                        <xsl:map-entry key="$term" select="current-group()"/>
                                    </xsl:if>
                                </xsl:for-each-group>
                            </xsl:when>
                            <xsl:otherwise>
                                <!--Group by string value (so basically just distinct values)-->
                                <xsl:for-each-group select="current-group()" group-by="hcmc:cleanWordForStemming(lower-case(string(.)))">
                                    <xsl:variable name="word" select="current-grouping-key()" as="xs:string"/>
                                    <xsl:if test="not(hcmc:isInDictionary($word))">
                                        <xsl:map-entry key="$word" select="current-group()"/>
                                    </xsl:if>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </xsl:map>
            </xsl:variable>
            
            
            <xsl:variable name="wordsNotInDictionaryCount" select="map:size($wordsNotInDictionaryMap)" as="xs:integer"/>
            
            <details>
                <summary>Total words not in dictionary: <xsl:value-of select="$wordsNotInDictionaryCount"/></summary>

                <xsl:choose>
                    <xsl:when test="$wordsNotInDictionaryCount = 0">
                        <p>None found!</p>
                    </xsl:when>
                    <xsl:otherwise>
                        <table>
                            <thead>
                                <tr>
                                    <th>Word</th>
                                    <th>Forms</th>
                                    <th>Instances</th>
                                </tr>
                            </thead>
                            <tbody>
                                <xsl:for-each select="map:keys($wordsNotInDictionaryMap)">
                                    <xsl:sort select="count($wordsNotInDictionaryMap(.))" order="descending"/>
                                    <tr>
                                        <td><xsl:value-of select="."/></td>
                                        <td>
                                            <ul>
                                                <xsl:for-each-group select="$wordsNotInDictionaryMap(.)" group-by="string(.)">
                                                    <xsl:sort select="count(current-group())" order="descending"/>
                                                    <li><xsl:value-of select="current-grouping-key()"/></li>
                                                </xsl:for-each-group>
                                            </ul>
                                        </td>
                                        <td><xsl:value-of select="count($wordsNotInDictionaryMap(.))"/></td>
                                    </tr>
                                </xsl:for-each>     
                            </tbody>
                        </table>
                 
                    </xsl:otherwise>
                </xsl:choose>
            </details>
        </section>
    </xsl:template>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:isInDictionary">hcmc:isInDictionary</xd:ref> checks
        whether or not a word is in the provided dictionary. This is basically just a wrapper
        around the key() function, but we take advantage of Saxon 10HE's memo-function capabilities
        and cache the results.</xd:desc>
        <xd:param name="word">The normalized and lower-cased word to check</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:isInDictionary" new-each-time="no" as="xs:boolean">
        <xsl:param name="word" as="xs:string"/>
        <xsl:sequence select="exists(key('w', $word, $dictionaryFileXml))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Template to create a report of all "foreign" words in the collection:
        by foreign, we mean words that are in a language different from the declared root lang.
        This has no bearing on the search results, but this is helpful for determining if there are
        blocks of text in languages that you weren't expecting or thought you had excluded.</xd:desc>
    </xd:doc>
    <xsl:template name="createForeignWordList">
        <xsl:message>Creating Foreign Word list...</xsl:message>
        <section>
            <h2>Foreign Words</h2>
            
            <!--Make a map of foreign words to their spans for easier calculation below-->
            <xsl:variable name="foreignWords" as="map(xs:string, element(span)*)">
                <xsl:map>
                    <xsl:for-each-group select="$spans[hcmc:isForeign(.)]" group-by="string(.)">
                        <xsl:map-entry key="current-grouping-key()" select="current-group()"/>
                    </xsl:for-each-group>
                </xsl:map>
            </xsl:variable>
            <details>
                <summary>Total foreign words: <xsl:value-of select="map:size($foreignWords)"/></summary>
                <xsl:choose>
                    <xsl:when test="map:size($foreignWords) gt 0">
                        <table>
                            <thead>
                                <tr>
                                    <th>Word</th>
                                    <th>Instances</th>
                                    <th>Declared Languages</th>
                                </tr>
                            </thead>
                            <tbody>
                                <!--Iterate through the map keys to get all of the words-->
                                <xsl:for-each select="map:keys($foreignWords)">
                                    <xsl:sort select="count($foreignWords(.))" order="descending"/>
                                    <xsl:variable name="spans" select="$foreignWords(.)" as="element(span)*"/>
                                    
                                    <!--Get all of the distinct languages for that word across documents (i.e.
                                        there could be words that are understood as foreign but have been declared with
                                        two different langs-->
                                    <xsl:variable name="langs" as="xs:string*">
                                        <xsl:for-each select="$spans">
                                            <xsl:variable name="declaredLang"
                                                select="ancestor-or-self::*[@lang or @xml:lang][1]/(@lang, @xml:lang)[1]" as="xs:string?"/>
                                            <xsl:sequence select="if (exists($declaredLang)) then $declaredLang else string('NULL')"/>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    
                                    <!--Now output the row-->
                                    <tr>
                                        <td><xsl:value-of select="."/></td>
                                        <td><xsl:value-of select="count($spans)"/></td>
                                        <td>
                                            <xsl:value-of select="string-join(distinct-values($langs),', ')"/>
                                        </td>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>None found.</p>
                    </xsl:otherwise>
                </xsl:choose>
            </details>
        </section>           
         
    </xsl:template>
    
    
    
    
</xsl:stylesheet>