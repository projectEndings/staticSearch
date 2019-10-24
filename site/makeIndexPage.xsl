<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/staticSearch"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all" 
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 23, 2019</xd:p>
            <xd:p><xd:b>Author:</xd:b> joeytakeda</xd:p>
            <xd:p>A very simple stylesheet for creating the index page for deployment
            on github pages.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>Output as XHTML with HTML version 5.0; this is necessary for adding the
            propery DOCTYPE processing instruction.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" encoding="UTF-8" normalization-form="NFC"
        exclude-result-prefixes="#all" omit-xml-declaration="yes" html-version="5.0"/>
    
    <xsl:template name="go">
        <html id="index">
            <head>
                <title>Static Search</title>
            </head>
            <body>
                <header>
                    <h1>Static Search</h1>
                </header>
                <section>
                    <p>This is the development homepage for Static Search, a serverless search engine for static websites.</p>
                </section>
                <section>
                    <ul>
                        <li><a href="master/search.html">Master Branch</a></li>
                        <li><a href="dev/search.html">Development Branch</a></li>
                    </ul>
                </section>
            </body>
        </html>
    </xsl:template>
    
</xsl:stylesheet>