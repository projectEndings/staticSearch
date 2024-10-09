<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:ss="http://hcmc.uvic.ca/ns/ssStemmer"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 26, 2019</xd:p>
            <xd:p><xd:b>Updated on:</xd:b> November 16, 2023</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
            <xd:p>This transformation takes as input one of the collection of documents specified in
                the configuration file and creates the temporary tokenized and stemmed output HTML
                files to create the JSON indexes.</xd:p>
            <xd:p>The document is run through a chain of templates to create a version that contains
                all of the necessary information for the creation of the JSON indexes. These
                modified documents are then output into a temporary directory (removed at the end of
                the ANT build).</xd:p>
            <xd:p>Note that these templates are contingent on <xd:a href="config.xsl">config.xsl</xd:a>,
                which is a generated file that contains templates that
                correspond to rules specified in the configuration file.</xd:p>
            <xd:p>Where older versions of staticSearch performed transformations in 6 passes, as of
                staticSearch 2.0, this transformation processes a document thrice:</xd:p>
            <xd:ol>
                <xd:li>
                    <xd:p>First, the document is passed through the <xd:b>decorate</xd:b> templates.
                        These templates rely on the priority attribute and
                        <xd:pre>xsl:next-match</xd:pre> and process each element multiple times,
                        accumulating data (e.g. weight, ignore, contexts, et cetera) using the
                        tunneled <xd:ref name="DATA" type="param">$data</xd:ref> parameter.</xd:p>
                    <xd:p>The highest priority templates are located in <xd:a ref="tokenize.xsl"
                            >this file</xd:a>; the template with highest priority (<xd:ref
                            name="PRIORITY_FIRST" type="variable">$PRIORITY_FIRST</xd:ref>) just
                        matches all elements and initializes the data map. Templates with the second
                        highest priority (<xd:ref name="PRIORITY_SECOND" type="variable"
                            >$PRIORITY_SECOND</xd:ref>) are those that are understood to be default
                        configurations; for instance, we presume that all xhtml:script and
                        xhtml:style elements should be given a weight of 0 and thus removed
                        entirely. These templates are meant to be overridden by the lower priority
                        templates that derive from the user-supplied configuration (in <xd:a
                            href="config.xsl">config.xsl</xd:a>, but are generated via <xd:a
                            href="create_config_xsl.xsl">create_config.xsl</xd:a>).</xd:p>
                    <xd:p>The final template in the process (<xd:ref name="hcmc:last"
                            type="template">hcmc:last</xd:ref>) evaluates the accumulated data and
                        determines how to process the element (whether it ought to be deleted
                        entirely, ignored, or decorated with the attributes necessary to create the
                        stem files (cf. <xd:a href="json.xsl">json.xsl</xd:a>).</xd:p>
                </xd:li>
                <xd:li><xd:b>tokenize</xd:b>: Tokenizes the decorated file on word boundaries, wraps each word
                    in a span element, and adds a @data-ss-stem for that term. This is the bulk of
                    the process.</xd:li>
                <xd:li><xd:b>enumerate</xd:b>: A final pass on the tokenized document, which adds a
                    position for each stem and any other document-specific information necessary for
                    the JSON step.</xd:li>
            </xd:ol>
        </xd:desc>
    </xd:doc>
    
    
    <!--**************************************************************
       *                                                            *
       *                         Includes                           *
       *                                                            *
       **************************************************************-->    
    
    <xd:doc>
        <xd:desc>Include the configuration file, which is generated 
            via <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a>.
            The stemmer XSLT is included in the config.</xd:desc>
    </xd:doc>
    <xsl:include href="config.xsl"/>
    
    <xd:doc>
        <xd:desc>Include the global functions file.</xd:desc>
    </xd:doc>
    <xsl:include href="functions.xsl"/>
    
    <xsl:mode name="decorate" warning-on-multiple-match="no" on-no-match="shallow-copy"/>
    <xsl:mode name="tokenize" on-no-match="shallow-copy"/>
    <xsl:mode name="enumerate" on-no-match="shallow-copy"/>
    
    <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->    
    
    <xd:doc>
        <xd:desc>Output method that specifies that the output HTML files are
        not indented (important to ensure that the output formatting does not
        unwittingly break the input formatting) and that the output is XML.</xd:desc>
    </xd:doc>
    <xsl:output indent="no" method="xml"/>
    
    
    <!--**************************************************************
       *                                                            *
       *                         Variables                          *
       *                                                            *
       **************************************************************-->  
    
    <xd:doc>
        <xd:desc>A simple regex to match (x)?htm(l)? document URIs.</xd:desc>
    </xd:doc>
    <xsl:variable name="docRegex">(.+)(\..?htm.?$)</xsl:variable>

     <xd:doc>
         <xd:desc>Regex to match words that are numeric with a decimal</xd:desc>
     </xd:doc>
    <xsl:variable name="numericWithDecimal">[<xsl:value-of select="string-join($allApos,'')"/>\d]+([\.,]?\d+)</xsl:variable>
    
    <xd:doc>
        <xd:desc>Regex to match alphanumeric words. Note that we use 
        Unicode character classes to take our best shot at splitting on
        word boundaries, but this is bound to be fragile where multiple
        languages are involved. NOTE: character U+A78F is introduced explicitly,
        although it should be covered by \p{L}, because of an apparent bug in
        Java or Saxon regex processing; see GH issue #200.</xd:desc>
    </xd:doc>
  <xsl:variable name="alphanumeric">[&#xA78F;\p{L}\p{M}\p{Pc}<xsl:value-of select="string-join($allApos,'')"/>]+</xsl:variable>
    
    <xd:doc>
        <xd:desc>Regex to match hyphenated words</xd:desc>
    </xd:doc>
    <xsl:variable name="hyphenatedWord">(<xsl:value-of select="$alphanumeric"/>-<xsl:value-of select="$alphanumeric"/>(-<xsl:value-of select="$alphanumeric"/>)*)</xsl:variable>
    
    
    <xd:doc>
        <xd:desc>All of the above word regexes, strung together to match all
        possible words.</xd:desc>
    </xd:doc>
    <xsl:variable name="tokenRegex">(<xsl:value-of select="string-join(($numericWithDecimal,$hyphenatedWord,$alphanumeric),'|')"/>)</xsl:variable>

    
    <xd:doc>
        <xd:desc>The identifier for the document within staticSearch; this is
                just the relative URI with all of punctuation that could conceivably
                be in filenames converted to underscores.</xd:desc>
    </xd:doc>
    <xsl:variable name="searchIdentifier"
        select="replace($relativeUri,'^(/|\\)','') => 
        replace('\.x?html?$','') => 
        replace('\s+|\\|/|\.','_')" 
        as="xs:string"/>
    
    <!--**************************************************************
       *                                                            *
       *                         Root template                      *
       *                                                            *
       **************************************************************-->  
    <xd:doc>
        <xd:desc>Root/driver template.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        
        <!--Call the "echoParams" template in the config file,
            which just outputs all parameters when verbose is true-->
        <xsl:call-template name="echoParams"/>
        
        <!--Store the results from the #decorate templates -->
        <xsl:variable name="decorated">
            <xsl:apply-templates select="/" mode="decorate"/>
        </xsl:variable>
        <!--Check to see if the root element is excluded; if it is,
            then we can just skip this step entirely; if it isn't,
            then process the document.-->
        <xsl:if test="not(root($decorated)/*[@ss-excld])">
            <!--Now tokenize the document-->
            <xsl:variable name="tokenizedDoc">
                <xsl:apply-templates select="$decorated" mode="tokenize">
                    <xsl:with-param name="currDocUri" select="$uri" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!--And then finally add positions to the tokenized document-->
            <xsl:apply-templates select="$tokenizedDoc" mode="enumerate"/>
        </xsl:if>
        <!--For debugging purposes only: Output the decorated version
            of the document (and any others)-->
        <xsl:if test="$verbose">
            <!--Stash all of the documents we want to output into a map so we can simply
                    iterate through them-->
            <xsl:variable name="outputMap" select="map{
                'decorated': $decorated
                }"/>
            <!--Iterate through the keys, which are the filenames-->
            <xsl:for-each select="map:keys($outputMap)">
                <xsl:result-document href="{replace(current-output-uri(),'_tokenized',('_' || .))}">
                    <xsl:message>Creating <xsl:value-of select="current-output-uri()"/></xsl:message>
                    <xsl:copy-of select="map:get($outputMap, .)"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    
    <!--**************************************************************
       *                                                            *
       *                    Templates: decorate                     *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Highest priority template, which sets up an empty
            data map to hold accumulated values to tunnel through
            each element.</xd:desc>
    </xd:doc>
    <xsl:template match="*" _priority="{$PRIORITY_FIRST}" mode="decorate">
        <xsl:next-match>
            <xsl:with-param name="data" tunnel="yes" as="map(*)">
                <xsl:map>
                    <xsl:map-entry key="$KEY_WEIGHTS" select="()"/>
                    <xsl:map-entry key="$KEY_CONTEXTS" select="()"/>
                    <xsl:map-entry key="$KEY_CONTEXT_IDS" select="()"/>
                    <xsl:map-entry key="$KEY_EXCLUDES" select="()"/>
                </xsl:map>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template (added for release 1.4) to catch any instance of 
            @data-ssFilterSortKey, which should be @data-ssfiltersortkey per the 
            XHTML spec. This should be deprecated for version 1.4 and by invalid for
            1.5.</xd:desc>
    </xd:doc>
    <xsl:template match="@data-ssFilterSortKey"       
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:message terminate="yes">ERROR: @data-ssFilterSortKey is deprecated. Use @data-ssfiltersortkey (all lowercased) instead. (<xsl:value-of select="$relativeUri"/>)</xsl:message>
        <xsl:next-match/>
    </xsl:template>

    <xd:doc>
        <xd:desc>All html head elements should
        remain a context, since they contain crucial information.</xd:desc>
    </xd:doc>
    <xsl:template match="html/head"        
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_CONTEXTS"/>
            <xsl:with-param name="value" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Basic template to strip away extraneous tags around elements that won't affect indexing in any way.
        Note that this template is overriden by templates in the configuration file if they have been specified
        as important for weighting or contextualizing.</xd:desc>
    </xd:doc>
    <xsl:template match="span | em | b | i | a"     
        _priority="{$PRIORITY_SECOND}" mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_CONTEXTS"/>
            <xsl:with-param name="value" select="false()"/>
        </xsl:call-template>
    </xsl:template>

    
    <xd:doc>
        <xd:desc>Template to match all block-like elements that we assume are contexts by default.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="body | div | blockquote | p | li | section | article | nav | h1 | h2 | h3 | h4 | h5 | h6 | td | details | summary | table/caption"
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_CONTEXTS"/>
            <xsl:with-param name="value" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Default weighting template that specifies that all headings have a weight
            of 2. Note that the other weighting templates are contained within the 
            generated configuration file and will override this one, if necessary.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="*[matches(local-name(),'^h\d$')]" 
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_WEIGHTS"/>
            <xsl:with-param name="value" select="2"/>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template that simply deletes the word break opportunity (wbr) element,
            since it is specifically not word breaking.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="wbr"   
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_WEIGHTS"/>
            <xsl:with-param name="value" select="0"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>Template to retain all important meta information.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="head/title | head/meta[matches(@class,'staticSearch')] | head/meta[matches(@content,'charset')] | head/meta[@charset]"
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:copy"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to delete script elements in the body, since they
            will never contain information that should be indexed.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="script | link"
        _priority="{$PRIORITY_SECOND}"
        mode="decorate">
        <xsl:call-template name="hcmc:updateData">
            <xsl:with-param name="caller" select="'tokenize#decorate'"/>
            <xsl:with-param name="key" select="$KEY_WEIGHTS"/>
            <xsl:with-param name="value" select="0"/>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to remove all unnecessary attributes from the document to make
            processing more efficient; since the contextualization step is the final step
            before tokenizing, most of the elements attributes are unimportant by this point
            since any configuration based off of these attributes has already been handled
            by a previous template pass.</xd:desc>
    </xd:doc>
    <xsl:template 
        match="*[not(self::meta)]/@*" 
        _priority="{$PRIORITY_SECOND}" 
        mode="decorate">
        <xsl:choose>
            <xsl:when test="local-name()=('id','lang')">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="matches(local-name(),'^(data-)?(staticSearch|ss)-')">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to convert all self closing elements--except for the wbr element (processed below)--into
            single spaces since we assume that they are word boundary marking, unless otherwise specified</xd:desc>
        <xd:param name="data" tunnel="yes">The data map, which is 
        necessary for evaluating whether this element can safely be converted into a space.</xd:param>
    </xd:doc>
    <xsl:template 
        match="br | hr | area | base | col | embed | hr | img | input | link[ancestor::body] | meta[ancestor::body] | param | source | track"
        _priority="{$PRIORITY_FOURTH}"
        mode="decorate">
        <xsl:param name="data" tunnel="yes" as="map(*)"/>
        <xsl:choose>
            <xsl:when test="some $key in map:keys($data) satisfies not(empty($data($key)))">
                <xsl:next-match/>
            </xsl:when> 
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!--**************************************************************
       *                                                            *
       *                    Templates: tokenize                     *
       *                                                            *
       **************************************************************--> 
    <xd:doc>
        <xd:desc>If some element has been excluded, then don't process it any further.</xd:desc>
    </xd:doc>
    <xsl:template match="*[@ss-excl]" mode="tokenize">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Matches the staticSearch_docImage URL so that the URL is relative to the search file, not the containing document.</xd:desc>
    </xd:doc>
    <xsl:template match="meta[contains-token(@class,'staticSearch_docImage')]/@content[not(matches(.,'^https?'))]" mode="tokenize">
        <xsl:variable name="absPath" as="xs:string" select="resolve-uri(., $uri)"/>
        <xsl:variable name="newRelPath" as="xs:string" select="hcmc:makeRelativeUri($searchFile, $absPath)"/>
        <xsl:attribute name="content" select="$newRelPath"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Checks docImage, docTitle, and docSortKey metas to make sure that they have matching values. </xd:desc>
    </xd:doc>
    <xsl:template match="meta[@name or @class][not(@ss-excld)]" mode="tokenize">
        <xsl:variable name="currMeta" select="."/>
        <!--Process the meta no matter what-->
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
        <!--But check to see if it's a candidate for checking--> 
        <xsl:if test="($currMeta/@name = $docMetas) or (some $meta in $docMetas satisfies matches($currMeta/@class, $meta))">
            <!--Iterate through them all in case there's a name/class mixup (i.e. docTitle with class staticSearch_docSortKey or something)-->
            <xsl:for-each select="$docMetas">
                <xsl:variable name="thisDocMeta" select="." as="xs:string"/>
                <xsl:variable name="thisDocMetaClass" select="'staticSearch_' || $thisDocMeta" as="xs:string"/>
                <xsl:variable name="hasName" select="exists($currMeta[@name = $thisDocMeta])" as="xs:boolean"/>
                <xsl:variable name="hasClass" select="exists($currMeta[contains-token(@class, $thisDocMetaClass)])" as="xs:boolean"/>
                <!--Has the name or a class, but not both, raise a warning.-->
                <xsl:if test="($hasName or $hasClass) and not($hasName and $hasClass)">
                    <xsl:message>WARNING: Bad meta tag in <xsl:value-of select="$currMeta/ancestor::html/@ss-uri"/> (<xsl:value-of select="'name: ' || $currMeta/@name || '; class=' || $currMeta/@class"/>). All <xsl:value-of select="$thisDocMeta"/> meta tags must have matching @name="<xsl:value-of select="$thisDocMeta"/>" and @class="<xsl:value-of select="$thisDocMetaClass"/>".</xsl:message>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
     <xd:doc>
         <xd:desc>Main tokenizing template: Match all text nodes that:
          * Are contained within the body element
          * Are not entirely whitespace
          * Are not descendant of an excluded element.
         </xd:desc>
     </xd:doc>
    <xsl:template match="text()[ancestor::body][matches(.,'\S')][not(ancestor::*[@ss-excld])]" mode="tokenize">
        
        <!--Stash the current node so that we can retain its context in later steps-->
        <xsl:variable name="currNode" select="."/>
        
        <!--Analyze the string and find all things we consider tokens-->
        <xsl:analyze-string select="." regex="{$tokenRegex}">
            <xsl:matching-substring>
                <!--If we've found a token, start the stemming process!-->
                <xsl:copy-of select="hcmc:startStemmingProcess(.)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Otherwise, just return the string-->
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>


    <xd:doc>
        <xd:desc><xd:ref name="hcmc:startStemmingProcessing">hcmc:startStemmingProcess</xd:ref> determines whether
        or not the token should be indexed based off a set of rules as described in hcmc:shouldIndex, and processes
        it if it should be. Since this is deterministic, we set @new-each-time to no.</xd:desc>
        <xd:param name="word">The input word token.</xd:param>
        <xd:return>One or more items: this could be a span, a text node, or a string.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:startStemmingProcess" new-each-time="no" as="item()+">
        <xsl:param name="word" as="xs:string"/>
        
        <!--If we're in verbose mode, then return the word-->
        <xsl:message use-when="$verbose">$word: <xsl:value-of select="$word"/></xsl:message>


        <!--Clean the word for stemming-->
        <xsl:variable name="wordToStem" select="hcmc:cleanWordForStemming($word)"/>
        <xsl:message use-when="$verbose">$wordToStem: <xsl:value-of select="$wordToStem"/></xsl:message>
        
        <!--Return it as a lowercase word-->
        <xsl:variable name="lcWord" select="lower-case($wordToStem)"/>
        <xsl:message use-when="$verbose">$lcWord: <xsl:value-of select="$lcWord"/></xsl:message>
        
        
        <!--Determine whether or not it should be indexed-->
        <xsl:variable name="shouldIndex" select="hcmc:shouldIndex($lcWord)"/>
        <xsl:message use-when="$verbose">$shouldIndex: <xsl:value-of select="$shouldIndex"/></xsl:message>
        
        <xsl:choose>
            <!--If it should, then create the stem for it-->
            <xsl:when test="$shouldIndex">
                <xsl:copy-of select="hcmc:getStem($word)"/>
            </xsl:when>
            
            <!--Otherwise, return the word as text-->
            <xsl:otherwise>
                <xsl:value-of select="$word"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
  

    <xd:doc>
        <xd:desc><xd:ref name="hcmc:getStem">hcmc:getStem</xd:ref> takes the the word string and creates
        a span element with a set of attributes for use by the JSON indexing process.</xd:desc>
        <xd:param name="word">The *original* word to stem.</xd:param>
        <xd:return>A span element, furnished with a variety of attributes for use in the indexing process, that contains the original word.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:getStem" as="element(span)">
        <xsl:param name="word" as="xs:string"/>

        <xsl:message use-when="$verbose">hcmc:getStem: $word: <xsl:value-of select="$word"/></xsl:message>
        
        
        <!--Get the cleaned word again, since we're using the ORIGINAL word here, not the cleaned word
        we used to determine the word's stemmability in hcmc:startStemmingProcess -->
        <xsl:variable name="cleanedWord" select="hcmc:cleanWordForStemming($word)" as="xs:string"/>
        <xsl:message use-when="$verbose">hcmc:getStem: $cleanedWord: <xsl:value-of select="$cleanedWord"/></xsl:message>
        
        
        <!--Make it lowercase-->
        <xsl:variable name="lcWord" select="lower-case($cleanedWord)" as="xs:string"/>
        <xsl:message use-when="$verbose">hcmc:getStem: $lcWord: <xsl:value-of select="$lcWord"/></xsl:message>
        
        
        <!--Determine whether or not the word has a digit in it; if it does, then the word shouldn't be put
        through the stemmer-->
        <xsl:variable name="containsDigit" select="matches($cleanedWord,'\d+')" as="xs:boolean"/>
        <xsl:message use-when="$verbose">hcmc:getStem: $containsDigit: <xsl:value-of select="$containsDigit"/></xsl:message>
        
        
        <!--Check whether or not the word is hyphenated-->
        <xsl:variable name="hyphenated" select="matches($cleanedWord,'[A-Za-z]-[A-Za-z]')" as="xs:boolean"/>
        <xsl:message use-when="$verbose">hcmc:getStem: $hyphenated: <xsl:value-of select="$hyphenated"/></xsl:message>
        
        
        <!--Now create the stem val-->
        <xsl:variable name="stemVal" 
            select="if ($containsDigit) then $lcWord else ss:stem($lcWord)"
            as="xs:string?"/>
        <xsl:message use-when="$verbose">hcmc:getStem: $stemVal: <xsl:value-of select="$stemVal"/></xsl:message>
        
        
        <!--Now do stuff-->
        <!--Wrap it in a span-->
                <span>
                    <xsl:if test="not(empty($stemVal))">
                        <xsl:attribute name="ss-stem" select="$stemVal"/>
                    </xsl:if>
                    
                    <!--Fork again, in case we have a hyphenated construct-->
                    <xsl:choose>
                        
                        <!--When we have a hyphenated word, we want to split it into pieces-->
                        <xsl:when test="$hyphenated">
                            <xsl:message use-when="$verbose">hcmc:getStem: Found hyphenated construct: <xsl:value-of select="$word"/></xsl:message>
                            
                            <!--Split the word on the hyphens-->
                            <xsl:variable name="wordTokens" select="tokenize($word,'-')" as="xs:string+"/>
                            
                            <!--Now iterate through the hyphens-->
                            <xsl:for-each select="$wordTokens">
                                <xsl:variable name="thisToken" select="." as="xs:string"/>
                                <xsl:variable name="thisTokenPosition" select="position()"/>
                                
                                <!--Spit out a message if we want it-->
                                <xsl:message use-when="$verbose" expand-text="yes">hcmc:getStem: Process hyphenated segment: {$thisToken} ({$thisTokenPosition}/{count($wordTokens)})</xsl:message>
                                
                                
                                <!--Now run each hyphen through the process again, and add hyphens after each word-->
                                <xsl:sequence select="hcmc:startStemmingProcess(.)"/><xsl:if test="$thisTokenPosition ne count($wordTokens)"><xsl:text>-</xsl:text></xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                       
                        <!--If it's not hyphenated, then just plop the content back in-->
                        <xsl:otherwise>
                            <xsl:value-of select="$word"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:shouldIndex">hcmc:shouldIndex</xd:ref> returns a boolean value 
            regarding whether or not the word should be indexed. Currently the two conditions are:
            * The word must be longer than the configured minimum word length (default 3)
            * The word must not be a stopword</xd:desc>
        <xd:param name="lcWord">A lower-cased word.</xd:param>
        <xd:return>A boolean value.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:shouldIndex" as="xs:boolean">
        <xsl:param name="lcWord" as="xs:string"/>
        <xsl:sequence select="string-length($lcWord) ge xs:integer($minWordLength) and not(key('w', $lcWord, $stopwordsFileXml))"/>
    </xsl:function>


    <!--**************************************************************
       *                                                            *
       *                    Templates: enumerate                    *
       *                                                            *
       **************************************************************--> 
    
    <xd:doc>
        <xd:desc>An accumulator that matches all generated spans so that we can get its position
        in the indexing phase</xd:desc>
    </xd:doc>
    <xsl:accumulator name="stem-position" initial-value="0">
        <xsl:accumulator-rule match="span[@ss-stem]">
            <xsl:value-of select="$value + 1"/>
        </xsl:accumulator-rule>
    </xsl:accumulator>
    
    <xd:doc>
        <xd:desc>Template to match all elements with ids, which then pass its id value to
            its descendants.</xd:desc>
    </xd:doc>
    <xsl:template match="*[@id][ancestor::body]" mode="enumerate">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current">
                <xsl:with-param name="id" select="string(@id)" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>Template to determine whether or not we can remove the @ss-ctx from this
        element: if this element has other contexts declared, then we check to see if this element
        has any spans that need this context; if not, then we can delete the attribute since its superfluous.</xd:desc>
    </xd:doc>
    <xsl:template match="*[@ss-ctx][descendant::*[@ss-ctx]]/@ss-ctx" mode="enumerate">
        <xsl:variable name="parent" select="parent::*" as="element()"/>
        <xsl:variable name="spans" select="$parent/descendant::span[@ss-stem]" as="element(span)*"/>
        <!--If some span uses this element as its context ancestor, then we retain the attribute-->
        <xsl:if test="some $span in $spans satisfies $span/ancestor::*[@ss-ctx][1][. is $parent]">
            <xsl:sequence select="."/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Match all of the generated spans and add a position to 
            the element so that we can simply determine their order in 
            later processes.
        </xd:desc>
        <xd:param name="id">Tunnelled parameter that contains the nearest 
            ancestor fragment id, if it exists.</xd:param>
    </xd:doc>
    <xsl:template match="span[@ss-stem]" mode="enumerate">
        <xsl:param name="id" as="xs:string?" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="ss-pos" select="accumulator-before('stem-position')"/>
            <xsl:if test="$id">
                <xsl:attribute name="ss-fid" select="$id"/>
                <xsl:message use-when="$verbose">Found fragment id: <xsl:value-of select="$id"/></xsl:message>
            </xsl:if>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
   
</xsl:stylesheet>
