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

/**
  * First some constant values for categorizing term types.
  * I would like to put these inside the class, but I can't
  * find an elegant way to do that.
  */
/**@constant MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN, PHRASE
  * @type {Number}
  */
  const MUST_CONTAIN         = 0;
  const MUST_NOT_CONTAIN     = 1;
  const MAY_CONTAIN          = 2;
  const PHRASE               = 3;

/**
  * Components in the ss namespace that are used by default, but
  * which may easily be overridden by the project.
  */
/**
  * Our handy namespace
  * @namespace ss
  */
  var ss = {};

/**
  * @property ss.captions
  * @type {Array}
  * @description ss.captions is the an array of languages (default contains
  * only en), each of which has some caption properties. Extend
  * by adding new languages or replace if necessary.
  */
  ss.captions = [];
  ss.captions['en'] = {};
  ss.captions['en'].strDocumentsFound    = 'Documents found: ';
  ss.captions['en'][MUST_CONTAIN]        = 'Must contain: ';
  ss.captions['en'][MUST_NOT_CONTAIN]    = 'Must not contain: ';
  ss.captions['en'][MAY_CONTAIN]         = 'May contain: ';
  ss.captions['en'][PHRASE]              = 'Exact phrase: ';

/**
  * @property ss.stopwords
  * @type {Array}
  * @description a simple array of stopwords. Extend
  * by adding new items or replace if necessary.
  */
  ss.stopwords = new Array('i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', 'should', 'now');


/** @class StaticSearch
  * @description This is the class that handles parsing the user's
  * input, through typed queries in the search box and selections in
  * search filters.
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
      else{
        this.searchButton.addEventListener('click', function(){this.doSearch(); return false;}.bind(this));
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
      //Configuration for phrasal searches if found.
      //Default
      this.allowPhrasal = true;
      var tmp = document.querySelector("form[data-allowPhrasal]");
      if (tmp && !/(y|Y|yes|true|True|1)/.test(tmp.getAttribute('data-AllowPhrasal'))){
        this.allowPhrasal = false;
      }
      //Associative array for storing retrieved JSON data. Any retrieved
      //data stored in here is retained between searches to avoid having
      //to retrieve it twice.
      this.index = {};

      //Porter2 stemmer object.
      this.stemmer = new PT2();

      //Array of terms parsed out of search string. This is emptied
      //at the beginning of every new search.
      this.terms = new Array();

      //Captions
      this.captions = ss.captions; //Default; override this if you wish by setting the property after instantiation.
      this.captionLang  = document.getElementsByTagName('html')[0].getAttribute('lang') || 'en'; //Document language.
      this.captionSet   = this.captions[this.captionLang]; //Pointer to the caption object we're going to use.

      //Stopwords
      this.stopwords = ss.stopwords;

      //Directory for JSON files.
      this.jsonDirectory = 'js/search/'; //Default value. Override if necessary.

      //Boolean: should this instance report the details of its search
      //in human-readable form?
      this.showSearchReport = false;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/** @function StaticSearch~doSearch
  * @description this function initiates the search process,
  *              taking it as far as creating the promises
  *              for retrieval of JSON files. After that, the
  *              resolution of the promises carries the process
  *              on.
  *
  * @return {Boolean} true if a search is initiated otherwise false.
  */
  doSearch(){
    var result = false; //default.
    if (this.parseSearchQuery()){
      if (this.writeSearchReport()){
          result = true;
      }
    }
    return result;
  }


