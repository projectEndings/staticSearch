<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sch:schema xmlns:rng="http://relaxng.org/ns/structure/1.0"
             xmlns:sch="http://purl.oclc.org/dsdl/schematron"
             queryBinding="xslt2">
   <sch:ns xmlns="http://relaxng.org/ns/structure/1.0"
            xmlns:tei="http://www.tei-c.org/ns/1.0"
            xmlns:teix="http://www.tei-c.org/ns/Examples"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            prefix="tei"
            uri="http://www.tei-c.org/ns/1.0"/>
   <ns xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:tei="http://www.tei-c.org/ns/1.0"
        xmlns:teix="http://www.tei-c.org/ns/Examples"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        prefix="xh"
        uri="http://www.w3.org/1999/xhtml"/>
   <pattern xmlns="http://purl.oclc.org/dsdl/schematron"
             xmlns:tei="http://www.tei-c.org/ns/1.0"
             xmlns:teix="http://www.tei-c.org/ns/Examples"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             id="d10e3357-constraint">
      <rule context="xh:label">
         <report test="descendant::*[not(namespace-uri(.) =               ('http://www.w3.org/1999/xhtml', 'http://www.tei-c.org/ns/1.0'))]">label descendants must be in the
              namespaces
              'http://www.w3.org/1999/xhtml', 'http://www.tei-c.org/ns/1.0'</report>
      </rule>
   </pattern>
   <sch:diagnostics/>
</sch:schema>
