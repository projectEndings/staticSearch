/*           ssStemmer.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/* This file is a identity stemmer; in other words, it
 * takes a token or term as input, and returns it unchanged
 * as the stemmer result. This is useful for documents where 
 * stemming is inappropriate or impractical, and wildcard 
 * searching is more effective.
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
    //Nothing required.
  }
  /**
   * stem is the core function that takes a single token and returns
   * its stemmed version.
   * @param  {String} token The input token
   * @return {String}       the stemmed token
   */
   stem(token){
     return token.normalize('NFC');
   }
}
