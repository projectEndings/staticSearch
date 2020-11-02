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

class SSStemmer{
  constructor(){
    // A character class of vowels
    this.vowel                         = '[aeiouyâàëéêèïîôûù]';
    this.reVowel                       = new RegExp(this.vowel);
    //A character class of non-vowels
    this.nonVowel                      = '[^aeiouyâàëéêèïîôûù]';
    this.reNonVowel                    = new RegExp(this.nonVowel);
  }
  /**
   * stem is the core function that takes a single token and returns
   * its stemmed version.
   * @param  {String} token The input token
   * @return {String}       the stemmed token
   */
   stem(token){
     if (token.length < 3){
       return token;
     }
     else{

     }
   }
}