/** @function StaticSearch~parseSearchQuery
  * @description this retrieves the content of the text
  * search box and parses it into an array of term items
  * ready for analysis against retrieved results.
  *
  * @return {Boolean} true if terms found, otherwise false.
  */
  parseSearchQuery(){
    //Clear anything in the existing array.
    this.terms = [];
    var strSearch = this.queryBox.value;
    //Start by normalizing whitespace.
    strSearch = strSearch.replace(/((^\s+)|\s+$)/g, '');
    strSearch = strSearch.replace(/\s+/g, ' ');

    //Next, replace curly quotes/apostrophes with straight.
    strSearch = strSearch.replace(/[“”]/g, '"');
    strSearch = strSearch.replace(/[‘’‛]/g, "'");

    //If we're not supporting phrasal searches, get rid of double quotes.
    if (!this.allowPhrasal){
      strSearch = strSearch.replace(/"/g, '');
    }
    else{
    //Get rid of any quote pairs with nothing between them.
      strSearch = strSearch.replace(/""/g, '');
    }

    //Now delete any unmatched double quotes.
    var qCount = 0;
    var lastQPos = -1;
    var tmp = '';
    for (var i=0; i<strSearch.length; i++){
        tmp += strSearch.charAt(i);
        if (strSearch.charAt(i) === '"'){
          qCount++;
          lastQPos = i;
        }
    }
    if (qCount % 2 > 0){
      strSearch = tmp.substr(0, lastQPos) + tmp.substr(lastQPos + 1, tmp.length);
    }
    else{
      strSearch = tmp;
    }

    //Put that fixed string back in the box to make
    //clear to the user what's been understood.
    this.queryBox.value = strSearch;

    //Now iterate through the string, paying attention
    //to whether you're inside a quote or not.
    var inPhrase = false;
    var strSoFar = '';
    for (var i=0; i<strSearch.length; i++){
      var c = strSearch.charAt(i);
      if (c === '"'){
        this.addSearchItem(strSoFar);
        inPhrase = !inPhrase;
        strSoFar = '';
      }
      else{
        if ((c === ' ')&&(!inPhrase)){
          this.addSearchItem(strSoFar);
          strSoFar = '';
        }
        else{
          strSoFar += c;
        }
      }
    }
    this.addSearchItem(strSoFar);
    return (this.terms.length > 0);
    console.log(JSON.stringify(this.terms));
  }
/** @function StaticSearch~addSearchItem
  * @description this is passed a single component from the
  * search box parser by parseSearchQuery. It constructs a
  * single item from it, and adds that to this.terms.
  * @param {String}   strInput a string of text.
  * @return {Boolean} true if terms found, otherwise false.
  */
  addSearchItem(strInput){
    //Sanity check
    if (strInput.length < 1){
      return false;
    }
    console.log('Adding: ' + strInput);
    //Is it a phrase?
    if (/\s/.test(strInput)){
    //We need to find the first component which is not a stopword.
      var subterms = strInput.toLowerCase().split(/\s+/);
      var i;
      for (i = 0; i <= subterms.length; i++){
        if (this.stopwords.indexOf(subterms[i]) < 0){
          break;
        }
      }
      if (i < subterms.length){
        this.terms.push({str: strInput, stem: this.stemmer.stem(subterms[i]), type: PHRASE});
      }
    }
    else{
      //Else is it a must-contain?
      if (/^[\+]/.test(strInput)){
        var term = strInput.substring(1).toLowerCase();
        this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), type: MUST_CONTAIN});
      }
      else{
      //Else is it a must-not-contain?
        if (/^[\-]/.test(strInput)){
          var term = strInput.substring(1).toLowerCase();
          this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), type: MUST_NOT_CONTAIN});
        }
        else{
        //Else may-contain.
          var term = strInput.toLowerCase();
          this.terms.push({str: strInput, stem: this.stemmer.stem(term), type: MAY_CONTAIN});
        }

      }
    }
    return (this.terms.length > 0);
  }
