<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 26, 2019</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation takes a collection of tokenized and stemmed documents (tokenized
            via the process described in <xd:a href="tokenize.xsl">tokenize.xsl</xd:a>) and creates
            a JSON file for each stemmed token.</xd:p>
        </xd:desc>
        <xd:param name="ellipses">A string parameter to denote what sorts of ellipses one wants in the KWIC.</xd:param>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            * 
       *                         Includes                           *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Include the generated configuration file. See 
        <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a> for
        full documentation of how the configuration file is created.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>    
    
    <!--**************************************************************
       *                                                            * 
       *                      Parameters                            *
       *                                                            *
       **************************************************************-->
   
    <xsl:param name="ellipses" as="xs:string">...</xsl:param>
    
    
    <!--**************************************************************
       *                                                            * 
       *                      Global Variables                      *
       *                                                            *
       **************************************************************-->
    <xd:doc>
        <xd:desc><xd:ref name="kwicLengthHalf" type="variable">$kwicLengthHalf</xd:ref> is simply
        rounded half of the length of the KWIC word limit. This helps when creating the KWIC
        in the later stages of the process.</xd:desc>
    </xd:doc>
    <xsl:variable name="kwicLengthHalf" select="xs:integer(round(xs:integer($totalKwicLength) div 2))" as="xs:integer"/>
    
    <!--**************************************************************
       *                                                            * 
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
    
<!--    ROOT TEMPLATE -->
    
    <xd:doc>
        <xd:desc>Root template, which calls the rest of the templates.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="createJson"/>
        <xsl:call-template name="createStopwordsJson"/>
        <xsl:call-template name="createConfigJson"/>
    </xsl:template>
    
    
    <!--**************************************************************
       *                                                            * 
       *                       Named Templates                      *
       *                                                            *
       **************************************************************-->
    
