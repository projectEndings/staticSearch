/*           porter2Stemmer.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/* This file is an implementation of the
 * Porter2 stemmer as described  here:
 *
 * https://snowballstem.org/algorithms/english/stemmer.html
 *
 * If is part of the projectEndings staticSearch
 * project.
 *
 * Free to anyone for any purpose, but
 * acknowledgement would be appreciated. */

/* jshint strict:false */
/* jshint esversion: 6*/
/* jshint strict: global*/

"use strict";

/*  We use a class to put everything in our
 *  Pt2 'namespace' (= Porter2). */

class PT2{
  constructor(){
    // A character class of vowels
      this.vowel                         = '[aeiouy]';
      this.reVowel                       = new RegExp(this.vowel);
    //A character class of non-vowels
      this.nonVowel                      = '[^aeiouy]';
      this.reNonVowel                    = new RegExp(this.nonVowel);
    // A regex for determining whether a token ends with a short syllable
      this.reEndsWithShortSyllable       = new RegExp(this.vowel + this.nonVowel + '[^aeiouywxY]$');
    // A regex for doubled consonants
      this.reDbl                         = /((bb)|(dd)|(ff)|(gg)|(mm)|(nn)|(pp)|(rr)|(tt))/;
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
                      ['ousness', 'ousness','ous'],
                      ['iveness', 'iveness','ive'],
                      ['fulness', 'fulness','ful'],
                      ['ization', 'ization','ize'],
                      ['ational', 'ational','ate'],
                      ['biliti', 'biliti','ble'],
                      ['tional', 'tional','tion'],
                      ['lessli', 'lessli','less'],
                      ['ousli', 'ousli','ous'],
                      ['fulli', 'fulli','ful'],
                      ['iviti', 'iviti','ive'],
                      ['entli', 'entli','ent'],
                      ['alism', 'alism','al'],
                      ['aliti', 'aliti','al'],
                      ['enci', 'enci','ence'],
                      ['anci', 'anci','ance'],
                      ['abli', 'abli','able'],
                      ['izer', 'izer','ize'],
                      ['ation', 'ation','ate'],
                      ['ator', 'ator','ate'],
                      ['alli', 'alli','al'],
                      ['bli', 'bli','ble'],
                      ['logi', 'ogi','og'],
                      ['[cdeghkmnrt]li', 'li', '']
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
                      [1, 'ational', 'ate'],
                      [1, 'tional', 'tion'],
                      [1, 'alize', 'al'],
                      [1, 'icate', 'ic'],
                      [1, 'iciti', 'ic'],
                      [2, 'ative', ''],
                      [1, 'ical', 'ic'],
                      [1, 'ness', ''],
                      [1, 'ful', '']
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
                      ['ement', 'ement'],
                      ['ment', 'ment'],
                      ['ance', 'ance'],
                      ['ence', 'ence'],
                      ['able', 'able'],
                      ['ible', 'ible'],
                      ['ant', 'ant'],
                      ['ent', 'ent'],
                      ['ism', 'ism'],
                      ['ate', 'ate'],
                      ['iti', 'iti'],
                      ['ous', 'ous'],
                      ['ive', 'ive'],
                      ['ize', 'ize'],
                      ['[st]|ion', 'ion'],
                      ['al', 'al'],
                      ['er', 'er'],
                      ['ic', 'ic']
                    ];
    // arrExeptions is a list of exceptional forms and their matching
    // stems, to be processed before the rest of the stemming takes place.
    // The format is:
    //     token:stem
    // This list includes items from two lists in the Porter2 description:
    // the set of special words which have hard-coded stems, and the set
    // of words which should remain unchanged.
      this.arrExceptions = [
                        ['skis', 'ski'],
                        ['skies', 'sky'],
                        ['dying', 'die'],
                        ['lying', 'lie'],
                        ['tying', 'tie'],
                        ['idly', 'idl'],
                        ['gently', 'gentl'],
                        ['ugly', 'ugli'],
                        ['early', 'earli'],
                        ['only', 'onli'],
                        ['singly', 'singl'],
                        ['sky', 'sky'],
                        ['news', 'news'],
                        ['howe', 'howe'],
                        ['atlas', 'atlas'],
                        ['cosmos', 'cosmos'],
                        ['bias', 'bias'],
                        ['andes', 'andes']
                      ];
    // arrStep1aExceptions is a short list of items to be left unchanged
    // if they are found after step 1a.
      this.arrStep1aExceptions = [
                              'inning', 'outing', 'canning', 'herring',
                              'earring', 'proceed', 'exceed', 'succeed'
                            ];
  }

  /**
   * getR1AndR2 decomposes an input token to get the R1 and R2 regions,
   * and returns the string values of those two regions, along with their
   * offsets.
   * @param  {String} token The input token
   * @return {Object}       an object with four members:
   *                        r1 {String} the part of the word constituting R1
   *                        r1 {String} the part of the word constituting R2
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
     var R2Index = ($R2Candidate == R1)? token.length + 1 : (token.length - R2.length) + 1;
     return {r1: R1, r2: R2, r1of: R1Index, r2of: R2Index};
   }

  /**
    * preflight does a couple of simple replacements that need to precede
    * the actual stemming process.
    * @param  {String} token the input token
    * @return {String}       the result of the replacement operations
    */
  preflight(token){
    return token.replace(/^'/, '').replace(/^y/, 'Y').replace(new RegExp('(' + this.vowel + ')y'), '$1Y');
  }

  /**
    * step0 trims plural/possessive type suffixes from the end.
    * @param  {String} token the input token
    * @return {String}       the result of the trimming operations
    */
  step0(token){
    return token.replace(/'(s(')?)?$/, '');
  }

 /**
   * step1 performs three replacements on the end of a token (1a, 1b and 1c).
   * @param  {String} token the input token
   * @param  {Number} R1    the offset of the R1 region in the token
   * @return {String}       the result of the replacement operations
   */
   step1(token, R1){
     //Some regular expressions used only in this function.
     var reStep1a2     = /(..)((ied)|(ies))$/;
     var reStep1a3     = new RegExp('(.*' + this.vowel + '.+)s$');
     var reStep1b2     = new RegExp('(' + this.vowel + '.*)((ed)|(ing))(ly)?$');
     var reStep1c      = new RegExp('(.+' + this.nonVowel + ')[Yy]$');

     //TODO
   }




}
