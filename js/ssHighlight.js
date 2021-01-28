/*           ssHighlight.js                */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/** This file is part of the projectEndings staticSearch
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  */

 /** WARNING:
   * This lib has "use strict" defined. You may
   * need to remove that if you are mixing this
   * code with non-strict JavaScript.
   */

/* jshint strict:false */
/* jshint esversion: 6*/
/* jshint strict: global*/
/* jshint browser: true */

"use strict";

/** @function ssHighlightOnLoad
  * @description this function parses the URL querystring to determine
  *              whether it has a text string to be highlighted in the 
  *              page (with the search param ssMark), and if so, attempts
  *              to highlight it.
  *
  */
function ssHighlightOnLoad(){
  let sp = new URLSearchParams(document.location.search.substring(1));
  let encStr = sp.get('ssMark');
  if (encStr !== ''){
    let str = decodeURIComponent(encStr);
    let re = new RegExp('(' + str.replace(/\s+/g, '\\s+') + ')', 'g');
    let ctx = (document.location.hash != '')? document.getElementById(document.location.hash.substring(1)) : document.body;
    ctx.innerHTML = ctx.innerHTML.replace(re, '<mark>$1</mark>');
  }
}

window.addEventListener('load', ssHighlightOnLoad);