<!--    Start create JSON process ... -->
    
    <xd:doc>
        <xd:desc>The <xd:ref name="createJson" type="template">createJson</xd:ref> is the meat of this process;
        it kicks of the process by calling the createMap template with a selection of spans derived from the
        tokenized docs.</xd:desc>
    </xd:doc>
    <xsl:template name="createJson">
        <xsl:message>Found <xsl:value-of select="count($tokenizedDocs)"/> tokenized documents...</xsl:message>
        <xsl:variable name="stems" select="$tokenizedDocs//span[@data-staticSearch-stem]" as="element(span)*"/>
        <xsl:call-template name="createMap">
            <xsl:with-param name="stems" select="$stems"/>   
        </xsl:call-template>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>The <xd:ref name="createMap" type="template">createMap</xd:ref> processes 
            the XML map (created in the makeMap template) and converts it into a JSON for 
            each unique stem. It does so by first grouping the HTML span elements by their 
            @data-staticSearch-stem (and note this is tokenized, since @data-staticSearch-stem
            can contain more than one token) and then passing those spans to the makeMap template.</xd:desc>
        <xd:param name="stems">The collection of span[@data-staticSearch-stem[ passed from the tokenized documents.</xd:param>
    </xd:doc>
    <xsl:template name="createMap">
        <xsl:param name="stems"/>
        
<!--        Group by staticSearch-stem-->
        <xsl:for-each-group select="$stems" group-by="tokenize(@data-staticSearch-stem,'\s+')">
            
<!--            Sort these (for no reason, really).-->
            <xsl:sort select="current-grouping-key()" case-order="upper-first"/>
            
<!--            Variable that is simply the current-grouping-key (i.e. the stem from which
                a JSON is being created)-->
            <xsl:variable name="token" select="current-grouping-key()"/>
            
<!--            Simple message-->
            <xsl:if test="$verbose">
                <xsl:message>Processing <xsl:value-of select="$token"/></xsl:message>
            </xsl:if>
      
<!--            Now create the map element by passing the current grouping key as a term and
                note that the current context items for the makeMap template is the current group
                of the for-each-group-->
            <xsl:variable name="map" as="element()">
                <xsl:call-template name="makeMap">
                    <xsl:with-param name="term" select="$token"/>
                </xsl:call-template>
            </xsl:variable>
            
<!--            Now create the result document. Note that the JSONs are output into two directories (upper and lower)
                as operating systems other than Linux tend to be case-insensitive, meaning that the last of
                    August.json
                    august.json
                
                would silently (as of Saxon 9.8) overwrite the first.-->
            <xsl:result-document href="{$outDir}/{if (matches($token,'^[A-Z]')) then 'upper' else 'lower'}/{$token}.json" method="text">
                <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>
                The <xd:ref name="makeMap" type="template">makeMap</xd:ref> creates the XML map from a set
                of spans (compiled in the createMap template). This map has a number of fields necessary for
                the search interface:
            </xd:p>
           <xd:ul>
               <xd:li>
                   <xd:b>token (string):</xd:b> the stem, passed as a parameter
               </xd:li>
               <xd:li><xd:b>instances (array):</xd:b> an array of all the documents that contain that stem
                   <xd:ul>
                       <xd:li><xd:b>docId (string):</xd:b> The document id, which is taken from the document's
                       declared html/@id. (Note that this may be a value derived from the document's URI, which
                       is placed into the html/@id in the absence of a pre-existing id during the 
                           <xd:a href="tokenize.xsl">tokenization tranformation</xd:a>.</xd:li>
                       <xd:li><xd:b>docTitle (string):</xd:b> The title of the document, which may come from
                           the html/head/title or, if that is missing, is constructed from the document URI</xd:li>
                       <xd:li><xd:b>docUri (string):</xd:b> The URI of the source document.</xd:li>
                       <xd:li><xd:b>score (number):</xd:b> The sum of the weighted scores of each span that
                           is in that document. For instance, if some document had n instances of token x
                           ({x1, x2, ..., xn}) with corresponding scores ({s1, s2, ..., sn}), then the score
                           for the document is the sum of all s: s1 + s2 + . . . + sn.</xd:li>
                       <xd:li><xd:b>contexts (array)</xd:b>: an array of all of the contexts in which the 
                           stem appears in the tokenized document; an entry is created for each span in the current group.
                           Note that the contexts array is created iff the contexts parameter in the config file 
                           is set to true (or 1, T, yes, y). Also note
                           that the number of contexts depends on the limit set in the config file. If no limit
                           is set, then all contexts are used in the document. While this creates larger JSON 
                           files, this provides the search Javascript with enough information to do more precise 
                           phrasal searches.
                          <xd:ul>
                              <xd:li><xd:b>form (string):</xd:b> The text associated with the stemmed token 
                                 (for instance, for the word "ending", "end" is the stem, while "ending" is 
                                 the form).</xd:li>
                              <xd:li><xd:b>context (string):</xd:b> The context of this span for use in the KWIC.
                              The context string is determined by the KWIC length parameter (i.e. how many words
                              can the KWIC be) and by the context weight attributes described in 
                              <xd:a href="tokenize.xsl">tokenize.xsl</xd:a>. The string returned from the 
                               context also contains the term pre-marked using the HTML mark element.</xd:li>
                              <xd:li><xd:b>weight (number):</xd:b> The weight of this span in context.</xd:li>
                          </xd:ul>
                       
                       </xd:li>
                   </xd:ul>
               
               </xd:li>
           </xd:ul>
        </xd:desc>
        <xd:param name="term">The current stem from which the map is being created.</xd:param> <!--Note: Not 
            sure we actually need this parameter; we can probably just use current-grouping-key() since 
            we're in the context of the group-->
    </xd:doc>
    <xsl:template name="makeMap">
        <xsl:param name="term"/>
        <xsl:variable name="termRegex" select="concat('(^|\s)',$term,'(\s|$)')"/>
        <xsl:variable name="termGroup" select="current-group()"/>
        
<!--        Start map-->
        <map xmlns="http://www.w3.org/2005/xpath-functions">
            
<!--            The token is the top level string key for this map; it should be 
                the same as the JSON file name.-->
            <string key="token">
                <xsl:value-of select="$term"/>
            </string>
            
<!--            Start instances array -->
            <array key="instances">
                
<!--                If every HTML document processed has an @id at the root,
                    then use that as the grouping-key; otherwise,
                    use the document uri -->
                <xsl:for-each-group select="current-group()" 
                    group-by="document-uri(/)">
                  
                    
<!--                    Sort the documents so that the document with the most number of this hit comes first-->
                    <xsl:sort select="count(current-group())" order="descending"/>
                    <xsl:if test="$verbose">
                        <xsl:message><xsl:value-of select="$term"/>: Processing <xsl:value-of select="current-grouping-key()"/> (<xsl:value-of select="position()"/> / <xsl:value-of select="count(current-group())"/>)</xsl:message>
                    </xsl:if>
              
<!--                    The document that we want to process will always be the ancestor html of 
                        any item of the current-group() -->
                    <xsl:variable name="thisDoc" 
                        select="current-group()[1]/ancestor::html"
                        as="element(html)"/>
                    
<!--                    Now the document ID, which we've created (if necessary) in the 
                        tokenization step -->
                    <xsl:variable name="docId" select="$thisDoc/@id" as="xs:string"/>
                    
<!--                Now we get the document title:
                    
                    If there is something usable in the title, then use that;
                    otherwise, just use the document id as the title
                    -->
                    <xsl:variable name="docTitle" as="xs:string"
                        select="
                        let $t := normalize-space(string-join($thisDoc//head/title[1]/descendant::text(),'')) 
                        return 
                            if ($t ne '') 
                            then $t 
                            else $docId"
                    />
                    
<!--                    And the relative URI from the document, which is to be used
                        for linking from the KWIC to the document. We've created this
                        already in the tokenization stage and stored it in a custom
                        data-attribute-->
                    <xsl:variable name="relativeUri" 
                        select="$thisDoc/@data-staticSearch-relativeUri"
                        as="xs:string"/>
                    
<!--                   Stash the spans in a variable; they are the current-group -->
                    <xsl:variable name="spans" select="current-group()" as="element(span)+"/>
                    

<!--                    Now create the XPATH map, which will become a JSON -->
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
<!--                        Document id -->
                        <string key="docId">
                            <xsl:value-of select="$docId"/>
                        </string>
                        
<!--                        Document title -->
                        <string key="docTitle">
                            <xsl:value-of select="$docTitle"/>
                        </string>
                        
<!--                        Document URI (relative) -->
                        <string key="docUri">
                            <xsl:value-of select="$relativeUri"/>
                        </string>
                        
<!--                       Document score -->
                        <number key="score">
                            <xsl:value-of select="sum(for $s in $spans return hcmc:returnWeight($s))"/>
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
                                    else subsequence($spans, 1, $maxContexts)"
                                 />
                                
<!--                                Count the contexts -->
                                <xsl:variable name="contextsCount" select="count($contexts)" as="xs:integer"/>
                                
<!--                                Debugging message, if we're in verbose mode-->
                                <xsl:if test="$verbose">
                                    <xsl:message><xsl:value-of select="$term"/>: <xsl:value-of select="current-grouping-key()"/>: Processing <xsl:value-of select="$contextsCount"/> contexts.</xsl:message>
                                </xsl:if>
                                
<!--                                Now iterate through the contexts, returning a simple map that gives its
                                    form, context, and weight.-->
                                <xsl:for-each select="$contexts">
                                    
<!--                                    Sort by weight, since we want the highest weighted first -->
                                    <xsl:sort select="hcmc:returnWeight(.)" order="descending"/>
                                    <map>
                                        
<!--                                        Get the form (which is just the text value of the span) -->
                                        <string key="form"><xsl:value-of select="text()"/></string>
                                        
<!--                                        Get the context using the hcmc:returnContext function -->
                                        <string key="context"><xsl:value-of select="hcmc:returnContext(.)"/></string>
                                        
<!--                                        Get the weight, using hcmc:returnWeight function -->
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
            select="$contextAncestor/descendant::text()[. &lt;&lt; $span and not(parent::*[. is $span]) and ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>
        
        
<!--        These are all of the descendant text nodes of the ancestor node, which:
            1) Follow this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->
        <xsl:variable name="folNodes" 
            select="$contextAncestor/descendant::text()[. &gt;&gt; $span and not(parent::*[. is $span])][ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>

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
        
        <!--The starting snippet: if there are fewer than $totalKwicLength/2 words, then just leave the string
            otherwise, trim to the $totalKwicLength/2 limit-->
        <xsl:variable name="startSnippet" select="
            
            (:If the number of start tokens is less than half the kwicLimit:)
            if ($startTokensCount lt $kwicLengthHalf) 
            
            (: Then just return the start string :)
            then $startString  
            
            (:Otherwise, concatenate the sequence:)
            else $ellipses || hcmc:joinSubseq($startTokens, $startTokensCount - $kwicLengthHalf, $startTokensCount)"
            as="xs:string?"/>
        
<!--        The ending snippet: if there are fewer than $kwicLengthHalf words, then just leave the string,
            otherwise, trim to the $kwicLengthHalf limit-->
        <xsl:variable name="endSnippet" select="
            
            (: if the number of words is less than the kwic length:)
            if ($endTokensCount lt $kwicLengthHalf) 
            
            (: Then just return the end string:)
            then $endString 
            
            (: Otherwise, get as many words as we can and concatenate an ellipses:)
            else hcmc:joinSubseq($endTokens, 1, $kwicLengthHalf) || $ellipses" 
            as="xs:string"/>
        
<!--        Now, concatenate the start snippet, the term, and the end snippet
            and then normalize the spaces (to eliminate \n etc)-->
        
<!--        Note that we output the serialized version of the <mark> element for simplicities sake;
            it will be escaped in the JSON output anyway and the Javascript is able to handle the
            escaped version of the mark element.-->
        <xsl:value-of
            select="
            string-join($startSnippet,'') || '&lt;mark&gt;' || $thisTerm || '&lt;/mark&gt;' || string-join($endSnippet,'')
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
        for joining sequences of strings.</xd:desc>
        <xd:param name="seq">The sequence from which to derive the subset. 
            Example: ("A", "Bob ", "fourteen", "Fred Bloggs")</xd:param>
        <xd:param name="start">An integer that denotes the start of the subsequence. 
            Example: 2</xd:param>
        <xd:param name="end">An integer that denotes the end of the subsequence. 
            Example: 4</xd:param>
        <xd:return>A string joined version of the sequence from sequence[start] to sequence [end].
            Example:  "BobfourteenFred Bloggs"</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:joinSubseq" as="xs:string">
        <xsl:param name="seq" as="item()+"/>
        <xsl:param name="start" as="xs:integer"/>
        <xsl:param name="end" as="xs:integer"/>
        <xsl:value-of select="string-join(subsequence($seq, $start, $end),'')"/>
    </xsl:function>
    
    <!--TO DO: DOCUMENT THE BELOW (OR THINK ABOUT SPLITTING THEM INTO SEPARATE MODULES)-->
    
    
    <xd:doc>
        <xd:desc></xd:desc>
    </xd:doc>
    <xsl:template name="createStopwordsJson">
        <xsl:message>Creating stopwords array...</xsl:message>
        <xsl:result-document href="{$outDir}/stopwords.json" method="text">
            <xsl:variable name="map">
                <xsl:apply-templates select="$stopwordsFileXml" mode="dictToArray"/>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
        </xsl:result-document>
    </xsl:template>
    
<!--    Create a config file for the JSON-->
    <xsl:template name="createConfigJson">
        <xsl:message>Creating Configuration JSON file....</xsl:message>
        <xsl:result-document href="{$outDir}/config.json" method="text">
            <xsl:variable name="map">
                <xsl:apply-templates select="doc($configFile)" mode="configToArray"/>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': true()})"/>
        </xsl:result-document>
    </xsl:template>
    
<!--    Templates for converting the HCMC words files
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
    
    
<!--    Templates for converting the HCMC config file
        into a simple JSON for use in the Javascript.-->
    
    
    <xsl:template match="hcmc:config" mode="configToArray">
        <map:map key="config">
            <xsl:apply-templates mode="#current"/>
        </map:map>
    </xsl:template>
    
    <xsl:template match="hcmc:params" mode="configToArray">
        <map:array key="params">
            <map:map>
                <xsl:apply-templates mode="#current"/>
            </map:map>
        </map:array>
    </xsl:template>
    
    <xsl:template match="hcmc:params/hcmc:*" mode="configToArray">
        <xsl:element namespace="http://www.w3.org/2005/xpath-functions" name="{if (text() castable as xs:integer) then 'number' else 'string'}">
            <xsl:attribute name="key" select="local-name()"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    

    
    
    
    
    
    
</xsl:stylesheet>
