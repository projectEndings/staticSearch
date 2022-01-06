/*           ssStemmer.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/* This file is an implementation of the
 * Porter2 stemmer as described  here:
 *
 * https://snowballstem.org/algorithms/english/stemmer.html
 *
 * It is part of the projectEndings staticSearch
 * project.
 *
 * Free to anyone for any purpose, but
 * acknowledgement would be appreciated. */

 /** HOW TO USE:
     var ssStemmer = new SSStemmer();
     var stemmedToken = ssStemmer.stem(token);
  */

 /** WARNING:
   * This lib has "use strict" defined. You may
   * need to remove that if you are mixing this
   * code with non-strict JavaScript.   
   */

/*  We use a class to put everything in our
 *  SSStemmer 'namespace' (= staticSearch Stemmer). */

class SSStemmer{
  constructor(){
    // A character class of vowels
      this.vowel                         = '[aeiouy]';
      this.reVowel                       = new RegExp(this.vowel);
    //A character class of non-vowels
      this.nonVowel                      = '[^aeiouy]';
      this.reNonVowel                    = new RegExp(this.nonVowel);
    // A regex for determining whether a token ends with a short syllable
      this.reEndsWithShortSyllable       = new RegExp(this.nonVowel + this.vowel + '[^aeiouywxY]$');
    // A regex for doubled consonants
      this.dbl                           = '((bb)|(dd)|(ff)|(gg)|(mm)|(nn)|(pp)|(rr)|(tt))';
      this.reDbl                         = new RegExp(this.reDbl);
    // A regular expression which returns R1, defined as "the region after
    // the first non-vowel following a vowel, or the end of the word if
    // there is no such non-vowel".
    //See exceptional cases below. It also returns R2 when applied to R1.
      this.reR1R2                        = new RegExp('^.*?' + this.vowel + this.nonVowel + '(.*)$');
    // A regular expression which for the exceptions: "If the words begins gener,
    // commun or arsen, set R1  to be the remainder of the word."
      this.reR1Except                    = /^(gener|commun|arsen)(.*)$/;
    // arrStep2Seq is an array of items, each of which is a three-item
    // array consisting of a suffix to match, a suffix to replace (which
    // may be the same, or may be shorter) and a replacement string.
    // NOTE: When browser support for lookbehinds is available, this
    // can be simplified.
      this.arrStep2Seq = [
                    [/ousness$/, /ousness$/, 'ous'],
                    [/iveness$/, /iveness$/, 'ive'],
                    [/fulness$/, /fulness$/, 'ful'],
                    [/ization$/, /ization$/, 'ize'],
                    [/ational$/, /ational$/, 'ate'],
                    [/biliti$/, /biliti$/, 'ble'],
                    [/tional$/, /tional$/, 'tion'],
                    [/lessli$/, /lessli$/, 'less'],
                    [/ousli$/, /ousli$/, 'ous'],
                    [/fulli$/, /fulli$/, 'ful'],
                    [/iviti$/, /iviti$/, 'ive'],
                    [/entli$/, /entli$/, 'ent'],
                    [/alism$/, /alism$/, 'al'],
                    [/aliti$/, /aliti$/, 'al'],
                    [/enci$/, /enci$/, 'ence'],
                    [/anci$/, /anci$/, 'ance'],
                    [/abli$/, /abli$/, 'able'],
                    [/izer$/, /izer$/, 'ize'],
                    [/ation$/, /ation$/, 'ate'],
                    [/ator$/, /ator$/, 'ate'],
                    [/alli$/, /alli$/, 'al'],
                    [/bli$/, /bli$/, 'ble'],
                    [/logi$/, /ogi$/, 'og'],
                    [/[cdeghkmnrt]li$/, /li$/,  '']
                    ];
    // step3Seqis a list of suffixes to
    // be evaluated against a token; as soon as one is matched, the rest
    // are ignored, and if the match location is in R1 (or in R2 for
    // -ative, a replacement operation is done.
    // The format is:
    //   whichR, match, replacement
    // where whichR is either 1 or 2.
    // So for example: "ative" matches, but the match must be in R2 to
    // satisfy the condition.
      this.arrStep3Seq = [
                      [1, /ational$/, 'ate'],
                      [1, /tional$/, 'tion'],
                      [1, /alize$/, 'al'],
                      [1, /icate$/, 'ic'],
                      [1, /iciti$/, 'ic'],
                      [2, /ative$/, ''],
                      [1, /ical$/, 'ic'],
                      [1, /ness$/, ''],
                      [1, /ful$/, '']
                    ];
    // arrStep4Seq is a list of suffixes to
    // be evaluated against a token; as soon as one is matched,
    // the rest are ignored, and if the match location is in R2,
    // a delete operation is done.
    // The format is:
    //  match, delete
    // So for example: "al" matches, but the match must be in R2
    // to satisfy the condition.
      this.arrStep4Seq = [
                      [/ement$/, /ement$/],
                      [/ment$/, /ment$/],
                      [/ance$/, /ance$/],
                      [/ence$/, /ence$/],
                      [/able$/, /able$/],
                      [/ible$/, /ible$/],
                      [/[st]ion$/, /ion$/],
                      [/ant$/, /ant$/],
                      [/ent$/, /ent$/],
                      [/ism$/, /ism$/],
                      [/ate$/, /ate$/],
                      [/iti$/, /iti$/],
                      [/ous$/, /ous$/],
                      [/ive$/, /ive$/],
                      [/ize$/, /ize$/],
                      [/al$/, /al$/],
                      [/er$/, /er$/],
                      [/ic$/, /ic$/]
                    ];
    // arrExeptions is a list of exceptional forms and their matching
    // stems, to be processed before the rest of the stemming takes place.
    // The format is:
    //     token:stem
    // This list includes items from two lists in the Porter2 description:
    // the set of special words which have hard-coded stems, and the set
    // of words which should remain unchanged.
      this.arrExceptions = [
                        'skis',
                        'skies',
                        'dying',
                        'lying',
                        'tying',
                        'idly',
                        'gently',
                        'ugly',
                        'early',
                        'only',
                        'singly',
                        'sky',
                        'news',
                        'howe',
                        'atlas',
                        'cosmos',
                        'bias',
                        'andes'
                      ];

      this.arrExceptionStems=[
                        'ski',
                        'sky',
                        'die',
                        'lie',
                        'tie',
                        'idl',
                        'gentl',
                        'ugli',
                        'earli',
                        'onli',
                        'singl',
                        'sky',
                        'news',
                        'howe',
                        'atlas',
                        'cosmos',
                        'bias',
                        'andes'
                      ];
    // arrStep1aExceptions is a short list of items to be left unchanged
    // if they are found after step 1a.
      this.arrStep1aExceptions = [
                              'inning', 'outing', 'canning', 'herring',
                              'earring', 'proceed', 'exceed', 'succeed'
                            ];
  }
  /**
   * stem is the core function that takes a single token and returns
   * its stemmed version.
   * @param  {string} token The input token
   * @return {string}       the stemmed token
   */
   stem(token){
    let normToken = token.normalize('NFC');
     if (normToken.length < 3){
       return normToken;
     }
     else{
       var indEx = this.arrExceptions.indexOf(normToken);
       if (indEx > -1){
         return this.arrExceptionStems[indEx];
       }
       else{
         var pref = this.preflight(normToken);
         var R = this.getR1AndR2(pref);
         var s0 = this.step0(pref);
         var s1 = this.step1(s0, R.r1of);
         if (this.arrStep1aExceptions.indexOf(s1) > -1){
           return s1;
         }
         else{
           var s2 = this.step2(s1, R.r1of);
           var s3 = this.step3(s2, R.r1of, R.r2of);
           var s4 = this.step4(s3, R.r2of);
           var s5 = this.step5(s4, R.r1of, R.r2of);
           return s5;
         }
       }
     }
   }

