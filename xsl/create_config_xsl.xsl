<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xso="dummy"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 26, 2019</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation converts the user-supplied configuration file (config.xml) into
                  an XSLT stylesheet that can be imported throughout the process. In particular,
            the generated configuration contains:</xd:p>
            <xd:ul>
                <xd:li>Global variables and parameters that correspond to (or calculated from)
                configuration options</xd:li>
                <xd:li>Templates (derived from rules) to customize the tokenization process;
                see <xd:a href="tokenize.xsl">tokenize.xsl</xd:a> for full documentation
                on the tokenization process.</xd:li>
            </xd:ul>
          
        </xd:desc>
        <xd:param name="configFile">A URI pointing to the config XML file that will be turned into the 
        configuration XSLT.</xd:param>
        <xd:param name="buildReportFilename">A URI pointing to the staticSearch report file.</xd:param>
        <xd:param name="ssBaseDir">The basedir for staticSearch</xd:param>
        <xd:param name="ssVerbose">Flag passed from ant that describes the user set verbosity setting
            for messages in the XSLT--useful primarily for debugging.</xd:param>
    </xd:doc>
    
    <xsl:include href="constants.xsl"/>
    <xsl:include href="process_schema_for_config.xsl"/>
    
    <!--**************************************************************
        *                                                            * 
        *                         PARAMETERS                         *
        *                                                            *
        **************************************************************-->
    
    <xsl:param name="configFile" select="'config.xml'" as="xs:string"/>
    <xsl:param name="buildReportFilename" select="'staticSearch_report.html'" as="xs:string"/>
    <xsl:param name="ssVerbose" as="xs:string" select="'false'" static="yes"/>
    <xsl:param name="ssBaseDir" as="xs:string" required="yes"/>
    
    <xd:doc>
        <xd:desc>Parameter to determine if verbose xsl:messages should be enabled.</xd:desc>
    </xd:doc>
    <xsl:variable name="verbose" as="xs:boolean" 
        select="matches($ssVerbose,'^(t|true|y|yes|1)','i')" static="yes"/>
    
    
    <!--**************************************************************
        *                                                            * 
        *                         NAMESPACE ALIAS                    *
        *                                                            *
        **************************************************************-->
    
    <xd:doc>
        <xd:desc>
            <xd:p>We create a namespace alias of "xso" to create XSLT using XSLT.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl" />
    
    
    <!--**************************************************************
        *                                                            * 
        *                         VARIABLES                          *
        *                                                            *
        **************************************************************-->

    <xd:doc>
        <xd:desc><xd:ref name="configDoc" type="variable">$configDoc</xd:ref> is the configuration
            document (i.e. the URI provided by the param loaded using the document function). We are extra
            careful here to test whether or not the configuration document actually exists; if it doesn't
            then the process exits.</xd:desc>
    </xd:doc>
    <xsl:variable name="configDoc" as="document-node()">
        <xsl:choose>
            <xsl:when test="doc-available($configFile)">
                <xsl:copy-of select="document($configFile)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">ERROR: Config file <xsl:value-of select="$configFile"/> not found.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xd:doc>
        <xd:desc>Declared configuration options</xd:desc>
    </xd:doc>
    <xsl:variable name="configParams" as="map(xs:string, item()?)">
        <xsl:map>
            <xsl:for-each select="$configDoc//*:params/*/@*">
                <xsl:variable name="ident" select="local-name(parent::*) || '.' || local-name()"/>
                <xsl:variable name="value" select="string(.)" as="xs:string"/>
                <xsl:map-entry key="$ident" select="hcmc:castParam($ident, $value)"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    
    <xd:doc>
        <xd:desc>Final parameters</xd:desc>
    </xd:doc>
    <xsl:variable name="mergedParams" 
        as="map(xs:string, item()?)" 
        select="map:merge(($defaultParams, $configParams), map{'duplicates': 'use-last'})"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="configUri" type="variable">$configUri</xd:ref> is the resolved URI
        of the configuration file; this works as the base directory against which we can resolve
        any of the described URIs in the configuration file.</xd:desc>
    </xd:doc>
    <xsl:variable name="configUri" select="resolve-uri($configFile)" as="xs:anyURI"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="searchDocUri" type="variable">$searchDocUri</xd:ref> is the absolute URI
            of the search document that will be transformed (in <xd:a href="makeSearchPage.xsl">makeSearchPage.xsl</xd:a>)
            and from which we can derive the project directory.</xd:desc>
    </xd:doc>
    <xsl:variable name="searchDocUri" select="resolve-uri($mergedParams?searchPage.file, $configUri)" as="xs:anyURI"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="versionString" type="variable">$versionString</xd:ref> is the version information read from the
            versionDoc if there is one; otherwise it is an empty string.</xd:desc>
    </xd:doc>
    <xsl:variable name="versionString" as="xs:string">
        <xsl:choose>
            <xsl:when test="$mergedParams?version.file ne ''">
                <xsl:try>
                    <xsl:variable name="v" 
                        select="unparsed-text(resolve-uri($mergedParams?version.file, $configUri)) =>
                        normalize-space() =>
                        replace('\s+','_')"/>
                    <xsl:sequence select="if (starts-with($v,'_')) then $v else ('_' || $v)"/>
                    <xsl:catch>
                        <xsl:message>WARNING: No version file specified.</xsl:message>
                        <xsl:sequence select="'_' || hcmc:generateRandomHash()"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'_' || hcmc:generateRandomHash()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable> 
    
    
    <xd:doc>
        <xd:desc><xd:ref name="collectionDir" type="variable">$collectionDir</xd:ref> is the path to the
        directory that contains the search document, which we assume is the project directory that contains
        all of the files that static search is meant to index.</xd:desc>
    </xd:doc>
    <xsl:variable name="collectionDir" select="string-join(tokenize($searchDocUri,'/')[not(position() = last())],'/')" as="xs:string?"/>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="outDir" type="variable">$outDir</xd:ref> is path to the output directory for all
        of the static search products, which is simply a directory contained within the collection directory.</xd:desc>
    </xd:doc>
    <xsl:variable name="outDir" select="$collectionDir || '/' || $mergedParams?output.dir"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="tempDir" type="variable">$tempDir</xd:ref> is the directory in which the static search
            process stores all of the temporary outputs; it is deleted at the end of the process (in the ANT build).</xd:desc>
    </xd:doc>
    <xsl:variable name="tempDir" select="$outDir || '/ssTemp'"/>
  
    <xd:doc>
      <xd:desc><xd:ref name="ssPatternsetFile" type="variable">$ssPatternsetFile</xd:ref> is the location for a 
        temporary file which is used to store a patternset for the tokenization step. The patternset
        forms the basis of a fileset identifying all the files that need to be tokenized.
      </xd:desc>
    </xd:doc>
    <xsl:param name="ssPatternsetFile" select="$tempDir || '/patternset.txt'"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="excludeRules" type="variable">excludeRules</xd:ref> variable
            is a sequence of 0 or more rules of elements that should be ignored by the tokenization process.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="excludeRules" select="$configDoc//excludes/exclude" as="element(exclude)*"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="rules" type="variable">rules</xd:ref> variable
                is a sequence of 0 or more rules that should be flagged
                with a particular weight during tokenization.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="rules" select="$configDoc//rule" as="element(rule)*"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="contexts" type="variable">contexts</xd:ref> variable is
                a sequence of 0 or more contexts that are specified as context blocks--blocks that are to
                be used in the JSON creation stage to create the context for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="contexts" select="$configDoc//contexts/context" as="element(context)*"/>
    
    <!--First create our own context label map, which has to be slightly more
        complicated as context rules could have the same label-->
    <xsl:variable name="contextMap" as="map(xs:string, xs:string)">
        <xsl:map>
            <!--Group all of the contexts by label-->
            <xsl:for-each-group select="$contexts[@label]" group-by="normalize-space(@label)">
                <xsl:map-entry key="current-grouping-key()" select="'ssCtx' || position()"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <!--All matches-->
    <xsl:variable name="selectors" 
        select="distinct-values(($rules/@match, $excludeRules/@match, $contexts/@match))"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="filters" type="variable">filters</xd:ref> variable is
                a sequence of 0 or more filter elements that may be specified by the 
                user wanting more control over filter labels.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="filters" select="$configDoc//filters/filter" as="element(filter)*"/>
    
    
    <!--**************************************************************
       *                                                            * 
       *                         TEMPLATES                          *
       *                                                            *
       **************************************************************-->
    
    
    
    <xd:doc>
        <xd:desc>This is the main, root template that creates config.xsl. This XSL is then imported into the 
            tokenize.xsl, overriding any existing rules that are included in the document.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Creating configuration file from <xsl:value-of select="$configFile"/></xsl:message>
        <xsl:if test="$versionString != ''">
            <xsl:message>Version string for this build: <xsl:value-of select="$versionString"/></xsl:message>
        </xsl:if>
        
        <xsl:call-template name="createPatternSet"/>
        
        <!--Create the result document, which is also an XSLT document, but placed in the dummy XSO namespace-->
        <xsl:result-document href="file:///{$ssBaseDir}/xsl/config.xsl" 
            method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes">
            
            <!--Root stylesheet-->
            <xso:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                exclude-result-prefixes="#all"
                xpath-default-namespace="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                version="3.0">
                
                <!--Simple documentation to add -->
                <xd:doc scope="stylesheet">
                    <xd:desc>
                        <xd:p>Created on <xsl:value-of select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/> by an automated process.</xd:p>
                        <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
                        <xd:p>This is the temporary stylesheet derived from <xsl:value-of select="$configUri"/> and generated by 
                            <xsl:value-of select="base-uri()"/>. See <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a>
                            (or https://github.com/projectEndings/staticSearch/blob/master/xsl/create_config_xsl.xsl)
                            for further information on how this document is created and the purpose it serves for the
                            staticSearch codebase.
                        </xd:p>
                    </xd:desc>
                </xd:doc>
                <!-- First, we have to include the stemmer. We can't do this dynamically because
                    a dynamic variable can't be used to create a shadow attribute. -->
                <xso:include href="{$ssBaseDir || '/' || $mergedParams?stemmer.dir || '/ssStemmer.xsl'}"/>
                <xso:include href="constants.xsl"/>
                <!--First, create the global variables and parameters-->
                <xsl:call-template name="createGlobals" exclude-result-prefixes="#all"/>
                <!-- Always create the filterLabels variable even if there aren't any. It 
                     makes downstream processing easier. -->
                <xsl:call-template name="createFilterLabels"/>
                <!--Create the stopwords XML for use by a key-->
                <xsl:call-template name="createStopwordsXML" exclude-result-prefixes="#all"/>
                <!--And the complex rules as configured-->
                <xsl:call-template name="processRules" exclude-result-prefixes="#all"/>
            </xso:stylesheet>
        </xsl:result-document>
    </xsl:template>

    
    <!--**************************************************************
       *                                                            * 
       *                         NAMED TEMPLATES                    *
       *                                                            *
       **************************************************************-->
    <xd:doc>
        <xd:desc>This creates the global parameters and variables for the config file, which works as the global
            document for the transformations</xd:desc>
    </xd:doc>
    <xsl:template name="createGlobals" exclude-result-prefixes="#all">
        <xsl:variable name="recurseYN" 
            select="if ($mergedParams?index.recurse) then 'yes' else 'no'"
            as="xs:string"/>
        
        <!--First, create the actual configuration file thing-->
        <xso:param name="configFile"><xsl:value-of select="$configUri"/></xso:param>
        <!-- Pass through the build report filename param. -->
        <xso:param name="buildReportFilename" select="'{$buildReportFilename}'"/>    
        <!--Set the ssVerbose parameter -->
        <xso:param name="ssVerbose" select="'false'" as="xs:string" static="yes"/>
        <!--And the corresponding verbose variable-->
        <xso:variable name="verbose" select="{matches($ssVerbose,'^(y|yes|t|true|1)$','i')}()" as="xs:boolean" static="yes"/>
        <!--Now iterate through the merged parameters-->
        <xsl:for-each select="map:keys($mergedParams)">
            <xsl:variable name="key" select="." as="xs:string"/>
            <xsl:variable name="value" select="$mergedParams($key)" as="item()?"/>
            <xsl:if test="$verbose">
                <xsl:message>config: <xsl:value-of select="$key"/> = <xsl:value-of select="$value"/> (default: <xsl:value-of select="$defaultParams($key)"/>; type: <xsl:value-of select="$paramTypes($key)"/>)</xsl:message>
            </xsl:if>
            <xso:param name="{$key}">
                <xsl:attribute name="select">
                    <xsl:choose>
                        <xsl:when test="empty($value)">
                            <xsl:sequence select="'()'"/>
                        </xsl:when>
                        <xsl:when test="$value instance of xs:integer">
                            <xsl:sequence select="$value"/>
                        </xsl:when>
                        <xsl:when test="$value instance of xs:boolean">
                            <xsl:sequence select="string($value) || '()'"/>
                        </xsl:when>
                        <xsl:when test="$value = ''">
                            <xsl:sequence select="hcmc:quoteString('')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="hcmc:quoteString($value)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xso:param>
        </xsl:for-each>
        <!-- Finally, add the parsed-out version string from the versionFile. -->
        <xso:param name="versionString"><xsl:value-of select="$versionString"/></xso:param>
        
        <!--Configure the collection use x?html? ( so htm, html, xhtml, xhtm would all work
        as files)-->
        <xso:variable name="searchDocUri"><xsl:value-of select="$searchDocUri"/></xso:variable>
        <!--We've determines these above, so we can just shove in the absolute URIs-->
        <xso:variable name="collectionDir"><xsl:value-of select="$collectionDir"/></xso:variable>
        <xso:variable name="outDir"><xsl:value-of select="$outDir"/></xso:variable>
        <xso:variable name="tempDir"><xsl:value-of select="$tempDir"/></xso:variable>
        <xso:variable name="ssBaseDir"><xsl:value-of select="$ssBaseDir"/></xso:variable>
        <!--Now generated / handy variables we use throughout other processes-->
        <xso:variable name="kwicLengthHalf" as="xs:integer"
            select="{round(xs:integer($mergedParams?createContexts.maxKwicLength) div 2)}">
        </xso:variable>
        <!--The full name of the collection, stored here as a literal path-->
        <xso:variable name="collectionURI"><xsl:sequence 
                select="$collectionDir || '?select=*.*htm*;recurse=' || $recurseYN"/></xso:variable>
        <!--The documents to use, based on the collectionURI-->
        <xso:variable name="docs" 
            select="collection($collectionURI)[not(starts-with(base-uri(.),$tempDir))]
                                              [not(ends-with(base-uri(.), $buildReportFilename))]"/>
        <!--And the document URIs-->
        <xso:variable name="docUris" 
            select="uri-collection($collectionURI)[not(starts-with(.,$tempDir))]
                                                  [not(ends-with(., $buildReportFilename))]"/>
        <!--The tokenized collection URI, which will similarily require potential recursion-->
        <xso:variable name="tokenizedCollectionURI"><xsl:sequence
                select="$tempDir || '?select=*_tokenized.*htm*;recurse=' || $recurseYN"/></xso:variable>
        <!--The tokenized documents, which do not need any exclusions-->
        <xso:variable name="tokenizedDocs" 
            select="collection($tokenizedCollectionURI)"/>
        <!--The URIs for the tokenized documents-->
        <xso:variable name="tokenizedUris" 
            select="uri-collection($tokenizedCollectionURI)"/>
        <!--Whether this has exclusions-->
        <xso:variable name="hasExclusions" 
            select="{if ($configDoc//exclude) then 'true' else 'false'}()"/>
        <!--Whether this has filter labels-->
        <xso:variable name="hasFilterLabels" 
            select="{if ($configDoc//filter) then 'true' else 'false'}()"/>
        <!--The document's URI as a string-->
        <xso:variable name="uri" select="xs:string(base-uri(.))" as="xs:string"/>
        <xd:doc>
            <xd:desc>The relative uri from the root:
                this is the full URI minus the collection dir. 
                Note that we TRIM off the leading slash</xd:desc>
        </xd:doc>
        <xso:variable name="relativeUri" 
            select="substring-after($uri,replace($collectionDir, '^(file:/)/+', '$1')) => replace('^(/|\\)','')"
            as="xs:string"/>
        
        <xso:template name="echoParams">
            <xso:if test="$verbose">
                <xso:variable name="thisUri" select="static-base-uri()" as="xs:anyURI"/>
                <xso:variable name="thisBasename" select="tokenize($thisUri,'/')[last()]" as="xs:string"/>
                <xso:message>====== VARIABLES DECLARED IN <xso:value-of select="static-base-uri()"/> =======</xso:message>
                <xso:for-each select="document(static-base-uri())//*:stylesheet/(*:param | *:variable)">
                    <xso:message><xso:value-of select="$thisBasename"/>: $<xso:value-of select="@name"/>: <xso:value-of select="@select"/> [<xso:value-of select="local-name()"/>]</xso:message>
                </xso:for-each>
                <xso:message>====== END PARAMETERS =======</xso:message>
            </xso:if>
        </xso:template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Template to create an XML representation of the stopwords file
        and an associated key</xd:desc>
    </xd:doc>
    <xsl:template name="createStopwordsXML">
        <xsl:variable name="path" select="resolve-uri($mergedParams?stopwords.file,$configUri)"/>
        <xsl:variable name="uri" select="concat($outDir,'/dicts/',substring-before(tokenize($path,'/')[last()],'.txt'),'.xml')"/>
        <xsl:result-document href="{$uri}" method="xml">
            <hcmc:words>
                <xsl:for-each select="tokenize(unparsed-text($path),'\s+')">
                    <hcmc:word><xsl:value-of select="lower-case(normalize-space(.))"/></hcmc:word>
                </xsl:for-each>
            </hcmc:words>
        </xsl:result-document>
        <xsl:variable name="docFn">doc('<xsl:value-of select="$uri"/>')</xsl:variable>
        <xso:variable name="stopwordsFileXml" select="{$docFn}"/>
        <xso:key name="w" match="hcmc:word" use="."/>
    </xsl:template>


    <xd:doc>
        <xd:desc>The <xd:ref name="createFilterLabels" type="template">createFilterLabels</xd:ref> template creates 
            a copy of the original filter data in a variable; there's no real reason to process 
            it in any special way.</xd:desc>
    </xd:doc>
    <xsl:template name="createFilterLabels" exclude-result-prefixes="#all">
        <xso:variable name="filterLabels" as="element(hcmc:filter)*">
            <xsl:sequence select="$filters"/>
        </xso:variable>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>Create the patternset file which will be used later by the tokenizing process.</xd:desc>
    </xd:doc>
    <xsl:template name="createPatternSet">
        <xsl:result-document href="{$ssPatternsetFile}" method="text">
            <xsl:choose>
                <xsl:when test="$mergedParams?index.recurse">
                    <xsl:sequence select="'**/*.html&#x0a;**/*.xhtml&#x0a;**/*.htm'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="'*.html&#x0a;*.xhtml&#x0a;*.htm'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The processRules template creates all of the template rules for decorating 
        each token during tokenization. It relies on a set of priorities, which recursively keeps 
        track of all declared values, and then works out which should be honoured.</xd:desc>
    </xd:doc>
    <xsl:template name="processRules">
        <xsl:for-each select="$rules">
            <xso:template match="{@match}" priority="{$PRIORITY_THIRD}" mode="decorate">
                <xso:param name="data" tunnel="yes" as="map(*)"/>                        
                <xso:call-template name="hcmc:updateData">
                    <xso:with-param name="caller" select="'config#decorate'"/>
                    <xso:with-param name="key" select="$KEY_WEIGHTS"/>
                    <xso:with-param name="value" select="{@weight}"/>
                    <xso:with-param name="append">[<xsl:value-of select="local-name()"/>/@match=<xsl:value-of select="@match"/>]</xso:with-param>
                </xso:call-template>
            </xso:template>
        </xsl:for-each>
        
        <!--Now create the config XSL's version of the context map,
            which may be a map (if there are contexts with labels)
            OR an empty sequence (if there aren't)-->
        <xso:variable name="ssContextMap" as="map(*)?">
            <xsl:choose>
                <xsl:when test="exists($contexts[@label])">
                    <!--Create a usable map in the output config
                        using the values assembled by $contextMap-->
                    <xso:map>
                        <xsl:for-each select="map:keys($contextMap)">
                            <xso:map-entry 
                                key="{hcmc:quoteString(.)}"
                                select="{hcmc:quoteString($contextMap(.))}"/>
                        </xsl:for-each>
                    </xso:map>
                </xsl:when>
                <xsl:otherwise>
                    <xso:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xso:variable>
        
        <xsl:for-each select="$contexts">
            <xso:template match="{@match}" priority="{$PRIORITY_THIRD}" mode="decorate">
                <xso:call-template name="hcmc:updateData">
                    <xso:with-param name="caller" select="'config#decorate'"/>
                    <xso:with-param name="key" select="$KEY_CONTEXTS"/>
                    <xso:with-param name="value" select="{hcmc:stringToBoolean(@context)}()"/>
                    <xso:with-param name="append">[<xsl:value-of select="local-name()"/>/@match=<xsl:value-of select="@match"/>]</xso:with-param>
                </xso:call-template>
            </xso:template>
            
            <xsl:if test="@label">
                <xsl:variable name="thisLabel" select="@label"/>
                <xsl:variable name="contextId" 
                    select="$contextMap(normalize-space($thisLabel))"
                    as="xs:string"/>
                <xso:template match="{@match}" priority="{$PRIORITY_THIRD}" mode="decorate">
                    <xso:call-template name="hcmc:updateData">
                        <xso:with-param name="caller" select="'config#decorate'"/>
                        <xso:with-param name="key" select="$KEY_CONTEXT_IDS"/>
                        <xso:with-param name="value" select="{hcmc:quoteString($contextId)}"/>
                        <xso:with-param name="append">[<xsl:value-of select="local-name()"/>/@match=<xsl:value-of select="@match"/>]</xso:with-param>
                    </xso:call-template>
                </xso:template>
            </xsl:if>
        </xsl:for-each>
        
        <xsl:for-each select="$excludeRules">
            <xso:template match="{@match}"  priority="{$PRIORITY_THIRD}" mode="decorate">
                <xso:call-template name="hcmc:updateData">
                    <xso:with-param name="caller" select="'config#decorate'"/>
                    <xso:with-param name="key" select="$KEY_EXCLUDES"/>
                    <xso:with-param name="value" select="{hcmc:stringToBoolean('')}()"/>
                    <xso:with-param name="append">[<xsl:value-of select="local-name()"/>/@match=<xsl:value-of select="@match"/>]</xso:with-param>
                </xso:call-template>
            </xso:template>
        </xsl:for-each>

        <!--Now, finally, the last rule -->
        <xso:template match="*" name="hcmc:last"  priority="{$PRIORITY_LAST}" mode="decorate">
            <xso:param name="data" tunnel="yes" as="map(*)"/>
            <xso:variable name="weights" select="$data($KEY_WEIGHTS)" as="xs:integer*"/>
            <xso:variable name="ctxIds" select="$data($KEY_CONTEXT_IDS)" as="xs:string*"/>
            <xso:variable name="contexts" select="$data($KEY_CONTEXTS)" as="xs:boolean*"/>
            <xso:variable name="excludes" select="$data($KEY_EXCLUDES)" as="xs:boolean*"/>
            <xso:choose>
                <!--This is the root, so we must process it-->
                <xso:when test="not(ancestor::*)">
                    <xso:if test="not(empty($weights)) and $weights[last()] = 0">
                        <xso:message terminate="yes">
                            *********************************************
                            ERROR: You have specified a weight of 0 for 
                            the root <xso:value-of select="local-name()"/> element, 
                            which would create an empty output file and generate an error during 
                            tokenization.
                            
                            Did you mean to use an exclude instead?
                            *********************************************
                        </xso:message>
                    </xso:if>
                    <xso:call-template name="hcmc:copy"/>
                </xso:when>
                <!--If there is weighting info, then either...-->
                <xso:when test="not(empty($weights))">
                    <xso:choose>
                        <!--It should be removed (since it's a weight=0)-->
                        <xso:when test="$weights[last()] = 0">
                            <xso:if test="$verbose">
                                <xso:message>config#decorate: Removing <xso:value-of select="local-name()"/> (weight=0)</xso:message>
                            </xso:if>
                        </xso:when>
                        <!--Or it must be retained-->
                        <xso:otherwise>
                            <xso:call-template name="hcmc:copy"/>
                        </xso:otherwise>
                    </xso:choose>
                </xso:when>
                <xso:when test="empty($contexts) or ($contexts[last()] = false())">
                    <xso:apply-templates select="node()" mode="#current"/>
                </xso:when>
                <xso:otherwise>
                    <xso:call-template name="hcmc:copy"/>
                </xso:otherwise>
            </xso:choose>
        </xso:template>
        
        <!--Special template used to update data and 
                    provide debugging output, if necessary-->
        <xso:template name="hcmc:updateData">
            <xso:param name="data" tunnel="yes" as="map(*)"/>
            <xso:param name="caller" as="xs:string?"/>
            <xso:param name="append" as="xs:string?"/>
            <xso:param name="key" as="xs:string"/>
            <xso:param name="value" as="item()"/>
            <xso:variable name="currValues" select="$data($key)" as="item()*"/>
            <xso:variable name="newValues" select="($currValues, $value)" as="item()+"/>
            <xso:if test="$verbose">
                <xso:message>
                    <xso:value-of separator=": ">
                        <xso:text>hcmc:updateData</xso:text>
                        <xso:sequence select="$caller"/>
                        <xso:sequence select="'Updating ' || local-name()"/>
                        <xso:sequence select="$key || '=' || string-join($newValues,';')"/>
                    </xso:value-of>
                    <xso:if test="not(empty($append))">
                        <xso:value-of select="' ' || $append"/>
                    </xso:if>
                </xso:message>
            </xso:if>
            <xso:next-match>
                <xso:with-param name="data"
                    tunnel="yes" as="map(*)"
                    select="map:put($data, $key ,$newValues)"/>
            </xso:next-match>
        </xso:template>
        
        <xso:template name="hcmc:copy">
            <xso:copy>
                <xso:call-template name="hcmc:copy-atts"/>
                <xso:apply-templates select="node()" mode="decorate"/>
            </xso:copy>
        </xso:template>
        
        <xso:template name="hcmc:copy-atts">
            <xso:param name="data" as="map(*)" tunnel="yes"/>
            <xsl:message>Add the ss-uri attribute for the uris</xsl:message>
            <xso:if test="not(ancestor::*)">
                <xso:attribute name="ss-uri" select="$relativeUri"/>
            </xso:if>
            <xso:apply-templates select="@*" mode="decorate"/>
            <xso:where-populated>
                <xso:attribute name="ss-wt" select="$data($KEY_WEIGHTS)[last()]"/>
            </xso:where-populated>
            <xso:where-populated>
                <xso:attribute name="ss-ctx-id" select="string-join($data($KEY_CONTEXT_IDS), ' ')"/>
            </xso:where-populated>
            <xso:where-populated>
                <xso:attribute name="ss-ctx" select="xs:string($data($KEY_CONTEXTS)[last()])"/>
            </xso:where-populated>
            <xso:where-populated>
                <xso:attribute name="ss-excld" select="xs:string($data($KEY_EXCLUDES)[last()])"/>
            </xso:where-populated>
        </xso:template>
    </xsl:template>
    
 
    <!--**************************************************************
       *                                                            * 
       *                         FUNCTIONS                          *
       *                                                            *
       **************************************************************-->
 
 
 
    <xd:doc>
        <xd:desc>
            <xd:p><xd:ref name="hcmc:stringToBoolean" type="function">hcmc:stringToBoolean</xd:ref> converts a string value to a boolean. String values can be one of (case-insensitive): "T", "true", "y", "yes", "1"; anything else will evaluate to false.</xd:p>
        </xd:desc>
        <xd:param name="str">The input string.</xd:param>
        <xd:return>A boolean value.</xd:return>
    </xd:doc>
    
    <xsl:function name="hcmc:stringToBoolean" as="xs:boolean">
        <xsl:param name="str" as="xs:string?"/>
        
        <xsl:choose>
            <!--If you haven't specified a string, then we assume
                it's true-->
            <xsl:when test="empty($str) or $str=''">
                <xsl:value-of select="true()"/>
            </xsl:when>
            
            <!--if it looks like the word yes or true, then it's true-->
            <xsl:when test="matches(lower-case($str),'^(y(es)?|t(rue)?)')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            
            <!--If it equals 1, then it's true-->
            <xsl:when test="$str castable as xs:integer and xs:integer($str) = 1">
                <xsl:value-of select="true()"/>
            </xsl:when>
            
            <!--All else fails, it's false-->
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc><xd:ref name="hcmc:quoteString">hcmc:quoteString</xd:ref> takes a string value
        and adds single quotation marks around it; this is for instances where the output
        XSLT needs to have a string value as its attribute value.</xd:desc>
        <xd:param name="str">The input string (e.g. "value")</xd:param>
        <xd:return>The input value with single quotation marks ("'value'")</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:quoteString" as="xs:string">
        <xsl:param name="str" as="item()"/>
        <xsl:sequence select="concat('''', string($str), '''')"/>
    </xsl:function>
    
    <xsl:function name="hcmc:getGitHash" as="xs:string">
        <xsl:variable name="dotGitDir" select="resolve-uri('.git', $configFile)"/>
        <xsl:variable name="gitHEAD" select="normalize-space(unparsed-text($dotGitDir || '/HEAD'))" as="xs:string"/>
        <xsl:variable name="refDir" select="normalize-space(substring-after($gitHEAD,'ref: '))" as="xs:string"/>
        <xsl:variable name="commitHash" select="unparsed-text(resolve-uri($refDir,$dotGitDir))"/>
        <xsl:sequence select="substring($commitHash,1, 6)"/>
    </xsl:function>
    
    <xsl:function name="hcmc:generateRandomHash" as="xs:string">
        <xsl:variable name="generator" select="random-number-generator()" as="map(*)"/>
        <xsl:variable name="alpha" select="(97 to 122) ! codepoints-to-string(.)" as="xs:string+"/>
        <xsl:variable name="nums" select="0 to 9" as="xs:integer+"/>
        <xsl:sequence select="string-join($generator?permute(($alpha, $nums))[position() lt 7],'')"/>
    </xsl:function>
    
</xsl:stylesheet>