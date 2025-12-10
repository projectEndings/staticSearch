<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://hcmc.uvic.ca/ns/staticSearch"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://hcmc.uvic.ca/ns/staticSearch"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> February 14, 2022; restarted in early 2025.</xd:p>
            <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>            
            <xd:p>This transformation is used to automatically convert a configuration
            file crafted for a pre-2.0 staticSearch to the configuration format for 2.0.</xd:p>
            <xd:p>For more information on changes, see the documentation and GitHub issues.</xd:p> 
            <xd:p>NOTE: We should parameterize the version numbers so this same transformation
            can be run for future changes.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>Include the schema processing for outlining default values,
            which is stored in a separate module.</xd:desc>
    </xd:doc>
    <xsl:include href="process_schema_for_config.xsl"/>
    
    <xd:doc>
        <xd:desc>This is an xml-to-xml identity transform.</xd:desc>
    </xd:doc>
    <xsl:output method="xml" encoding="UTF-8" exclude-result-prefixes="#all"
         normalization-form="NFC" indent="yes" />
    
    <xd:doc>
        <xd:desc>Since much of the configuration has not been changed,
                 this transform can be an identity transformation.</xd:desc>
    </xd:doc>
    <xsl:mode on-no-match="shallow-copy" exclude-result-prefixes="#all"/>
    
    <xd:doc>
        <xd:desc>This parameter controls how the transformation operates;
        the user gets to choose whether to overwrite the old file or not.
        Options are (o=overwrite|n=new).</xd:desc>
    </xd:doc>
    <xsl:param name="output" as="xs:string" select="'n'"/>
    
    <xd:doc>
        <xd:desc>Parameter (provided by ant) that provides the path to the schema,
            relative to the configuration file.</xd:desc>
    </xd:doc>
    <xsl:param name="ssSchemaPath" as="xs:string" select="'../schema/staticSearch.rng'"/>
    
    <xd:doc>
        <xd:desc>The output file is calculated based on the parameter above.</xd:desc>
    </xd:doc>
    <xsl:variable name="outputFile" as="xs:string" select="if ($output eq 'o') then base-uri(/) else replace(base-uri(/),'\.xml$','_v2.xml')"/>
    
    <xd:doc>
        <xd:desc>In v1 we allowed boolean parameters to take a variety of forms; this
        regex should match them all.</xd:desc>
    </xd:doc>
    <xsl:variable name="reBooleanTrue" as="xs:string">^\s*(t|true|1|y|yes)\s*$</xsl:variable>
    <xsl:variable name="reBooleanFalse" as="xs:string">^\s*(f|false|0|n|no)\s*$</xsl:variable>
    
    
    
    <xd:doc>
        <xd:desc>Root template: if the config is already set to 2.0, this transformation just ends
        and produces no results; otherwise, it creates a new configuration file (with v2 appended).</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="config[xs:integer(@version) = 2]">
                <xsl:message>WARNING: Configuration file <xsl:value-of select="base-uri(.)"/>
                    is already set to version=2, so this transformation will do nothing.
                </xsl:message>
            </xsl:when>
            <xsl:when test="$output eq 'n' and unparsed-text-available($outputFile)">
                <xsl:message terminate="yes">&#x0a;******************&#x0a;The file {$outputFile} already exists.&#x0a;Please delete or move it before running this process again.&#x0a;******************&#x0a;&#x0a;</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{$outputFile}">
                    <xsl:processing-instruction
                        name="xml-model">href="{$ssSchemaPath}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
                    <xsl:processing-instruction
                        name="xml-model">href="{$ssSchemaPath}" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
                    <xsl:message>Configuration file {base-uri(/)} converted to version 2 {format-date(current-date(), '[Y0001]-[M01]-[D01]')}, with output at {$outputFile}.</xsl:message>
                    <xsl:comment>Configuration file {base-uri(/)} converted to version 2 {format-date(current-date(), '[Y0001]-[M01]-[D01]')}.</xsl:comment>
                    <xsl:apply-templates/>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The config element itself needs the new version.</xd:desc>
    </xd:doc>
    <xsl:template match="config">
        <xsl:copy>
            <xsl:apply-templates select="@*[not(local-name() eq 'version')]"/>
            <xsl:attribute name="version" select="'2'"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This is where most of the changes have been made.</xd:desc>
    </xd:doc>
    <xsl:template match="params">
        <xsl:copy>
        <!-- The best approach here is to construct a complete file based on 
             what's present. -->
            <searchPage file="{hcmc:getString(searchFile/text(),$defaultParams?searchPage.file)}"/>
            <index recurse="{hcmc:getStrBoolean(recurse, $defaultParams?index.recurse)}"/>
            
            <!--Per #322, default stopword and dictionary files have been moved to their own dedicated directories,
                        so we should warn if it appears that a default may have been used -->
            <xsl:variable name="stopwordsFilePointer" 
                select="hcmc:getString(stopwordsFile, $defaultParams?stopwords.file)"
                as="xs:string"/>
            <xsl:variable name="resolvedStopwordsURI" 
                select="resolve-uri($stopwordsFilePointer)"
                as="xs:anyURI"/>
            <xsl:if test="matches($resolvedStopwordsURI,'/xsl/.+_stopwords.txt$')">
                <xsl:message 
                    select="'WARNING: Stopword files have been moved to /stopwords/; 
                            if you had been using a default stopwords file bundled with v1
                            of staticSearch (xsl/.+_stopwords.txt), then you may need to update
                            your config file to use /stopwords/.'
                            => normalize-space()"/>
                <xsl:comment>stopwords/@file may need to be changed to use a file in /stopwords/</xsl:comment>
            </xsl:if>
            <stopwords file="{$stopwordsFilePointer}"/>
            
            <!--Now do the same as above, but for the dictionary-->
            <xsl:variable name="dictionaryFilePointer" 
                select="hcmc:getString(dictionaryFile, $defaultParams?dictionary.file)"
                as="xs:string"/>
            <xsl:variable name="resolvedDictionaryURI" 
                select="resolve-uri($dictionaryFilePointer)"
                as="xs:anyURI"/>
            <xsl:if test="matches($resolvedDictionaryURI,'/xsl/.+_words.txt$')">
                <xsl:message 
                    select="'WARNING: Dictionary files have been moved to /dicts/;
                            if you had been using a default dictionary file bundled with
                            v1 of staticSearch (xsl/.+_words.txt), then you may need to update
                            your config file to use /dicts/.'
                            => normalize-space()"/>
                <xsl:comment>dictionary/@file may need to be changed to use a file in /dicts/</xsl:comment>
            </xsl:if>
            <dictionary file="{$dictionaryFilePointer}"/>
            
            <scoringAlgorithm name="{hcmc:getString(scoringAlgorithm, $defaultParams?scoringAlgorithm.name)}"/>
            <xsl:variable name="stemmerFolder" 
                select="if (stemmerFolder) then concat('stemmers/', stemmerFolder) else ()" as="xs:string?"/>
            <stemmer
                dir="{hcmc:getString($stemmerFolder, $defaultParams?stemmer.dir)}"/>
            <tokenizer minWordLength="{hcmc:getInteger(minWordLength, $defaultParams?tokenizer.minWordLength)}"/>
            <createContexts>
                <xsl:variable name="create" 
                    select="hcmc:getStrBoolean(createContexts, $defaultParams?createContexts.create)"
                    as="xs:string"/>
                <xsl:attribute name="create" select="$create"/>
                <!--If create is false, no other attributes are allowed, so we're done-->
                <xsl:if test="$create = 'true'">
                    <!--Always check phrasal search-->
                    <xsl:variable name="phrasalSearch" as="xs:string"
                        select="hcmc:getStrBoolean(phrasalSearch, $defaultParams?createContexts.phrasalSearch)"/>
                    <xsl:attribute name="phrasalSearch" select="$phrasalSearch"/>
                    <xsl:attribute name="wildcardSearch"
                        select="hcmc:getStrBoolean(wildcardSearch, $defaultParams?createContexts.wildcardSearch)"/>
                    <xsl:if test="$phrasalSearch = 'false'">
                        <xsl:attribute name="maxKwicsToHarvest"
                            select="hcmc:getInteger(maxKwicsToHarvest, $defaultParams?createContexts.maxKwicsToHarvest)"/>
                    </xsl:if>
                    <xsl:attribute name="maxKwicLength"
                        select="hcmc:getInteger(totalKwicLength, $defaultParams?createContexts.maxKwicLength)"/>
                    <xsl:attribute name="kwicTruncateString" 
                        select="hcmc:getString(kwicTruncateString, $defaultParams?createContexts.kwicTruncateString)"/>
                </xsl:if>
            </createContexts>
            <results 
                resultsPerPage="{hcmc:getInteger(resultsPerPage, $defaultParams?results.resultsPerPage)}"
                maxKwicsToShow="{hcmc:getInteger(maxKwicsToShow, $defaultParams?results.maxKwicsToShow)}"
                maxResults="{hcmc:getInteger(resultsLimit, $defaultParams?results.maxResults)}"/>
            <version file="{hcmc:getString(versionFile, $defaultParams?version.file)}"/>
            <output dir="{hcmc:getString(outputFolder, $defaultParams?output.dir)}"/>
        </xsl:copy>
        
        <!-- Now we handle the things we want to warn about. -->
        <xsl:apply-templates select="verbose | indentJSON | linkToFragmentId"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Verbose has been removed; use the ant parameter ssVerbose instead.</xd:desc>
    </xd:doc>
    <xsl:template match="verbose">
        <xsl:if test="matches(normalize-space(.),$reBooleanTrue,'i')">
            <xsl:message>WARNING: verbose has been removed; to add verbose messages to 
            the console during the build process, use the ant parameter ssVerbose.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>indentJSON has been removed since the option was meant purely for
        debugging the output JSON files, which can be better handled by external tools.</xd:desc>
    </xd:doc>
    <xsl:template match="indentJSON">
        <xsl:if test="matches(normalize-space(.),$reBooleanTrue,'i')">
            <xsl:message>WARNING: indentJSON has been removed and output files will no
            longer be indented.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>linkToFragmentId has been removed; it was experimental to begin with
            and is still not widely supported.</xd:desc>
    </xd:doc>
    <xsl:template match="linkToFragmentId">
        <xsl:if test="not(matches(normalize-space(.),$reBooleanTrue,'i'))">
            <xsl:message>WARNING: linkToFragmentId is no longer configurable; by default,
            all results will link to their nearest ancestor id. You can hide those links
            by targeting the .fidLink class in your CSS (e.g. .fidLink{{ display:none; }}).</xsl:message>
        </xsl:if>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>scrollToTextFragment has been removed; it was experimental to begin with
            and is still not widely supported.</xd:desc>
    </xd:doc>
    <xsl:template match="scrollToTextFragment">
        <xsl:if test="matches(normalize-space(.),$reBooleanTrue,'i')">
            <xsl:message>WARNING: scrollToTextFragment has been removed due to lack of
            browser support. See the documentation for alternative approaches for in-page
            highlighting, including the use of the ssHighlight.js across your document
            collection.</xsl:message>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Function to create boolean string values from unreliable or absent input.</xd:desc>
        <xd:param name="input" as="item()?">May be an element, attribute, or text node
            which contains the original value if it exists.</xd:param>
        <xd:param name="default" as="xs:boolean">The default value to use if the input does 
            not provide anything usable.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getStrBoolean" as="xs:string">
        <xsl:param name="input" as="item()?"/>
        <xsl:param name="default" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$input and matches($input, $reBooleanTrue, 'i')">
                <xsl:sequence select="'true'"/>
            </xsl:when>
            <xsl:when test="$input and matches($input, $reBooleanFalse, 'i')">
                <xsl:sequence select="'false'"/>
            </xsl:when>
            <xsl:when test="$default">
                <xsl:sequence select="'true'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'false'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Function to create string values from unreliable or absent input.</xd:desc>
        <xd:param name="input" as="item()?">May be an element, attribute, or text node
            which contains the original value if it exists.</xd:param>
        <xd:param name="default" as="xs:string?">The default value to use if the input does 
        not provide anything usable.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getString" as="xs:string">
        <xsl:param name="input" as="item()?"/>
        <xsl:param name="default" as="xs:string?"/>
        <xsl:message select="xs:string($input)"/>
        <xsl:choose>
            <xsl:when test="xs:string($input) and string-length($input) gt 0">
                <xsl:sequence select="xs:string($input)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$default"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Function to create integer values from unreliable or absent input.</xd:desc>
        <xd:param name="input" as="item()?">May be an element, attribute, or text node
            which contains the original value if it exists.</xd:param>
        <xd:param name="default" as="xs:integer">The default value to use if the input does 
            not provide anything usable.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getInteger" as="xs:integer">
        <xsl:param name="input" as="item()?"/>
        <xsl:param name="default" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$input and xs:integer($input)">
                <xsl:sequence select="xs:integer($input)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$default"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    
</xsl:stylesheet>