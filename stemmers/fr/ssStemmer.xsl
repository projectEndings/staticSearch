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
        <xd:p><xd:b>Started on:</xd:b> Oct 31, 2020</xd:p>
        <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
        <xd:p>This is an implementation of the French Snowball stemmer
          described at 
          <xd:a href="https://snowballstem.org/algorithms/french/stemmer.html">snowballstem.org</xd:a>. 
          It follows the pattern of the English stemmer in this project, but is much more 
          complicated because the algorithm for French is so.
        </xd:p>
      </xd:desc>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            * 
       *                    Variables                               *
       *     Many regular expressions are defined globally          *
       *     because they are used in more than one context.        *
       **************************************************************-->
  
    <xd:doc scope="component">
      <xd:desc>The <xd:ref name="vowel">vowel</xd:ref> variable is a character 
        class of vowels [aeiouyâàëéêèïîôûù].</xd:desc>
    </xd:doc>
    <xsl:variable name="vowel" as="xs:string">[aeiouyâàëéêèïîôûù]</xsl:variable>
    
    <xd:doc>
      <xd:desc>The <xd:ref name="nonVowel">nonVowel</xd:ref> variable is 
        a character class of non-vowels.</xd:desc>
    </xd:doc>
    <xsl:variable name="nonVowel">[^aeiouyâàëéêèïîôûù]</xsl:variable>
    
    <xd:doc>
      <xd:desc>The <xd:ref name="neitherVowelNorH">neitherVowelNorH</xd:ref> variable is 
        a character class of characters which are not vowels or H (used in step 2a).</xd:desc>
    </xd:doc>
    <xsl:variable name="neitherVowelNorH">[^aeiouyâàëéêèïîôûùH]</xsl:variable>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVExceptRex">RVExceptRex</xd:ref> is a regular expression
        which returns returns RV when applied to a token which fits the exception pattern.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVExceptRex" as="xs:string" select="'^(par|col|tap)(.*)$'"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVARex">RVARex</xd:ref> is a regular expression
        which returns returns RV for words beginning with two vowels.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVARex" as="xs:string" select="concat('^', $vowel, '{2}', '.(.*)$')"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVBRex">RVBRex</xd:ref> is a regular expression
        which returns returns RV for words not beginning with two vowels.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVBRex" as="xs:string" select="concat('^.', $nonVowel, '*', $vowel, '(.*)$')"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="R1R2Rex">R1R2Rex</xd:ref> is a regular expression
        which returns R1, defined as "the region after the first non-vowel 
        following a vowel, or the end of the word if there is no such non-vowel".
        It also returns R2 when applied to R1.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="R1R2Rex" as="xs:string" select="concat('^.*?', $vowel, $nonVowel, '(.*)$')"/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1">reStep1</xd:ref> is the single 
      massive regex matching all suffixes handled in step 1. Initial is 
      non-greedy to ensure longest suffix match succeeds, since we need
      to act on the longest possible match.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1" as="xs:string" select="'.+?((issements)|(issement)|(atrices)|(atrice)|(ateurs)|(ations)|(logies)|(usions)|(utions)|(ements)|(amment)|(emment)|(ments)|(ances)|(iqUes)|(ismes)|(ables)|(istes)|(ateur)|(ation)|(logie)|(usion)|(ution)|(ences)|(ement)|(euses)|(ance)|(iqUe)|(isme)|(able)|(iste)|(ence)|(ités)|(ives)|(eaux)|(euse)|(ment)|(eux)|(ité)|(ive)|(ifs)|(aux)|(if))$'"/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1a">reStep1a</xd:ref>
      is a sequence of suffixes that must be deleted if they lie entirely within
      R2. The longest found should be deleted, so they are in descending 
      order of size in the form of a regular expression.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1a" as="xs:string" select="
      '((ances?)|(iqUes?)|(ismes?)|(ables?)|(istes?)|(eux))$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1b" as="xs:string">reStep1b</xd:ref>
      is a regex for a sequence of suffixes that should be deleted if they
      are in R2; or if they are not, but are preceded by 'ic', should be
      replaced by '1qU'.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1b" as="xs:string" select="
      '((atrices?)|(ateurs?)|(ations?))$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1c" as="xs:string">reStep1c</xd:ref>
        is a regex for a pair of suffixes that should be replaced with
        'log' if they are in R2.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1c" as="xs:string" select="
      'logies?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1d" as="xs:string">reStep1d</xd:ref>
        is a regex for a sequence of suffixes that should be replaced with 
        u if they are in R2.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1d" as="xs:string" select="
      'u[st]ions?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1e" as="xs:string">reStep1e</xd:ref>
        is a regex for a sequence of suffixes that should be replaced with 
        ent if they are in R2.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1e" as="xs:string" select="
      'ences?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1f" as="xs:string">reStep1f</xd:ref>
        is a regex for a sequence of suffixes that undergo one of a variety 
      of transformations or deletion based on where they are in the word.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1f" as="xs:string" select="
      'ements?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1g" as="xs:string">reStep1g</xd:ref>
        is a regex for a pair of suffixes that are deleted, then preceding
        bits may be deleted or modified based on where they are in the word.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1g" as="xs:string" select="
      'ités?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1h" as="xs:string">reStep1h</xd:ref>
        is a regex for four suffixes that are deleted, then preceding
        bits may be deleted or modified based on where they are in the word.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1h" as="xs:string" select="
      'i((f)|(ve))s?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1i" as="xs:string">reStep1i</xd:ref>
        is a simple regex for two suffixes, eaux and aux.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1i" as="xs:string" select="
      '((eaux)|(aux))?$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1j" as="xs:string">reStep1j</xd:ref>
        is a regex for two suffixes that are deleted or replaced 
        depending on context.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1j" as="xs:string" select="
      '(euses?)$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1k" as="xs:string">reStep1k</xd:ref>
        is a regex for two suffixes that are deleted if in R1 and preceded
        by a non-vowel.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1k" as="xs:string" select="
      '(issements?)$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1l" as="xs:string">reStep1l</xd:ref>
        is a regex for two suffixes that are replaced if in RV.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1l" as="xs:string" select="
      '[ae]mment$'
      "/>
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep1m" as="xs:string">reStep1m</xd:ref>
        is a regex for two suffixes that are deleted if preceded
        by a vowel in RV.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep1m" as="xs:string" select="
      'ments?$'
      "/>
    
    
    
    <xd:doc>
      <xd:desc><xd:ref name="reStep4a" as="xs:string">reStep4a</xd:ref>
        is a regex for deleting s in certain circumstances.</xd:desc>
    </xd:doc>
    <xsl:variable name="reStep4a" as="xs:string" 
      select="'((Hi)|[^aiouès])s$'"/>
    
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
      <xd:result>The stemmed version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:stem" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:variable name="normToken" as="xs:string" select="normalize-unicode($token, 'NFC')"/>
      
      <xsl:variable as="xs:string" name="preProc" select="ss:preflight($normToken)"/>
      
      <xsl:variable name="rvr1r2" as="item()+" select="ss:getRVR1R2($preProc)"/>
      
      
      <!-- Step 1 returns a sequence of three values because we need to 
           note the effect of the last couple of actions. -->
      
      <xsl:variable name="step1Result" select="ss:step1($preProc, $rvr1r2)"/>
      
      <xsl:variable as="xs:boolean" name="step1MadeChange" select="$step1Result[2]"/>
      
      <xsl:variable as="xs:boolean" name="foundMent" select="$step1Result[3]"/>
      
      <xsl:variable as="xs:boolean" name="doStep2a" select="not($step1MadeChange) or $foundMent"/>
      
      <xsl:variable as="xs:string" name="step2First" select="
        if ($doStep2a) then ss:step2a($step1Result[1], $rvr1r2) else $step1Result[1]"/>
      
      <xsl:variable as="xs:boolean" name="step2aMadeChange" select="$step1Result[1] ne $step2First"/>
      
      <xsl:variable as="xs:boolean" name="doStep2b" select="$doStep2a and not($step2aMadeChange)"/>
      
      <xsl:variable as="xs:string" name="step2Second" select="if ($doStep2b) then ss:step2b($step2First, $rvr1r2) else $step2First"/>
      
      <xsl:variable as="xs:boolean" name="step2bMadeChange" select="$step2First ne $step2Second"/>
      
      <!--  If the last step to be obeyed — either step 1, 2a or 2b — altered the word, do step 3  -->
      <xsl:variable as="xs:boolean" name="doStep3" 
        select="if ($doStep2b and $step2bMadeChange) then true()
                else
                  if (not($doStep2b) and ($doStep2a and $step2aMadeChange)) then true()
                  else
                    if ($step1MadeChange) then true()
                    else
                      false()"/>
      
      <xsl:variable as="xs:string" name="step3" select="if ($doStep3) then 
        replace(replace($step2Second, 'Y$', 'i'), 'ç$', 'c') 
                              else $step2Second"/>
      
      <xsl:variable as="xs:string" name="step4" select="if (not($doStep3)) then ss:step4($step3, $rvr1r2) else $step3"/>
      
      <!-- Step 5, always done: undouble. -->
      <xsl:variable as="xs:string" name="step5" select="if (matches($step4, '((enn)|(onn)|(ett)|(ell)|(eill))$')) then replace($step4, '.$', '') else $step4"/>
      
      <!-- Step 6, always done: unaccent. -->
      <xsl:variable as="xs:string" name="step6" select="replace($step5, '[éè](' || $nonVowel || '+)$', 'e$1')"/>
      
      <!-- Post-flight normalization. -->
      <xsl:variable as="xs:string" name="post1" select="translate($step6, 'IUY', 'iuy')"/>
      <xsl:variable as="xs:string" name="post2" select="translate(replace(replace($post1, 'He', 'ë'), 'Hi', 'ï'), 'H', '')"/>
      
      <!--<xsl:message>$rvr1r2: <xsl:value-of select="string-join($rvr1r2, ', ')"/></xsl:message>
      <xsl:message>$step1Result: <xsl:value-of select="string-join($step1Result, ', ')"/></xsl:message>
      <xsl:message>$step1MadeChange: <xsl:value-of select="$step1MadeChange"/></xsl:message>
      <xsl:message>$foundMent: <xsl:value-of select="$foundMent"/></xsl:message>
      <xsl:message>$step2Second: <xsl:value-of select="$step2Second"/></xsl:message>-->
      
      <xsl:sequence select="$post2"/>
      
    </xsl:function>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:preflight" type="function">ss:preflight</xd:ref> 
        does a couple of simple replacements that need to precede the actual 
        stemming process. Note that these operations need to be done in 
        precisely the correct order because the outcomes of some affect 
        the operation of others.
      </xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:preflight" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:value-of select="replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace($token, 
                                     'y(' || $vowel || ')', 'Y$1'),
                                     '(' || $vowel || ')y', '$1Y'),
                                     '(' || $vowel || ')u(' || $vowel || ')', '$1U$2'),
                                     'qu', 'qU'),
                                     '(' || $vowel || ')i(' || $vowel || ')', '$1I$2'),
                                     'ë', 'He'),
                                     'ï', 'Hi')
        "/>
    </xsl:function>
  
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:getRVR1R2" type="function">ss:getRVR1R2</xd:ref>
        decomposes an input token to get the RV, R1 and R2 regions, 
        and returns the string values of those three 
        regions, along with their offsets.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>A sequence consisting of three strings for RV, R1 and
        R2, and three integers for the offsets of RV, R1 and R2 respectively</xd:result>
    </xd:doc>
    <xsl:function name="ss:getRVR1R2" as="item()+" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:variable name="RV" as="xs:string" select="if (matches($token, $RVExceptRex)) then 
                                                         replace($token, $RVExceptRex, '$2') else
                                                     if (matches($token, $RVARex)) then
                                                         replace($token, $RVARex, '$1') else
                                                     if (matches($token, $RVBRex)) then
                                                         replace($token, $RVBRex, '$1') else
                                                         ''"/>
      <xsl:variable name="RVIndex" as="xs:integer" select="(string-length($token) - string-length($RV))"/>
      <xsl:variable name="R1" as="xs:string" select="if (matches($token, $R1R2Rex)) then
                                                         replace($token, $R1R2Rex, '$1') else
                                                         ''"/>
      <xsl:variable name="R1Index" as="xs:integer" select="(string-length($token) - string-length($R1))"/>
      <xsl:variable name="R2Candidate" as="xs:string" select="replace($R1, $R1R2Rex, '$1')"/>
      <xsl:variable name="R2" select="if ($R2Candidate = $R1) then '' else $R2Candidate"/>
      <xsl:variable name="R2Index" as="xs:integer" select="if ($R2Candidate = $R1) then string-length($token) + 1 else (string-length($token) - string-length($R2))"/>
      <xsl:sequence select="($RV, $R1, $R2, $RVIndex, $R1Index, $R2Index)"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1a">ss:step1a</xd:ref> is the first 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1a" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1a, '')"/>
      
      <!--<xsl:message select="'step1a $rep: ' || $rep || ' R2: ' || $R2"/>-->
      
      <xsl:sequence select=" if ($rep ne $token and string-length($rep) ge $R2) 
                             then $rep else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1b">ss:step1b</xd:ref> is the second
        part of standard suffix removal. Matching suffixes are removed if
        they are in R2, but replaced with iqU if they are preceded by 
        ic but not in R2.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1b" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1b, '')"/>
      <xsl:choose>
        <xsl:when test="$rep ne $token and string-length($rep) ge $R2">
          <xsl:variable name="icGone" as="xs:string" select="replace($rep, 'ic$', '')"/>
          <xsl:choose>
            <xsl:when test="($icGone eq $rep) or (string-length($icGone) ge $R2)">
              <xsl:sequence select="$icGone"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$icGone || 'iqU'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1c">ss:step1c</xd:ref> is the third 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1c" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1c, '')"/>
      <xsl:sequence select=" if ($rep ne $token and string-length($rep) ge $R2) 
        then $rep || 'log' else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1d">ss:step1d</xd:ref> is the fourth 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1d" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1d, '')"/>
      <xsl:sequence select=" if ($rep ne $token and string-length($rep) ge $R2) 
        then $rep || 'u' else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1e">ss:step1e</xd:ref> is the fifth 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1e" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1e, '')"/>
      <xsl:sequence select=" if ($rep ne $token and string-length($rep) ge $R2) 
        then $rep || 'ent' else $token"/>
    </xsl:function>
  
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1f">ss:step1f</xd:ref> is the sixth 
        part of standard suffix removal, and is significantly more 
        complex than the preceding ones.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
      calculated for the word</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1f" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1f, '')"/>
      <xsl:variable as="xs:integer" name="repLen" select="string-length($rep)"/>
      <xsl:choose>
        <!-- Delete if in RV. -->
        <xsl:when test="($rep ne $token) and ($repLen ge xs:integer($rvr1r2[4]))">
          <xsl:choose>
            <!-- if preceded by iv, delete if in R2 (and if further preceded by at, delete if in R2)...-->
            <!-- We do the longer one first. -->
            <xsl:when test="ends-with($rep, 'ativ') and ($repLen - 4) ge xs:integer($rvr1r2[6])">
              <xsl:sequence select="replace($rep, 'ativ$', '')"/>
            </xsl:when>
            <!-- Now the shorter one. -->
            <xsl:when test="ends-with($rep, 'iv') and ($repLen - 2) ge xs:integer($rvr1r2[6])">
              <xsl:sequence select="replace($rep, 'iv$', '')"/>
            </xsl:when>
            <!-- "if preceded by eus, delete if in R2, else replace by eux if in R1" -->
            <xsl:when test="ends-with($rep, 'eus')">
              <xsl:choose>
                <xsl:when test="($repLen - 3) ge xs:integer($rvr1r2[6])">
                  <xsl:sequence select="replace($rep, 'eus$', '')"/>
                </xsl:when>
                <xsl:when test="($repLen - 3) ge xs:integer($rvr1r2[5])">
                  <xsl:sequence select="replace($rep, 'eus$', 'eux')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$rep"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- if preceded by abl or iqU, delete if in R2...-->
            <xsl:when test="matches($rep, '(abl)|(iqU)$') and ($repLen - 3) ge xs:integer($rvr1r2[6])">
              <xsl:sequence select="replace($rep, '(abl)|(iqU)$', '')"/>
            </xsl:when>
            <!-- if preceded by ièr or Ièr, replace by i if in RV...-->
            <xsl:when test="matches($rep, '[iI]èr$') and ($repLen - 3) ge xs:integer($rvr1r2[4])">
              <xsl:sequence select="replace($rep, '[iI]èr$', 'i')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$rep"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1g">ss:step1g</xd:ref> is the seventh 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1g" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1g, '')"/>
      <!--    delete if in R2   -->
      <xsl:variable name="repLen" as="xs:integer" select="string-length($rep)"/>
      <xsl:choose>
        <xsl:when test="($rep ne $token) and ($repLen ge $R2)">
          <xsl:choose>
            <!-- if preceded by abil, delete if in R2, else replace by abl, otherwise, -->
            <xsl:when test="matches($rep, 'abil$')">
              <xsl:sequence select="if (($repLen - 4) ge $R2) then replace($rep, 'abil$', '') else replace($rep, 'abil$', 'abl')"/>
            </xsl:when>
            <!-- if preceded by ic, delete if in R2, else replace by iqU, otherwise, -->
            <xsl:when test="matches($rep, 'ic$')">
              <xsl:sequence select="if (($repLen - 2) ge $R2) then replace($rep, 'ic$', '') else replace($rep, 'ic$', 'iqU')"/>
            </xsl:when>
            <!-- if preceded by iv, delete if in R2 -->
            <xsl:when test="matches($rep, 'iv$')">
              <xsl:sequence select="if (($repLen - 2) ge $R2) then replace($rep, 'iv$', '') else $rep"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$rep"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1h">ss:step1h</xd:ref> is the eighth 
        part of standard suffix removal.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R2">Offset of the R2 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1h" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R2" as="xs:integer"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1h, '')"/>
      <xsl:variable name="repLen" as="xs:integer" select="string-length($rep)"/>
      <xsl:choose>
        <xsl:when test="($rep ne $token) and ($repLen ge $R2)">
          <xsl:choose>
            <xsl:when test="matches($rep, 'icat$') and ($repLen - 4) ge $R2">
              <xsl:sequence select="replace($rep, 'icat$', '')"/>
            </xsl:when>
            <xsl:when test="matches($rep, 'icat$') and ($repLen - 2) ge $R2">
              <xsl:sequence select="replace($rep, 'icat$', 'iqU')"/>
            </xsl:when>
            <xsl:when test="matches($rep, 'at$') and ($repLen - 2) ge $R2">
              <xsl:sequence select="replace($rep, 'at$', '')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$rep"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1i">ss:step1i</xd:ref> is the ninth 
        part of standard suffix removal, combining two simple steps.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R1">Offset of the R1 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1i" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R1" as="xs:integer"/>
      <xsl:choose>
        <xsl:when test="ends-with($token, 'eaux')"><xsl:sequence select="replace($token, 'x$', '')"/></xsl:when>
        <xsl:otherwise>
          <xsl:variable name="rep" select="replace($token, 'aux$', 'al')"/>
          <xsl:sequence select="if (($rep ne $token) and ((string-length($rep) - 2) ge $R1)) then $rep else $token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1j">ss:step1j</xd:ref> is the tenth 
        part of standard suffix removal, handling euse(s).</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
        calculated for the word</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1j" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      <xsl:variable as="xs:string" name="rep" select="replace($token, $reStep1j, '')"/>
      <xsl:variable name="repLen" as="xs:integer" select="string-length($rep)"/>
      <xsl:choose>
        <!--    delete if in R2   -->
        <xsl:when test="($rep ne $token) and (string-length($rep)  ge xs:integer($rvr1r2[6]))">
          <xsl:sequence select="$rep"/>
        </xsl:when>
        <!-- else replace by eux if in R1 -->  
        <xsl:when test="($rep ne $token) and (string-length($rep)  ge xs:integer($rvr1r2[5]))">
          <xsl:sequence select="$rep || 'eux'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1k">ss:step1k</xd:ref> is the eleventh 
        part of standard suffix removal, removing suffixes if in R1 and 
        preceded by a non-vowel.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="R1">Offset of the R1 region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1k" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="R1" as="xs:integer"/>
      <xsl:variable name="rep" select="replace($token, '(' || $nonVowel || ')' || $reStep1k, '$1')"/>
      <xsl:sequence select="if (($rep ne $token) and (string-length($rep) ge $R1)) then $rep else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1l">ss:step1l</xd:ref> is the twelfth 
        part of standard suffix removal, replacing suffix amment with ant and
        emment with ent if in RV. (Shows as two steps in the algorithm 
        description.)</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="RV">Offset of the RV region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1l" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="RV" as="xs:integer"/>
      <xsl:variable name="rep" select="replace($token, '([ea])mment$', '$1nt')"/>
      <xsl:sequence select="if (($rep ne $token) and ((string-length($rep) - 3) ge $RV)) then $rep else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step1m">ss:step1m</xd:ref> is the thirteenth and
        final part of standard suffix removal, replacing suffix ments?
        if preceded by a vowel in RV.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="RV">Offset of the RV region in the token</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1m" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="RV" as="xs:integer"/>
      <xsl:variable name="rep" select="replace($token, '(' || $vowel || ')ments?', '$1')"/>
      <xsl:sequence select="if (($rep ne $token) and ((string-length($rep) - 1) ge $RV)) then $rep else $token"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step2a">ss:step2a</xd:ref> is the first part of
        step 2, removing any of a long list of suffixes beginning with i,
        if preceded by a char which is neither a vowel nor H, in RV. As with
        step 2b,the test to find out the longest match is carried out on 
        RV, rather than the longest match being found on the word and then 
        tested to see if it's in RV.
      </xd:desc>
      <xd:desc><xd:ref name="reStep2a" as="xs:string">reStep2a</xd:ref>
        is a regex for this set of suffixes.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
        calculated for the word</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step2a" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      <xsl:variable name="currRV" as="xs:string" select="substring($token, $rvr1r2[4] + 1)"/>
      
      <xsl:variable name="reStep2a" as="xs:string" select="
        '(' || $neitherVowelNorH ||  ')((issaIent)|(issantes)|(iraIent)|(issante)|(issants)|(issions)|(irions)|(issais)|(issait)|(issant)|(issent)|(issiez)|(issons)|(irais)|(irait)|(irent)|(iriez)|(irons)|(iront)|(isses)|(issez)|(îmes)|(îtes)|(irai)|(iras)|(irez)|(isse)|(ies)|(ira)|(ît)|(ie)|(ir)|(is)|(it)|(i))$'
        "/>
      
      <xsl:variable name="rep" select="replace($currRV, $reStep2a, '$1')"/>
      <!--<xsl:message select="'Step2a $rep: ' || $rep"/>-->
      
      <xsl:sequence select="if ($rep ne $currRV) then replace($token, $currRV || '$', $rep) else $token"/>
      
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step2b">ss:step2b</xd:ref> is the second part of
        step 2, removing any of a long list of suffixes beginning with vowels in
        various configurations.</xd:desc>
      <xd:desc><xd:ref name="reStep2b" as="xs:string">reStep2b</xd:ref> is the 
        initial long regex for matching in step 2b, before breaking down the 
        matches to treat them differently.</xd:desc>
      <xd:desc><xd:ref name="reStep2b1" as="xs:string">reStep2b1</xd:ref>
        is a regex for a set of suffixes that are deleted if in RV.</xd:desc><xd:desc><xd:ref name="reStep2b2" as="xs:string">reStep2b2</xd:ref>
          is a regex for a set of suffixes that are deleted if in RV; a preceding
          e should also be deleted if in RV, but that is handled in the function.</xd:desc>

      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
        calculated for the word</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step2b" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      
      <xsl:variable name="currRV" as="xs:string" select="substring($token, $rvr1r2[4] + 1)"/>

      <xsl:variable name="reStep2b" as="xs:string" select="'.*?((eraIent)|(erions)|(assent)|(assiez)|(èrent)|(erais)|(erait)|(eriez)|(erons)|(eront)|(aIent)|(antes)|(asses)|(ions)|(erai)|(eras)|(erez)|(âmes)|(âtes)|(ante)|(ants)|(asse)|(ées)|(era)|(iez)|(ais)|(ait)|(ant)|(ée)|(és)|(er)|(ez)|(ât)|(ai)|(as)|(é)|(a))$'"/>

      <xsl:variable name="reStep2b1" as="xs:string"      select="'((eraIent)|(erions)|(èrent)|(erais)|(erait)|(eriez)|(erons)|(eront)|(eras)|(erez)|(erai)|(iez)|(era)|(ées)|(ez)|(er)|(ée)|(és)|(é))$'"/>
      
      <xsl:variable name="reStep2b2" as="xs:string" select="'((assions)|(assiez)|(assent)|(asses)|(antes)|(aIent)|(asse)|(ante)|(ants)|(âtes)|(âmes)|(ais)|(ait)|(ant)|(ât)|(ai)|(as)|(a))$'"/>
      
      <xsl:variable as="xs:string" name="longestMatch" select="replace($currRV, $reStep2b, '$1')"/>
      
      <!--<xsl:message select="'Step 2b: $token: ' || $token || ' currRV: ' || $currRV || ' longestMatch: ' || $longestMatch"/>-->
      
          <xsl:variable name="result" as="xs:string">
            <xsl:choose>
              <xsl:when test="$longestMatch eq 'ions'">
                <xsl:variable as="xs:string" name="rep" select="replace($token, 'ions$', '')"/>
                <xsl:sequence select="if (($rep ne $token) and (string-length($rep) ge $rvr1r2[4]) and (string-length($rep) ge $rvr1r2[6])) then $rep else $token"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep2b1)">
                <xsl:sequence select="replace($token, $longestMatch || '$', '')"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep2b2)">
                <xsl:variable name="rep" as="xs:string" select="replace($token, $longestMatch || '$', '')"/>
                <xsl:choose>
                  <xsl:when test="not(ends-with($rep, 'e'))">
                    <xsl:sequence select="$rep"/>
                  </xsl:when>
                  <xsl:when test="ends-with($rep, 'e')">
                    <xsl:sequence select="if ((string-length($rep) - 1) ge $rvr1r2[4]) then replace($rep, 'e$', '') else $rep"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="$token"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$token"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xd:doc>
      <xd:desc><xd:ref name="ss:step4">ss:step4</xd:ref> is a short 
      sequence of replacements done if step3 did not run.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
        calculated for the word</xd:param>
      <xd:result>The treated version of the token</xd:result>
    </xd:doc>
    <xsl:function name="ss:step4" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      <!-- If the word ends s, not preceded by a, i (unless itself preceded by H), o, u, è or s, delete it. -->
      <xsl:variable name="rep1" select="replace($token, $reStep4a, '$1')"/>
      
      <xsl:variable name="rep2" as="xs:string" select="replace($rep1, '([st])ion$', '$1')"/>
      
      <!--<xsl:message select="'step4 rep2: '|| $rep2"/>-->
      
      <xsl:variable name="rep2Len" as="xs:integer" select="string-length($rep2)"/>
      <xsl:variable name="step4a" select="if (($token ne $rep2) and 
        ($rep2Len ge $rvr1r2[6]) and ($rep2Len gt $rvr1r2[4])) 
        then $rep2 else $rep1"/>
      
      <!--<xsl:message select="'step4a: '|| $step4a"/>-->
      
      <xsl:variable name="rep3" as="xs:string" select="replace($step4a, '(([Ii]ère)|([Ii]er))$', 'i')"/>
      
      <xsl:variable name="step4b" as="xs:string" select="if (($step4a ne $rep3) and ((string-length($rep3)-1) ge $rvr1r2[4])) then $rep3 else $step4a"/>
      
      <xsl:sequence select="if (ends-with($step4b, 'e') and string-length($step4b) gt $rvr1r2[4]) then replace($step4b, 'e$', '') else $step4b"/>
    </xsl:function>

    <xd:doc>
      <xd:desc><xd:ref name="ss:step1">ss:step1</xd:ref> combines all
        the substeps which are part of the step1 process It has to
        be a monolithic process, unfortunately.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:param name="rvr1r2">The complete sequence of items and offsets
        calculated for the word</xd:param>
      <xd:result>A sequence consisting of the treated version of the token, a boolean
        for whether it was changed or not, and a boolean for whether one of amment, 
        emment, ment, or ments was found</xd:result>
    </xd:doc>
    <xsl:function name="ss:step1" as="item()+" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <xsl:param name="rvr1r2" as="item()+"/>
      <xsl:variable as="xs:string" name="longestMatch" select="replace($token, $reStep1, '$1')"/>
      
      <!--<xsl:message select="'$token: ' || $token || ', $longestMatch: ' || $longestMatch"/>-->
      
      <xsl:variable name="result" as="xs:string">
        <xsl:choose>
          <xsl:when test="$token ne $longestMatch">
            <!-- We now test the longest match found to find which category it
                 fits, and process accordingly. -->
            <xsl:choose>
              <xsl:when test="matches($longestMatch, '^' || $reStep1a)">
                <xsl:sequence select="ss:step1a($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1b)">
                <xsl:sequence select="ss:step1b($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1c)">
                <xsl:sequence select="ss:step1c($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1d)">
                <xsl:sequence select="ss:step1d($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1e)">
                <xsl:sequence select="ss:step1e($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1f)">
                <xsl:sequence select="ss:step1f($token, $rvr1r2)"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1g)">
                <xsl:sequence select="ss:step1g($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1h)">
                <xsl:sequence select="ss:step1h($token, $rvr1r2[6])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1i)">
                <xsl:sequence select="ss:step1i($token, $rvr1r2[5])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1j)">
                <xsl:sequence select="ss:step1j($token, $rvr1r2)"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1k)">
                <xsl:sequence select="ss:step1k($token, $rvr1r2[5])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1l)">
                <xsl:sequence select="ss:step1l($token, $rvr1r2[4])"/>
              </xsl:when>
              <xsl:when test="matches($longestMatch, '^' || $reStep1m)">
                <xsl:sequence select="ss:step1m($token, $rvr1r2[4])"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$token"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!--<xsl:message><xsl:sequence select="'$token: ' || $token || ', $result: ' || $result"/></xsl:message>-->
      <xsl:sequence select="($result, ($token ne $result), (matches($longestMatch, '^(([ae]mment)|(ments?))$')))"/>
    </xsl:function>
    
    
    <!--**************************************************************
       *                                                            * 
       *                          Testing                           *
       *                                                            *
       **************************************************************-->
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:runTests" type="function">ss:runTests</xd:ref>
        feeds all of the test data into the ss:stem function and checks the 
        results.</xd:desc>
      <xd:result>A sequence consisting of boolean true or false: tests all passed = true, 
        any test failed = false, and an empty message or an error report</xd:result>
    </xd:doc>
    <xsl:function name="ss:runTests" as="item()+" new-each-time="no">
      <xsl:variable name="fullTokenSetUrl" as="xs:string" select="'https://raw.githubusercontent.com/snowballstem/snowball-data/master/french/voc.txt'"/>
      <xsl:variable name="fullStemSetUrl" as="xs:string" select="'https://raw.githubusercontent.com/snowballstem/snowball-data/master/french/output.txt'"/>
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