/** @function StaticSearch~writeSearchReport
  * @description this outputs a human-readable explanation of the search
  * that's being done, to clarify for users what they've chosen to look for.
  * @return {Boolean} true if the process succeeds, otherwise false.
  */
  writeSearchReport(){
    try{
      var sp = document.querySelector('#searchReport');
      if (sp){sp.parentNode.removeChild(sp);}
      var arrOutput = new Array();
      var i;
      for (i=0; i<this.terms.length; i++){
        if (!arrOutput[this.terms[i].type]){
          arrOutput[this.terms[i].type] = new Array();
        }
        arrOutput[this.terms[i].type].push('"' + this.terms[i].str + '"');
      }
      var d = document.createElement('div');
      d.setAttribute('id', 'searchReport')
      for (i=arrOutput.length-1; i>=0; i--){
        var p = document.createElement('p');
        var t = document.createTextNode(this.captionSet[i] + arrOutput[i].join(', '));
        p.appendChild(t);
        d.appendChild(p);
      }
      this.resultsDiv.insertBefore(d, this.resultsDiv.firstChild);
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

/**
  * @function StaticSearch~populateIndex
  * @description this is passed an array of tokens, and its job is
  * to ensure that the index is ready to handle a search with
  * those tokens. The index is deemed ready when either a) the
  * JSON file for that token has been retrieved and its contents
  * merged into the index, or b) a retrieval has failed, so an
  * empty placeholder has been inserted to signify that there is
  * no such dataset.
  *
  * The function works with fetch and promises, and its final
  * .then() calls the processResults function.
  * @param {Array} arrTokens An array of tokens.
  */
  populateIndex(arrTokens){
    var i, imax, tokensToFind = [], promises = [], emptyIndex;
//We need a self pointer because this will go out of scope.
    var self = this;
    try{
  //For each token in the search string
      for (i=0, imax=this.arrTokens.length; i<imax; i++){
  //Now check whether we already have an index entry for this token
        if (!this.index.hasOwnProperty(this.arrTokens[i])){
  //If not, add it to the array of tokens we want to retrieve.
          tokensToFind.push(this.arrTokens[i]);
        }
      }
      //If we do need to retrieve JSON index data, then do it
      if (tokensToFind.length > 0){

//Set off fetch operations for the things we don't have yet.
        for (i=0, imax=tokensToFind.length; i<imax; i++){

//We will add an empty entry for anything that's not found, so we don't
//have to retrieve it again.
          emptyIndex = {'token': tokensToFind[i], 'instances': []}; //used as return value when nothing retrieved.

//We create an array of fetches to get the json file for each token,
//assuming it's there.
          promises[i] = fetch(this.jsonDirectory + tokensToFind[i] + '.json', {
                              credentials: 'same-origin',
                              cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
                              headers: {
                                'Accept': 'application/json'
                              },
                              method: 'GET',
                              redirect: 'follow', // *manual, follow, error
                              referrer: 'no-referrer' // *client, no-referrer
              })
//If we get a response, and it looks good
              .then(function(response){
                if ((response.status >= 200) &&
                    (response.status < 300) &&
                    (response.headers.get('content-type')) &&
                    (response.headers.get('content-type').includes('application/json'))) {
//then we ask for response.json(), which is itself a promise, to which we add a .then to store the data.
                  return response.json().then(function(data){ self.tokenFound(data); }.bind(self));
                }
                else {
//Otherwise, we store the pre-created emptyIndex, so we don't have to look
//for this token again in a future search.
                  self.tokenFound(emptyIndex);
                }
              })
//If something goes wrong, then we again try to store an empty index
//through the notFound function.
//This is not really necessary -- we could call the found method
//instead -- but we may want to do better debugging in the future.
              .catch(function(e, token){
                console.log('Failed to retrieve ' + token + ': ' + e);
                self.tokenNotFound(token);
              }.bind(self, tokensToFind[i]));
            }

//Now set up a Promise.all to fire the rest of the work when all fetches have
//completed or failed.
        Promise.all(promises).then(function(values) {
          this.processResults();
        }.bind(this));
      }
  //Otherwise we can just do the search with the index data we already have.
      else{
        this.processResults();
      }
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/**
  * @function StaticSearch~tokenFound
  * @description When a request for a JSON file for a specific
  *              token results in a JSON file with data, we store
  *              the data in the index, indexed under the token.
  *              Sometimes the data coming in may be an instance
  *              of an empty index, if the retrieval code knows it
  *              got nothing.
  * @param {Object} data the data structure retrieved for the token.
  */
  tokenFound(data){
    try{
      this,index[data.token] = data;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/**
  * @function StaticSearch~tokenNotFound
  * @description When a request for a JSON file for a specific
  *              token results in no retrieval, we store an empty
  *              item so that we don't need to check again. We can
  *              also use this function for debugging.
  * @param token {String} the token not found.
  */
  tokenNotFound(token){
    if (!this.index.hasOwnProperty(token)){
      this.index[token] = {'token': tokensToFind[i], 'instances': []};
    }
  }

/**
  * @function StaticSearch~processResults
  * @description When we are satisfied that all relevant search data
  *              has been retrieved and added to the index, this
  *              function is called to process the search and show
  *              any results found.
  * @return {Boolean} true if there are results to show; false if not.
  */
  processResults(){
    try{
//TODO.
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

}