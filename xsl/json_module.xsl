<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
            <xd:p><xd:b>Created on:</xd:b> February 29, 2020</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
            <xd:p>This transformation takes the collection of tokenized and stemmed documents (tokenized
            via the process described in <xd:a href="tokenize.xsl">tokenize.xsl</xd:a>) and creates
            a JSON file for each stemmed token. It also creates a separate JSON file for the project's
            stopwords list, for all the document titles in the collection, and for each of the filter facets.
            Finally, it creates a single JSON file listing all the tokens, which may be used for glob searches.</xd:p>
        </xd:desc>
    </xd:doc>

        

    <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
    
    <xsl:template name="createFilters">
        <xsl:variable name="docId" select="@id"/>
        <xsl:variable name="relativeUri" select="@data-staticSearch-relativeUri"/>
        <xsl:for-each-group 
            select="descendant::meta[not(@data-staticSearch-exclude)][matches(@class,'(^|\s)(staticSearch\.(bool|num|date|desc))(\s|$)')]" 
            group-by="tokenize(@class,'\s+')[matches(.,'^staticSearch\.')][1] => substring-after('.')">
            <xsl:variable name="folder" select="current-grouping-key()"/>

                <xsl:for-each-group select="current-group()" group-by="@name">
                    <xsl:variable name="filterName" select="encode-for-uri(encode-for-uri(current-grouping-key()))"/>
                    <xsl:variable name="filterOutDir" select="concat($tempDir,'/new/filters/',$folder,'/', $filterName)"/>
                    <xsl:if test="not(unparsed-text-available($filterOutDir|| '/NAME'))">
                        <xsl:result-document href="{$filterOutDir}/NAME" method="text">
                            <xsl:value-of select="@name"/>
                        </xsl:result-document>
                    </xsl:if>
                    <xsl:result-document method="text" href="{$filterOutDir}/{$docId}.json">
                        <xsl:variable name="tempDoc">
                            <map xmlns="http://www.w3.org/2005/xpath-functions">
                                <!--                        Document id -->
                                <string key="docId">
                                    <xsl:value-of select="$docId"/>
                                </string>
                                <string key="docUri">
                                    <xsl:value-of select="$relativeUri"/>
                                </string>
                                <array key="values">
                                    <xsl:for-each select="current-group()">
                                        <xsl:choose>
                                            <xsl:when test="$folder = 'bool'">
                                                <string>
                                                    <xsl:value-of select="hcmc:normalize-boolean(@content)"/>
                                                </string>
                                            </xsl:when>
                                            <xsl:when test="$folder = ('num','date','desc')">
                                                <string>
                                                    <xsl:value-of select="@content"/>
                                                </string>
                                            </xsl:when>
                                            <xsl:otherwise/>
                                        </xsl:choose>
                                    </xsl:for-each>                                    
                                </array>
                            </map>
                        </xsl:variable>
                        <xsl:value-of select="xml-to-json($tempDoc)"/>
                    </xsl:result-document>
                </xsl:for-each-group>
            
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template name="createTitles">
        <xsl:result-document
            href="{$tempDir}/new/titles/{encode-for-uri(encode-for-uri(replace(@data-staticSearch-relativeUri,'\.(x?html?)','$1')))}.json"
            method="text">
            <xsl:variable name="map">
                <map:map>
                    <map:array key="{@data-staticSearch-relativeUri}">
                        <map:string><xsl:value-of select="hcmc:getDocTitle(.)"/></map:string>
                        <!-- Add a thumbnail graphic if one is specified. This generates
                            nothing if there isn't. -->
                        <xsl:sequence select="hcmc:getDocThumbnail(.)"/>
                    </map:array>
                </map:map>
              
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': $indentJSON})"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="createTokens">
        <xsl:variable name="docId" select="@id"/>
        <xsl:variable name="relativeUri" select="@data-staticSearch-relativeUri"/>
        <xsl:for-each-group select="descendant::span[@data-staticSearch-stem]" group-by="tokenize(@data-staticSearch-stem,'\s+')">
            <xsl:variable name="spans" select="current-group()"/>
            <xsl:variable name="upperOrLower" select="if (matches(current-grouping-key(),'^[A-Z]')) then 'upper' else 'lower'"/>
            <xsl:variable name="firstChar" select="substring(current-grouping-key(),1,1)"/>
            <xsl:variable name="folder" select="if (matches($firstChar,'[a-zA-Z]')) then lower-case($firstChar) else '0'"/>
            <xsl:result-document method="text" href="{$tempDir}/new/{$upperOrLower}/{$folder}/{current-grouping-key()}/{$docId}.json">
                <xsl:variable name="tempDoc">
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <!--                        Document id -->
                        <string key="docId">
                            <xsl:value-of select="$docId"/>
                        </string>
                        
                        <!--                        Document title -->
                        <!--<string key="docTitle">
                            <xsl:value-of select="$docTitle"/>
                        </string>-->
                        
                        <!--                        Document URI (relative) -->
                        <string key="docUri">
                            <xsl:value-of select="$relativeUri"/>
                        </string>
                        
                        <!--                       Document score -->
                        <number key="score">
                            <xsl:value-of select="sum(for $s in current-group() return hcmc:returnWeight($s))"/>
                        </number>
                        
                        <!--                        Now add the contexts array, if specified to do so -->
                        <xsl:if test="$phrasalSearch or $createContexts">
                            <array key="contexts">
                                
                                <!--                                Return only the number of contexts we want;
                                    if a limit has been specified, only return
                                    up to the limit; otherwise, return them all. -->
                                <xsl:variable name="contexts" as="element(span)+"
                                    select="
                                    if ($phrasalSearch)
                                    then $spans
                                    else subsequence($spans, 1, $maxKwicsToHarvest)"
                                />
                                
                                <!--                                Count the contexts -->
                                <xsl:variable name="contextsCount" select="count($contexts)" as="xs:integer"/>
                                
                                <!--                                Now iterate through the contexts, returning a simple map that gives its
                                    form, context, and weight.-->
                                <xsl:for-each select="$contexts">
                                    
                                    <!--                                    Sort by weight, since we want the highest weighted first -->
                                    <xsl:sort select="hcmc:returnWeight(.)" order="descending"/>
                                    <!--And then sort by its position secondarily-->
                                    <xsl:sort select="xs:integer(@data-staticSearch-pos)" order="ascending"/>
                                    <map>
                                        
                                        <!--                                        Get the form (which is just the text value of the span and any descendant spans) -->
                                        <string key="form"><xsl:value-of select="string-join(descendant::text(),'')"/></string>
                                        
                                        <!--                                        Get the context using the hcmc:returnContext function -->
                                        <string key="context"><xsl:value-of select="hcmc:returnContext(.)"/></string>
                                        
                                        <!--                                        Get the weight, using hcmc:returnWeight function -->
                                        <number key="weight"><xsl:value-of select="hcmc:returnWeight(.)"/></number>
                                        
                                        <number key="pos"><xsl:value-of select="@data-staticSearch-pos"/></number>
                                    </map>
                                </xsl:for-each>
                            </array>
                        </xsl:if>
                    </map>
                </xsl:variable>
                <xsl:value-of select="xml-to-json($tempDoc)"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:normalize-boolean">hcmc:normalize-boolean</xd:ref>
            takes any of a variety of different boolean representations and converts them to
            string "true" or string "false".
        </xd:desc>
        <xd:param name="string">The input string.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:normalize-boolean" as="xs:string">
        <xsl:param name="string"/>
        <xsl:value-of select="if (matches(normalize-space($string),'true|1','i')) then 'true' else 'false'"/>
    </xsl:function>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:returnContext" type="function">hcmc:returnContext</xd:ref> returns the context string for a span;
        it does so by gathering up the text before the span and the text after the span, and then trims the length of the overall string
        to whatever the $kwicLimit ought to be.</xd:desc>
        <xd:param name="span">The span from which to return the context.</xd:param>
        <xd:return>A string with the term included in $span tagged as a mark element.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:returnContext" as="xs:string">
        <xsl:param name="span" as="element(span)"/>

