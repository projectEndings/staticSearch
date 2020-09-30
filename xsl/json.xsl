<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:j="http://www.w3.org/2005/xpath-functions"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
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
            a JSON file for each stemmed token. It also creates a separate JSON file for the project's
            stopwords list, for all the document titles in the collection, and for each of the filter facets.
            Finally, it creates a single JSON file listing all the stems, which may be used for glob searches.</xd:p>
        </xd:desc>
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
       *                        Variables                           *
       *                                                            *
       **************************************************************-->
        
     <xd:doc>
         <xd:desc>Basic count of all of the tokenized documents</xd:desc>
     </xd:doc>
    <xsl:variable name="tokenizedDocsCount" select="count($tokenizedDocs)" as="xs:integer"/>
    

    <xd:doc>
        <xd:desc>All stems from the tokenized docs; we use this in a few places.</xd:desc>
    </xd:doc>
    <xsl:variable name="stems" select="$tokenizedDocs//span[@data-staticSearch-stem]" as="element(span)*"/>
    
    
    
    
    <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->

    <!--ROOT TEMPLATE -->

    <xd:doc>
        <xd:desc>Root template, which calls the rest of the templates. Note that 
        these do not have to be run in any particular order.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="createStemmedTokenJson"/>
        <xsl:call-template name="createTitleJson"/>
        <xsl:call-template name="createFiltersJson"/>
        <xsl:call-template name="createStopwordsJson"/>
        <xsl:call-template name="createWordStringTxt"/>
        <xsl:call-template name="createConfigJson"/>
    </xsl:template>


    <!--**************************************************************
       *                                                            *
       *                     createdStemmedTokenJson                *
       *                                                            *
       **************************************************************-->

    <xd:doc>
        <xd:desc>The <xd:ref name="createStemmedTokenJson" type="template">createStemmedTokenJson</xd:ref> 
            is the meat of this process. It first groups the HTML span elements by their
            @data-staticSearch-stem (and note this is tokenized, since @data-staticSearch-stem
            can contain more than one stem) and then creates a XML map, which is then converted to JSON.</xd:desc>
    </xd:doc>
    <xsl:template name="createStemmedTokenJson">
        <xsl:message>Found <xsl:value-of select="$tokenizedDocsCount"/> tokenized documents...</xsl:message>
        
         <!--Group by each of the static search stem values-->
        <xsl:for-each-group select="$stems" group-by="tokenize(@data-staticSearch-stem,'\s+')">
            
             <!--Sort these (for no reason, really). -->
            <xsl:sort select="current-grouping-key()" case-order="upper-first"/>
            
             <!--Variable that is simply the current-grouping-key (i.e. the stem from which
                a JSON is being created)-->
            <xsl:variable name="stem" select="current-grouping-key()"/>
            
             <!--Simple message if one wants it -->
            <xsl:if test="$verbose">
                <xsl:message>Processing <xsl:value-of select="$stem"/></xsl:message>
            </xsl:if>
            
             <!--Now create the JSON map structure. Since we're calling a template, all of the contexts
                 are inherited -->
            <xsl:variable name="map" as="element()">
                <xsl:call-template name="makeMap"/>
            </xsl:variable>
            
              
                <!--Now create the result document. Note that the JSONs are output into two directories (upper and lower)
                as operating systems other than Linux tend to be case-insensitive, meaning that the last of
                    August.json
                    august.json

                would silently overwrite the first. -->
            
            <xsl:result-document href="{$outDir}/{if (matches($stem,'^[A-Z]')) then 'upper' else 'lower'}/{$stem}{$versionString}.json" method="text">
                <xsl:value-of select="xml-to-json($map, map{'indent': $indentJSON})"/>
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
                   <xd:b>stem (string):</xd:b> the stem, inherited from the initial template
               </xd:li>
               <xd:li><xd:b>instances (array):</xd:b> an array of all the documents that contain that stem
                   <xd:ul>
                       <xd:li><xd:b>docId (string):</xd:b> The document id, which is taken from the document's
                       declared html/@id. (Note that this may be a value derived from the document's URI, which
                       is placed into the html/@id in the absence of a pre-existing id during the
                           <xd:a href="tokenize.xsl">tokenization tranformation</xd:a>.</xd:li>
                       <xd:li><xd:b>docUri (string):</xd:b> The URI of the source document.</xd:li>
                       <xd:li><xd:b>score (number):</xd:b> The sum of the weighted scores of each span that
                           is in that document. For instance, if some document had n instances of stem x
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
    </xd:doc>
    <xsl:template name="makeMap" as="element(j:map)">
        
        <!--The term we're creating a JSON for, inherited from the createMap template -->
        <xsl:variable name="stem" select="current-grouping-key()" as="xs:string"/>
        
        <!--The group of all the terms (so all of the spans that have this particular term
            in its @data-staticSearch-stem -->
        <xsl:variable name="stemGroup" select="current-group()" as="element(span)*"/>
        
       

        <!--Create the outermost part of the structure-->
        <map xmlns="http://www.w3.org/2005/xpath-functions">

           <!--The stem is the top level string key for this map; it should be
                the same as the JSON file name.-->
            <string key="stem">
                <xsl:value-of select="$stem"/>
            </string>

             <!--Start instances array: this contains all of the instances of the stem
                 per document -->
            <array key="instances">

                <!--If every HTML document processed has an @id at the root,
                    then use that as the grouping-key; otherwise,
                    use the document uri -->
                <xsl:for-each-group select="$stemGroup"
                    group-by="document-uri(/)">
                    
                    <!--Sort the documents so that the document with the most number of this hit comes first-->
                    <xsl:sort select="count(current-group())" order="descending"/>
                    
                    <!--The current document uri, which functions as the key for grouping the spans-->
                    <xsl:variable name="currDocUri" select="current-grouping-key()" as="xs:string"/>
                    
                    <!--The spans that are contained within this document-->
                    <xsl:variable name="thisDocSpans" select="current-group()" as="element(span)*"/>

                    <!--Get the total number of documents (i.e. the number of iterations that this
                        for-each-group will perform) for this span-->
                    <xsl:variable name="stemDocsCount" select="last()" as="xs:integer"/>
                    
                    <!--Output message, if verbose-->
                    <xsl:if test="$verbose">
                        <xsl:message><xsl:value-of select="$stem"/>: Processing <xsl:value-of select="$currDocUri"/></xsl:message>
                    </xsl:if>
                    
                    <!--The document that we want to process will always be the ancestor html of
                        any item of the current-group() -->
                    <xsl:variable name="thisDoc"
                        select="current-group()[1]/ancestor::html"
                        as="element(html)"/>

                    <!--Now the document ID, which we've created (if necessary) in the
                        tokenization step -->
                    <xsl:variable name="docId" select="$thisDoc/@id" as="xs:string"/>

                    <!--And the relative URI from the document, which is to be used
                        for linking from the KWIC to the document. We've created this
                        already in the tokenization stage and stored it in a custom
                        data-attribute-->
                    <xsl:variable name="relativeUri"
                        select="$thisDoc/@data-staticSearch-relativeUri"
                        as="xs:string"/>
                    
                    <!--Get the raw score of all the spans by getting the weight for 
                        each span and then adding them all together -->
                    <xsl:variable name="rawScore" 
                        select="sum(for $span in $thisDocSpans return hcmc:returnWeight($span))"
                        as="xs:integer"/>
          
                    
                   <!--Now start the map that represents each document-->
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <!--Document id -->
                        <string key="docId">
                            <xsl:value-of select="$docId"/>
                        </string>

                        <!--Document URI (relative) -->
                        <string key="docUri">
                            <xsl:value-of select="$relativeUri"/>
                        </string>

                       <!--Document score -->
                        <number key="score">
                            <xsl:choose>
                                <xsl:when test="$scoringAlgorithm = 'tf-idf'">
                                    <xsl:sequence select="hcmc:returnTfIdf($rawScore, $stemDocsCount, $currDocUri)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="$rawScore"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </number>

                        <!--Now add the contexts array, if specified to do so -->
                        <xsl:if test="$phrasalSearch or $createContexts">
                            <array key="contexts">

                                <!--Return only the number of contexts we want;
                                    if a limit has been specified, only return
                                    up to the limit; otherwise, return them all. -->
                                <xsl:variable name="contexts" as="element(span)+"
                                    select="
                                    if ($phrasalSearch)
                                    then $thisDocSpans
                                    else subsequence($thisDocSpans, 1, $maxKwicsToHarvest)"
                                 />

                                <!--Count the contexts -->
                                <xsl:variable name="contextsCount" select="count($contexts)" as="xs:integer"/>

                                <!--Debugging message, if we're in verbose mode-->
                                <xsl:if test="$verbose">
                                    <xsl:message>
                                        <xsl:value-of select="$stem"/>: <xsl:value-of select="$currDocUri"/>: Processing <xsl:value-of select="$contextsCount"/> contexts.
                                    </xsl:message>
                                </xsl:if>

                                <!--Now iterate through the contexts, returning a simple map that gives its
                                    form, context, and weight.-->
                                <xsl:for-each select="$contexts">
                                    
                                    <!--Sort by weight, since we want the highest weighted first -->
                                    <xsl:sort select="hcmc:returnWeight(.)" order="descending"/>
                                    <!--And then sort by its position secondarily-->
                                    <xsl:sort select="xs:integer(@data-staticSearch-pos)" order="ascending"/>
                                    <map>

                                        <!--Get the form (which is just the text value of the span and any descendant spans) -->
                                        <string key="form"><xsl:value-of select="string-join(descendant::text(),'')"/></string>

                                        <!--Get the context using the hcmc:returnContext function -->
                                        <string key="context"><xsl:value-of select="hcmc:returnContext(.)"/></string>

                                        <!--Get the weight, using hcmc:returnWeight function -->
                                        <number key="weight"><xsl:value-of select="hcmc:returnWeight(.)"/></number>
                                        
                                        <number key="pos"><xsl:value-of select="@data-staticSearch-pos"/></number>
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
        <xd:desc><xd:ref name="hcmc:returnTfIdf" type="function">hcmc:tf-idf</xd:ref> returns the tf-idf 
        score for a span; this is calculated following the standard tf-idf formula.</xd:desc>
        <xd:param name="rawScore">The raw score for this term (t)</xd:param>
        <xd:param name="stemDocsCount">The number of documents in which this stem appears (df)</xd:param>
        <xd:param name="thisDocUri">The document URI from which we can generate the total terms that
        appear in that document.(f)</xd:param>
        <xd:return>A score as a double.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:returnTfIdf" as="xs:double">
        <xsl:param name="rawScore" as="xs:integer"/>
        <xsl:param name="stemDocsCount" as="xs:integer"/>
        <xsl:param name="thisDocUri" as="xs:string"/>
        
        <!--Get the total terms in the document-->
        <xsl:variable name="totalTermsInDoc" 
            select="hcmc:getTotalTermsInDoc($thisDocUri)" as="xs:integer"/>

        <!--Get the term frequence (i.e. tf). Note this is slightly altered
                        since we're using a weighted term frequency -->
        <xsl:variable name="tf"
            select="($rawScore div $totalTermsInDoc)"
            as="xs:double"/>
        
        <!--Now get the inverse document frequency (i.e idf) -->
        <xsl:variable name="idf"
            select="math:log10($tokenizedDocsCount div $stemDocsCount)"
            as="xs:double"/>
        
        <!--Now get the term frequency index document frequency (i.e. tf-idf) -->
        <xsl:variable name="tf-idf" select="$tf * $idf" as="xs:double"/>
        <xsl:if test="$verbose">
            <xsl:message>Calculated tf-idf: <xsl:sequence select="$tf-idf"/></xsl:message>
        </xsl:if>
        <xsl:sequence
            select="$tf * $idf"/>
        
   
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

        <!--The string term: String joining is overly cautious here.-->
        <xsl:variable name="thisTerm"
            select="string-join($span/descendant::text(),'')"
            as="xs:string"/>

        <!--The first ancestor that has been signaled as an ancestor-->
        <xsl:variable name="contextAncestor"
            select="$span/ancestor::*[@data-staticSearch-context='true'][1]"
            as="element()?"/>

        <!--If there's no context ancestor, then something's wrong-->
        <xsl:if test="empty($contextAncestor)">
            <xsl:message terminate="yes">THIS SPAN CAUSED A PROBLEM! <xsl:copy-of select="$span"/> / <xsl:value-of select="$span/ancestor::html/@id"/></xsl:message>
        </xsl:if>

        <!--Note that the below approaches to pre and fol nodes cannot be done using
            the simpler $span/preceding::text()[ancestor::*[@data-staticSearch-context='true'][1] is $contextAncestor]
            as it causes some error in Saxon (9.8.) TinyTreeImpl.-->

        <!--These are all of the descendant text nodes of the ancestor node, which:
            1) Precede this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->

        <xsl:variable name="preNodes"
            select="$contextAncestor/descendant::text()[. &lt;&lt; $span and not(ancestor::*[. is $span]) and ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>


        <!--These are all of the descendant text nodes of the ancestor node, which:
            1) Follow this span element
            2) Is not contained within this span element
            3) And who does not have a different context ancestor
            -->
        <xsl:variable name="folNodes"
            select="$contextAncestor/descendant::text()[. &gt;&gt; $span and not(ancestor::*[. is $span])][ancestor::*[@data-staticSearch-context='true'][1][. is $contextAncestor]]" as="xs:string*"/>

        <!--The preceding text joined together-->
        <xsl:variable name="startString"
            select="string-join($preNodes,'')" as="xs:string?"/>

        <!--The following string joined together-->
        <xsl:variable name="endString"
            select="string-join($folNodes,'')" as="xs:string?"/>

        <!--The start string split on whitespace to be counted and
            reconstituted below-->
        <xsl:variable name="startTokens" select="tokenize($startString, '\s+')" as="xs:string*"/>

        <!--Count of how many tokens there are in the start sequence-->
        <xsl:variable name="startTokensCount" select="count($startTokens)" as="xs:integer"/>

        <!--The trailing string split on whitespace to be counted and
            reconstituted below-->
        <xsl:variable name="endTokens" select="tokenize($endString,'\s+')" as="xs:string*"/>


        <!--Count of how many tokens there are in the end sequence-->
        <xsl:variable name="endTokensCount" select="count($endTokens)" as="xs:integer"/>

        <!--Re-add the beginning space if there was one to begin with-->
        <xsl:variable name="preSpace" 
            select=" if (matches($startString,'\s+$'))  then ' ' else ()"
            as="xs:string?"/>
        
        <!--Re-add the trailing space if there was one to begin with-->
        <xsl:variable name="endSpace" 
            select="if (matches($endString,'^\s+')) then ' ' else ()"
            as="xs:string?"/>
        
        
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



        <!--The ending snippet: if there are fewer than $kwicLengthHalf words, then just leave the string,
            otherwise, trim to the $kwicLengthHalf limit-->
        <xsl:variable name="endSnippet" select="

            (: if the number of words is less than the kwic length:)
            if ($endTokensCount lt $kwicLengthHalf)

            (: Then just return the end string:)
            then normalize-space($endString)

            (: Otherwise, get as many words as we can and concatenate an ellipses:)
            else hcmc:joinSubseq($endTokens, 1, $kwicLengthHalf) || $kwicTruncateString"
            as="xs:string"/>
        
        

        <!--Now, concatenate the start snippet, the term, and the end snippet
            and then normalize the spaces (to eliminate \n etc)-->

        <!--Note that we output the serialized version of the <mark> element for simplicities sake;
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
        <xd:desc><xd:ref name="hcmc:getTotalTermsInDoc" type="function">hcmc:getTotalTermsInDoc</xd:ref> counts up all of the
        distinct spans from a given document URI; we use the URI here since we want this function to be cached (since it is called for every
        document for every stem).</xd:desc>
        <xd:param name="docUri" as="xs:string">The document URI (which is really an xs:anyURI)</xd:param>
        <xd:return>An integer count of all distinct terms in that document.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:getTotalTermsInDoc" as="xs:integer" new-each-time="no">
        <xsl:param name="docUri" as="xs:string"/>
        <xsl:variable name="thisDoc" select="$tokenizedDocs[document-uri(.) = $docUri]" as="document-node()"/>
        <xsl:variable name="thisDocSpans" select="$thisDoc//span[@data-staticSearch-stem]" as="element(span)*"/>
        
        <!--We tokenize these since there can be multiple stems for a given span-->
        <xsl:variable name="thisDocStems" select="for $span in $thisDocSpans return tokenize($span/@data-staticSearch-stem,'\s+')" as="xs:string+"/>
        
        <xsl:variable name="uniqueStems" select="distinct-values($thisDocStems)" as="xs:string+"/>
        <xsl:sequence select="count($uniqueStems)"/>
    </xsl:function>
    
    
    
    
    <!--**************************************************************
       *                                                            *
       *                      createFiltersJson                     *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>createFiltersJson is a named template that creates files for each filter JSON; it will eventually supercede createDocsJson.
        There are (currently) three types of filters that this process creates:
        
        <xd:ol>
            <xd:li>Desc filters: These are organized as a desc (i.e. Genre) with an array of values (i.e. Poem) that contains an array of document ids that apply to that value (i.e. MyPoem1.html, MyPoem2.html)</xd:li>
            <xd:li>Boolean Filters: These are organized as a desc value (i.e. Discusses Foreign Affairs) with an array of two values: True and False.</xd:li>
            <xd:li>Date filters: These are a bit different than the above. Since dates can contain a range, these JSONs must be organized not by date but by document.</xd:li>
        </xd:ol>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createFiltersJson">
        <!--We only want metas from documents which themselves aren't excluded
            and from documents that aren't excluded-->
        <xsl:for-each-group select="$tokenizedDocs//meta[matches(@class,'^|\s+staticSearch\.')][not(@data-staticSearch-exclude)][not(ancestor::html[@data-staticSearch-exclude])]" group-by="tokenize(@class,'\s+')[matches(.,'^staticSearch\.')]">
            
            <xsl:variable name="thisClass" select="current-grouping-key()"/>
            <xsl:variable name="metaNum" select="position()"/>
            <xsl:for-each-group select="current-group()" group-by="@name">
                <xsl:variable name="thisName" select="current-grouping-key()"/>
                <xsl:variable name="thisId" select="current-group()[1]/@data-staticSearch-filter-id"/>
                    <xsl:choose>
                        <xsl:when test="$thisClass = 'staticSearch.desc'">
                            <xsl:variable name="tmpMap" as="element(j:map)">
                                <map xmlns="http://www.w3.org/2005/xpath-functions">
                                    <string key="filterId"><xsl:value-of select="$thisId"/></string>
                                    <string key="filterName"><xsl:value-of select="$thisName"/></string>
                                    
                                    <!--Now iterate through these values via their content-->
                                    <xsl:for-each-group select="current-group()" group-by="@content">
                                        
                                        <xsl:variable name="thisContent" select="current-grouping-key()"/>
                                        <xsl:variable name="subGroupPos" select="position()"/>
                                        
                                        
                                        <xsl:variable name="filterId" select="$thisId || '_' || $subGroupPos"/>
                                        <map key="{$filterId}">
                                            <string key="name"><xsl:value-of select="$thisContent"/></string>
                                            <array key="docs">
                                                <xsl:for-each-group select="current-group()" group-by="ancestor::html[not(@data-staticSearch-exclude)]/@data-staticSearch-relativeUri">
                                                    
                                                    <string><xsl:value-of select="current-grouping-key()"/></string>
                                                </xsl:for-each-group>
                                            </array>
                                        </map>
                                    </xsl:for-each-group>
                                </map>
                            </xsl:variable>
                            <xsl:result-document href="{$outDir || '/filters/' || $thisId || $versionString || '.json'}" method="text">
                                <xsl:value-of select="xml-to-json($tmpMap)"/>
                            </xsl:result-document>
                        </xsl:when>
                        
                        
                        <xsl:when test="$thisClass='staticSearch.bool'">
                            <xsl:variable name="tmpMap" as="element(j:map)">
                                <map xmlns="http://www.w3.org/2005/xpath-functions">
                                    <string key="filterId"><xsl:value-of select="$thisId"/></string>
                                    <string key="filterName"><xsl:value-of select="@name"/></string>
                                    <xsl:for-each-group select="current-group()" group-by="hcmc:normalize-boolean(@content)">
                                         <!--We have to sort these descending so that we reliably get true followed by false. -->
                                        <xsl:sort select="hcmc:normalize-boolean(@content)" order="descending"/>
                                        <xsl:variable name="filterId" select="concat($thisId,'_',position())"/>
                                        <map key="{$filterId}">
                                            <string key="value"><xsl:value-of select="current-grouping-key()"/></string>
                                            <array key="docs">
                                                <xsl:for-each-group select="current-group()" group-by="ancestor::html/@data-staticSearch-relativeUri">
                                                    <string><xsl:value-of select="current-grouping-key()"/></string>
                                                </xsl:for-each-group>
                                            </array>
                                        </map>
                                    </xsl:for-each-group>
                                </map>
                            </xsl:variable>
                            <xsl:result-document href="{$outDir || '/filters/' || $thisId || $versionString || '.json'}" method="text">
                                <xsl:value-of select="xml-to-json($tmpMap)"/>
                            </xsl:result-document>
                        </xsl:when>
                        
                        <xsl:when test="$thisClass='staticSearch.date'">
                            <xsl:variable name="tmpMap" as="element(j:map)">
                                <map xmlns="http://www.w3.org/2005/xpath-functions">
                                    <string key="filterId"><xsl:value-of select="$thisId"/></string>
                                    <string key="filterName"><xsl:value-of select="$thisName"/></string>
                                    <map key="docs">
                                        <xsl:for-each-group select="current-group()" group-by="ancestor::html/@data-staticSearch-relativeUri">
                                            <xsl:variable name="filterId" select="concat($thisId,'_',position())"/>
                                            <array key="{current-grouping-key()}">
                                                <xsl:for-each select="current-group()">
                                                    <xsl:for-each select="tokenize(@content,'/')">
                                                        <string><xsl:value-of select="."/></string>
                                                    </xsl:for-each>
                                                </xsl:for-each>
                                            </array>
                                        </xsl:for-each-group>
                                    </map>
                                    
                                </map>
                            </xsl:variable>
                            <xsl:result-document href="{$outDir || '/filters/' || $thisId || $versionString || '.json'}" method="text">
                                <xsl:value-of select="xml-to-json($tmpMap)"/>
                            </xsl:result-document>
                        </xsl:when>
                        <xsl:when test="$thisClass ='staticSearch.num'">
                            <xsl:variable name="tmpMap" as="element(j:map)">
                                <map xmlns="http://www.w3.org/2005/xpath-functions">
                                    <string key="filterId"><xsl:value-of select="$thisId"/></string>
                                    <string key="filterName"><xsl:value-of select="$thisName"/></string>
                                    <map key="docs">
                                        <xsl:for-each-group select="current-group()" group-by="ancestor::html/@data-staticSearch-relativeUri">
                                            <xsl:variable name="filterId" select="concat($thisId,'_',position())"/>
                                            <array key="{current-grouping-key()}">
                                                <xsl:for-each-group select="current-group()[@content castable as xs:decimal]" group-by="xs:decimal(@content)">
                                                    <string><xsl:value-of select="xs:decimal(current-grouping-key())"/></string>
                                                </xsl:for-each-group>
                                            </array>
                                        </xsl:for-each-group>
                                    </map>
                                    
                                </map>
                            </xsl:variable>
                            <xsl:result-document
                                href="{$outDir || '/filters/' || $thisId || $versionString || '.json'}" method="text">
                                <xsl:value-of select="xml-to-json($tmpMap)"/>
                            </xsl:result-document>
                        </xsl:when>
                    </xsl:choose>
                
            </xsl:for-each-group>
        </xsl:for-each-group>
    </xsl:template>
    
    
    <!--**************************************************************
       *                                                            *
       *                    createStopwordsJson                     *
       *                                                            *
       **************************************************************-->
    
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
    
    
    
    <!--**************************************************************
       *                                                            *
       *                        createTitleJson                     *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc><xd:ref name="createTitleJson">createTitleJson</xd:ref>
            builds a JSON file containing a list of all the titles of documents in the 
        collection, indexed by their relative URI (which serves as their identifier),
        to be used when displaying results in the search page.</xd:desc>
    </xd:doc>
    <xsl:template name="createTitleJson">
        <xsl:result-document href="{$outDir}/ssTitles{$versionString}.json" method="text">
            <xsl:variable name="map" as="element(j:map)">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <xsl:for-each select="$tokenizedDocs//html">
                        <array key="{@data-staticSearch-relativeUri}">
                            <string><xsl:value-of select="hcmc:getDocTitle(.)"/></string>
                             <!--Add a thumbnail graphic if one is specified. This generates
                            nothing if there isn't. -->
                            <xsl:sequence select="hcmc:getDocThumbnail(.)"/>
                        </array>
                    </xsl:for-each>
                </map>
            </xsl:variable>
            <xsl:value-of select="xml-to-json($map, map{'indent': $indentJSON})"/>
        </xsl:result-document>
    </xsl:template>
    
    
    
    <!--**************************************************************
       *                                                            *
       *                     createWordStringTxt                    *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc><xd:ref name="createWordStringTxt">createWordStringTxt</xd:ref> 
            creates a string of the all of the unique words in the tokenized
            documents, in the form of a text file listing them, with pipe 
            delimiters. This will be used as the basis for the wildcard search
            (second implementation).</xd:desc>
        <xd:return>A large string of words in a text file.</xd:return>
    </xd:doc>
    <xsl:template name="createWordStringTxt">
        <xsl:message>Creating word string text file...</xsl:message>
        <xsl:variable name="words" as="xs:string*" select="for $w in $stems 
            return replace($w, '((^[^\p{L}\p{Nd}]+)|([^\p{L}\p{Nd}]+$))', '')"/>
        <xsl:result-document encoding="UTF-8" href="{$outDir}/ssWordString{$versionString}.txt" method="text" item-separator="">
            <xsl:for-each select="distinct-values($words)">
                <xsl:sort select="lower-case(.)"/>
                <xsl:sequence select="concat('|', ., '|')"/>
            </xsl:for-each>
        </xsl:result-document>
    </xsl:template>


    <!--**************************************************************
       *                                                            *
       *                       createConfigJson                     *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc><xd:ref name="createConfigJson">createConfigJson</xd:ref> 
            creates a JSON representation of the project's configuration file.
        This is not currently used for any specific purpose, but it may be 
        helpful for the JS search engine to know what configuration was 
        used to create the indexes at some point.</xd:desc>
        <xd:return>The configuration file in JSON.</xd:return>
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
    
    

    <!--**************************************************************
       *                                                            *
       *                     templates: dictToArray                 *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Template to convert an XML structure consisting
        of word elements inside a words element to a JSON/XML structure.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:words" mode="dictToArray">
        <j:map>
            <j:array key="words">
                <xsl:apply-templates mode="#current"/>
            </j:array>
        </j:map>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to convert a single word element inside 
            a words element to a JSON/XML string.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:word" mode="dictToArray">
        <j:string><xsl:value-of select="."/></j:string>
    </xsl:template>
    

    <!--**************************************************************
       *                                                            *
       *                     templates: configToArray               *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Template to convert an hcmc:config element to a JSON map.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:config" mode="configToArray">
        <j:map key="config">
            <xsl:apply-templates mode="#current"/>
        </j:map>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to convert an hcmc:params element to a JSON array.</xd:desc>
    </xd:doc>
    <xsl:template match="hcmc:params" mode="configToArray">
        <j:array key="params">
            <j:map>
                <xsl:apply-templates mode="#current"/>
            </j:map>
        </j:array>
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
        <xd:desc><xd:ref name="hcmc:normalize-boolean">hcmc:normalize-boolean</xd:ref>
            takes any of a variety of different boolean representations and converts them to
            string "true" or string "false".</xd:desc>
        <xd:param name="string">The input string.</xd:param>
        <xd:return>A string value that represents the boolean true/false.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:normalize-boolean" as="xs:string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:value-of select="if (matches(normalize-space($string),'true|1','i')) then 'true' else 'false'"/>
    </xsl:function>


    <xd:doc>
        <xd:desc><xd:ref name="hcmc:getDocTitle" type="function">hcmc:getDocTitle</xd:ref> is a simple function to retrieve 
                the document title, which we may have to construct if there's nothing usable.</xd:desc>
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
        <xd:desc><xd:ref name="hcmc:getDocThumbnail" type="function">hcmc:getDocThumbnail</xd:ref> 
                generates a j:string element containing a pointer to the first of any configured graphics, 
                relative to the search page location. NOTE: this function assumes that the graphic path has
            been massaged as necessary during the tokenizing process, so that it is now relative to the 
            search page location, not to the containing document.</xd:desc>
        <xd:param name="doc">The input document, which must be an HTML element.</xd:param>
        <xd:result>A j:string element, if there is a configured graphic, or the empty sequence.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocThumbnail" as="element(j:string)?">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:if test="$doc/head/meta[@name='docImage'][@class='staticSearch.docImage']">
            <j:string><xsl:value-of select="$doc/head/meta[@name='docImage'][@class='staticSearch.docImage'][1]/@content"/></j:string>
        </xsl:if>
    </xsl:function>
    
</xsl:stylesheet>
