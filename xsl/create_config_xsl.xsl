<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs"
    xpath-default-namespace="https://hcmc.uvic.ca/ns/"
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
    <xsl:variable name="retainRules" select="//rule[(xs:integer(@weight) gt 0) or parent::contexts]" as="element(rule)*"/>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The <xd:ref name="deleteRules" type="variable">deleteRules</xd:ref> variable is
                a sequence of 0 or more rules that either have have a weight of 0, which means that
                the xpaths specified should not be processed by the tokenizer and should be deleted
                from the document that will eventually be indexed.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="deleteRules" select="//rule[xs:integer(@weight) = 0]" as="element(rule)*"/>
    
    
    <xd:doc>
        <xd:desc>This is the main, root template that creates config.xsl. This XSL is then imported into the 
        [[ADD TOKENIZING XSL NAME HERE]], overriding any existing rules that are included in the document.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:result-document href="config.xsl" method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all">
            
            <!--Root stylesheet-->
            <xso:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                exclude-result-prefixes="#all"
                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns="http://www.tei-c.org/ns/1.0"
                version="2.0">
                
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
                
                <!--If there are retain rules specified in the configuration file,
                    then call the createRetainRules template-->
                <xsl:if test="not(empty($retainRules))">
                    <xsl:call-template name="createRetainRules"/>
                </xsl:if>
                
                
                <!--If there are deletion rules specified in the configuration file,
                    then call the createDeleteRules template-->
                <xsl:if test="not(empty($deleteRules))">
                    <xsl:call-template name="createDeleteRules"/>
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
        <xso:template match="{string-join($retainRules/@xpath,' | ')}" priority="1" mode="pass1">
            <xso:copy>
                <xsl:for-each select="$retainRules[xs:integer(@weight) gt 1]">
                    <xso:if test="self::{@xpath}">
                        <xso:attribute name="data-weight" select="{@weight}"/>
                    </xso:if>
                </xsl:for-each>
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
        <xso:template match="{string-join($deleteRules/@xpath,' | ')}" priority="1" mode="pass1"/>
    </xsl:template>
    
</xsl:stylesheet>