<!--        The string term: String joining is overly cautious here.-->
        <xsl:variable name="thisTerm"
            select="string-join($span/descendant::text(),'')"
            as="xs:string"/>

<!--        The first ancestor that has been signaled as an ancestor-->
        <xsl:variable name="contextAncestor"
            select="$span/ancestor::*[@data-staticSearch-context='true'][1]"
            as="element()?"/>

<!--        If there's no context ancestor, then something's wrong-->
        <xsl:if test="empty($contextAncestor)">
            <xsl:message terminate="yes">THIS SPAN CAUSED A PROBLEM! <xsl:copy-of select="$span"/> / <xsl:value-of select="$span/ancestor::html/@id"/></xsl:message>
        </xsl:if>

<!--        Note that the below approaches to pre and fol nodes cannot be done using
            the simpler $span/preceding::text()[ancestor::*[@data-staticSearch-context='true'][1] is $contextAncestor]
            as it causes some error in Saxon (9.8.) TinyTreeImpl.-->

<!--        These are all of the descendant text nodes of the ancestor node, which:
            1) Precede this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->

        <xsl:variable name="preNodes"
            select="$contextAncestor/descendant::text()[. &lt;&lt; $span and not(ancestor::*[. is $span]) and ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>


<!--        These are all of the descendant text nodes of the ancestor node, which:
            1) Follow this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->
        <xsl:variable name="folNodes"
            select="$contextAncestor/descendant::text()[. &gt;&gt; $span and not(ancestor::*[. is $span])][ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>

