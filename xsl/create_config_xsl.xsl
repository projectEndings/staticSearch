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
            <xd:p>This transformation converts the configuration file (config.xml) into
                  an XSLT stylesheet, which is imported into the main tokenization stylesheet
                  to allow for various configuration options. <!--WRITE MORE HERE ONCE WRITTEN--></xd:p>
          
        </xd:desc>
        <xd:param name="configFile">A URI pointing to the config XML file that will be turned into the 
        configuration XSLT.</xd:param>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            * 
       *                         PARAMETERS                         *
       *                                                            *
       **************************************************************-->
    
    <xsl:param name="configFile" select="'config.xml'"/>
    <xsl:param name="buildReportFilename" select="'staticSearch_report.html'"/>
    
    
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
    <xsl:variable name="configDoc">
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
        <xd:desc><xd:ref name="ssBasedir" type="variable">$ssBasedir</xd:ref> is the base directory for the static
            search codebase. It is just the directory above the /xsl/ directory that contains this file.</xd:desc>
    </xd:doc>
    <xsl:variable name="ssBaseDir" select="substring-before(document-uri(/),'/xsl/create_config_xsl.xsl')"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="ssDefaultStemmerFolder" 
            type="variable">$ssDefaultStemmerFolder</xd:ref>
            is the location to use when no specific stemmer has been supplied. 
            It's the location of the English Porter 2 stemmer.
        </xd:desc>
    </xd:doc>
    <xsl:variable name="ssDefaultStemmerFolder" as="xs:string" 
        select="'en'"/>
    
    
    <xd:doc>
        <xd:desc><xd:ref name="schemaURI" type="variable">$schemaURI</xd:ref> is the URI for the static search 
            configuration schema written in the TEI ODD language. We get the URI here during the configuration creation
            process as it can provide useful information as to what the expected values are for various
            configuration options. If, for whatever reason, the schema is not available locally (it is packed
            with the static search distribution), then we check to see if this has been downloaded as a package
            from a formal release; if it hasn't, then we get the latest release. If, for whatever reason, the 
            latest release isn't available, then we just get the latest one from the /dev/ branch.
            </xd:desc>
    </xd:doc>
    
    <xsl:variable name="schemaURI" as="xs:string">
        <xsl:choose>
            <xsl:when test="doc-available($ssBaseDir || '/schema/staticSearch.odd')">
                <xsl:value-of select="$ssBaseDir || '/schema/staticSearch.odd'"/>
            </xsl:when>
            <xsl:when test="unparsed-text-available($ssBaseDir || '/VERSION.txt')">
                <xsl:variable name="versionNum" 
                    select="unparsed-text-lines($ssBaseDir || '/VERSION.txt')[1] =>
                    normalize-space()"/>
                <xsl:value-of select="'https://raw.githubusercontent.com/projectEndings/staticSearch/v' || $versionNum || '/schema/staticSearch.odd'"/>
            </xsl:when>
            <xsl:when test="doc-available('https://raw.githubusercontent.com/projectEndings/staticSearch/' || hcmc:getLatestReleaseNum() || '/schema/staticSearch.odd')">
                <xsl:value-of select="'https://raw.githubusercontent.com/projectEndings/staticSearch/' || hcmc:getLatestReleaseNum() || '/schema/staticSearch.odd'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'https://raw.githubusercontent.com/projectEndings/staticSearch/dev/schema/staticSearch.odd'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc><xd:ref name="schema" type="variable">$schema</xd:ref> is the loaded
        TEI ODD file that contains the schema available at the URI determined by
        <xd:ref name="schemaURI" type="variable">$schemaURI</xd:ref>.</xd:desc>
    </xd:doc>
    <xsl:variable name="schema" as="document-node()">
        <xsl:if test="$verbose">
            <xsl:message>Getting schema from <xsl:value-of select="$schemaURI"/></xsl:message>
        </xsl:if>
        <xsl:sequence select="document($schemaURI)"/>
    </xsl:variable>
        
        
    
  


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
    <xsl:variable name="searchDocUri" select="resolve-uri($configDoc//searchFile/text(),$configUri)" as="xs:anyURI"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="versionDocUri" type="variable">$versionDocUri</xd:ref> is the absolute URI
            of an optional document that contains a version string for the build to use in creating filenames.</xd:desc>
    </xd:doc>
    <xsl:variable name="versionDocUri" select="if ($configDoc//versionFile) then resolve-uri($configDoc//versionFile/text(),$configUri) else ''" as="xs:string"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="versionString" type="variable">$versionString</xd:ref> is the version information read from the
            versionDoc if there is one; otherwise it is an empty string.</xd:desc>
    </xd:doc>
    <xsl:variable name="versionString" select="if (($versionDocUri != '') and (unparsed-text-available($versionDocUri))) then replace(normalize-space(unparsed-text($versionDocUri)), '\s+', '_') else ''" as="xs:string"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="stemmerFolder" type="variable">$stemmerFolder</xd:ref> is the location of 
        a folder containing XSLT and JavaScript implementations of stemmers. If empty, we default to 
        ssDefaultStemmerFolder.</xd:desc>
    </xd:doc>
    <xsl:variable name="stemmerFolder" select="if ($configDoc//stemmerFolder) then $configDoc//stemmerFolder/text() else $ssDefaultStemmerFolder" as="xs:string"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="collectionDir" type="variable">$searchDirName</xd:ref> is the path to the
        directory that contains the search document, which we assume is the project directory that contains
        all of the files that static search is meant to index.</xd:desc>
    </xd:doc>
    <xsl:variable name="collectionDir" select="string-join(tokenize($searchDocUri,'/')[not(position() = last())],'/')" as="xs:string?"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="outputFolder" type="variable">$outputFolder</xd:ref> is the optional name of a folder
            in which to store the output JS and JSON.</xd:desc>
    </xd:doc>
    <xsl:variable name="outputFolder" select="if ($configDoc//outputFolder) then $configDoc//outputFolder/text() else 'staticSearch'" as="xs:string"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="outDir" type="variable">$outDir</xd:ref> is path to the output directory for all
        of the static search products, which is simply a directory contained within the collection directory.</xd:desc>
    </xd:doc>
    <xsl:variable name="outDir" select="$collectionDir || '/' || $outputFolder"/>
    
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
        <xd:desc><xd:ref name="recurse" type="variable">$recurse</xd:ref> is a boolean that states whether or not the 
            static search should recurse into subdirectories of the collection directory.</xd:desc>
    </xd:doc>
    <xsl:variable name="recurse" select="hcmc:stringToBoolean($configDoc//recurse/text())" as="xs:boolean"/>
    
    <xd:doc>
        <xd:desc><xd:ref name="verbose" type="variable">$verbose</xd:ref> describes the user set verbosity setting
        for messages in the XSLT--useful primarily for debugging.</xd:desc>
    </xd:doc>
    <xsl:variable name="verbose" select="hcmc:stringToBoolean($configDoc//verbose/text())" as="xs:boolean"/>
  
  <!--Single quote-->
  <xsl:variable name="sq">'</xsl:variable>
 
      
      
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="retainRules" type="variable">retainRules</xd:ref> variable is
                a sequence of 0 or more rules that either have a weight greater than 0 or have been
                specified as a context item.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="retainRules" 
        select="
        $configDoc//rule[(xs:integer(@weight) gt 0) or 
        (parent::contexts and hcmc:stringToBoolean(@context))]" as="element(rule)*"/>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="deleteRules" type="variable">deleteRules</xd:ref> variable is
                a sequence of 0 or more rules that either have have a weight of 0, which means that
                the xpaths specified should not be processed by the tokenizer and should be deleted
                from the document that will eventually be indexed.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="deleteRules" select="$configDoc//rule[xs:integer(@weight) = 0]" as="element(rule)*"/>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="excludeRules" type="variable">excludeRules</xd:ref> variable
            is a sequence of 0 or more rules of elements that should be ignored by the tokenization process.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="excludeRules" select="$configDoc//excludes/exclude" as="element(exclude)*"/>
    
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>OBSOLETE: Now specified as context elements, not rule elements. 
                The <xd:ref name="contextRules" type="variable">contextRules</xd:ref> variable is
                a sequence of 0 or more rules that are specified as context blocks--blocks that are to
                be used in the JSON creation stage to create the context for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="contextRules" select="$configDoc//contexts/rule" as="element(rule)*"/>
    
    <xsl:variable name="weightedRules" select="$configDoc//rule[xs:integer(@weight) gt 1]" as="element(rule)*"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="contexts" type="variable">contexts</xd:ref> variable is
                a sequence of 0 or more contexts that are specified as context blocks--blocks that are to
                be used in the JSON creation stage to create the context for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="contexts" select="$configDoc//contexts/context" as="element(context)*"/>
    
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
        
        <xsl:if test="$verbose">
            <xsl:for-each select="$configDoc//params/*">
                <xsl:message>$<xsl:value-of select="local-name()"/>: <xsl:value-of select="."/></xsl:message>
            </xsl:for-each>
        </xsl:if>
      
        <!-- Create the patternset file which will be used later by the tokenizing process. -->
        <xsl:result-document href="{$ssPatternsetFile}" method="text">
          <xsl:choose>
            <xsl:when test="$recurse">
              <xsl:sequence select="'**/*.html&#x0a;**/*.xhtml&#x0a;**/*.htm'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="'*.html&#x0a;*.xhtml&#x0a;*.htm'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:result-document>
        
        <!--Create the result document, which is also an XSLT document, but placed in the dummy XSO namespace-->
        <xsl:result-document href="{$ssBaseDir}/xsl/config.xsl" method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all">
            
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
                        <xd:p>This is the temporary stylesheet derived from <xsl:value-of select="$configUri"/> and generated by <xsl:value-of select="document-uri(/)"/>.
                            See <xd:a href="create_config_xsl.xsl">create_config_xsl.xsl</xd:a> (or https://github.com/projectEndings/staticSearch/blob/master/xsl/create_config_xsl.xsl)
                            for further information on how this document is created and the purpose it serves for the static search codebase.
                        </xd:p>
                    </xd:desc>
                </xd:doc>
                
                <!-- First, we have to include the stemmer. We can't do this dynamically because
                    a dynamic variable can't be used to create a shadow attribute. -->
                <xso:include href="{$ssBaseDir || '/stemmers/' || $stemmerFolder || '/ssStemmer.xsl'}"/>
                
                <!--Now, create all the parameters-->
                
                <!--First, create the global variables and parameters-->
                <xsl:call-template name="createGlobals" exclude-result-prefixes="#all"/>
            
                <!--Now create the dictionary XML files-->
                <xsl:call-template name="createDictionaryXML" exclude-result-prefixes="#all"/>
                
                
                <!--And now create the sets of templates that will be used in the later tokenization stages-->
                <!--If there are retain rules specified in the configuration file,
                    then call the createRetainRules template-->
                <xsl:if test="not(empty($retainRules))">
                    <xsl:call-template name="createRetainRules" exclude-result-prefixes="#all"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create retain rules</xsl:message>
                        <xsl:message>  <xsl:call-template name="createRetainRules"/></xsl:message>
                    </xsl:if>
                </xsl:if>
                
                
                <!--If there are deletion rules specified in the configuration file,
                    then call the createDeleteRules template-->
                <xsl:if test="not(empty($deleteRules))">
                    <xsl:call-template name="createDeleteRules" exclude-result-prefixes="#all"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create delete rules</xsl:message>
                        <xsl:message>
                            <xsl:call-template name="createDeleteRules"/>
                        </xsl:message>
                    </xsl:if>
                </xsl:if>
                
                <xsl:if test="not(empty($excludeRules))">
                    <xsl:call-template name="createExcludeRules" exclude-result-prefixes="#all"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create exclude rules</xsl:message>
                        <xsl:message>
                            <xsl:call-template name="createExcludeRules"/>
                        </xsl:message>
                    </xsl:if>
                </xsl:if>
                
                <xsl:call-template name="createContextRules" exclude-result-prefixes="#all"/>
                
                <xsl:if test="$verbose and not(empty($contexts))">
                    <xsl:message>Create context rules</xsl:message>
                    <xsl:message>
                        <xsl:call-template name="createContextRules" exclude-result-prefixes="#all"/>
                    </xsl:message>
                </xsl:if>
                
                
                <xsl:if test="not(empty($weightedRules))">
                    <xsl:call-template name="createWeightingRules"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create weighting rules</xsl:message>
                        <xsl:message><xsl:call-template name="createWeightingRules" exclude-result-prefixes="#all"/></xsl:message>
                    </xsl:if>
                </xsl:if>
                
                
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
        
        <xsl:variable name="params" as="element()+">
            <!--First, create the actual configuration file thing-->
            <xso:param name="configFile"><xsl:value-of select="$configUri"/></xso:param>
            <!-- Pass through the build report filename param. -->
            <xso:param name="buildReportFilename" select="'{$buildReportFilename}'"/>    
            <xsl:for-each select="$configDoc//params/*" >
                <xsl:variable name="thisParam" select="."/>
                <xsl:variable name="paramName" select="local-name()"/>
                <xsl:variable name="thisElementSpec" select="$schema//tei:elementSpec[@ident=$paramName]" as="element(tei:elementSpec)?"/>
                
                <xso:param>
                    <xsl:attribute name="name" select="$paramName"/>
                    
                    <xsl:choose>
                        <!--TODO: Make this smarter! Look at the ODD file
                            and see if the parameter is a boolean or not. If it is, do this, otherwise, just assume its a string
                            (or an integer or whatever else)-->
                        <xsl:when test="$thisElementSpec and $thisElementSpec[descendant::tei:dataRef[@name='boolean']]">
                            <xsl:attribute name="select" select="concat(hcmc:stringToBoolean(xs:string(.)),'()')"/>
                        </xsl:when>
                        <xsl:when test="$thisElementSpec and $thisElementSpec[descendant::tei:dataRef[@name='anyURI']]">
                            <xsl:value-of select="resolve-uri(.,$configUri)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xso:param>
            </xsl:for-each>
            
            <!-- We record the current default stemmer folder. -->
            <xso:param name="defaultStemmerFolder"><xsl:value-of select="$ssDefaultStemmerFolder"/></xso:param>
            
            <!-- We need an outputFolder element even if the user hasn't put one in. -->
            <xsl:if test="not($configDoc//params/outputFolder)">
                <xso:param name="outputFolder">staticSearch</xso:param>
            </xsl:if>
            
            <!--Specify whether or not wildcard search should be performed; we default false-->
            <xsl:if test="not($configDoc//params/wildcardSearch)">
                <xso:param name="wildcardSearch" select="false()"/>
            </xsl:if>
            
            <!--Set the scoring algorithm, if it's not set-->
            <xsl:if test="not($configDoc//params/scoringAlgorithm)">
                <xso:param name="scoringAlgorithm" select="'raw'"/>
            </xsl:if>
            
            <!--Specify whether or not to link to fragments; we default true-->
            <xsl:if test="not($configDoc//params/linkToFragmentId)">
                <xso:param name="linkToFragmentId" select="true()"/>
            </xsl:if>
            
            <!--Specify the minimum length of items to index; we default to 3. -->
            <xsl:if test="not($configDoc//params/minWordLength)">
                <xso:param name="minWordLength" select="3"/>
            </xsl:if>
            
            <!--Turn on experimental scroll-to-text feature: default false.-->
            <xsl:if test="not($configDoc//params/scrollToTextFragment)">
                <xso:param name="scrollToTextFragment" select="false()"/>
            </xsl:if>
            
            <!--Add resultsPerPage: default to 0-->
            <xsl:if test="not($configDoc//params/resultsPerPage)">
                <xso:param name="resultsPerPage" select="0"/>
            </xsl:if>
            
            <!--And resultsLimit: default to 2000-->
            <xsl:if test="not($configDoc//params/resultsLimit)">
                <xso:param name="resultsLimit" select="2000"/>
            </xsl:if>
            
            <!-- Finally, add the parsed-out version string from the versionFile. -->
            <xso:param name="versionString"><xsl:value-of select="if (($versionDocUri != '') and (unparsed-text-available($versionDocUri))) then concat('_', replace(normalize-space(unparsed-text($versionDocUri)), '\s+', '_')) else ''"/></xso:param>
            
        </xsl:variable>
        
        <xsl:sequence select="$params" exclude-result-prefixes="#all"/>
        

        
        <!--Configure the collection use x?html? ( so htm, html, xhtml, xhtm would all work
        as files)-->
        
        <!--We've determines these above, so we can just shove in the absolute URIs-->
        <xso:variable name="collectionDir"><xsl:value-of select="$collectionDir"/></xso:variable>
        <xso:variable name="outDir"><xsl:value-of select="$outDir"/></xso:variable>
        <xso:variable name="tempDir"><xsl:value-of select="$tempDir"/></xso:variable>
        <xso:variable name="ssBaseDir"><xsl:value-of select="$ssBaseDir"/></xso:variable>
        
        
        <xso:variable name="kwicLengthHalf"
            select="{xs:integer(round(xs:integer($configDoc//totalKwicLength) div 2))}"/>
        <xso:variable name="docs" 
            select="collection(concat($collectionDir, {$sq || '?select=*.*htm*;recurse=' || (if ($recurse) then 'yes' else 'no') || $sq}))[not(starts-with(document-uri(.),$tempDir))][not(ends-with(document-uri(.), $buildReportFilename))]"/>
        
        <xso:variable name="docUris" 
            select="uri-collection(concat($collectionDir, {$sq || '?select=*.*htm*;recurse=' || (if ($recurse) then 'yes' else 'no') || $sq}))[not(starts-with(.,$tempDir))][not(ends-with(., $buildReportFilename))]"/>
        
        <xso:variable name="tokenizedDocs" 
            select="collection(concat($tempDir, {$sq || '?select=*_tokenized.*htm*;recurse=' || (if ($recurse) then 'yes' else 'no') || $sq}))"/>
        
        <xso:variable name="tokenizedUris" 
            select="uri-collection(concat($tempDir, {$sq || '?select=*_tokenized.*htm*;recurse=' || (if ($recurse) then 'yes' else 'no') || $sq}))"/>
        
        <xso:variable name="hasExclusions" 
            select="{if ($configDoc//exclude) then 'true' else 'false'}()"/>
        
        
        <xso:template name="echoParams">
            <xso:if test="$verbose">
                <xsl:for-each select="$params">
                    <xso:message>$<xsl:value-of select="@name"/>: <xso:value-of select="{concat('$',@name)}"/></xso:message>
                </xsl:for-each>
                <xso:message>$collectionDir: <xso:value-of select="$collectionDir"/></xso:message>
                <xso:message>$outDir: <xso:value-of select="$outDir"/></xso:message>
                <xso:message>$tempDir: <xso:value-of select="$tempDir"/></xso:message>
            </xso:if>
        </xso:template>
    </xsl:template>
    
    
    

    <xd:doc>
        <xd:desc>Template to create an XML representation of the dictionary file 
        and an associated key.</xd:desc>
    </xd:doc>
    <xsl:template name="createDictionaryXML" exclude-result-prefixes="xs xd tei">
        <xsl:for-each select="($configDoc//stopwordsFile, $configDoc//dictionaryFile)">
            <xsl:variable name="path" select="resolve-uri(text(),$configUri)"/>
            <xsl:variable name="uri" select="concat($outDir,'/dicts/',substring-before(tokenize($path,'/')[last()],'.txt'),'.xml')"/>
            <xsl:result-document href="{$uri}" method="xml">
                <hcmc:words>
                    <xsl:for-each select="tokenize(unparsed-text($path),'\s+')">
                        <hcmc:word><xsl:value-of select="lower-case(normalize-space(.))"/></hcmc:word>
                    </xsl:for-each>
                </hcmc:words>
            </xsl:result-document>
            <xsl:variable name="docFn">doc('<xsl:value-of select="$uri"/>')</xsl:variable>
            <xso:variable name="{concat(local-name(),'Xml')}" select="{$docFn}"/>
        </xsl:for-each>
        
        <xso:key name="w" match="hcmc:word" use="."/>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createRetainRules" type="template">createRetainRules</xd:ref> template
            creates an XSL identity template for the xpaths specified in the configuration file that have
            either a weight greater than 0 OR want to be retained as a context item for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createRetainRules" exclude-result-prefixes="#all">
        <xso:template match="{string-join($retainRules/@match,' | ')}" priority="1" mode="clean">
            <xso:if test="$verbose">
                <xso:message>Template #clean: retaining <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
            <xso:copy>
                <xso:apply-templates select="@*|node()" mode="#current"/>
            </xso:copy>
        </xso:template>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createDeleteRules" type="template">createDeleteRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that have
                a weight of 0, which signals that these elements should be deleted from the tokenization process.
                These are usually elements that have text content that shouldn't be analyzed (for instance, footer
                text that appears in every document or navigation items).</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createDeleteRules" exclude-result-prefixes="#all">
        <xso:template match="{string-join($deleteRules/@match,' | ')}" priority="1" mode="clean">
            <xso:if test="$verbose">
                <xso:message>Template #clean: Deleting <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
          <xso:if test="local-name() = 'html'">
            <xso:message terminate="yes">
