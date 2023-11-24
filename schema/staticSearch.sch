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
   <sch:ns xmlns="http://www.tei-c.org/ns/1.0"
            xmlns:math="http://www.w3.org/1998/Math/MathML"
            xmlns:svg="http://www.w3.org/2000/svg"
            xmlns:tei="http://www.tei-c.org/ns/1.0"
            xmlns:teix="http://www.tei-c.org/ns/Examples"
            xmlns:xh="http://www.w3.org/1999/xhtml"
            xmlns:xi="http://www.w3.org/2001/XInclude"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            uri="http://hcmc.uvic.ca/ns/staticSearch"
            prefix="ss"/>
   <pattern xmlns="http://purl.oclc.org/dsdl/schematron"
             xmlns:tei="http://www.tei-c.org/ns/1.0"
             xmlns:teix="http://www.tei-c.org/ns/Examples"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             id="d10e3373-constraint">
      <rule context="xh:span">
         <report test="descendant::*[not(namespace-uri(.) =               ('http://www.w3.org/1999/xhtml', 'http://www.tei-c.org/ns/1.0'))]">span descendants must be in the
              namespaces
              'http://www.w3.org/1999/xhtml', 'http://www.tei-c.org/ns/1.0'</report>
      </rule>
   </pattern>
   <sch:pattern xmlns="http://www.tei-c.org/ns/1.0"
                 xmlns:math="http://www.w3.org/1998/Math/MathML"
                 xmlns:svg="http://www.w3.org/2000/svg"
                 xmlns:tei="http://www.tei-c.org/ns/1.0"
                 xmlns:teix="http://www.tei-c.org/ns/Examples"
                 xmlns:xh="http://www.w3.org/1999/xhtml"
                 xmlns:xi="http://www.w3.org/2001/XInclude"
                 xmlns:xlink="http://www.w3.org/1999/xlink">
      <sch:rule context="ss:context">
         <sch:assert test="not(@label and @context = 'false')">
                      ERROR: If a context has a label, it must be a context for the purposes of indexing.
                    </sch:assert>
      </sch:rule>
   </sch:pattern>
   <sch:diagnostics/>
</sch:schema>