<!--        The preceding text joined together-->
        <xsl:variable name="startString"
            select="string-join($preNodes,'')" as="xs:string?"/>

<!--        The following string joined together-->
        <xsl:variable name="endString"
            select="string-join($folNodes,'')" as="xs:string?"/>

<!--        The start string split on whitespace to be counted and
            reconstituted below-->
        <xsl:variable name="startTokens" select="tokenize($startString, '\s+')"/>

<!--        Count of how many tokens there are in the start sequence-->
        <xsl:variable name="startTokensCount" select="count($startTokens)" as="xs:integer"/>

        <!--The trailing string split on whitespace to be counted and
            reconstituted below-->
        <xsl:variable name="endTokens" select="tokenize($endString,'\s+')"/>


        <!--Count of how many tokens there are in the end sequence-->
        <xsl:variable name="endTokensCount" select="count($endTokens)" as="xs:integer"/>

        <!--Variables for detecting when we may need to add a space before the <mark>-->
        <xsl:variable name="preSpace" select=" if (matches($startString,'\s+$'))  then ' ' else ()" as="xs:string?"/>

        <xsl:variable name="endSpace" select="if (matches($endString,'^\s+')) then ' ' else ()"/>
        <!--The starting snippet: if there are fewer than $totalKwicLength/2 words, then just leave the string
            otherwise, trim to the $totalKwicLength/2 limit-->
        <xsl:variable name="startSnippet" select="

            (:If the number of start tokens is less than half the kwicLimit:)
            if ($startTokensCount lt $kwicLengthHalf)

            (: Then just return the start string :)
            then normalize-space($startString)

            (:Otherwise, concatenate the sequence:)
            else
            $kwicTruncateString || hcmc:joinSubseq($startTokens, $startTokensCount - $kwicLengthHalf, $startTokensCount)"
            as="xs:string?"/>



<!--        The ending snippet: if there are fewer than $kwicLengthHalf words, then just leave the string,
            otherwise, trim to the $kwicLengthHalf limit-->
        <xsl:variable name="endSnippet" select="

            (: if the number of words is less than the kwic length:)
            if ($endTokensCount lt $kwicLengthHalf)

            (: Then just return the end string:)
            then normalize-space($endString)

            (: Otherwise, get as many words as we can and concatenate an ellipses:)
            else hcmc:joinSubseq($endTokens, 1, $kwicLengthHalf) || $kwicTruncateString"
            as="xs:string"/>

