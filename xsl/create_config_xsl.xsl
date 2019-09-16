<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://hcmc.uvic.ca/ns/staticSearch"
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
    </xd:doc>
    <!--This stylesheet converts the configuration document into a temporary stylesheet-->
    
  <xsl:param name="configFile" select="'config.xml'"/>
    
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
    
    <xsl:variable name="baseDir" select="$configDoc//baseDir/text()" as="xs:string"/>
    <xsl:variable name="resolvedBaseDir" select="resolve-uri($baseDir,resolve-uri($configFile))"/>
    
    
    <xsl:variable name="verbose" select="hcmc:stringToBoolean($configDoc//verbose/text())" as="xs:boolean"/>
      
    
   <xd:doc>
       <xd:desc>
           <xd:p>We create a namespace alias of "xso" to create XSLT using XSLT.</xd:p>
       </xd:desc>
   </xd:doc>
    <xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl" />
    
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
            <xd:p>The <xd:ref name="contextRules" type="variable">contextRules</xd:ref> variable is
                a sequence of 0 or more rules that are specified as context blocks--blocks that are to
                be used in the JSON creation stage to create the context for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="contextRules" select="$configDoc//contexts/rule" as="element(rule)*"/>
    
    <xsl:variable name="weightedRules" select="$configDoc//rule[xs:integer(@weight) gt 1]" as="element(rule)*"/>
    
    
    <xd:doc>
        <xd:desc>This is the main, root template that creates config.xsl. This XSL is then imported into the 
        [[ADD TOKENIZING XSL NAME HERE]], overriding any existing rules that are included in the document.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Creating configuration file from <xsl:value-of select="$configFile"/></xsl:message>
        
        <xsl:if test="$verbose">
            <xsl:for-each select="$configDoc//params/*">
                <xsl:message>$<xsl:value-of select="local-name()"/>: <xsl:value-of select="."/></xsl:message>
            </xsl:for-each>
        </xsl:if>
        <xsl:result-document href="xsl/config.xsl" method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all">
            
            <!--Root stylesheet-->
            <xso:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
                exclude-result-prefixes="#all"
                xpath-default-namespace="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                version="3.0">
                
                <!--Simply documentation to add -->
                <xd:doc scope="stylesheet">
                    <xd:desc>
                        <xd:p>Created on <xsl:value-of select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/> by an automated process.</xd:p>
                        <xd:p><xd:b>Authors:</xd:b> Joey Takeda and Martin Holmes</xd:p>
                        <xd:p>
                            This is a temporary stylesheet derived from <xsl:value-of select="document-uri(/)"/>.
                        </xd:p>
                    </xd:desc>
                </xd:doc>
                
                <!--Now, create all the parameters-->
                
                <xsl:call-template name="createGlobals"/>
                
                <!--If there are retain rules specified in the configuration file,
                    then call the createRetainRules template-->
                <xsl:if test="not(empty($retainRules))">
                    <xsl:call-template name="createRetainRules"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create retain rules</xsl:message>
                      <xsl:message>  <xsl:call-template name="createRetainRules"/></xsl:message>
                    </xsl:if>
                </xsl:if>
                
                
                <!--If there are deletion rules specified in the configuration file,
                    then call the createDeleteRules template-->
                <xsl:if test="not(empty($deleteRules))">
                    <xsl:call-template name="createDeleteRules"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create delete rules</xsl:message>
                        <xsl:message>
                            <xsl:call-template name="createDeleteRules"/>
                        </xsl:message>
                    </xsl:if>
                </xsl:if>
                
                <xsl:if test="not(empty($contextRules))">
                    <xsl:call-template name="createContextRules"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create context rules</xsl:message>
                        <xsl:message>
                            <xsl:call-template name="createContextRules"/>
                        </xsl:message>
  
                    </xsl:if>
                </xsl:if>
                
                <xsl:if test="not(empty($weightedRules))">
                    <xsl:call-template name="createWeightingRules"/>
                    <xsl:if test="$verbose">
                        <xsl:message>Create weighting rules</xsl:message>
                        <xsl:message><xsl:call-template name="createWeightingRules"/></xsl:message>
                    </xsl:if>
                </xsl:if>
            </xso:stylesheet>
        </xsl:result-document>
          
        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createRetainRules" type="template">createRetainRules</xd:ref> template
            creates an XSL identity template for the xpaths specified in the configuration file that have
            either a weight greater than 0 OR want to be retained as a context item for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createRetainRules">
        <xso:template match="{string-join($retainRules/@xpath,' | ')}" priority="1" mode="clean">
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
    <xsl:template name="createDeleteRules">
        <xso:template match="{string-join($deleteRules/@xpath,' | ')}" priority="1" mode="clean">
            <xso:if test="$verbose">
                <xso:message>Template #clean: Deleting <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
        </xso:template>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createContextRules" type="template">createContextRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that are
                specified as context nodes for the kwic.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createContextRules">
        <xso:template match="{string-join($contextRules/@xpath,' | ')}" priority="1" mode="contextualize">
            <xso:if test="$verbose">
                <xso:message>Template #contextualize: Adding @data-staticSearch-context flag to <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
            <xso:copy>
                <xso:apply-templates select="@*" mode="#current"/>
                <xsl:for-each select="$contextRules">
                    <xso:if test="self::{@xpath}">
                        <xso:attribute name="data-staticSearch-context" select="{concat('''',hcmc:stringToBoolean(@context),'''')}"/>
                    </xso:if>
                </xsl:for-each>
                <xso:apply-templates select="node()" mode="#current"/>
            </xso:copy>
        </xso:template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="createWeightingRules" type="template">createWeightingRules</xd:ref> template
                creates an XSL identity template for the xpaths specified in the configuration file that have
                some non-0 weight specified.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createWeightingRules">
        <xso:template match="{string-join($weightedRules/@xpath,' | ')}" priority="1" mode="weigh">
            <xso:if test="$verbose">
                <xso:message>Template #weigh: Adding @data-weight to <xso:value-of select="local-name(.)"/></xso:message>
            </xso:if>
            <xso:copy>
                <xso:apply-templates select="@*" mode="#current"/>
                <xsl:for-each select="$weightedRules[xs:integer(@weight) gt 1]">
                    <xso:if test="self::{@xpath}">
                        <xso:attribute name="data-staticSearch-weight" select="{@weight}"/>
                    </xso:if>
                </xsl:for-each>
                <xso:apply-templates select="node()" mode="#current"/>
            </xso:copy>
        </xso:template>
    </xsl:template>
    

    
    
    <xd:doc>
        <xd:desc>This creates the global parameters and variables for the config file, which works as the global
            document for the transformations</xd:desc>
    </xd:doc>
    <xsl:template name="createGlobals">
       
        <xsl:variable name="params" as="element()+">
            <!--First, create the actual configuration file thing-->
            <xso:param name="configFile"><xsl:value-of select="resolve-uri($configFile)"/></xso:param>
            <xsl:for-each select="$configDoc//params/*" >
                <xsl:variable name="thisParam" select="."/>
                <xsl:variable name="paramName" select="local-name()"/>
                <xsl:variable name="isDirProp" select="matches($paramName, 'Dir$')" as="xs:boolean"/>
                <xsl:variable name="isFileProp" select="matches($paramName,'File$')" as="xs:boolean"/>
                <xsl:variable name="prependBaseDir" select="$isDirProp or $isFileProp"/>
                <xso:param>
                    <xsl:attribute name="name" select="local-name()"/>
                    <xsl:choose>
                        <xsl:when test="local-name()=('createContexts','phrasalSearch','verbose','recurse', 'indentJSON')">
                            <xsl:attribute name="select" select="concat(hcmc:stringToBoolean(xs:string(.)),'()')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="baseVal" select="
                                if ($prependBaseDir) 
                                then concat($resolvedBaseDir, 
                                if ($paramName = 'baseDir') 
                                then ()
                                else $thisParam/text())
                                else ."/>
                            <xsl:value-of select="
                                if ($isDirProp and not(ends-with($baseVal,'/'))) 
                                then concat($baseVal,'/') 
                                else $baseVal"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xso:param>
            </xsl:for-each>

        </xsl:variable>
        
       <xsl:sequence select="$params"/>
        
        <xsl:call-template name="createDictionaryXML"/>
      
        
        <!--Configure the collection use x?html? ( so htm, html, xhtml, xhtm would all work
        as files)-->
        
        <!--The documents to process; also could be created in the config file-->
        <!--Now create a set of other params, based off of the simple stuff-->
        
        <xso:variable name="searchDirName" select="
            if (contains($searchFile,'/')) then
            string-join(tokenize($searchFile,'/')[not(position() = last())],'/')
            else ()" as="xs:string?"/>

        <xso:variable name="collectionDir" select="$searchDirName"/>
        <xso:variable name="outDir" select="$collectionDir || '/staticSearch'"/>
        <xso:variable name="tempDir" select="$outDir || '/temp'"/>
        
     

        <xso:variable name="docs" select="collection(concat($collectionDir,'?select=*.*htm*;recurse=',if ($recurse) then 'yes' else 'no'))"/>
        
        <xso:variable name="tokenizedDocs" select="collection(concat($tempDir,'?select=*_tokenized.*htm*;recurse=',if ($recurse) then 'yes' else 'no'))"/>
        
        

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
    
    
    <xsl:template name="createDictionaryXML">
        <xsl:for-each select="($configDoc//stopwordsFile, $configDoc//dictionaryFile)">
           <xsl:variable name="path" select="resolve-uri(text(),$resolvedBaseDir)"/>
            <xsl:message>PATH: <xsl:value-of select="$path"/></xsl:message>
            <xsl:variable name="uri" select="concat($resolvedBaseDir,'dicts/',substring-before(tokenize($path,'/')[last()],'.txt'),'.xml')"/>
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
    
    
</xsl:stylesheet>