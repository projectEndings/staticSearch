<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    version="3.0">
    
    <!--JT TO ADD DOCUMENTATION HERE-->
    
    
    <!--Include the configuration file, which is generated via another XSLT-->
    <xsl:include href="config.xsl"/>
    
    <!--ANd include the PORTER2STEMMER; we should also include PORTER1, I think
        and let users choose which one they want (tho, I don't see why anyone would
        use PORTER1 and not PORTER2-->
    <xsl:include href="porter2Stemmer.xsl"/>
    
    <!--Simple regular expression for match document names-->
    <xsl:variable name="docRegex">(.+)(\..?htm.?$)</xsl:variable>
    
    <!--Apostrophes-->
    <xsl:variable name="curlyAposOpen">‘</xsl:variable>
    <xsl:variable name="curlyAposClose">’</xsl:variable>
    <xsl:variable name="straightSingleApos">'</xsl:variable>
    <xsl:variable name="curlyDoubleAposOpen">“</xsl:variable>
    <xsl:variable name="curlyDoubleAposClose">”</xsl:variable>
    <xsl:variable name="straightDoubleApos">"</xsl:variable>
  
    
    <!--IMPORTANT: Do this to avoid indentation-->
    <xsl:output indent="no" method="xml"/>
    
    
    <!--Basic template-->
    <xsl:template match="/">
        <xsl:message>Found <xsl:value-of select="count($docs)"/> documents to process...</xsl:message>
        <xsl:call-template name="echoParams"/>
        <xsl:for-each select="$docs">
            <xsl:variable name="fn" select="tokenize(document-uri(),'/')[last()]" as="xs:string"/>
            <xsl:variable name="basename" select="replace($fn, $docRegex, '$1')"/>
            <xsl:variable name="extension" select="replace($fn,$docRegex,'$2')"/>
            <xsl:variable name="pass1OutDoc" select="concat($tempDir,$basename,'_pass1',$extension)"/>
            <xsl:variable name="tokenizedOutDoc" select="concat($tempDir,$basename,'_tokenized',$extension)"/>
            <xsl:message>Tokenizing <xsl:value-of select="document-uri()"/></xsl:message>
            <xsl:variable name="pass1">
                <xsl:apply-templates mode="pass1"/>
            </xsl:variable>
            
            <xsl:if test="$verbose">
                <xsl:message>Creating <xsl:value-of select="$pass1OutDoc"/></xsl:message>
                <xsl:result-document href="{$pass1OutDoc}">
                    <xsl:copy-of select="$pass1"/>
                </xsl:result-document>
            </xsl:if>
            <xsl:result-document href="{$tokenizedOutDoc}">
                <xsl:if test="$verbose">
                    <xsl:message>Creating <xsl:value-of select="$tokenizedOutDoc"/></xsl:message>
                </xsl:if>
                <xsl:apply-templates select="$pass1" mode="tokenize"/>
            </xsl:result-document>
           
        </xsl:for-each>
    </xsl:template>
    
 <!--*****************************************************
      Pass 1 templates
      ****************************************************-->
    
    <!--Basic template to strip away extraneous tags around things we don't care about-->
    <!--Note that this template is overriden with any XPATHS configured in the config file-->
    <xsl:template match="span | br | wbr | em | b | i | a" mode="pass1">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <!--Here is where we normalize the string values-->
    <xsl:template match="text()" mode="pass1">
        <xsl:value-of select="replace(.,string-join(($curlyAposOpen,$curlyAposClose),'|'), $straightSingleApos) => replace(string-join(($curlyDoubleAposOpen,$curlyDoubleAposClose),'|'),$straightDoubleApos)"/>
    </xsl:template>
    
 <!--TOKENIZE TEMPLATES -->
    
    <!--The basic thing: tokenizing the string at the text level-->
    <xsl:template match="text()[ancestor::body][not(matches(.,'^\s+$'))]" mode="tokenize">
        <xsl:variable name="currNode" select="."/>
        <xsl:variable name="regex" select="concat('[A-Za-z\d',$straightDoubleApos,$straightDoubleApos,']+')"/>
        <!--Match on word tokens-->
        <!--TODO: THIS NEEDS TO BE FINESSED TO HANDLE CONTRACTIONS, 
            DECIMALS, ET CETERA-->
        <xsl:analyze-string select="." regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="word" select="."/>
                <xsl:variable name="wordToStem" select="replace($word,$straightDoubleApos,'')"/>
                <xsl:variable name="lcWord" select="lower-case($wordToStem)"/>
                <xsl:if test="$verbose">
                    <xsl:message>$word: <xsl:value-of select="$word"/></xsl:message>
                </xsl:if>
                <xsl:variable name="lcWord" select="lower-case($word)"/>
                <xsl:if test="$verbose">
                    <xsl:message>$lcWord: <xsl:value-of select="$lcWord"/></xsl:message>
                </xsl:if>
                <xsl:variable name="shouldIndex" select="hcmc:shouldIndex($lcWord)"/>
                <xsl:if test="$verbose">
                    <xsl:message>$shouldIndex: <xsl:value-of select="$shouldIndex"/></xsl:message>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$shouldIndex">
                        <span>
                            <xsl:copy-of select="hcmc:getStem($wordToStem)"/>
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    

    
    
    <xsl:function name="hcmc:getStem" as="attribute(data-staticSearch-stem)">
        <xsl:param name="word"/>
        <xsl:variable name="lcWord" select="lower-case($word)"/>
        <xsl:variable name="startsWithCap" select="matches($word,'^[A-Z]')" as="xs:boolean"/>
        <xsl:variable name="isAllCaps" select="matches($word,'^[A-Z]+$')" as="xs:boolean"/>
        <xsl:variable name="containsDigit" select="matches($word,'\d+')" as="xs:boolean"/>
        <xsl:variable name="stemVal" as="xs:string+">
            <xsl:choose>
                <!--If it has a digit, then it makes no sense to stem it-->
                <xsl:when test="$containsDigit">
                    <xsl:value-of select="$word"/>
                </xsl:when>
                <xsl:when test="$isAllCaps or $startsWithCap">
                    <xsl:value-of select="hcmc:stem($lcWord)"/>
                    <xsl:value-of select="concat(substring($word,1,1),lower-case(substring($word,2)))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="hcmc:stem($lcWord)"/>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>
        <xsl:attribute name="data-staticSearch-stem" 
            select="string-join($stemVal,' ')"/>
    </xsl:function>
    
    
    
    <xsl:function name="hcmc:shouldIndex" as="xs:boolean">
        <xsl:param name="lcWord" as="xs:string"/>
        <xsl:sequence select="string-length($lcWord) gt 2 and not($lcWord = $englishStopwords)"/>
    </xsl:function>
    
    

    
    <!--IDenTITY-->
   <xsl:template match="@*|node()" mode="#all" priority="-1">
       <xsl:copy>
           <xsl:apply-templates select="@*|node()" mode="#current"/>
       </xsl:copy>
   </xsl:template>
    
</xsl:stylesheet>