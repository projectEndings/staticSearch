/*               search.js                 */
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

"use strict";

/** StaticSearch is the class that handles parsing the user's
  * input, through typed queries in the search box
  * and selections in search filters.
  *
  * It expects to find the following HTML items in
  * the HTML of the search page which includes it
  * (expressed as CSS selectors):
  *
  * input#searchQuery[type='text']   (the main search box)
  * button#doSearch                  (button for invoking search)
  * div.searchResults                (div in which to outpu the results)
  * select.searchFilter              (drop-down lists for filtering search)
  * input.searchFilter[type='text']  (type-ahead search filter boxes)
  *
  * The first is mandatory, although the user is
  * not required to use it; they may choose simply
  * to retrieve filtered lists of documents.
  * The second is mandatory, although the user may also invoke
  * search by pressing return while the text box has focus.
  * The third is mandatory, because there must be somewhere to
  * show the results of a search.
  * The other two are optional, but if present,
  * they will be incorporated.
  */
class StaticSearch{
  constructor(){
    //Essential query text box.
    try {
      this.queryBox =
           document.querySelector("input#searchQuery[type='text']");
      if (!this.queryBox){
        throw new Error('Failed to find text input box with id "searchQuery". Cannot provide search functionality.');
      }
      //Essential search button.
      this.searchButton =
           document.querySelector("button#doSearch");
      if (!this.searchButton){
       throw new Error('Failed to find search button. Cannot provide search functionality.');
      }
      //Essential results div.
      this.resultsDiv =
           document.querySelector("div#searchResults");
      if (!this.resultsDiv){
       throw new Error('Failed to find div with id "searchResults". Cannot provide search functionality.');
      }
      //Optional drop-down list search filters.
      this.filterSelects =
           Array.from(document.querySelectorAll("select.searchFilter"));
      //Optional type-ahead search filters.
      this.filterTexts   =
           Array.from(document.querySelectorAll("input.searchFilter[type='text']"));
      //Porter2 stemmer object.
      this.stemmer = new PT2();
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }
}
