/*           ssStemmer.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/* This file is an implementation of the
 * French Snowball stemmer as described  here:
 *
 * https://snowballstem.org/algorithms/french/stemmer.html
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

/* jshint strict:false */
/* jshint esversion: 6*/
/* jshint strict: global*/

"use strict";

/*  We use a class to put everything in our
 *  SSStemmer 'namespace' (= staticSearch Stemmer). */

class SSStemmer {
  constructor() {
    // A character class of vowels
    this.vowel = '[aeiouyâàëéêèïîôûù]';
    this.reVowel = new RegExp(this.vowel);
    //A character class of non-vowels
    this.nonVowel = '[^aeiouyâàëéêèïîôûù]';
    this.reNonVowel = new RegExp(this.nonVowel);
    //A regex which returns RV, defined as 
    //"If the word begins with two vowels, 
    //the region after the third letter, otherwise 
    //the region after the first vowel not at the 
    //beginning of the word, or the end of the word 
    //if these positions cannot be found. (Exceptionally, 
    //par, col or tap, at the beginning of a word is 
    //also taken to define RV as the region to their right.)"
    this.reRVA = new RegExp('^' + this.vowel + this.vowel + '.(.*)$'); 
    this.reRVB = new RegExp('^.' + this.nonVowel + '*' + this.vowel + '(.*)$');
    this.reRVExcept = /^(par|col|tap)(.*)$/;
    // A regular expression which returns R1, defined as "the region after
    // the first non-vowel following a vowel, or the end of the word if
    // there is no such non-vowel".
    //It also returns R2 when applied to R1.
    this.reR1R2 = new RegExp('^.*?' + this.vowel + this.nonVowel + '(.*)$');

    //reStep1a is a regular expression for suffixes to be deleted if they
    //are in R2.
    this.reStep1a = /(ances?)|(iqUes?)|(ismes?)|(ables?)|(istes?)|(eux)$/;
    //reStep1b is a regex for suffixes to be deleted if in R2, or replaced
    //with iqU if they are preceded by ic and not in R2.
    this.reStep1b = /((atrices?)|(ateurs?)|(ations?))$/;
  }
  /**
   * stem is the core function that takes a single token and returns
   * its stemmed version.
   * @param  {String} token The input token
   * @return {String}       the stemmed token
   */
  stem(token) {
    if (token.length < 3) {
        return token;
    } else {

    }
  }

  /**
   * preflight does a couple of simple replacements that need to precede
   * the actual stemming process.
   * @param  {String} token the input token
   * @return {String}       the result of the replacement operations
   */
  preflight(token) {
      return token.replace(new RegExp('(' + this.vowel + ')i(' + this.vowel + ')'), '$1I$2')
          .replace(new RegExp('(' + this.vowel + ')u(' + this.vowel + ')'), '$1U$2')
          .replace(new RegExp('(' + this.vowel + ')y'), '$1Y')
          .replace(new RegExp('y(' + this.vowel + ')'), 'Y$1')
          .replace('qu', 'qU')
          .replace('ï', 'Hi')
          .replace('ë', 'He');
  }

  /**
   * getRVR1R2 decomposes an input token to get the RV, R1 and R2 regions,
   * and returns the string values of those regions, along with their
   * offsets.
   * @param  {String} token the input token
   * @return {Object}       an object with six members:
   *                        rv {String} the part of the word constituting RV
   *                        r1 {String} the part of the word constituting R1
   *                        r2 {String} the part of the word constituting R2
   *                        rvof {Number} the offset of the start of RV
   *                        r1of {Number} the offset of the start of R1
   *                        r2of {Number} the offset of the start of R2
   */
  getRVR1R2(token){
    let RV = '';
    if (token.match(this.reRVExcept)){
      RV = token.replace(this.reRVExcept, '$2');
    }
    else{
      if (token.match(this.reRVA)){
        RV = token.replace(this.reRVA, '$1');
      }
      else{
        if (token.match(this.reRVB)){
          RV = token.replace(this.reRVB, '$1');
        }
      }
    }
    let RVIndex = (token.length - RV.length) + 1;
    let R1 = '';
    if (token.match(this.reR1R2)){
      R1 = token.replace(this.reR1R2, '$1');
    }
    let R1Index = (token.length - R1.length) + 1;
    let R2Candidate = R1.replace(this.reR1R2, '$1');
    let R2 = (R2Candidate == R1)? '' : R2Candidate;
    let R2Index = (R2Candidate == R1)? token.length + 1 : (token.length - R2.length) + 1;
    return {rv: RV, r1: R1, r2: R2, rvof: RVIndex, r1of: R1Index, r2of: R2Index}
  }

  /**
   * step1a deletes any of a number of suffixes if they appear within R2.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1a(token, r2of){
    let rep = token.replace(this.reStep1a, '');
    return ((rep !== token) && (rep.length >= (r2of - 1)))? rep : token;
  }

  /**
   * step1b deletes any of a number of suffixes if they appear within R2;
   * then deletes any preceding ic if it's in R2, or replaces it with iqU
   * if it's not.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1b(token, r2of){
    let rep = token.replace(this.reStep1b, '');
    if ((rep !== token) && (rep.length >= (r2of - 1))){
      let icGone = rep.replace(/ic$/, '');
      if ((icGone == rep) || (icGone.length >= (r2of - 1))){
        return icGone;
      }
      else{
        return icGone + 'iqU';
      }
    }
    else{
      return token;
    }
  }
}