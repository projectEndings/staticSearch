<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
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
    </xd:doc>
    
    <xd:doc>
        <xd:desc>Include the generated config file.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
 
    <xd:doc>
        <xd:desc>Include the functions</xd:desc>
    </xd:doc>
    <xsl:include href="functions.xsl"/>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="hasFilters">$hasFilters</xd:ref> is used to specify whether
            the site build process has discovered any filter metadata in the collection. If so, then
            we need to create appropriate form controls.</xd:desc>
    </xd:doc>
    <xsl:param name="hasFilters" as="xs:string" select="'false'"/>
    
    <xd:doc>
        <xd:desc>Output as XHTML with HTML version 5.0; this is necessary for adding the
            proper DOCTYPE and to create a valid file.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" encoding="UTF-8" normalization-form="NFC"
        exclude-result-prefixes="#all" omit-xml-declaration="yes" html-version="5.0"/>
    <xsl:variable name="spans" select="$tokenizedDocs//span[@data-staticSearch-stem]"/>
    
    <xsl:template match="/">
        <xsl:message>Creating reports...this might take a while</xsl:message>
        <xsl:result-document href="{$ssBaseDir}/{$buildReportFilename}">
            <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
                <head>
                    <title>Static Search Report: <xsl:value-of select="$collectionDir"/></title>
                    <style>
                        <xsl:comment>
                            body{
                                font-family: sans-serif;
                                margin: 1em 10%;
                            }
                            section{
                                padding: 1em;
                                margin: 0.25rem 0;
                                border-radius: 0.5em;
                            }
                            section:nth-of-type(odd){
                                background-color: #ddddff;
                            }
                            section:nth-of-type(even){
                                background-color: #ddffdd;
                            }
                            h1{
                                text-align: center;
                                margin: 1em 5%;
                            }
                            h2{
                                margin: 0.25em;
                            }
                            summary{
                                cursor: pointer;
                            }
                            summary:hover{
                                color: #990000;
                            }
                            table{
                                border: solid 1pt gray;
                                border-collapse: collapse;
                            }
                            td{
                                border: solid 1pt gray;
                                padding: 0.25em;
                            }
                            li{
                                margin: 0.25em;
                            }
                        </xsl:comment>
                    </style>
                </head>
                <body>
                    <div>
                        <h1>Static Search Report: <xsl:value-of select="$collectionDir"/></h1>
                        <h2>Using config file: <xsl:value-of select="$configFile"/></h2>
                        <xsl:call-template name="createStats"/>
                        <xsl:call-template name="createDiagnostics"/>
                        <xsl:call-template name="createFilters"/>
                        <xsl:call-template name="createExcludes"/>
                        <xsl:call-template name="createWordTables"/>
                        <xsl:call-template name="createNonDictionaryList"/>

                        <xsl:call-template name="createForeignWordList"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="createDiagnostics">
        
        <xsl:variable name="docsWithoutIds" select="$tokenizedDocs//html[not(@id)]"/>
        <xsl:variable name="docsWithoutLang" select="$tokenizedDocs//html[not(@lang)]"/>
        <xsl:variable name="badNumericFilters" select="$tokenizedDocs//meta[contains-token(@class,'staticSearch.num')][not(@content castable as xs:decimal)]"/>
        <xsl:variable name="docsWithoutFragmentIds" select="$tokenizedDocs//body[not(descendant::*[@id])]"/>
        
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
 
    <xsl:template name="createFilters">
        <xsl:message>Generating report on search filters...</xsl:message>
        <section>
            <h2>Search Filters</h2>
            <xsl:variable name="filterFiles" select="if ($hasFilters = 'true') then
                uri-collection(concat($outDir,'/filters/?select=*.json')) else ()"/>
            <xsl:choose>
                <xsl:when test="count($filterFiles) gt 0">
                    <details>
                        <summary>Total filters: <xsl:value-of select="count($filterFiles)"/></summary>
                        <ul>
                            <xsl:for-each select="$filterFiles">
                                <xsl:variable name="jDoc" select="json-to-xml(unparsed-text(.))"/>
                                <li>id: <xsl:value-of select="$jDoc//map:string[@key='filterId']"/>; type: <xsl:value-of select="replace($jDoc//map:string[@key='filterId'], '^ss([^\d]+)+\d+$', '$1')"/>; caption: "<xsl:value-of select="$jDoc//map:string[@key='filterName']"/>"</li>
                            </xsl:for-each>
                        </ul>
                        
                    </details>
                </xsl:when>
                <xsl:otherwise>
                    <p>None found!</p>
                </xsl:otherwise>
            </xsl:choose>
        </section>
    </xsl:template>
    
 
    
    <xsl:template name="createStats">
        <xsl:message>Generating statistics...</xsl:message>
        <section>
            <h2>Statistics</h2>
            <table>
                <tbody>
                    <tr>
                        <td>Total HTML Documents Analyzed</td>
                        <td><xsl:value-of select="count($docUris)"/></td>
                    </tr>
                    <xsl:if test="$hasExclusions">
                        <tr>
                            <td>HTML Documents Excluded</td>
                            <td><xsl:value-of select="count($docUris) - count($tokenizedDocs)"/></td>
                        </tr>
                    </xsl:if>
 
                    <tr>
                        <td>Total Tokens Stemmed</td>
                        <td><xsl:value-of select="count($spans)"/></td>
                    </tr>
                    <tr>
                        <td>Total Unique Tokens (= Number of JSON files created)</td>
                        <td><xsl:value-of select="count(distinct-values($spans/tokenize(@data-staticSearch-stem,'\s+')))"/></td>
                    </tr>
                </tbody>
            </table>
        </section>
        
    </xsl:template>
    
    <xsl:template name="createExcludes">
        <xsl:message>Generating exclusion stats...</xsl:message>
        <xsl:if test="doc($configFile)//*:exclude">
            <section>
                <h2>Exclusions</h2>
                <details>
                    <summary>Documents and filters excluded from this search...</summary>
                    <xsl:variable name="docExcludes" select="$tokenizedDocs//html[@data-staticSearch-exclude]" as="element(html)*"/>
                    <xsl:variable name="filterExcludes" select="$tokenizedDocs//meta[@data-staticSearch-exclude]" as="element(meta)*"/>
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
    
    <xsl:template name="createWordTables">
        <xsl:message>Generating frequency tables...</xsl:message>
        <section>
            <h2>Word Frequency</h2>
            <details>
                <summary>All stems found in the document collection.</summary>
                <table>
                    <thead>
                        <tr>
                            <td>Stem</td>
                            <td>Total Instances</td>
                            <td>Total Variants</td>
                            <td>Variant List</td>
                            <td>Number of Documents</td>
                            <td>Average use per document</td>
                            <!--                        <td>Document List</td>-->
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each-group select="$spans" group-by="tokenize(@data-staticSearch-stem,'\s+')">
                            <xsl:sort select="count(current-group())" order="descending"/>
                            <xsl:variable name="tokenGroup" select="current-group()"/>
                            <xsl:variable name="thisToken" select="current-grouping-key()"/>
                            <xsl:variable name="instancesCount" select="count(current-group())"/>
                            <xsl:variable name="variants" as="xs:string+">
                                <xsl:for-each-group select="current-group()" group-by="text()">
                                    <xsl:sort select="string-length(.)" order="ascending"/>
                                    <xsl:value-of select="."/>
                                </xsl:for-each-group>
                            </xsl:variable>
                            
                            <xsl:variable name="docIds" as="xs:string+">
                                <xsl:for-each-group select="$tokenGroup" group-by="ancestor::html/@id">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </xsl:for-each-group>
                            </xsl:variable>
                            
                            <xsl:variable name="distinctDocIds" select="distinct-values($docIds)" as="xs:string+"/>
                            <xsl:variable name="distinctDocCount" select="count($distinctDocIds)"/>
                            
                            <tr>
                                
                                <!--STEM-->
                                <td><xsl:value-of select="current-grouping-key()"/></td>
                                
                                <!--TOTAL INSTANCES-->
                                <td><xsl:value-of select="$instancesCount"/></td>
                                
                                <!--TOTAL VARIANTS-->
                                <td><xsl:value-of select="count($variants)"/></td>
                                
                                <!--LIST OF VARIANTS-->
                                <td>
                                    <ul>
                                        <xsl:for-each select="$variants">
                                            <xsl:sort select="string-length(.)" order="ascending"/>
                                            <li><xsl:value-of select="."/></li>
                                        </xsl:for-each>
                                    </ul>
                                </td>
                                
                                <!--TOTAL DOCS-->
                                <td>
                                    <xsl:value-of select="$distinctDocCount"/>
                                </td>
                                
                                <td>
                                    <xsl:value-of select="format-number($instancesCount div $distinctDocCount,'#.##')"/>
                                </td>
                                
                                <!--LIST OF DOCS-->
                                <!-- <td>
                                <xsl:choose>
                                    <xsl:when test="count(distinct-values($docIds)) = count($docs)">
                                        All
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <ul>
                                            <xsl:for-each select="distinct-values($docIds)">
                                                <xsl:sort/>
                                                <li><xsl:value-of select="."/></li>
                                            </xsl:for-each>
                                        </ul>
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                            </td>-->
                                
                            </tr>
                            
                        </xsl:for-each-group>
                    </tbody>
                </table>
            </details>
            
        </section>
        
    </xsl:template>
    
    
    <xsl:template name="createNonDictionaryList">
        <xsl:message>Creating Not-in-Dictionary list...</xsl:message>
        <section>
            <h2>Words Not In Dictionary</h2>
            
            <xsl:variable name="wordsNotInDictionary" as="xs:string*">
                <xsl:for-each-group select="$spans" group-by="replace(lower-case(string(.)),'^[“”]|[“”]$','')">
                    <xsl:if test="not(matches(current-grouping-key(),'\d'))">
                        <xsl:if test="not(exists(key('w', current-grouping-key(), $dictionaryFileXml)))">
                            <xsl:sequence select="current-grouping-key()"/>
                        </xsl:if>
                    </xsl:if>                   
                </xsl:for-each-group>
            </xsl:variable>
            
            <xsl:variable name="wordsNotInDictionaryCount" select="count($wordsNotInDictionary)" as="xs:integer"/>
            
            <details>
                <summary>Total words not in dictionary: <xsl:value-of select="$wordsNotInDictionaryCount"/></summary>
                
                <xsl:if test="not(empty($wordsNotInDictionary))">
                    <ul>
                        <xsl:for-each select="$wordsNotInDictionary">
                            <xsl:sort select="lower-case(.)"/>
                            <li><xsl:value-of select="."/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
            </details>
            
        </section>
    </xsl:template>
    
    <xsl:template name="createForeignWordList">
        <xsl:message>Creating Foreign Word list...</xsl:message>
        <section>
            <h2>Foreign Words</h2>
            
            <xsl:variable name="foreignWords" as="xs:string*">
                <xsl:for-each-group select="$spans" group-by="hcmc:isForeign(.)">
                     <xsl:if test="current-grouping-key()">
                         <xsl:for-each-group select="current-group()" group-by="string(.)">
                             <xsl:sequence select="current-group()"/>
                         </xsl:for-each-group>
                     </xsl:if>
                </xsl:for-each-group>
            </xsl:variable>
            
            <details>
                <summary>Total foreign words: <xsl:value-of select="count($foreignWords)"/></summary>
                <xsl:if test="not(empty($foreignWords))">
                    <ul>
                        <xsl:for-each select="$foreignWords">
                            <xsl:sort/>
                            <li>
                                <xsl:value-of select="string(.)"/>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
            </details>
        </section>           
         
    </xsl:template>
    
    
    
    
</xsl:stylesheet>