  /**
   * getR1AndR2 decomposes an input token to get the R1 and R2 regions,
   * and returns the string values of those two regions, along with their
   * offsets.
   * @param  {string} token The input token
   * @return {Object}       an object with four members:
   *                        r1 {string} the part of the word constituting R1
   *                        r1 {string} the part of the word constituting R2
   *                        r1of {Number} the offset of the start of R1
   *                        r2of {Number} the offset of the start of R2
   */
   getR1AndR2(token){
     var R1 = '';
     if (token.match(this.reR1Except)){
       R1 = token.replace(this.reR1Except, '$2');
     }
     else{
       if (token.match(this.reR1R2)){
         R1 = token.replace(this.reR1R2, '$1');
       }
     }
     var R1Index = (token.length - R1.length) + 1;
     var R2Candidate = R1.replace(this.reR1R2, '$1');
     var R2 = (R2Candidate == R1)? '' : R2Candidate;
     var R2Index = (R2Candidate == R1)? token.length + 1 : (token.length - R2.length) + 1;
     return {r1: R1, r2: R2, r1of: R1Index, r2of: R2Index};
   }

   /**
     * wordIsShort returns a boolean value from testing the input word
     * against a regular expression to determine whether it matches the
     * Porter2 definition of a short word. A short syllable is "either
     * (a) a vowel followed by a non-vowel other than w, x or Y and
     * preceded by a non-vowel, or * (b) a vowel at the beginning of the
     * word followed by a non-vowel," and "a word is called short if it
     * ends in a short syllable, and if R1 is null." R1 being null
     * basically means the R1 region is empty; that means it starts
     * after the end of the word, so its offset is the word-length + 1.
     * @param  {string} token the input token
     * @param  {Number} r1of  the offset of the R1 region
     * @return {boolean}      true if word is short, otherwise false.
     */
     wordIsShort(token, r1of){
       var R1IsNull = (token.length < r1of);
       var reOnlyShortSyllable = new RegExp('^' + this.vowel +
                                            this.nonVowel +
                                            this.nonVowel + '*$');
       return Boolean(((token.match(this.reEndsWithShortSyllable))||
              ((token.match(reOnlyShortSyllable)))) && (R1IsNull));
     }

