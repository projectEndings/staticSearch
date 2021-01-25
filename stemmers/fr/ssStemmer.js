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
    
    /* Some regexes are defined at the object
       property level because they're used in 
       multiple contexts. */

    // A character class of vowels
    this.vowel = '[aeiouyâàëéêèïîôûù]';
    this.reVowel = new RegExp(this.vowel);

    //A character class of non-vowels
    this.nonVowel = '[^aeiouyâàëéêèïîôûù]';
    this.reNonVowel = new RegExp(this.nonVowel);

    //A character class of neither vowel nor H.
    this.neitherVowelNorH = '[^aeiouyâàëéêèïîôûùH]';
    this.reNeitherVowelNorH = new RegExp(this.neitherVowelNorH);

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
    
    /* reStep1 is the single 
      massive regex matching all suffixes handled in step 1. Initial is 
      non-greedy to ensure longest suffix match succeeds, since we need
      to act on the longest possible match.*/
    this.reStep1 = /.+?((issements)|(issement)|(atrices)|(atrice)|(ateurs)|(ations)|(logies)|(usions)|(utions)|(ements)|(amment)|(emment)|(ments)|(ances)|(iqUes)|(ismes)|(ables)|(istes)|(ateur)|(ation)|(logie)|(usion)|(ution)|(ences)|(ement)|(euses)|(ance)|(iqUe)|(isme)|(able)|(iste)|(ence)|(ités)|(ives)|(eaux)|(euse)|(ment)|(eux)|(ité)|(ive)|(ifs)|(aux)|(if))$/;
    
    //reStep1a is a regular expression for suffixes to be deleted if they
    //are in R2.
    this.reStep1a = /((ances?)|(iqUes?)|(ismes?)|(ables?)|(istes?)|(eux))$/;
    //reStep1b is a regex for suffixes to be deleted if in R2, or replaced
    //with iqU if they are preceded by ic and not in R2.
    this.reStep1b = /((atrices?)|(ateurs?)|(ations?))$/;
    //reStep1c: logie(s) ending to be replaced by log if in R2.
    this.reStep1c = /logies?$/;
    //reStep1d: suffixes to be replaced with u if in R2.
    this.reStep1d = /u[st]ions?$/;
    //reStep1e: suffixes to be replaced with ent if in R2.
    this.reStep1e = /ences?$/;
    //reStep1f: suffixes to be handled in various complex ways
    this.reStep1f = /ements?$/;
    //reStep1g: suffixes to be handled in various complex ways
    this.reStep1g = /ités?$/;
    //reStep1h: suffixes to be deleted if in R2, and preceding bits handled. 
    this.reStep1h = /i((f)|(ve))s?$/;
    //reStep1i handles two suffixes ending in x.
    this.reStep1i = /((eaux)|(aux))?$/;
    //reStep1j: two suffixes to be deleted or replaced depending on context.
    this.reStep1j = /euses?$/;
    //reStep1k: two suffixes to be deleted if in R1 and preceded by a non-vowel.
    this.reStep1k = new RegExp('(' + this.nonVowel + ')(issements?)$');
    //reStep1m: ments? to be removed if preceded by a vowel in RV.
    this.reStep1m = new RegExp('(' + this.vowel + ')(ments?)$');
    //reStep2a: long regex for various suffixes beginning with i.
    this.reStep2a = new RegExp('(' + this.neitherVowelNorH + ')((issaIent)|(issantes)|(iraIent)|(issante)|(issants)|(issions)|(irions)|(issais)|(issait)|(issant)|(issent)|(issiez)|(issons)|(irais)|(irait)|(irent)|(iriez)|(irons)|(iront)|(isses)|(issez)|(îmes)|(îtes)|(irai)|(iras)|(irez)|(isse)|(ies)|(ira)|(ît)|(ie)|(ir)|(is)|(it)|(i))$');
    //reStep2b matches the complete set of suffixes for step 2b, finding the longest.
    this.reStep2b = /.*?((eraIent)|(erions)|(assent)|(assiez)|(èrent)|(erais)|(erait)|(eriez)|(erons)|(eront)|(aIent)|(antes)|(asses)|(ions)|(erai)|(eras)|(erez)|(âmes)|(âtes)|(ante)|(ants)|(asse)|(ées)|(era)|(iez)|(ais)|(ait)|(ant)|(ée)|(és)|(er)|(ez)|(ât)|(ai)|(as)|(é)|(a))$/;
    //reStep2b1 matches suffixes to be deleted if in RV; note anchors for testing against longest match.
    this.reStep2b1 = /^((eraIent)|(erions)|(èrent)|(erais)|(erait)|(eriez)|(erons)|(eront)|(eras)|(erez)|(erai)|(iez)|(era)|(ées)|(ez)|(er)|(ée)|(és)|(é))$/;
    //reStep2b2 matches suffixes to be deleted in RV, and if a preceding e is also in RV, it should be deleted.
    //Note anchors for testing against longest match.
    this.reStep2b2 = /^((assions)|(assiez)|(assent)|(asses)|(antes)|(aIent)|(asse)|(ante)|(ants)|(âtes)|(âmes)|(ais)|(ait)|(ant)|(ât)|(ai)|(as)|(a))$/;
    //reStep4a is for deletion of s in certain circumstances.
    this.reStep4a = /((Hi)|[^aiouès])s$/;

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
    } 
    else {

    }
  }

  /**
   * preflight does a couple of simple replacements that need to precede
   * the actual stemming process.
   * @param  {String} token the input token
   * @return {String}       the result of the replacement operations
   */
  preflight(token) {
      return token.replace(new RegExp('y(' + this.vowel + ')'), 'Y$1')
          .replace(new RegExp('(' + this.vowel + ')y'), '$1Y')
          .replace(new RegExp('(' + this.vowel + ')u(' + this.vowel + ')'), '$1U$2')
          .replace('qu', 'qU')
          .replace(new RegExp('(' + this.vowel + ')i(' + this.vowel + ')'), '$1I$2')
          .replace('ë', 'He')
          .replace('ï', 'Hi');
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
    let RVIndex = (token.length - RV.length);
    let R1 = '';
    if (token.match(this.reR1R2)){
      R1 = token.replace(this.reR1R2, '$1');
    }
    let R1Index = (token.length - R1.length);
    let R2Candidate = R1.replace(this.reR1R2, '$1');
    let R2 = (R2Candidate == R1)? '' : R2Candidate;
    let R2Index = (R2Candidate == R1)? token.length : (token.length - R2.length);
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
    return ((rep !== token) && (rep.length >= r2of))? rep : token;
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
    if ((rep !== token) && (rep.length >= r2of)){
      let icGone = rep.replace(/ic$/, '');
      if ((icGone == rep) || (icGone.length >= r2of)){
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
  /**
   * step1c replaces logie[s] with log if within R2.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1c(token, r2of){
    let rep = token.replace(this.reStep1c, '');
    return ((rep !== token) && (rep.length >= r2of))? rep + 'log' : token;
  }
  /**
   * step1d replaces u[st]ions? with u if within R2.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1d(token, r2of){
    let rep = token.replace(this.reStep1d, '');
    return ((rep !== token) && (rep.length >= r2of))? rep + 'u' : token;
  }
  /**
   * step1e replaces ences? with ent if within R2.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1e(token, r2of){
    let rep = token.replace(this.reStep1e, '');
    return ((rep !== token) && (rep.length >= r2of))? rep + 'ent' : token;
  }
  /**
   * step1f deletes ements? and replaces preceding components in various
   * ways depending on context
   * @param  {String} token the input token
   * @param  {Object} rvr1r2  the complete RVR1R2 object.
   * @return {String}       the result of the replacement operations
   */
  step1f(token, rvr1r2){
    //Delete if in RV.
    let rep = token.replace(this.reStep1f, '');
    let repLen = rep.length;
    if ((rep != token) && (repLen >= rvr1r2.rvof)){
      //if preceded by iv, delete if in R2 (and if further preceded by at, delete if in R2)...
      if ((rep.match(/ativ$/)) && ((repLen - 4) >= rvr1r2.r2of)){
        return rep.replace(/ativ$/, '');
      }
      if ((rep.match(/iv$/)) && ((repLen - 2) >= rvr1r2.r2of)){
        return rep.replace(/iv$/, '');
      }
      //if preceded by eus, delete if in R2, else replace by eux if in R1
      if (rep.match(/eus$/)){
        if ((repLen - 3) >= rvr1r2.r2of){
          return rep.replace(/eus$/, '');
        }
        else{
          if ((repLen - 3) >= rvr1r2.r1of){
            return rep.replace(/eus$/, 'eux');
          }
          else{
            return rep;
          }
        }
      }
      //if preceded by abl or iqU, delete if in R2.
      if ((rep.match(/(abl)|(iqU)$/)) && ((repLen - 3) >= rvr1r2.r2of)){
        return rep.replace(/(abl)|(iqU)$/, '');
      }
      //if preceded by ièr or Ièr, replace by i if in RV.
      if ((rep.match(/[iI]èr$/)) && ((repLen - 3) >= rvr1r2.rvof)){
        return rep.replace(/[iI]èr$/, '');
      }
      else{
        return rep;
      }
    }
    else{
      return token;
    }
  }
  /**
   * step1g  deletes ités? if within R2 and modifies preceding bits.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1g(token, r2of){
    let rep = token.replace(this.reStep1g, '');
    let repLen = rep.length;
    if ((rep != token) && (repLen >= r2of)){
      //if preceded by abil, delete if in R2, else replace by abl
      if (rep.match(/abil$/)){
        return ((repLen - 4) >= r2of)? rep.replace(/abil$/, '') : rep.replace(/abil$/, 'abl');
      }
      //if preceded by ic, delete if in R2, else replace by iqU
      if (rep.match(/ic$/)){
        return ((repLen - 2) >= r2of)? rep.replace(/ic$/, '') : rep.replace(/ic$/, 'iqU');
      }
      //if preceded by iv, delete if in R2
      if (rep.match(/iv$/)){
        return ((repLen - 2) >= r2of)? rep.replace(/iv$/, '') : rep;
      }
      else{
        return rep;
      }
    }
    else{
      return token;
    }
  }
  /**
   * step1h  deletes i((f)|(ve))s?$ if within R2 and modifies preceding bits.
   * @param  {String} token the input token
   * @param  {Number} r2of  the offset of R2 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1h(token, r2of){
    let rep = token.replace(this.reStep1h, '');
    let repLen = rep.length;
    if ((rep != token) && (repLen >= r2of)){
      //if preceded by at, delete if in R2 (and if further preceded by ic, delete if in R2, else replace by iqU) 
      if ((rep.match(/icat$/)) && ((repLen - 4) >= r2of)){
        return rep.replace(/icat$/, '');
      }
      if ((rep.match(/icat$/)) && ((repLen - 2) >= r2of)){
        return rep.replace(/icat$/, 'iqU');
      }
      if ((rep.match(/at$/)) && ((repLen - 2) >= r2of)){
        return rep.replace(/at$/, '');
      }
      else{
        return rep;
      }
    }
    else{
      return token;
    }
  }
  /**
   * step1i replaces eaux with eau, and aux with al if within R1.
   * @param  {String} token the input token
   * @param  {Number} r1of  the offset of R1 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1i(token, r1of){
    if (token.match(/eaux$/)){
      return token.replace(/eaux$/, 'eau');
    }
    else{
      let rep = token.replace(/aux$/, 'al');
      return ((rep !== token) && ((rep.length - 2) >= r1of))? rep : token;
    }
  }
  /**
   * step1j deletes euse(s) if in R2, or replaces with eux if within R1.
   * @param  {String} token the input token
   * @param  {Object} rvr1r2  the complete RVR1R2 object.
   * @return {String}       the result of the replacement operations
   */
  step1j(token, rvr1r2){
    let rep = token.replace(this.reStep1j, '');
    let repLen = rep.length;
    if ((rep != token) && (repLen >= rvr1r2.r2of)){
      return rep;
    }
    else{
      return ((rep != token) && (repLen >= rvr1r2.r1of))? rep + 'eux' : token;
    }
  }
  /**
   * step1k deletes issements? if within R1 and preceded by a vowel.
   * @param  {String} token the input token
   * @param  {Number} r1of  the offset of R1 in the token.
   * @return {String}       the result of the replacement operations
   */
  step1k(token, r1of){
    let rep = token.replace(this.reStep1k, '$1');
    return ((rep !== token) && (rep.length >= r1of))? rep : token;
  }
  /**
   * step1l replaces amment with ant and emment with ent if within RV.
   * @param  {String} token the input token
   * @param  {Number} rvof  the offset of RV in the token.
   * @return {String}       the result of the replacement operations
   */
  step1l(token, rvof){
    let rep = token.replace(/([ae])mment$/, '$1nt');
    return ((rep !== token) && ((rep.length - 3) >= rvof))? rep : token;
  }
  /**
   * step1m removes ments? if preceded by a vowel within RV.
   * @param  {String} token the input token
   * @param  {Number} rvof  the offset of RV in the token.
   * @return {String}       the result of the replacement operations
   */
  step1m(token, rvof){
    let rep = token.replace(this.reStep1m, '$1');
    return ((rep !== token) && ((rep.length - 1) >= rvof))? rep : token;
  }
  /**
   * step2a removes any of a long list of suffixes beginning with i if 
   * preceded by a char with is neither vowel nor H, in RV. The test 
   * is carried out in RV.
   * @param  {String} token the input token
   * @param  {Object} rvr1r2  the complete RVR1R2 object.
   * @return {String}       the result of the replacement operations
   */
  step2a(token, rvr1r2){
    let rep = rvr1r2.rv.replace(reStep2a, '$1');
    return (rep !== rvr1r2.rv)? token.replace(new RegExp(rvr1r2.rv + '$'), rep) : token;
  }
  /**
   * step2b removes any of a long list of suffixes beginning with 
   * vowels in various configurations. reStep2b is the initial long
   * regex for matching all suffixes; reStep2b1 then handles suffixes
   * to be deleted if in RV, and reStep2b a set to be deleted if in RV
   * but where if there is a preceding e also in RV, it should be deleted.
   * @param  {String} token the input token
   * @param  {Object} rvr1r2  the complete RVR1R2 object.
   * @return {String}       the result of the replacement operations
   */
  step2b(token, rvr1r2){
    let longestMatch = rvr1r2.rv.replace(reStep2b, '$1');
    if (longestMatch == 'ions'){
      let rep = token.replace('ions$', '');
      return ((rep !== token) && (rep.length >= rvr1r2.rvof) && (rep.length >= rvr1r2.r2of))? rep : token;
    }
    if (longestMatch.match(reStep2b1) !== null){
      return token.replace(new RegExp(longestMatch + '$'), '');
    }
    if (longestMatch.match(reStep2b2) !== null){
      let rep = token.replace(new RegExp(longestMatch + '$'), '');
      if (!rep.match(/e$/)){
        return rep;
      }
      if (rep.match(/e$/)){
        return ((rep.length - 1) >= rvr1r2.rvof)? rep.replace(/e$/, '') : rep;
      }
    }
    return token;
  }
}