<!--        Now, concatenate the start snippet, the term, and the end snippet
            and then normalize the spaces (to eliminate \n etc)-->

<!--        Note that we output the serialized version of the <mark> element for simplicities sake;
            it will be escaped in the JSON output anyway and the Javascript is able to handle the
            escaped version of the mark element.-->
        <xsl:value-of
            select="
            $startSnippet || $preSpace || '&lt;mark&gt;' || $thisTerm || '&lt;/mark&gt;' || $endSpace || $endSnippet
            => replace('\s+\n+\t+',' ')
            => normalize-space()"/>
    </xsl:function>

    <xd:doc>
        <xd:desc><xd:ref name="hcmc:returnWeight" type="function">hcmc:returnWeight</xd:ref> returns the
        weight of a span based off of the first ancestor's weight. Note that weighting is not accumulative;
        if, for instance, a structure looking something like (where W# = Weight):

        W2 > W3 > W1 > thisSpan

        The weight of the span would be 1, and not 6.
        </xd:desc>
        <xd:param name="span">The span element for which to retrieve the weight.</xd:param>
        <xd:return>The value of the span's weight derived from the ancestor or, if no ancestor, then 1.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:returnWeight" as="xs:integer">
        <xsl:param name="span"/>
        <xsl:variable name="ancestor" select="$span/ancestor::*[@data-staticSearch-weight][1]" as="element()?"/>
        <xsl:sequence select="
                if (not(empty($ancestor)))
                then $ancestor/@data-staticSearch-weight/xs:integer(.)
                else 1"
        />
    </xsl:function>


    <xd:doc>
        <xd:desc><xd:ref name="hcmc:joinSubseq" type="function">hcmc:joinSubseq</xd:ref> is a simple utility function
        for joining sequences of strings with spaces.</xd:desc>
        <xd:param name="seq">The sequence from which to derive the subset.
            Example: ("A", "Bob ", "fourteen", "Fred Bloggs")</xd:param>
        <xd:param name="start">An integer that denotes the start of the subsequence.
            Example: 2</xd:param>
        <xd:param name="end">An integer that denotes the end of the subsequence.
            Example: 4</xd:param>
        <xd:return>A string joined version of the sequence from sequence[start] to sequence [end].
            Example:  "Bob fourteen Fred Bloggs"</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:joinSubseq" as="xs:string">
        <xsl:param name="seq" as="item()+"/>
        <xsl:param name="start" as="xs:integer"/>
        <xsl:param name="end" as="xs:integer"/>
        <xsl:value-of select="normalize-space(string-join(subsequence($seq, $start, $end),' '))"/>
    </xsl:function>
    
    

    <xd:doc>
        <xd:desc>
            <xd:p><xd:ref name="hcmc:getDocTitle" type="function">hcmc:getDocTitle</xd:ref> is a simple function to retrieve the document title, which we may have to construct if there's nothing usable.</xd:p>
        </xd:desc>
        <xd:param name="doc">The input document, which must be an HTML element.</xd:param>
        <xd:result>A string title, derived either from the document's actual title (preferable) or the document's @id if all else fails.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocTitle" as="xs:string">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:variable name="defaultTitle" select="normalize-space(string-join($doc//head/title[1]/descendant::text(),''))" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="$doc/head/meta[@name='docTitle'][@class='staticSearch.docTitle']">
                <xsl:value-of select="normalize-space($doc/head/meta[@name='docTitle'][@class='staticSearch.docTitle'][1]/@content)"/>
            </xsl:when>
            <xsl:when test="string-length($defaultTitle) gt 0">
                <xsl:value-of select="$defaultTitle"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$doc/@id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="createStopwordsJson">createStopwordsJson</xd:ref>
            builds a JSON file containing the list of stopwords (either the default list or the 
            one provided by the project and referenced in its config file).</xd:desc>
    </xd:doc>
    <xsl:template name="createStopwordsJson">
        <xsl:message>Creating stopwords array...</xsl:message>
        <xsl:result-document href="{$outDir}/ssStopwords{$versionString}.json" method="text">
            <xsl:variable name="map">
                <xsl:apply-templates select="$stopwordsFileXml" mode="dictToArray"/>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': $indentJSON})"/>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc><xd:ref name="createTitleJson">createTitleJson</xd:ref>
            builds a JSON file containing a list of all the titles of documents in the 
            collection, indexed by their relative URI (which serves as their identifier),
            to be used when displaying results in the search page.</xd:desc>
    </xd:doc>

    
    
    <!--    Create a config file for the JSON-->
    <xd:doc>
        <xd:desc><xd:ref name="createConfigJson">createConfigJson</xd:ref> 
            creates a JSON representation of the project's configuration file.
            This is not currently used for any specific purpose, but it may be 
            helpful for the JS search engine to know what configuration was 
            used to create the indexes at some point.</xd:desc>
    </xd:doc>
    <xsl:template name="createConfigJson">
        <xsl:message>Creating Configuration JSON file....</xsl:message>
        <xsl:result-document href="{$outDir}/config{$versionString}.json" method="text">
            <xsl:variable name="map">
                <xsl:apply-templates select="doc($configFile)" mode="configToArray"/>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': $indentJSON})"/>
        </xsl:result-document>
    </xsl:template>
    
    
    <!--    Templates for converting the HCMC words files
        to a simple array for use in the Javascript;
        these are in templates in case we need to do
        any more creation of a words file into a JSON-->
    
    <xd:doc>
        <xd:desc>Template to convert an XML structure consisting
            of word elements inside a words element to a JSON/XML structure.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:words" mode="dictToArray">
        <map:map>
            <map:array key="words">
                <xsl:apply-templates mode="#current"/>
            </map:array>
        </map:map>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to convert a single word element inside 
            a words element to a JSON/XML string.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:word" mode="dictToArray">
        <map:string><xsl:value-of select="."/></map:string>
    </xsl:template>
    
    
    <!--    Templates for converting the HCMC config file
        into a simple JSON for use in the Javascript.-->
    
    <xd:doc>
        <xd:desc>Template to convert an hcmc:config element to a JSON map.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:config" mode="configToArray">
        <map:map key="config">
            <xsl:apply-templates mode="#current"/>
        </map:map>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to convert an hcmc:params element to a JSON array.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:params" mode="configToArray">
        <map:array key="params">
            <map:map>
                <xsl:apply-templates mode="#current"/>
            </map:map>
        </map:array>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to convert any child of an hcmc:params element to a JSON value.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:params/hcmc:*" mode="configToArray">
        <xsl:element namespace="http://www.w3.org/2005/xpath-functions" name="{if (text() castable as xs:integer) then 'number' else 'string'}">
            <xsl:attribute name="key" select="local-name()"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p><xd:ref name="hcmc:getDocThumbnail" type="function">hcmc:getDocThumbnail</xd:ref> 
                generates a map:string element containing a pointer to the first of any configured graphics, 
                relative to the search page location. NOTE: this function assumes that the graphic path has
                been massaged as necessary during the tokenizing process, so that it is now relative to the 
                search page location, not to the containing document.</xd:p>
        </xd:desc>
        <xd:param name="doc">The input document, which must be an HTML element.</xd:param>
        <xd:result>A map:string element, if there is a configured graphic, or the empty sequence.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocThumbnail" as="element(map:string)?">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:if test="$doc/head/meta[@name='docImage'][@class='staticSearch.docImage']">
            <map:string><xsl:value-of select="$doc/head/meta[@name='docImage'][@class='staticSearch.docImage'][1]/@content"/></map:string>
        </xsl:if>
    </xsl:function>
    

</xsl:stylesheet>
