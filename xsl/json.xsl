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
    <xsl:variable name="stems" select="$tokenizedDocs//span[@ss-stem]" as="element(span)*"/>
    
    
    <!--**************************************************************
       *                                                            *
       *                        Accumulators                        *
       *                                                            *
       **************************************************************-->
    
    <!--The logic for the following accumulators is based off of the "Histogram"
        example from the XSLT 3.0 specification:
        https://www.w3.org/TR/xslt-30/#d7e48465 -->
    
    <xd:doc>
        <xd:desc>Accumulator to keep track of the current weight for a span; note that
            weights are not additive: a structure like (where W# = Weight):
            
            W2 > W3 > W1 > thisSpan
            
            has a weight of 1, not 6.</xd:desc>
    </xd:doc>
    <xsl:accumulator name="weight" initial-value="1" as="xs:integer+">
        <xsl:accumulator-rule 
            match="*[@ss-wt]" 
            select="($value, xs:integer(@ss-wt))" 
            phase="start"/>
        <xsl:accumulator-rule 
            match="*[@ss-wt]" 
            select="$value[position() lt last()]" 
            phase="end"/>
    </xsl:accumulator>
    
    <xsl:accumulator name="context-ids" initial-value="()" as="xs:string*">
        <xsl:accumulator-rule match="*[@ss-ctx-id]" select="($value, @ss-ctx-id)" phase="start"/>
        <xsl:accumulator-rule match="*[@ss-ctx-id]" select="$value[position() lt last()]" phase="end"/>
    </xsl:accumulator>
    
   <!--JT: This accumulator added for 110, but causes overflow issues in LOI;
       commented out temporarily while testing-->
<!--    <xd:doc>
        <xd:desc>Accumulator to keep track of the current context node.</xd:desc>
    </xd:doc>
    <xsl:accumulator name="context" initial-value="()">
        <xsl:accumulator-rule match="*[@ss-ctx]" select="($value, .)" phase="start"/>
        <xsl:accumulator-rule match="*[@ss-ctx]" select="$value[position() lt last()]" phase="end"/>
    </xsl:accumulator>-->

  
    <xd:doc>
        <xd:desc>Accumulator to keep track of custom @data-ss-* properties: on entering an element
        with a @data-ss-* attribute, add its value to the value map; on leaving the element, remove the attribute
        from the value map. Note that this assumes that all data-ss-* attributes are single valued and are
        treated as strings (i.e. 
        @data-ss-thing="foo bar" means the value is "foo bar", not ("foo", "bar")).</xd:desc>
    </xd:doc>
    <xsl:accumulator name="properties" initial-value="()">
        
        <!--On entering the element, add the new data-ss values to the map-->
        <xsl:accumulator-rule match="*[@*[matches(local-name(),'^data-ss-')]]" phase="start">
            <!--Get all of the data attributes for the element-->
            <xsl:variable name="dataAtts" select="@*[matches(local-name(),'^data-ss-')]" as="attribute()+"/>
            
            <!--Create a new map from the data attributes-->
            <xsl:variable name="newMap" as="map(xs:string, xs:string)">
                <xsl:map>
                    <xsl:for-each select="$dataAtts">
                        <xsl:map-entry key="hcmc:dataAttToProp(local-name(.))" select="string(.)"/>
                    </xsl:for-each>
                </xsl:map>
            </xsl:variable>

            <!--Now merge it with the intial value (which may be empty or an existing map)-->
            <xsl:sequence select="map:merge(($value, $newMap), map{'duplicates': 'combine'})"/>
        </xsl:accumulator-rule>
        
        <!--On exiting the element, remove the last values for data-ss-* attributes -->
        <xsl:accumulator-rule match="*[@*[matches(local-name(),'data-ss-')]]" phase="end">
            <xsl:variable name="dataAtts" select="@*[matches(local-name(),'^data-ss-')]" as="attribute()+"/>
            <!--Get all of the property names (which function as keys to the value map) -->
            <xsl:variable name="dataProps" select="$dataAtts ! hcmc:dataAttToProp(local-name())" as="xs:string+"/>
            
            <!--Now create a new map to manually remove the values-->
            <xsl:map>
                <!--Iterate through the keys-->
                <xsl:for-each select="map:keys($value)">
                    <xsl:variable name="key" select="." as="xs:string"/>
                    <xsl:variable name="val" select="$value($key)" as="xs:string+"/>
                    <xsl:choose>
                        <!--If the accumulator is tracking an data attribute that isn't present
                            in this element, then retain it-->
                        <xsl:when test="not($key = $dataProps)">
                            <xsl:map-entry key="$key" select="$val"/>
                        </xsl:when>
                        
                        <!--When the value map has a key that is also in this element,
                            and there are multiple (i.e. cases where an ancestor element has a 
                            different value than the parent), then remove it from the end-->
                        <xsl:when test="$key = $dataProps and count($val) gt 1">
                            <xsl:map-entry key="$key" select="$val[position() lt last()]"/>
                        </xsl:when>
                        
                        <!--Otherwise, the value map was only tracking this value, so it can
                            be deleted from the map.-->
                        <xsl:otherwise/>
                        
                    </xsl:choose>
                </xsl:for-each>
            </xsl:map>
        </xsl:accumulator-rule>
    </xsl:accumulator>
    
    
    <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->

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
            @ss-stem (and note this is tokenized, since @ss-stem
            can contain more than one stem) and then creates a XML map, which is then converted to JSON.</xd:desc>
    </xd:doc>
    <xsl:template name="createStemmedTokenJson">
        <xsl:message>Found <xsl:value-of select="$tokenizedDocsCount"/> tokenized documents...</xsl:message>
        <!--Group all of the stems by their values;  tokenizing is a bit overzealous here-->
        <xsl:for-each-group select="$stems" group-by="tokenize(@ss-stem,'\s+')">
            <xsl:variable name="stem" select="current-grouping-key()" as="xs:string"/>
            <xsl:call-template name="makeTokenCounterMsg"/>
            <xsl:variable name="map" as="element(j:map)">
                <xsl:call-template name="makeMap"/>
            </xsl:variable>
            <xsl:result-document href="{$outDir}/stems/{$stem}{$versionString}.json" method="text">
                <xsl:sequence select="xml-to-json($map, map{'indent': $indentJSON})"/>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to output some better output messaging for the JSON process;
        since there are thousands of token files created, we only output messages
        at milestones unless verbose is turned on.</xd:desc>
    </xd:doc>
    <xsl:template name="makeTokenCounterMsg">
        <!--State how many token documents we're creating if we're on the initial loop-->
        <xsl:if test="position() = 1">
            <xsl:message>Creating <xsl:value-of select="last()"/> JSON documents...</xsl:message>
        </xsl:if>
        <xsl:if test="$verbose">
            <xsl:message>Processing <xsl:value-of select="current-grouping-key()"/></xsl:message>
        </xsl:if>
        <!--Figure out ten percent-->
        <xsl:variable name="tenPercent" select="last() idiv 10"/>
        <!--Get the rough percentage-->
        <xsl:variable name="roughPercentage" select="position() idiv $tenPercent"/>
        <xsl:variable name="isLast" select="position() = last()"/>
        <xsl:if test="position() mod $tenPercent = 0 or $isLast">
            <xsl:message expand-text="true">Processing {position()}/{last()}</xsl:message>
            <xsl:if test="$isLast">
                <xsl:message>Done!</xsl:message>
            </xsl:if>
        </xsl:if>
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
                       <xd:li><xd:b>contexts (array)</xd:b>: an array of all of the contexts. See <xd:ref name="returnContextsArray"/></xd:li>
                      
                   </xd:ul>

               </xd:li>
           </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template name="makeMap" as="element(j:map)">
        <!--The term we're creating a JSON for, inherited from the createMap template -->
        <xsl:variable name="stem" select="current-grouping-key()" as="xs:string"/>
        
        <!--The group of all the terms (so all of the spans that have this particular term
            in its @ss-stem -->
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
                    <xsl:if test="$verbose">
                        <xsl:message><xsl:value-of select="$stem"/>: Processing <xsl:value-of select="$currDocUri"/></xsl:message>
                    </xsl:if>
                    
                    <!--The document that we want to process will always be the ancestor html of
                        any item of the current-group() -->
                    <xsl:variable name="thisDoc"
                        select="current-group()[1]/ancestor::html"
                        as="element(html)"/>
                    
                    <!--Get the raw score of all the spans by getting the weight for 
                        each span and then adding them all together -->
                    <xsl:variable name="rawScore" 
                        select="sum(for $span in $thisDocSpans return hcmc:returnWeight($span))"
                        as="xs:integer"/>
                    
                   <!--Map for each document that has this token-->
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <!--Now the document ID, which we've created (if necessary) in the
                        tokenization step -->
                        <string key="docId">
                            <xsl:value-of select="$thisDoc/@id"/>
                        </string>
                        
                        <!--And the relative URI from the document, which is to be used
                        for linking from the KWIC to the document. We've created this
                        already in the tokenization stage and stored it in a custom
                        data-attribute-->
                        <string key="docUri">
                            <xsl:value-of select="$thisDoc/@data-staticSearch-relativeUri"/>
                        </string>
                        
                        <!--The document's score, forked depending on configured
                            algorithm -->
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
                            <xsl:call-template name="returnContextsArray"/>
                        </xsl:if>
                    </map>
                </xsl:for-each-group>
            </array>
        </map>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
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
        </xd:desc>
    </xd:doc>
    <xsl:template name="returnContextsArray">
        <!--The document that we want to process will always be the ancestor html of
                        any item of the current-group() -->
        <xsl:variable name="thisDoc"
            select="current-group()[1]/ancestor::html"
            as="element(html)"/>
        
        <!--If phrasal search is turned on, then we must process all of the contexts
                in order to perform phrasal search properly; otherwise, only create the number
                of kwics set in the config.-->
        <xsl:variable name="contexts" as="element(span)+"
            select="
            if ($phrasalSearch)
            then current-group()
            else subsequence(current-group(), 1, $maxKwicsToHarvest)"/>        
        <xsl:variable name="contextCount" select="count($contexts)" as="xs:integer"/>
        
        <array xmlns="http://www.w3.org/2005/xpath-functions" key="contexts">
            <!--Create a map for each hit in the document with data about that
                context-->
            <xsl:for-each select="$contexts">
                <!--Sort the contexts first by weight (highest to lowest) and then
                by position in the document (earliest to latest)-->
                <xsl:sort select="hcmc:returnWeight(.)" order="descending"/>
                <xsl:sort select="xs:integer(@ss-pos)" order="ascending"/>
                
                <xsl:if test="$verbose">
                    <xsl:message expand-text="true">{$thisDoc/@data-staticSearch-relativeUri}: {@ss-stem} (ctx: {position()}/{$contextCount}):  pos: {@ss-pos}</xsl:message>
                </xsl:if>
                
                <!--Accumulated properties map, which may or may not exist -->
                <xsl:variable name="properties"
                    select="accumulator-before('properties')" as="map(*)?"/>                
                <map>
                    <string key="form">
                        <xsl:sequence select="string(.)"/>
                    </string>
                    <string key="weight">
                        <xsl:sequence select="hcmc:returnWeight(.)"/>
                    </string>
                    <number key="pos">
                        <xsl:sequence select="xs:integer(@ss-pos)"/>
                    </number>
                    <string key="context">
                        <xsl:sequence select="hcmc:returnContext(.)"/>
                    </string>
                    <!--Get the best fragment id if that's set-->
                    <xsl:if test="$linkToFragmentId and @ss-fid">
                        <string key="fid">
                            <xsl:value-of select="@ss-fid"/>
                        </string>
                    </xsl:if>
                    <xsl:if test="not(empty($ssContextMap))">
                        <xsl:where-populated>
                            <array key="in">
                                <xsl:for-each select="accumulator-before('context-ids')">
                                    <string><xsl:value-of select="."/></string>
                                </xsl:for-each>
                            </array>
                        </xsl:where-populated>
                    </xsl:if>
                    <!--Now we add the custom properties, if we need to-->
                    <xsl:if test="exists($properties) and map:size($properties) gt 0">
                        <map key="prop">
                            <xsl:for-each select="map:keys($properties)">
                                <xsl:variable name="propVal" select="map:get($properties,.)[last()]" as="xs:string"/>
                                <string key="{.}"><xsl:value-of select="$propVal"/></string>
                            </xsl:for-each>
                        </map>                
                    </xsl:if>
                </map>
            </xsl:for-each>
        </array>
    </xsl:template>
    

    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:dataAttToProp">hcmc:dataAttToProp</xd:ref> converts the
        a special staticSearch custom attribute (data-ss-*) and converts it to property name.</xd:desc>
        <xd:param name="dataAtt">The local name of the attribute to process (i.e. data-ss-title, data-ss-my-value).</xd:param>
        <xd:return>The key for the property (title, my-value).</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:dataAttToProp" as="xs:string" new-each-time="no">
        <xsl:param name="dataAtt" as="xs:string"/>
        <xsl:variable name="suffix" select="substring-after($dataAtt,'data-ss-')" as="xs:string"/>
        <xsl:sequence select="$suffix"/>
    </xsl:function>
    
    
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
        <xd:desc><xd:ref name="hcmc:returnContext" type="function">hcmc:returnContext</xd:ref> returns
            the context string for a span; it does so by gathering up the text before the span and the
            text after the span, and then trims the length of the overall string to whatever the 
            $kwicLimit is.</xd:desc>
        <xd:param name="span">The span from which to return the context.</xd:param>
        <xd:return>A string with the term included in $span tagged as a mark element.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:returnContext" as="xs:string">
        <xsl:param name="span" as="element(span)"/>
        
        <xsl:variable name="spanText" 
            select="$span/descendant::text()" 
            as="node()*"/>
        <xsl:variable name="thisTerm"
            select="string-join($spanText)"
            as="xs:string"/>
        
        <!--The first ancestor that has been signaled as an ancestor-->
        <xsl:variable name="contextAncestor"
            select="$span/ancestor::*[@ss-ctx][1]"
            as="element()"/>
        
        <!--Get all of the descendant text nodes for that ancestor-->
        <xsl:variable name="thisContextNodes"
            select="hcmc:getContextNodes($contextAncestor)"
            as="node()*"/>
        
        <!--Find all of the nodes that precede this span for this context in document order-->
        <xsl:variable name="preNodes"
            select="$thisContextNodes[. &lt;&lt; $span]" as="node()*"/>
        
        <!--All the text nodes that follow the node (and aren't the preceding nodes or the following ones)-->
        <xsl:variable name="folNodes" 
            select="$thisContextNodes except ($preNodes, $spanText)" as="node()*"/>

        <!--The start and end snippets-->
        <xsl:variable name="startSnippet"
            select="if (not(empty($preNodes))) then hcmc:returnSnippet($preNodes,true()) else ()"
            as="xs:string?"/>
        <xsl:variable name="endSnippet" 
            select="if (not(empty($folNodes))) then hcmc:returnSnippet($folNodes, false()) else ()"
            as="xs:string?"/>

        <!--Create the the context string, and add an escaped
            version of the mark element around it (the kwicTruncateString is added by the returnSnippet
            function)-->
        <xsl:sequence
          select="hcmc:sanitizeForJson($startSnippet) || '&lt;mark&gt;' || $thisTerm || '&lt;/mark&gt;' || hcmc:sanitizeForJson($endSnippet)"/>
    </xsl:function>
  
  <xd:doc>
    <xd:desc><xd:ref name="hcmc:sanitizeForJson">hcmc:sanitizeForJson</xd:ref> takes a string
    input and escapes angle brackets so that actual tags cannot inadvertently find their way
    into search result KWICs.</xd:desc>
    <xd:param name="inStr" as="xs:string?">The string to escape</xd:param>
    <xd:return>The escaped string</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:sanitizeForJson" as="xs:string?">
    <xsl:param name="inStr" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$inStr">
        <xsl:sequence select="replace($inStr, '&amp;', '&amp;amp;') => replace('&gt;', '&amp;gt;') => replace('&lt;', '&amp;lt;')"/>
      </xsl:when>
      <xsl:otherwise><xsl:sequence select="()"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:returnSnippet">hcmc:returnSnippet</xd:ref> takes a sequence of nodes and constructs
        the surrounding text content by iterating through the nodes and concatenating their text; once the string is 
        long enough (or once the process has exhausted the sequence of nodes), then the function breaks out of the loop
        and returns the string.</xd:desc>
        <xd:param name="nodes">The text nodes to use to construct the snippet</xd:param>
        <xd:param name="isStartSnippet">Boolean to denote whether or not whether this is the start snippet</xd:param>
    </xd:doc>
    <!--TODO: Determine whether or not this needs to be more sensitive for right to left languages-->
    <xsl:function name="hcmc:returnSnippet" as="xs:string?">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:param name="isStartSnippet" as="xs:boolean"/>
    
        <!--Iterate through the nodes: 
            if we're in the start snippet we want to go from the end to the beginning-->
        <xsl:iterate select="if ($isStartSnippet) then reverse($nodes) else $nodes">
            <xsl:param name="stringSoFar" as="xs:string?"/>
            <xsl:param name="tokenCount" select="0" as="xs:integer"/>
            <!--If the iteration completes, then just return the full string-->
            <xsl:on-completion>
                <xsl:sequence select="$stringSoFar"/>
            </xsl:on-completion>
            <xsl:variable name="thisNode" select="."/>
            <!--Normalize and determine the word count of the text-->
            <xsl:variable name="thisText" select="replace(string($thisNode),'\s+', ' ')" as="xs:string"/>
            <xsl:variable name="tokens" select="tokenize($thisText)" as="xs:string*"/>
            <xsl:variable name="currTokenCount" select="count($tokens)" as="xs:integer"/>
            <xsl:variable name="fullTokenCount" select="$tokenCount + $currTokenCount" as="xs:integer"/>
            
            <xsl:choose>
                <!--If the number of preceding tokens plus the number of current tokens is 
                    less than half of the kwicLimit, then continue on, passing 
                    the new token count and the new string-->
                <xsl:when test="$fullTokenCount lt $kwicLengthHalf + 1">
                    <xsl:next-iteration>
                        <xsl:with-param name="tokenCount" select="$fullTokenCount"/>
                        <!--If we're processing the startSnippet, prepend the current text;
                            otherwise, append the current text-->
                        <xsl:with-param name="stringSoFar" 
                            select="if ($isStartSnippet)
                                    then ($thisText || $stringSoFar) 
                                    else ($stringSoFar || $thisText)"/>
                    </xsl:next-iteration>
                </xsl:when>
                
                <xsl:otherwise>
                    <!--Otherwise, break out of the loop and output the current context string-->
                    <xsl:break>
                        <!--Figure out how many tokens we need to snag from the current text-->
                        <xsl:variable name="tokenDiff" select="1 + $kwicLengthHalf - $tokenCount"/>
                        <xsl:choose>
                            <xsl:when test="$isStartSnippet">
                                <!--We need to see if there's a space before the token we care about:
                                    (there often is, but that is removed when we tokenized above) -->
                                <xsl:variable name="endSpace" 
                                    select="if (matches($thisText,'\s$')) then ' ' else ()"
                                    as="xs:string?"/>
                                <!--Get all of the tokens that we want from the string by:
                                    * Reverse the current tokens,
                                    * Getting the subset of tokens we need to hit the limit
                                    * And then reversing that sequence of tokens again.
                                -->
                                <xsl:variable name="newTokens" 
                                    select="reverse(subsequence(reverse($tokens), 1, $tokenDiff))"
                                    as="xs:string*"/>
                                <!--Return the string: we know we have to add the truncation string here too-->
                                <xsl:sequence 
                                    select="$kwicTruncateString || string-join($newTokens,' ') || $endSpace || $stringSoFar "/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!--Otherwise, we're going left to right, which is simpler
                                    to handle: the same as above, but with no reversing -->
                                <xsl:variable name="startSpace" 
                                    select="if (matches($thisText,'^\s')) then ' ' else ()"
                                    as="xs:string?"/>
                                <xsl:variable name="newTokens" 
                                    select="subsequence($tokens, 1, $tokenDiff)" 
                                    as="xs:string*"/>
                                <xsl:sequence
                                    select="$stringSoFar || $startSpace || string-join($newTokens,' ') || $kwicTruncateString"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:break>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:iterate>
    </xsl:function>
    

    <xd:doc>
        <xd:desc><xd:ref name="hcmc:returnWeight" type="function">hcmc:returnWeight</xd:ref> returns the
        weight of a span based off of the first ancestor's weight by using the accumulator. Since we do this
        a number of times, we cache the result.</xd:desc>
        <xd:param name="span">The span element for which to retrieve the weight.</xd:param>
        <xd:return>The value of the span's weight derived from the ancestor or, if no ancestor, then 1.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:returnWeight" as="xs:integer" new-each-time="no">
        <xsl:param name="span" as="element(span)"/>
        <xsl:sequence select="$span/accumulator-before('weight')[last()]"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:getContextNodes">hcmc:getContextNodes</xd:ref> returns all of the descendant text nodes
        for a context item; since context items can nest, however, this function checks to make sure that every nodes'
        context ancestor is the desired context. Note that this function is cached, since it's called many times.</xd:desc>
        <xd:param name="contextEl">The context element.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getContextNodes" as="node()*" new-each-time="no">
        <xsl:param name="contextEl" as="element()"/>
        <!--TODO: Remove if we no longer use accumulator-->
       <!-- <xsl:sequence select="$contextEl/descendant::text()[accumulator-before('context')[last()][. is $contextEl]]"/>-->
        <xsl:sequence select="$contextEl/descendant::text()[ancestor::*[@ss-ctx][1][. is $contextEl]]"/>
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
        <xsl:variable name="thisDocSpans" select="$thisDoc//span[@ss-stem]" as="element(span)*"/>
        <!--We tokenize these since there can be multiple stems for a given span-->
        <xsl:variable name="thisDocStems" select="for $span in $thisDocSpans return tokenize($span/@ss-stem,'\s+')" as="xs:string+"/>
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
        <!--Filter regex-->
        <xsl:variable name="filterRex"
            select="'(^|\s+)staticSearch_(desc|num|bool|date|feat)(\s+|$)'"
            as="xs:string"/>
        
      <xsl:variable name="ssMetas" 
        select="$tokenizedDocs//meta[matches(@class,$filterRex)][not(ancestor-or-self::*[@ss-excld])]"
        as="element(meta)*"/>
      
        
        <xsl:for-each-group select="$ssMetas" group-by="tokenize(@class,'\s+')[matches(.,$filterRex)]">
            <!--Get the class for the filter (staticSearch_desc, staticSearch_num, etc)-->
            <xsl:variable name="thisFilterClass" 
                select="current-grouping-key()"
                as="xs:string"/>
            
            <!--Stash the group of metas for this filter type-->
            <xsl:variable name="currentMetas"
                select="current-group()"
                as="element(meta)*"/>
            
            <!--Get the base type for the filter (desc, num, etc)-->
            <xsl:variable name="thisFilterType"
                select="replace($thisFilterClass, $filterRex, '$2')"
                as="xs:string"/>
            
            <!--Now create the filter type id (ssDesc, ssNum, etc)-->
            <xsl:variable name="thisFilterTypeId"
                select="'ss' || upper-case(substring($thisFilterType, 1,1)) || substring($thisFilterType, 2)"
                as="xs:string"/>
            
            <!--Now group the current metas by their name-->
            <xsl:for-each-group select="$currentMetas" group-by="normalize-space(@name)">
                
                <!--Get all of the current named filters-->
                <xsl:variable name="thisFilterMetas" 
                    select="current-group()"
                    as="element(meta)*"/>
                
                <!--Get the current name for this filter-->
                <xsl:variable name="thisFilterName" 
                    select="current-grouping-key()"
                    as="xs:string"/>
                
                <!--Get the filter position (which is arbitrary) since we do the sorting below -->
                <xsl:variable name="thisFilterPos" 
                    select="position()" 
                    as="xs:integer"/>
                
                <!--Construct the filter id-->
                <xsl:variable name="thisFilterId"
                    select="$thisFilterTypeId || $thisFilterPos"
                    as="xs:string"/>
                
                <!--Now start constructing the map for each meta by name-->
                <xsl:variable name="tmpMap" as="element(j:map)">
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <string key="filterId"><xsl:value-of select="$thisFilterId"/></string>
                        <string key="filterName"><xsl:value-of select="$thisFilterName"/></string>
                        
                        <!--Now fork on filter types and call the respective functions-->
                        <xsl:choose>
                            <xsl:when test="$thisFilterType = ('desc', 'feat')">
                                <xsl:sequence select="hcmc:createDescFeatFilterMap($thisFilterMetas, $thisFilterId)"/>
                            </xsl:when>
                            <xsl:when test="$thisFilterType = 'date'">
                                <xsl:sequence select="hcmc:createDateFilterMap($thisFilterMetas, $thisFilterId)"/>
                            </xsl:when>
                            <xsl:when test="$thisFilterType = 'num'">
                                <xsl:sequence select="hcmc:createNumFilterMap($thisFilterMetas, $thisFilterId)"/>
                            </xsl:when>
                            <xsl:when test="$thisFilterType = 'bool'">
                                <xsl:sequence select="hcmc:createBoolFilterMap($thisFilterMetas, $thisFilterId)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>WARNING: Unknown filter type: <xsl:value-of select="$thisFilterType"/></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </map>
                </xsl:variable>
                <!--Now output the JSON-->
                <xsl:result-document href="{$outDir || '/filters/' || $thisFilterId || $versionString || '.json'}" method="text">
                    <xsl:value-of select="xml-to-json($tmpMap, map{'indent': $indentJSON})"/>
                </xsl:result-document>
                
            </xsl:for-each-group>
        </xsl:for-each-group>
    </xsl:template>
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:createDescFeatFilterMap" type="function">hcmc:createDescFeatFilterMap</xd:ref>
            creates the content for each ssDesc or ssFeature filter map by associating each unique ssDesc|ssFeature value with the
            set of documents to which it corresponds.</xd:desc>
        <xd:param name="metas">All of the meta tags for a particular ssDesc or ssFeature filter (i.e. meta name="Document Type")</xd:param>
        <xd:param name="filterIdPrefix">The id for that filter (ssDesc1 or ssFeature1)</xd:param>
        <xd:return>A sequence of maps for each value:
            ssDesc1_1: {
            name: 'Poem',
            sortKey: 'Poem',
            docs: ['doc1', 'doc2', 'doc10']
            },
            ssDesc1_2: {
            name: 'Novel',
            sortKey: 'Novel',
            docs: ['doc3', 'doc4']
            }
        </xd:return>
    </xd:doc>
    <xsl:function name="hcmc:createDescFeatFilterMap" as="element(j:map)+">
        <xsl:param name="metas" as="element(meta)+"/>
        <xsl:param name="filterIdPrefix" as="xs:string"/>
        
        <xsl:for-each-group select="$metas" group-by="xs:string(@content)">
            <xsl:variable name="thisName"
                select="current-grouping-key()"
                as="xs:string"/>
            <xsl:variable name="thisPosition"
                select="position()"
                as="xs:integer"/>
            <xsl:variable name="filterId" 
                select="$filterIdPrefix || '_' || $thisPosition" 
                as="xs:string"/>
            <xsl:variable name="declaredSortKey"
                select="current-group()[@data-ssfiltersortkey][1]/@data-ssfiltersortkey"
                as="xs:string?"/>
            <xsl:variable name="currMetas" select="current-group()" as="element(meta)+"/>
            
            <map key="{$filterId}" xmlns="http://www.w3.org/2005/xpath-functions">
                <string key="name"><xsl:value-of select="$thisName"/></string>
                <string key="sortKey">
                    <xsl:value-of select="if (exists($declaredSortKey)) then $declaredSortKey else $thisName"/>
                </string>
                <array key="docs">
                    <xsl:for-each-group select="$currMetas" group-by="string(ancestor::html/@data-staticSearch-relativeUri)">
                        <string><xsl:value-of select="current-grouping-key()"/></string>
                    </xsl:for-each-group>
                </array>
            </map>
        </xsl:for-each-group>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:createBoolFilterMap" type="function">hcmc:createBoolFilterMap</xd:ref>
            creates the content for each ssBool filter map by associating each unique ssBool value with the
            set of documents to which it corresponds.</xd:desc>
        <xd:param name="metas">All of the meta tags for a particular ssBool filter (i.e. meta name="Discusses animals?")</xd:param>
        <xd:param name="filterIdPrefix">The id for that filter (ssBool1)</xd:param>
        <xd:return>A sequence of maps for each value:
            ssBool1_1: {
            value: 'true',
            docs: ['doc1','doc2']
            }
            ssBool1_2: {
            value: 'false',
            docs: ['doc3']
            }
        </xd:return>
    </xd:doc>
    <xsl:function name="hcmc:createBoolFilterMap" as="element(j:map)+">
        <xsl:param name="metas" as="element(meta)+"/>
        <xsl:param name="filterIdPrefix" as="xs:string"/>
        
        <xsl:for-each-group select="$metas" group-by="hcmc:normalize-boolean(@content)">
            
            <!--We have to sort these descending so that we reliably get true followed by false. -->
            <xsl:sort select="current-grouping-key()" order="descending"/>
            
            <xsl:variable name="thisValue"
                select="current-grouping-key()"
                as="xs:string"/>
            <xsl:variable name="thisPosition"
                select="position()"
                as="xs:integer"/>
            <xsl:variable name="filterId" 
                select="$filterIdPrefix || '_' || $thisPosition" 
                as="xs:string"/>
            <xsl:variable name="currMetas" 
                select="current-group()"
                as="element(meta)+"/>
            
            <!--If there under two categories, and we're grouping, then we have a lopsided boolean-->
            <xsl:if test="last() lt 2">
                <xsl:message><xsl:value-of select="$filterId"/> only contains <xsl:value-of select="$thisValue"/>.</xsl:message>
            </xsl:if>
            
            <map key="{$filterId}" xmlns="http://www.w3.org/2005/xpath-functions">
                <string key="value"><xsl:value-of select="$thisValue"/></string>
                <array key="docs">
                    <xsl:for-each-group select="$currMetas" group-by="string(ancestor::html/@data-staticSearch-relativeUri)">
                        <string><xsl:value-of select="current-grouping-key()"/></string>
                    </xsl:for-each-group>
                </array>
            </map>
        </xsl:for-each-group>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:createDateFilterMap" type="function">hcmc:createDateFilterMap</xd:ref>
            creates the content for each ssDate filter map.</xd:desc>
        <xd:param name="metas">All of the meta tags for a particular ssDate filter (i.e. meta name="Date of Publication")</xd:param>
        <xd:param name="filterIdPrefix">The id for that filter (ssDate1)</xd:param>
        <xd:return>A map organized by document:
            {
            doc1: ['1922'],
            doc2: ['1923','1924'] //Represents a range
            }
        </xd:return>
    </xd:doc>
    <xsl:function name="hcmc:createDateFilterMap" as="element(j:map)">
        <xsl:param name="metas" as="element(meta)+"/>
        <xsl:param name="filterIdPrefix" as="xs:string"/>
        <map key="docs" xmlns="http://www.w3.org/2005/xpath-functions">
            <xsl:for-each-group select="$metas" group-by="string(ancestor::html/@data-staticSearch-relativeUri)">
                <xsl:variable name="docUri" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="metasForDoc" select="current-group()" as="element(meta)+"/>
                <array key="{$docUri}">
                    <xsl:for-each select="$metasForDoc">
                        <!--Split the date on slashes, which represent a range of dates-->
                        <!--TODO: Verify that there are proper dates here-->
                        <xsl:for-each select="tokenize(@content,'/')">
                            <string><xsl:value-of select="."/></string>
                        </xsl:for-each>
                    </xsl:for-each>
                </array>
            </xsl:for-each-group>
        </map>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:createNumFilterMap" type="function">hcmc:createNumFilterMap</xd:ref>
            creates the content for each ssNum filter map by creating a single map, which associates each document
            with an array of values that it satisfies.</xd:desc>
        <xd:param name="metas">All of the meta tags for a particular ssNum filter (i.e. meta name="Word count")</xd:param>
        <xd:param name="filterIdPrefix">The id for that filter (ssNum1)</xd:param>
        <xd:return>A map organized by document:
            {
            doc1: ['130'],
            doc2: ['2490']
            }
        </xd:return>
    </xd:doc>
    <xsl:function name="hcmc:createNumFilterMap" as="element(j:map)">
        <xsl:param name="metas" as="element(meta)+"/>
        <xsl:param name="filterIdPrefix" as="xs:string"/>
        <map key="docs" xmlns="http://www.w3.org/2005/xpath-functions">
            <xsl:for-each-group select="$metas" group-by="string(ancestor::html/@data-staticSearch-relativeUri)">
                <xsl:variable name="docUri" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="metasForDoc" select="current-group()" as="element(meta)+"/>
                <array key="{$docUri}">
                    <xsl:for-each-group select="current-group()[@content castable as xs:decimal]" group-by="xs:decimal(@content)">
                        <string><xsl:value-of select="xs:decimal(current-grouping-key())"/></string>
                    </xsl:for-each-group>
                </array>
            </xsl:for-each-group>
        </map>
    </xsl:function>
    
    
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
                            an empty string or nothing if there isn't. -->
                            <xsl:sequence select="hcmc:getDocThumbnail(.)"/>
                            <xsl:sequence select="hcmc:getDocSortKey(.)"/>
                        </array>
                    </xsl:for-each>
                </map>
            </xsl:variable>
            <xsl:sequence select="xml-to-json($map, map{'indent': $indentJSON})"/>
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
        <xd:result>A string title, derived from the document's actual title, a configured document title,
            or the document's @id if all else fails.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocTitle" as="xs:string">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:variable name="defaultTitle" select="normalize-space(string-join($doc//head/title[1]/descendant::text(),''))" as="xs:string?"/>
        <xsl:variable name="docTitle" 
            select="$doc/head/meta[@name='docTitle'][contains-token(@class,'staticSearch_docTitle')][not(@ss-excld)]"
            as="element(meta)*"/>
        <xsl:choose>
            <xsl:when test="exists($docTitle)">
                <xsl:if test="count($docTitle) gt 1">
                    <xsl:message>WARNING: Multiple docTitles declared in <xsl:value-of select="$doc/@data-staticSearch-relativeUri"/>. Using <xsl:value-of select="$docTitle[1]/@content"/></xsl:message>
                </xsl:if>
                <xsl:value-of select="normalize-space($docTitle[1]/@content)"/>
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
        <xd:result>A j:string element, if there is a configured graphic, or an empty string if there is a subsequent sort key, or the empty
            sequence if not. We return the empty string in the 
        second case so that the sort key ends up at the right 
        position in the array.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocThumbnail" as="element(j:string)?">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:variable name="docImage" select="$doc/head/meta[@name='docImage'][contains-token(@class,'staticSearch_docImage')][not(@ss-excld)]" 
            as="element(meta)*"/>
        <xsl:variable name="docSortKey" 
            select="$doc/head/meta[@name='docSortKey'][contains-token(@class,'staticSearch_docSortKey')][not(@ss-excld)]" 
            as="element(meta)*"/>
        <xsl:choose>
            <xsl:when test="exists($docImage)">
                <xsl:if test="count($docImage) gt 1">
                    <xsl:message>WARNING: Multiple docImages declared in <xsl:value-of select="$doc/@data-staticSearch-relativeUri"/>. Using <xsl:value-of select="$docImage[1]/@content"/></xsl:message>
                </xsl:if>
                <j:string><xsl:value-of select="$docImage[1]/@content"/></j:string>
            </xsl:when>
            <xsl:when test="exists($docSortKey)">
                <j:string></j:string>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:getDocSortKey" type="function">hcmc:getDocSortKey</xd:ref> 
            generates a j:string element containing a string read
            from the meta[@name='ssDocSortKey'] element if there
            is one, or the empty sequence if not.</xd:desc>
        <xd:param name="doc">The input document, which must be an HTML element.</xd:param>
        <xd:result>A j:string element, if there is a configured sort key, or the empty sequence.</xd:result>
    </xd:doc>
    <xsl:function name="hcmc:getDocSortKey" as="element(j:string)?">
        <xsl:param name="doc" as="element(html)"/>
        <xsl:variable name="docSortKey" 
            select="$doc/head/meta[@name='docSortKey'][contains-token(@class,'staticSearch_docSortKey')][not(@ss-excld)]" 
            as="element(meta)*"/>
        <xsl:if test="exists($docSortKey)">
            <xsl:if test="count($docSortKey) gt 1">
                <xsl:message>WARNING: Multiple docSortKeys declared in <xsl:value-of select="$doc/@data-staticSearch-relativeUri"/>. Using <xsl:value-of select="$docSortKey[1]/@content"/></xsl:message>
            </xsl:if>
            <j:string><xsl:value-of select="$docSortKey[1]/@content"/></j:string>
        </xsl:if>
    </xsl:function>
    
    
</xsl:stylesheet>