  /**
    * preflight does a couple of simple replacements that need to precede
    * the actual stemming process.
    * @param  {string} token the input token
    * @return {string}       the result of the replacement operations
    */
  preflight(token){
    return token.replace(/^'/, '').replace(/^y/, 'Y').replace(new RegExp('(' + this.vowel + ')y'), '$1Y');
  }

  /**
    * step0 trims plural/possessive type suffixes from the end.
    * @param  {string} token the input token
    * @return {string}       the result of the trimming operations
    */
  step0(token){
    return token.replace(/'(s(')?)?$/, '');
  }

 /**
   * step1 performs three replacements on the end of a token (1a, 1b and 1c).
   * @param  {string} token the input token
   * @param  {Number} R1    the offset of the R1 region in the token
   * @return {string}       the result of the replacement operations
   */
   step1(token, R1){
     //Some regular expressions used only in this function.
     var reStep1a2     = /(..)((ied)|(ies))$/;
     var reStep1a3     = /((ied)|(ies))$/;
     var reStep1a4     = new RegExp('(.*' + this.vowel + '.+)s$');
     var reStep1a5     = /((us)|(ss))$/;
     var reStep1b1     = /eed(ly)?$/;
     var reStep1b2     = new RegExp('(' + this.vowel + '.*)((ed)|(ing))(ly)?$');
     var reStep1b3     = /((at)|(bl)|(iz))$/;
     var reStep1c      = new RegExp('(.+' + this.nonVowel + ')[Yy]$');

     //Start step 1a
     //Default if step1a matches don't pan out.
     var step1a = token;

     if (token.match(/sses$/)){
       step1a = token.replace(/sses$/, 'ss');
     }
     else{
       if (token.match(reStep1a2)){
         step1a = token.replace(reStep1a3, 'i');
       }
       else{
         if (token.match(reStep1a3)){
           step1a = token.replace(reStep1a3, 'ie');
         }
         else{
           if ( (token.match(reStep1a4)) && (! token.match(reStep1a5)) ){
             step1a = token.replace(reStep1a4, '$1');
           }
         }
       }
     }

     //Start step 1b
     //Default.
     var step1b = step1a;
     //If it's one of the exceptions, nothing more to do.
     if (this.arrStep1aExceptions.indexOf(step1a) > -1){
       step1b = step1a;
     }
     else{
       if (step1a.match(reStep1b1)){
         var tmp1 = step1a.replace(reStep1b1, 'ee');
         if ((tmp1.length + 1) >= R1){
           step1b = tmp1;
         }
         else{
           step1b = step1a;
         }
       }
       else{
         if (step1a.match(reStep1b2)){
          var tmp2 = step1a.replace(reStep1b2, '$1');
           if (tmp2.match(reStep1b3)){
             step1b = tmp2 + 'e';
           }
           else{
             if (tmp2.match(new RegExp(this.dbl + '$'))){
               step1b = tmp2.replace(/.$/, '');
             }
             else{
               if (this.wordIsShort(tmp2, R1)){
                 step1b = tmp2 + 'e';
               }
               else{
                 step1b = tmp2;
               }
             }
           }
         }
       }
     }
     //Start step 1c
     if (step1b.match(reStep1c)){
       return step1b.replace(reStep1c, '$1i');
     }
     else{
       return step1b;
     }
   }

   /**
     * step2 consists of a sequence of items to be evaluated against the
     * input token; if a match occurs, then a) a replacement operation
     * is done ONLY IF the match is in R1, and b) the process exits
     * whether or not a replacement was done.
     * @param  {string} token the input token
     * @param  {Number} R1    the offset of the R1 region in the token
     * @return {string}       the result of the replacement operations
     */
   step2(token, R1){
     //Default return if nothing happens.
     var result = token;
     for (var i=0; i<this.arrStep2Seq.length; i++){
       if (token.match(this.arrStep2Seq[i][0])){
         var nuked = token.replace(this.arrStep2Seq[i][1], '');
         if (nuked != token){
           if ((nuked.length + 1) >= R1){
             result = token.replace(this.arrStep2Seq[i][1], this.arrStep2Seq[i][2]);
           }
           break;
         }
       }
     }
     return result;
   }

   /**
     * step3 consists of a sequence of items to be evaluated against the
     * input token; if a match occurs, then a) a replacement operation
     * is done ONLY IF the match is in a specified region, and b) the
     * process exits whether or not a replacement was done.
     * @param  {string} token the input token
     * @param  {Number} R1    the offset of the R1 region in the token
     * @param  {Number} R2    the offset of the R2 region in the token
     * @return {string}       the result of the replacement operations
     */
   step3(token, R1, R2){
     //Default return if nothing happens.
     var result = token;
     for (var i=0; i<this.arrStep3Seq.length; i++){
       var offset = (this.arrStep3Seq[i][0] == 2)? R2 : R1;
       var nuked = token.replace(this.arrStep3Seq[i][1], '');
       if (nuked != token){
         if ((nuked.length + 1) >= offset){
           result = token.replace(this.arrStep3Seq[i][1], this.arrStep3Seq[i][2]);
         }
         break;
       }
     }
     return result;
   }

   /**
     * step4 consists of a sequence of items to be evaluated against the
     * input token; if a match occurs, then a) a deletion operation is
     * done ONLY IF the match is in R2, and b) the process exits whether
     * or not a replacement was done.
     * @param  {string} token the input token
     * @param  {Number} R2    the offset of the R1 region in the token
     * @return {string}       the result of the replacement operations
     */
   step4(token, R2){
     var result = token;
     for (var i=0; i<this.arrStep4Seq.length; i++){
       var nuked = token.replace(this.arrStep4Seq[i][0], '');
       if (nuked != token){
         nuked = token.replace(this.arrStep4Seq[i][1], '')
         if ((nuked.length + 1) >= R2){
           result = nuked;
         }
         break;
       }
     }
     return result;
   }
   /**
     * step5 consists of two specific replacements which are context-dependent:
     * "Search for the the following suffixes, and, if found,
     * perform the action indicated.
     *    e delete if in R2, or in R1 and not preceded by a short syllable*
     *    l delete if in R2 and preceded by l"
     * "Finally, turn any remaining Y letters in the word back into lower case. "
     *   *On mailing list, MP confirms that this means _immediately_
     * preceded by a short syllable.
     * @param  {string} token the input token
     * @param  {Number} R1    the offset of the R1 region in the token
     * @param  {Number} R2    the offset of the R1 region in the token
     * @return {string}       the result of the replacement operations
     */
   step5(token, R1, R2){
     //Some regexps used only in this function.
     //var reStep5a = new RegExp('(^' + this.vowel + this.nonVowel +
    //                           '$)|(' + this.reEndsWithShortSyllable + ')');
    var reStep5a = /(^[aeiouy][^aeiouy]$)|([^aeiouy][aeiouy][^aeiouywxY]$)/;

     //Start step5a
     var step5a = token;
     if (token.match(/e$/)){
       var nuked = token.replace(/e$/, '');
       if ((nuked.length + 1) >= R2){
         step5a = nuked;
       }
       else{
         if (((nuked.length + 1) >= R1) && (!nuked.match(reStep5a))){
//console.log(nuked);
           step5a = nuked;
         }
       }
     }

     //Start step5b.
     var step5b = step5a;
     //Only do anything if the previous step has not changed the token.
     if (step5b == token){
       if (step5b.match(/ll$/)){
         var nuked = step5b.replace(/l$/, '');
         if ((nuked.length + 2) > R2){
           step5b = nuked;
         }
       }
     }
     return step5b.replace(/Y/g, 'y');
   }



}
