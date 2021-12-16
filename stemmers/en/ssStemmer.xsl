<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  version="3.0"
  xmlns:ss="http://hcmc.uvic.ca/ns/ssStemmer">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Started on:</xd:b> May 17, 2019</xd:p>
      <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
      <xd:p>This is an implementation of the Porter2 stemmer
        described at <xd:a href="https://snowballstem.org/algorithms/english/stemmer.html">snowballstem.org</xd:a>.
        It is adapted from <xd:a href="https://github.com/joeytakeda/xslt-stemmer/blob/master/porterStemmer.xsl">Joey Takeda's implementation</xd:a> of the original Porter Stemmer, and draws on Chris McKenzie (Kristopolous)'s <xd:a href="https://github.com/kristopolous/Porter2-Stemmer">JavaScript implementation of Porter2</xd:a>.
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  
  
   <!--**************************************************************
       *                                                            * 
       *                    Parameters                              *
       *                                                            *
       **************************************************************-->
  
  <!-- None so far. -->
  
   <!--**************************************************************
       *                                                            * 
       *                    Variables                               *
       *                                                            *
       **************************************************************-->
  
  <xd:doc scope="component">
    <xd:desc>The <xd:ref name="vowel">vowel</xd:ref> variable is a character 
      class of vowels [aeiouy].</xd:desc>
  </xd:doc>
  <xsl:variable name="vowel" as="xs:string">[aeiouy]</xsl:variable>
  
  <xd:doc>
    <xd:desc>The <xd:ref name="nonVowel">nonVowel</xd:ref> variable is 
      a character class of non-vowels.</xd:desc>
  </xd:doc>
  <xsl:variable name="nonVowel">[^aeiouy]</xsl:variable>
  
  <xd:doc>
    <xd:desc>The <xd:ref name="endsWithShortSyllable">endsWithShortSyllable</xd:ref>
    variable is used when checking whether a word is "short", and also in Step 5.</xd:desc>
  </xd:doc>
  <xsl:variable name="endsWithShortSyllable" select="concat($nonVowel, $vowel, '[^aeiouywxY]$')"/>
  
  <xd:doc scope="component">
    <xd:desc>The <xd:ref name="dbl">dbl</xd:ref> variable is a character 
      class of doubled consonants ((bb)|(dd)|(ff)|(gg)|(mm)|(nn)|(pp)|(rr)|(tt)). 
      Note that Kristopolous has this as [bdfgmnprt]{2}, but this would 
      allow bd, ng, and other combinations, so I don't believe it's correct.
    </xd:desc>
  </xd:doc>
  <xsl:variable name="dbl" as="xs:string">((bb)|(dd)|(ff)|(gg)|(mm)|(nn)|(pp)|(rr)|(tt))</xsl:variable>
  
  <xd:doc scope="component">
    <xd:desc>The <xd:ref name="liEnding">liEnding</xd:ref> variable is a character 
      class of consonants [cdeghkmnrt].</xd:desc>
  </xd:doc>
  <xsl:variable name="liEnding" as="xs:string">[cdeghkmnrt]</xsl:variable>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="R1R2Rex">R1R2Rex</xd:ref> is a regular expression
      which returns R1, defined as "the region after the first non-vowel 
      following a vowel, or the end of the word if there is no such non-vowel".
      See exceptional cases below. It also returns R2 when applied to R1.
    </xd:desc>
  </xd:doc>
  <!--<xsl:variable name="R1R2Rex" as="xs:string" select="concat($nonVowel, '*', $vowel, $nonVowel, '(.*)$')"/>-->
  <xsl:variable name="R1R2Rex" as="xs:string" select="concat('^.*?', $vowel, $nonVowel, '(.*)$')"/>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="R1ExceptRex">R1ExceptRex</xd:ref> is a regular expression
      which for the exceptions: "If the words begins gener, commun or arsen, set R1 
      to be the remainder of the word."
    </xd:desc>
  </xd:doc>
  <xsl:variable name="R1ExceptRex" as="xs:string">^(gener|commun|arsen)(.*)$</xsl:variable>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="step2Seq">step2Seq</xd:ref> is a list of suffixes to
    be evaluated against a token; as soon as one is matched, the rest are ignored,
    and if the match location is in R1, a replacement operation is done. 
    The format is:
      prematch|match:replacement 
    where prematch is a component that must exist, but does not have to be in R1.
    So for example: "logi" matches, and the "o" must be in R1 to satisfy the condition.
    </xd:desc>
  </xd:doc>
  <xsl:variable name="step2Seq" as="xs:string+" 
    select="(
    'ousness:ous',
    'iveness:ive',
    'fulness:ful',
    'ization:ize',
    'ational:ate',
    'biliti:ble',
    'tional:tion',
    'lessli:less',
    'ousli:ous',
    'fulli:ful',
    'iviti:ive',
    'entli:ent',
    'alism:al',
    'aliti:al',
    'enci:ence',
    'anci:ance',
    'abli:able',
    'izer:ize',
    'ation:ate',
    'ator:ate',
    'alli:al',
    'bli:ble',
    'l|ogi:og',
    concat($liEnding, '|li:')
    )"/>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="step3Seq">step3Seq</xd:ref> is a list of suffixes to
      be evaluated against a token; as soon as one is matched, the rest are ignored,
      and if the match location is in R1 (or in R2 for the last one), a replacement 
      operation is done. 
      The format is:
      whichR|match:replacement 
      where whichR is either "1" or "2".
      So for example: "ative" matches, but the match must be in R2 to satisfy the condition.</xd:desc>
  </xd:doc>
  <xsl:variable name="step3Seq" as="xs:string+" 
    select="(
    '1|ational:ate',
    '1|tional:tion',
    '1|alize:al',
    '1|icate:ic',
    '1|iciti:ic',
    '2|ative:',
    '1|ical:ic',
    '1|ness:',
    '1|ful:'
    )"/>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="step4Seq">step4Seq</xd:ref> is a list of suffixes to
      be evaluated against a token; as soon as one is matched, the rest are ignored,
      and if the match location is in R2, a delete operation is done. 
      The format is:
      prematch|match 
      So for example: "al" matches, but the match must be in R2 to satisfy the condition.
    </xd:desc>
  </xd:doc>
  <xsl:variable name="step4Seq" as="xs:string+"
    select="(
    'ement',
    'ment',
    'ance',
    'ence',
    'able',
    'ible',
    'ant',
    'ent',
    'ism',
    'ate',
    'iti',
    'ous',
    'ive',
    'ize',
    '[st]|ion',
    'al',
    'er',
    'ic'
    )"/>
  
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="exceptions">exceptions</xd:ref> is a list of exceptional forms
      and their matching stems, to be processed before the rest of the stemming takes place.
      The format is:
      token:stem 
      This list includes items from two lists in the Porter2 description: the set of special words which have
      hard-coded stems, and the set of words which should remain unchanged. </xd:desc>
  </xd:doc>
  <xsl:variable name="exceptions" as="xs:string+"
    select="(
    'skis:ski',
    'skies:sky',
    'dying:die',
    'lying:lie',
    'tying:tie',
    'idly:idl',
    'gently:gentl',
    'ugly:ugli',
    'early:earli',
    'only:onli',
    'singly:singl',
    'sky:sky',
    'news:news',
    'howe:howe',
    'atlas:atlas',
    'cosmos:cosmos',
    'bias:bias',
    'andes:andes'
    )"/>
  
  <xd:doc>
    <xd:desc><xd:ref name="exceptionsTokens">exceptionsTokens</xd:ref> is a pre-generated
    list from the above set, for faster matching.</xd:desc>
  </xd:doc>
  <xsl:variable name="exceptionsTokens" as="xs:string+"
    select="for $e in $exceptions return substring-before($e, ':')"/>
    
  <xd:doc>
    <xd:desc><xd:ref name="exceptionsStems">exceptionsStems</xd:ref> is a pre-generated
      list from the above set, for faster replacement.</xd:desc>
  </xd:doc>
  <xsl:variable name="exceptionsStems" as="xs:string+"
    select="for $e in $exceptions return substring-after($e, ':')"/>
  
  <xd:doc>
    <xd:desc><xd:ref name="step1aExceptions">step1aExceptions</xd:ref> is a short list
    of items to be left unchanged if they are found after step 1a.</xd:desc>
  </xd:doc>
  <xsl:variable name="step1aExceptions" as="xs:string+"
  select="(
  'inning', 'outing', 'canning', 'herring', 'earring', 'proceed', 'exceed', 'succeed'
  )"/>
  
   <!--**************************************************************
       *                                                            * 
       *                         Functions                          *
       *                                                            *
       **************************************************************-->
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:stem" type="function">ss:stem</xd:ref> is the core function that
      takes a single token and returns its stemmed version. This function should be deterministic
      (same results every time from same input), so we mark it as new-each-time="no".
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:result>The stemmed version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:stem" as="xs:string" new-each-time="no">
    <xsl:param name="token" as="xs:string"/>
    <xsl:variable name="normToken" as="xs:string" select="normalize-unicode($token, 'NFC')"/>
    <xsl:choose>
      <xsl:when test="string-length($normToken) lt 3"><xsl:value-of select="$normToken"/></xsl:when>
      <xsl:when test="$normToken = $exceptionsTokens"><xsl:value-of select="$exceptionsStems[index-of($exceptionsTokens, $normToken)]"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="preflight" select="replace(replace(replace($normToken, '^''', ''), '^y', 'Y'), concat('(', $vowel, ')y'), '$1Y')"/>
        <xsl:variable name="R" select="ss:getR1AndR2($preflight)"/>
        <xsl:variable name="step0" select="ss:step0($preflight)"/>
        <xsl:variable name="step1" select="ss:step1($step0, $R[3])"/>
        <xsl:choose>
          <xsl:when test="$step1 = $step1aExceptions">
            <xsl:value-of select="$step1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="step2" select="ss:step2($step1, $R[3])"/>
            <xsl:variable name="step3" select="ss:step3($step2, $R[3], $R[4])"/>
            <xsl:variable name="step4" select="ss:step4($step3, $R[4])"/>
            <xsl:variable name="step5" select="ss:step5($step4, $R[3], $R[4])"/>
            <xsl:value-of select="$step5"/>
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:preflight" type="function">ss:preflight</xd:ref> does a couple of simple
      replacements that need to precede the actual stemming process.
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:preflight" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:value-of select="replace(replace(replace($token, '^''', ''), '^y', 'Y'), concat('(', $vowel, ')y'), '$1Y')"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step0" type="function">ss:step0</xd:ref> trims plural/possessive
      type suffixes from the end,
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step0" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:value-of select="replace($token, '''(s('')?)?$', '')"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step1" type="function">ss:step1</xd:ref> performs three replacements
      on the end of a token (1a, 1b and 1c).
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R1">Offset of the R1 region in the token</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step1" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R1" as="xs:integer"/>
    
    <!-- Some regular expressions used only in this function. -->
    <xsl:variable name="step1a2Rex">(..)((ied)|(ies))$</xsl:variable>
    <!--<xsl:variable name="step1a3Rex" select="concat('(', $vowel, '.*', $nonVowel, '.*)s$')"/>-->
    <xsl:variable name="step1a3Rex" select="concat('(.*', $vowel, '.+)s$')"/>
    <xsl:variable name="step1b2Rex" select="concat('(', $vowel, '.*)((ed)|(ing))(ly)?$')"/>
    <xsl:variable name="step1cRex" select="concat('(.+', $nonVowel, ')[Yy]$')"/>
    
    <xsl:variable name="step1a">
      <xsl:choose>
        <xsl:when test="matches($token, 'sses$')">
          <xsl:value-of select="replace($token, 'sses$', 'ss')"/>
        </xsl:when>
        <xsl:when test="matches($token, $step1a2Rex)"><xsl:value-of select="replace($token, '((ied)|(ies))$', 'i')"/></xsl:when>
        <xsl:when test="matches($token, '((ied)|(ies))$')"><xsl:value-of select="replace($token, '((ied)|(ies))$', 'ie')"/></xsl:when>
        <xsl:when test="matches($token, $step1a3Rex) and not(matches($token, '((us)|(ss))$'))"><xsl:value-of select="replace($token, $step1a3Rex, '$1')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$token"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
<!--  Step 1b on the face of it looks like it could be handled by
      a token sequence with xsl:iterate, but it turns out that the
      steps required for each ending vary so much that conditionals
      make more sense. -->
    <xsl:variable name="step1b">
      <xsl:choose>
        <xsl:when test="$step1a = $step1aExceptions">
          <xsl:value-of select="$step1a"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="matches($step1a, 'eed(ly)?$')">
                <xsl:variable name="tmp1" select="replace($step1a, 'eed(ly)?$', 'ee')"/>
                <xsl:value-of select="if ((string-length($tmp1) + 1) ge $R1) then $tmp1 else $step1a"/>
              </xsl:when>
              <xsl:when test="matches($step1a, $step1b2Rex)">
                <xsl:variable name="step1b2a" select="replace($step1a, $step1b2Rex, '$1')"/>
                <xsl:value-of select="if (matches($step1b2a, '((at)|(bl)|(iz))$')) then concat($step1b2a, 'e') 
                  else if (matches($step1b2a, concat($dbl, '$'))) then 
                  substring($step1b2a, 1, string-length($step1b2a) - 1) 
                  else if (ss:wordIsShort($step1b2a, $R1)) then concat($step1b2a, 'e')
                  else $step1b2a"/>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$step1a"/></xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="if (matches($step1b, $step1cRex)) then replace($step1b, $step1cRex, '$1i') else $step1b"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step2" type="function">ss:step2</xd:ref> consists
      of a sequence of items to be evaluated against the input token; if a match
      occurs, then a) a replacement operation is done ONLY IF the match is in
      R1, and b) the process exits whether or not a replacement was done.
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R1">Offset of the R1 region in the token</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step2" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R1" as="xs:integer"/>
    <xsl:variable name="resultToken" as="xs:string">
      <xsl:iterate select="$step2Seq">
        <xsl:param name="token" as="xs:string" select="$token"/>
        <xsl:param name="R1" as="xs:integer" select="$R1"/>
        <xsl:on-completion select="$token"/>
        <xsl:variable name="rex" select="concat(translate(substring-before(., ':'), '|', ''), '$')"/>
        <xsl:variable name="nuked" select="replace($token, $rex, '')"/>
        <xsl:choose>
  <!--  Simplest quick test: does it match?       -->
          <xsl:when test="$token != $nuked">
            <!--<xsl:message><xsl:value-of select="concat('Matched ', $token, ' against ', $rex)"/></xsl:message>-->
            <xsl:variable name="rep" select="substring-after(., ':')"/>
            <xsl:choose>
              <xsl:when test="contains(., '|')">
<!--    Special case: there's a leading component.          -->
                <xsl:value-of select="if ((string-length($nuked) + 2) ge $R1) then replace($token, concat(substring-after(substring-before(., ':'), '|'), '$'), $rep) else $token"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="if ((string-length($nuked) + 1) ge $R1) then replace($token, $rex, $rep) else $token"/>
              </xsl:otherwise>
            </xsl:choose>
<!--    Once we have a match, we break irrespective of whether we did a replace.        -->
            <xsl:break/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:next-iteration/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:iterate>
    </xsl:variable>
    <xsl:value-of select="$resultToken"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step3" type="function">ss:step3</xd:ref> consists
      of a sequence of items to be evaluated against the input token; if a match
      occurs, then a) a replacement operation is done ONLY IF the match is in
      a specified region, and b) the process exits whether or not a replacement 
      was done.
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R1">Offset of the R1 region in the token</xd:param>
    <xd:param name="R2">Offset of the R2 region in the token</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step3" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R1" as="xs:integer"/>
    <xsl:param name="R2" as="xs:integer"/>
    <xsl:variable name="resultToken" as="xs:string">
      <xsl:iterate select="$step3Seq">
        <xsl:param name="token" as="xs:string" select="$token"/>
        <xsl:param name="R1" as="xs:integer" select="$R1"/>
        <xsl:param name="R2" as="xs:integer" select="$R2"/>
        <xsl:on-completion select="$token"/>
        <xsl:variable name="offset" select="if (starts-with(., '1')) then $R1 else $R2"/>
        <xsl:variable name="rex" select="concat(translate(substring-before(., ':'), '12|', ''), '$')"/>
        <xsl:variable name="nuked" select="replace($token, $rex, '')"/>
        <!--<xsl:message>Rex = <xsl:value-of select="$rex"/> Nuked version = <xsl:value-of select="$nuked"/></xsl:message>-->
        <xsl:choose>
          <!-- Quick test: does it match?       -->
          <xsl:when test="$token != $nuked">
            <!--<xsl:message><xsl:value-of select="concat('Matched ', $token, ' against ', $rex)"/></xsl:message>-->
            <xsl:variable name="rep" select="substring-after(., ':')"/>
            <xsl:value-of select="if ((string-length($nuked) + 1) ge $offset) then replace($token, $rex, $rep) else $token"/>
            <!--    Once we have a match, we break irrespective of whether we did a replace.        -->
            <xsl:break/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:next-iteration/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:iterate>
    </xsl:variable>
    <xsl:value-of select="$resultToken"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step4" type="function">ss:step4</xd:ref> consists
      of a sequence of items to be evaluated against the input token; if a match
      occurs, then a) a deletion operation is done ONLY IF the match is in
      R2, and b) the process exits whether or not a replacement was done.
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R2">Offset of the R2 region in the token</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step4" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R2" as="xs:integer"/>
    <xsl:variable name="resultToken" as="xs:string">
      <xsl:iterate select="$step4Seq">
        <xsl:param name="token" as="xs:string" select="$token"/>
        <xsl:param name="R2" as="xs:integer" select="$R2"/>
        <xsl:on-completion select="$token"/>
        <xsl:variable name="rex" select="concat(translate(., '|', ''), '$')"/>
        <xsl:choose>
          <!--  Simplest quick test: does it match?       -->
          <xsl:when test="matches($token, $rex)">
<!--            <xsl:message><xsl:value-of select="concat('Matched ', $token, ' against ', $rex)"/></xsl:message>-->
            <xsl:choose>
              <xsl:when test="contains(., '|')">
                <!--    Special case: there's a leading component.          -->
                <xsl:variable name="replaced" select="replace($token, concat(substring-after(., '|'), '$'), '')"/>
                <xsl:value-of select="if ((string-length($replaced) + 2) ge $R2) then $replaced else $token"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="replaced" select="replace($token, $rex, '')"/>
                <!--<xsl:message>Length of replacement "<xsl:value-of select="$replaced"/>" = <xsl:value-of select="string-length($replaced)"/></xsl:message>
                <xsl:message>R2 = <xsl:value-of select="$R2"/></xsl:message>-->
                <xsl:value-of select="if ((string-length($replaced) + 1) ge $R2) then $replaced else $token"/>
              </xsl:otherwise>
            </xsl:choose>
            <!--    Once we have a match, we break irrespective of whether we did a replace.        -->
            <xsl:break/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:next-iteration/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:iterate>
    </xsl:variable>
    <xsl:value-of select="$resultToken"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:step5" type="function">ss:step5</xd:ref> consists
      of two specific replacements which are context-dependent:
      "Search for the the following suffixes, and, if found, perform the action indicated.
        e delete if in R2, or in R1 and not preceded by a short syllable* 
        l delete if in R2 and preceded by l"
      "Finally, turn any remaining Y letters in the word back into lower case. "
      
      *On mailing list, MP confirms that this means _immediately_ preceded by a 
       short syllable.
    </xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R1">Offset of the R1 region in the token</xd:param>
    <xd:param name="R2">Offset of the R2 region in the token</xd:param>
    <xd:result>The treated version of the token.</xd:result>
  </xd:doc>
  <xsl:function name="ss:step5" as="xs:string">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R1" as="xs:integer"/>
    <xsl:param name="R2" as="xs:integer"/>
    <xsl:variable name="step5a" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($token, 'e$')">
          <xsl:variable name="replaced" select="replace($token, 'e$', '')"/>
          <!--<xsl:message>replaced = <xsl:value-of select="$replaced"/>; match = <xsl:value-of select="matches($replaced, concat('(^', $vowel, $nonVowel, '$)|(', $endsWithShortSyllable, ')'))"/></xsl:message>-->
          <xsl:choose>
            <xsl:when test="(string-length($replaced) + 1) ge $R2">
              <xsl:value-of select="$replaced"/>
            </xsl:when>
            <xsl:when test="(string-length($replaced) + 1) ge $R1 and not(matches($replaced, concat('(^', $vowel, $nonVowel, '$)|(', $endsWithShortSyllable, ')')))">
              <xsl:value-of select="$replaced"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$token"/></xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$token"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- We do this only if step5a did not result in a change. -->
    <xsl:variable name="step5b" as="xs:string">
      <xsl:choose>
        <xsl:when test="($step5a = $token) and matches($step5a, 'll$')">
          <xsl:variable name="replaced" select="replace($step5a, 'l$', '')"/>
          <xsl:value-of select="if ((string-length($replaced) + 2) gt $R2) then $replaced else $step5a"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$step5a"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="translate($step5b, 'Y', 'y')"/>
  </xsl:function>
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:getR1AndR2" type="function">ss:getR1AndR2</xd:ref>
      decomposes an input token to get the R1 and R2 regions, and returns the string values of those two 
      regions, along with their offsets.</xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:result>A sequence consisting of two strings for R1 and R2 respectively,
      ant two integers for the offsets of R1 and R2.</xd:result>
  </xd:doc>
  <xsl:function name="ss:getR1AndR2" as="item()+">
    <xsl:param name="token" as="xs:string"/>
    <xsl:variable name="R1" as="xs:string" select="if (matches($token, $R1ExceptRex)) 
                                                   then replace($token, $R1ExceptRex, '$2') 
                                                   else if (matches($token, $R1R2Rex)) then 
                                                   replace($token, $R1R2Rex, '$1') else
                                                   ''"/>
    <xsl:variable name="R1Index" as="xs:integer" select="(string-length($token) - string-length($R1)) + 1"/>
    <xsl:variable name="R2Candidate" as="xs:string" select="replace($R1, $R1R2Rex, '$1')"/>
    <xsl:variable name="R2" select="if ($R2Candidate = $R1) then '' else $R2Candidate"/>
    <xsl:variable name="R2Index" as="xs:integer" select="if ($R2Candidate = $R1) then string-length($token) + 1 else (string-length($token) - string-length($R2)) + 1"/>
    <xsl:sequence select="($R1, $R2, $R1Index, $R2Index)"/>
  </xsl:function>
  
  
  <xd:doc scope="component">
    <xd:desc><xd:ref name="wordIsShort" type="function">wordIsShort</xd:ref> returns a boolean
    value from testing the input word against a regular expression to determine whether
    it matches the Porter2 definition of a short word. A short syllable is "either (a) a 
    vowel followed by a non-vowel other than w, x or Y and preceded by a non-vowel, or * (b) a
    vowel at the beginning of the word followed by a non-vowel," and "a word is called short 
    if it ends in a short syllable, and if R1 is null." R1 being null basically means the
    R1 region is empty; that means it starts after the end of the word, so its offset is
    the word-length + 1.</xd:desc>
    <xd:param name="token">Input token string</xd:param>
    <xd:param name="R1">Integer position of R1 in this token.</xd:param>
    <xd:result>True or false</xd:result>
  </xd:doc>
  <xsl:function name="ss:wordIsShort" as="xs:boolean">
    <xsl:param name="token" as="xs:string"/>
    <xsl:param name="R1" as="xs:integer"/>
    <xsl:variable name="R1IsNull" as="xs:boolean" select="string-length($token) lt $R1"/>
<!--    The second regex matches at the beginning, and we just need to know if it's only a
        short syllable. -->
    <xsl:variable name="rex2" select="concat('^', $vowel, $nonVowel, $nonVowel, '*$')"/>
    
    <xsl:sequence select="((matches($token, $endsWithShortSyllable) or matches($token, $rex2)) and $R1IsNull)"/>
    
  </xsl:function>
  
  
  <!--**************************************************************
       *                                                            * 
       *                          Testing                           *
       *                                                            *
       **************************************************************-->
  <xd:doc scope="component">
    <xd:desc><xd:ref name="porterTestData">porterTestData</xd:ref> is a list of words
      and the stems that should result from them, taken from the algorithm description
      at https://snowballstem.org/algorithms/english/stemmer.html.
      The format is:
      word:stem 
      Some items from the exceptions are also added.
      </xd:desc>
  </xd:doc>
  <xsl:variable name="porterTestData" as="xs:string+"
    select="(
    'consign:consign', 
    'consigned:consign', 
    'consigning:consign', 
    'consignment:consign', 
    'consist:consist', 
    'consisted:consist', 
    'consistency:consist', 
    'consistent:consist', 
    'consistently:consist', 
    'consisting:consist', 
    'consists:consist', 
    'consolation:consol', 
    'consolations:consol', 
    'consolatory:consolatori', 
    'console:consol', 
    'consoled:consol', 
    'consoles:consol', 
    'consolidate:consolid', 
    'consolidated:consolid', 
    'consolidating:consolid', 
    'consoling:consol', 
    'consolingly:consol', 
    'consols:consol', 
    'consonant:conson', 
    'consort:consort', 
    'consorted:consort', 
    'consorting:consort', 
    'conspicuous:conspicu', 
    'conspicuously:conspicu', 
    'conspiracy:conspiraci', 
    'conspirator:conspir', 
    'conspirators:conspir', 
    'conspire:conspir', 
    'conspired:conspir', 
    'conspiring:conspir', 
    'constable:constabl', 
    'constables:constabl', 
    'constance:constanc', 
    'constancy:constanc', 
    'constant:constant', 
    'knack:knack', 
    'knackeries:knackeri', 
    'knacks:knack', 
    'knag:knag', 
    'knave:knave', 
    'knaves:knave', 
    'knavish:knavish', 
    'kneaded:knead', 
    'kneading:knead', 
    'knee:knee', 
    'kneel:kneel', 
    'kneeled:kneel', 
    'kneeling:kneel', 
    'kneels:kneel', 
    'knees:knee', 
    'knell:knell',
    'knelt:knelt', 
    'knew:knew', 
    'knick:knick', 
    'knif:knif', 
    'knife:knife', 
    'knight:knight', 
    'knightly:knight', 
    'knights:knight', 
    'knit:knit', 
    'knits:knit', 
    'knitted:knit', 
    'knitting:knit', 
    'knives:knive', 
    'knob:knob', 
    'knobs:knob', 
    'knock:knock', 
    'knocked:knock', 
    'knocker:knocker', 
    'knockers:knocker', 
    'knocking:knock', 
    'knocks:knock', 
    'knopp:knopp', 
    'knot:knot', 
    'knots:knot',
    'skis:ski',
    'dying:die',
    'news:news',
    'herrings:herring',
    'proceed:proceed'
    )"/>
    
  <xd:doc scope="component">
    <xd:desc><xd:ref name="ss:runTests" type="function">ss:runTests</xd:ref>
      feeds all of the test data into the ss:stem function and checks the 
     results. There is a local set of test data used for development, but 
     that test is commented out in favour of downloading and running
    the full set of 29,000+ items from the tartarus site.</xd:desc>
    <xd:result>A sequence consisting of boolean true or false: tests all passed = true, 
    any test failed = false, and an empty message or an error report.</xd:result>
  </xd:doc>
  <xsl:function name="ss:runTests" as="item()+">
    <!--<xsl:iterate select="$porterTestData">
      <xsl:on-completion select="(true(), '')"/>
      <xsl:variable name="result" select="ss:stem(substring-before(., ':'))"/>
      <xsl:choose>
        <xsl:when test="$result = substring-after(., ':')">
          <xsl:next-iteration/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="output">Failed test with input <xsl:value-of select="."/>. Result was <xsl:value-of select="$result"/></xsl:variable>
          <xsl:break select="(false(), $output)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:iterate>-->
    <xsl:variable name="fullTokenSetUrl" as="xs:string" select="'https://raw.githubusercontent.com/snowballstem/snowball-data/master/english/voc.txt'"/>
    <xsl:variable name="fullStemSetUrl" as="xs:string" select="'https://raw.githubusercontent.com/snowballstem/snowball-data/master/english/output.txt'"/>
    <xsl:variable name="fullTokenSet" select="
    if (unparsed-text-available('voc.txt')) 
    then tokenize(unparsed-text('voc.txt'), '[\n\s]+')
    else tokenize(unparsed-text($fullTokenSetUrl), '[\n\s]+')"/>
    <xsl:variable name="fullStemSet" select="
      if (unparsed-text-available('output.txt')) 
      then tokenize(unparsed-text('output.txt'), '[\n\s]+')
      else tokenize(unparsed-text($fullStemSetUrl), '[\n\s]+')"/>  
    <xsl:iterate select="$fullTokenSet">
      <xsl:on-completion select="(true(), '')"/>
      <xsl:variable name="pos" select="position()"/>
      <xsl:variable name="stem" select="$fullStemSet[$pos]"/>
      <xsl:variable name="result" select="ss:stem(.)"/>
      <xsl:choose>
        <xsl:when test="$result = $stem">
          <xsl:next-iteration/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="output"><xsl:text>&#x0a;</xsl:text> 
            Failed test with input: <xsl:value-of select="."/><xsl:text>&#x0a;</xsl:text> 
            at position <xsl:value-of select="$pos"/><xsl:text>&#x0a;</xsl:text> 
            Result should be: <xsl:value-of select="$stem"/>.<xsl:text>&#x0a;</xsl:text> 
            Result was <xsl:value-of select="$result"/></xsl:variable>
          <xsl:break select="(false(), $output)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:iterate>
  </xsl:function>
  
</xsl:stylesheet>