*********************************************
ERROR: You have specified a weight of 0 for 
an html element, which will create an empty 
output file and generate an error during 
tokenization.
*********************************************
            </xso:message>
          </xso:if>
        </xso:template>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createExcludeRules" type="template">createDeleteRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that have been excluded from the tokenization
                process.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createExcludeRules" exclude-result-prefixes="#all">
        <xso:template match="{string-join($excludeRules/@match, ' | ')}" priority="1" mode="exclude">
            <xso:if test="$verbose">
                <xso:message>Template #exclude: Adding @ss-excld flag to <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
            <xso:copy>
                <xso:attribute name="ss-excld" select="'true'"/>
                <xso:apply-templates select="@*|node()" mode="#current"/>
            </xso:copy>
        </xso:template>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createContextRules" type="template">createContextRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that are
                specified as context nodes for the kwic. It also creates the map of context ids/labels,
                if they are specified in the config, for creating the "Search in" configuration.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createContextRules" exclude-result-prefixes="#all">
        
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
        
        <xsl:if test="not(empty($contexts))">
            <xso:template match="{string-join($contexts/@match,' | ')}" priority="1" mode="contextualize">
                <xso:if test="$verbose">
                    <xso:message>Template #contextualize: Adding @ss-ctx flag to <xso:value-of select="local-name(.)"/></xso:message>
                </xso:if>
                <xso:copy>
                    <xso:apply-templates select="@*" mode="#current"/>
                    <xsl:for-each select="$contexts">
                        <xsl:variable name="thisCtx" select="@context"/>
                        <xsl:variable name="thisMatchPtn" select="@match"/>
                        <xsl:variable name="thisLabel" select="@label"/>
                        <xsl:for-each select="tokenize($thisMatchPtn,'\s*\|\s*')">
                            <xso:if test="self::{.}">
                                <xso:attribute name="ss-ctx" select="{hcmc:quoteString(hcmc:stringToBoolean($thisCtx))}"/>
                                <!--If the context has a label, then add its corresponding context id value-->
                                <xsl:if test="exists($thisLabel)">
                                    <xsl:variable name="contextId" 
                                        select="$contextMap(normalize-space($thisLabel))"
                                        as="xs:string"/>
                                    <xso:attribute name="ss-ctx-id" select="{hcmc:quoteString($contextId)}"/>
                                </xsl:if>
                            </xso:if>
                        </xsl:for-each>
                        
                    </xsl:for-each>
                    <xso:apply-templates select="node()" mode="#current"/>
                </xso:copy>
            </xso:template>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createWeightingRules" type="template">createWeightingRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that have
                some non-0 weight specified.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createWeightingRules" exclude-result-prefixes="#all">
        <xso:template match="{string-join($weightedRules/@match,' | ')}" priority="1" mode="weigh">
            <xso:if test="$verbose">
                <xso:message>Template #weigh: Adding @data-weight to <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
            <xso:copy>
                <xso:apply-templates select="@*" mode="#current"/>
                <xsl:for-each select="$weightedRules[xs:integer(@weight) gt 1]">
                    <xso:if test="self::{@match}">
                        <xso:attribute name="ss-wt" select="{@weight}"/>
                    </xso:if>
                </xsl:for-each>
                <xso:apply-templates select="node()" mode="#current"/>
            </xso:copy>
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
    
    <xd:doc>
        <xd:desc>This function gets the latest release number from Github </xd:desc>
    </xd:doc>
    <xsl:function name="hcmc:getLatestReleaseNum" as="xs:string">
        <xsl:variable name="json" select="unparsed-text('https://api.github.com/repos/projectEndings/staticSearch/releases/latest')"/>
        <xsl:variable name="xml" select="json-to-xml($json)"/>
        <xsl:value-of select="$xml//*:string[@key='tag_name']/text()"/>
    </xsl:function>
    
    
</xsl:stylesheet>