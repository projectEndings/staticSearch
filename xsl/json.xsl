<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all" xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:hcmc="http://hcmc.uvic.ca/ns" version="3.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions">
    
    
    <xsl:include href="config.xsl"/>
    
    
    <xsl:key name="docs" match="span[contains(@data-staticSearch-stem,' ')]" 
        use="tokenize(@data-staticSearch-stem,'\s+')"/>
    <xsl:key name="docs" match="span[not(contains(@data-staticSearch-stem,' '))]" use="@data-staticSearch-stem"/>
    
    
    
    <xsl:variable name="kwicLengthHalf" select="xs:integer(round(xs:integer($totalKwicLength) div 2))" as="xs:integer"/>
    
  
    
    <xsl:template match="/">
        <xsl:call-template name="createJson"/>
        <xsl:call-template name="createStopwordsJson"/>
    </xsl:template>
    
    <xsl:template name="createStopwordsJson">
        <xsl:message>Creating stopwords array...</xsl:message>
        <xsl:result-document href="{$outDir}/stopwords.json" method="text">
            <xsl:variable name="map">
                <xsl:apply-templates select="$stopwordsFileXml" mode="dictToArray"/>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
        </xsl:result-document>
    </xsl:template>
    
    <!--Templates for converting the HCMC words files
        to a simple array for use in the Javascript;
        these are in templates in case we need to do
        any more creation of a words file into a JSON-->
    
    <xsl:template match="hcmc:words" mode="dictToArray">
        <map:map>
            <map:array key="words">
                <xsl:apply-templates mode="#current"/>
            </map:array>
        </map:map>
    </xsl:template>
    
    <xsl:template match="hcmc:word" mode="dictToArray">
        <map:string><xsl:value-of select="."/></map:string>
    </xsl:template>
    
    <xsl:template name="createJson">
        <xsl:message>Found <xsl:value-of select="count($tokenizedDocs)"/> tokenized documents...</xsl:message>
        <xsl:variable name="stems" select="$tokenizedDocs//span[@data-staticSearch-stem]" as="element(span)*"/>
        <xsl:call-template name="createMap">
            <xsl:with-param name="stems" select="$stems"/>   
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="createMap">
        <xsl:param name="stems"/>
        <xsl:for-each-group select="$stems" group-by="tokenize(@data-staticSearch-stem,'\s+')">
            <xsl:sort select="current-grouping-key()" case-order="upper-first"/>
            <xsl:variable name="token" select="current-grouping-key()"/>
                 <xsl:message>Processing <xsl:value-of select="$token"/></xsl:message>
            <xsl:variable name="map" as="element()">
                <xsl:call-template name="makeMap">
                    <xsl:with-param name="term" select="$token"/>
                </xsl:call-template>
            </xsl:variable>
            <!--            <xsl:message>Creating <xsl:value-of select="$token"/>.json</xsl:message>-->
            <xsl:result-document href="{$outDir}/{if (matches($token,'^[A-Z]')) then 'upper' else 'lower'}/{$token}.json" method="text">
                <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    
    <xsl:template name="makeMap">
        <xsl:param name="term"/>
        <xsl:variable name="termRegex" select="concat('(^|\s)',$term,'(\s|$)')"/>
        <xsl:variable name="termGroup" select="current-group()"/>
        <map xmlns="http://www.w3.org/2005/xpath-functions">
            <string key="token">
                <xsl:value-of select="$term"/>
            </string>
            
            <!--Boolean value to evaluate whether or not this "string" is actually an integer-->
            <xsl:variable name="isInteger" select="$term castable as xs:integer" as="xs:boolean"/>

            
            <array key="instances">
                <!--If every HTML document processed has an @id at the root,
                    then use that as the grouping-key; otherwise,
                    use the document uri-->
                <xsl:for-each-group select="current-group()" 
                    group-by="document-uri(/)">
                  
                    
                    <!--Sort the documents so that the document with the most number of this hit comes first-->
                    <xsl:sort select="count(current-group())" order="descending"/>
                    <xsl:if test="$verbose">
                        <xsl:message><xsl:value-of select="$term"/>: Processing <xsl:value-of select="current-grouping-key()"/> (<xsl:value-of select="position()"/> / <xsl:value-of select="count(current-group())"/>)</xsl:message>
                    </xsl:if>
              
                    <!--The document that we want to process will always be the ancestor html of 
                        any item of the current-group()-->
                    <xsl:variable name="thisDoc" 
                        select="current-group()[1]/ancestor::html"
                        as="element(html)"/>
                    
                    <!--Now the document ID, which we've created (if necessary) in the 
                        tokenization step-->
                    <xsl:variable name="docId" select="$thisDoc/@id" as="xs:string"/>
                    
                    <!--Now we get the document title:
                    
                    If there is something usable in the title, then use that;
                    otherwise, just use the document id as the title
                    -->
                    <xsl:variable name="docTitle" 
                        select="
                        let $t := string-join($thisDoc//head/title[1]/descendant::text(),'') 
                        return 
                            if (normalize-space(string-join($t,'')) ne '') 
                            then $t 
                            else $docId"
                    />
                    
                    <!--And the relative URI from the document, which is to be used
                        for linking from the KWIC to the document. We've created this
                        already in the tokenization stage and stored it in a custom
                        data-attribute-->
                    <xsl:variable name="relativeUri" 
                        select="$thisDoc/@data-staticSearch-relativeUri"
                        as="xs:string"/>
                    
                    <!--Now get the spans, using the declared key-->
                    <xsl:variable name="spans" select="current-group()" as="element(span)+"/>
                    
                    
           
                    
                    <!--Now create the XPATH map, which will become a JSON-->
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <string key="docId">
                            <xsl:value-of select="$docId"/>
                        </string>
                        <string key="docTitle">
                            <xsl:value-of select="$docTitle"/>
                        </string>
                        <string key="docUri">
                            <xsl:value-of select="$relativeUri"/>
                        </string>

                        <number key="count">
                            <xsl:value-of select="count($spans)"/>
                        </number>
                        
                        <number key="weight">
                            <xsl:value-of select="sum(for $s in $spans return hcmc:returnWeight($s))"/>
                        </number>
                        
                        
                        <xsl:if test="$phrasalSearch or $createContexts">
                            <array key="contexts">
                                <xsl:variable name="contexts" as="element(span)+">
                                    <xsl:choose>
                                        <xsl:when test="$phrasalSearch">
                                            <xsl:sequence select="$spans"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="for $n in 1 to $maxContexts return $spans[$n]"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:variable name="contextsCount" select="count($contexts)"/>
                                <xsl:if test="$verbose">
                                    <xsl:message><xsl:value-of select="$term"/>: <xsl:value-of select="current-grouping-key()"/>: Processing <xsl:value-of select="$contextsCount"/> contexts.</xsl:message>
                                </xsl:if>

                                <xsl:for-each select="$contexts">
                                    <xsl:sort select="hcmc:returnWeight(.)" order="descending"/>
                                    <map>
                                        <string key="form"><xsl:value-of select="text()"/></string>
                                        <string key="context"><xsl:value-of select="hcmc:returnContext(.)"/></string>
                                        <number key="weight"><xsl:value-of select="hcmc:returnWeight(.)"/></number>
                                    </map>
                                </xsl:for-each>
                            </array>
                        </xsl:if>
                    </map>
                </xsl:for-each-group>
            </array>
        </map>
        
    </xsl:template>
    
    
    <xsl:function name="hcmc:returnContext">
        <xsl:param name="span" as="element(span)"/>
        
        <!--The string term-->
        <xsl:variable name="thisTerm"
            select="string-join($span/descendant::text(),'')" 
            as="xs:string"/>
        
      
        
        <!--The first ancestor that has been signaled as an ancestor-->
        <xsl:variable name="contextAncestor" 
            select="$span/ancestor::*[@data-staticSearch-context='true'][1]" 
            as="element()?"/>
        
        <xsl:if test="empty($contextAncestor)">
            <xsl:message terminate="yes">THIS SPAN CAUSED A PROBLEM! <xsl:copy-of select="$span"/> / <xsl:value-of select="$span/ancestor::html/@id"/></xsl:message>
            
        </xsl:if>
        
        <!--These are all of the descendant text nodes of the ancestor node, which:
            1) Precede this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->
        
        <xsl:variable name="preNodes" 
            select="$contextAncestor/descendant::text()[. &lt;&lt; $span and not(parent::*[. is $span]) and ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>
        
        
        <!--These are all of the descendant text nodes of the ancestor node, which:
            1) Follow this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->
        <xsl:variable name="folNodes" 
            select="$contextAncestor/descendant::text()[. &gt;&gt; $span and not(parent::*[. is $span])][ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>

        <!--The preceding text joined together-->
        <xsl:variable name="startString" 
            select="string-join($preNodes,'')" as="xs:string?"/>
        
        <!--The following string joined together-->
        <xsl:variable name="endString" 
            select="string-join($folNodes,'')" as="xs:string?"/>
        
        <!--The start string split on whitespace to be counted and 
            reconstituted below-->
        <xsl:variable name="startTokens" select="tokenize($startString, '\s+')"/>
        
        <!--The trailing string split on whitespace to be counted and
            reconstituted below-->
        <xsl:variable name="endTokens" select="tokenize($endString,'\s+')"/>
        
        <!--The starting snippet: if there are fewer than $totalKwicLength/2 words, then just leave the string
            otherwise, trim to the $totalKwicLength/2 limit-->
        <xsl:variable name="startSnippet" select="
            if (count($startTokens) lt $kwicLengthHalf)
            then $startString 
            else concat('...',string-join($startTokens[position() = ((count($startTokens) - $kwicLengthHalf) to count($startTokens))],' '))" as="xs:string?"/>
        
        <!--The ending snippet: if there are fewer than $kwicLengthHalf words, then just leave the string,
            otherwise, trim to the $kwicLengthHalf limit-->
        <xsl:variable name="endSnippet" select="
            if (count($endTokens) lt $kwicLengthHalf) 
            then $endString 
            else concat(string-join($endTokens[position() = (1 to $kwicLengthHalf)],' '),'...')" as="xs:string"/>
        
        <!--Now, concatenate the start snippet, the term, and the end snippet
            and then normalize the spaces (to eliminate \n etc)-->
        <xsl:value-of
            select="
            concat(string-join($startSnippet,''), '&lt;mark&gt;',$thisTerm,'&lt;/mark&gt;', string-join($endSnippet,''))
            => replace('\s+\n+\t+',' ') 
            => normalize-space()"/>
    </xsl:function>
    
    <xsl:function name="hcmc:returnWeight" as="xs:integer">
        <xsl:param name="span"/>
        <xsl:sequence select="if ($span/ancestor::*[@data-staticSearch-weight]) then $span/ancestor::*[@data-staticSearch-weight][1]/@data-staticSearch-weight/xs:integer(.) else 1"/>
    </xsl:function>

    <xsl:function name="hcmc:getDocTitle">
        <xsl:param name="docNode"/>
        <xsl:variable name="titleEl" select="$docNode//head/title[1]" as="element()?"/>
        <xsl:choose>
            <xsl:when test="exists($titleEl) 
                and normalize-space(string-join($titleEl/descendant::text(),'')) ne ''">
                <xsl:value-of select="normalize-space(string-join($titleEl/descendant::text(),''))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$docNode/@id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    
    
    
    
    
    
</xsl:stylesheet>