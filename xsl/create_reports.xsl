<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
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
    
    <xsl:include href="config.xsl"/>
    
    <xsl:variable name="spans" select="$tokenizedDocs//span[@data-staticSearch-stem]"/>
    
    <xsl:template match="/">
        <xsl:message>Creating reports...this might take a bit</xsl:message>
        <xsl:result-document href="staticSearch_report.html">
            <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                    <title>Static Search Report: <xsl:value-of select="$collectionDir"/></title>
                </head>
                <body>
                    <div>
                        <h1>Static Search Report: <xsl:value-of select="$collectionDir"/></h1>
                        <xsl:call-template name="createStats"/>
                        <xsl:call-template name="createDiagnostics"/>
                        <xsl:call-template name="createWordTables"/>
                        <xsl:call-template name="createNonDictionaryList"/>
                        <xsl:call-template name="createForeignWordList"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="createDiagnostics">
        <xsl:variable name="docsWithoutIds" select="$docs//html[not(@id)]"/>
        <xsl:variable name="docsWithoutLang" select="$docs//html[not(@lang)]"/>
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
        </section>
    </xsl:template>
 
    
    
    <xsl:template name="createStats">
        <xsl:message>Generating statistics...</xsl:message>
        <section>
            <h2>Statistics</h2>
            <table>
                <tbody>
                    <tr>
                        <td>HTML Documents Analyzed</td>
                        <td><xsl:value-of select="count($docs)"/></td>
                    </tr>
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
                                
                                <!--TOTAL INSTANCes-->
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
                <xsl:for-each-group select="$spans[@data-staticSearch-notInDictionary]" group-by="@data-staticSearch-notInDictionary">
                    <xsl:value-of select="current-grouping-key()"/>
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
                <xsl:for-each-group select="$spans[@data-staticSearch-foreign]" group-by="tokenize(@data-staticSearch-stem,'\s+')">
                    <xsl:value-of select="current-grouping-key()"/>
                </xsl:for-each-group>
            </xsl:variable>
            <details>
                <summary>Total foreign words: <xsl:value-of select="count($foreignWords)"/></summary>
                <xsl:if test="not(empty($foreignWords))">
                    <ul>
                        <xsl:for-each select="$foreignWords">
                            <xsl:sort/>
                            <li>
                                <xsl:value-of select="."/>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
            </details>
        </section>           
         
    </xsl:template>
    
    
    
    
</xsl:stylesheet>