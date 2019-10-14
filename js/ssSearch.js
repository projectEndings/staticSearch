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
/* jshint browser: true */

"use strict";

/**
  * First some constant values for categorizing term types.
  * I would like to put these inside the class, but I can't
  * find an elegant way to do that.
  */
/**@constant PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN
  * @type {Number}
  */

  const PHRASE               = 0;
  const MUST_CONTAIN         = 1;
  const MUST_NOT_CONTAIN     = 2;
  const MAY_CONTAIN          = 3;

/**@constant arrTermTypes
   * @type {Array}
   * @description array of PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN
   *              used so we can easily iterate through them.
   */
  const arrTermTypes = [PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN];

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
  ss.captions['en'][PHRASE]              = 'Exact phrase: ';
  ss.captions['en'][MUST_CONTAIN]        = 'Must contain: ';
  ss.captions['en'][MUST_NOT_CONTAIN]    = 'Must not contain: ';
  ss.captions['en'][MAY_CONTAIN]         = 'May contain: ';
  ss.captions['en'].strScore             = 'Score: ';


/**
  * @property ss.stopwords
  * @type {Array}
  * @description a simple array of stopwords. Extend
  * by adding new items or replace if necessary. If a local
  * stopwords.json file exists, that will be loaded and overwrite
  * this set.
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
  * input#ssQuery[type='text']   (the main search box)
  * button#ssDoSearch                  (button for invoking search)
  * div.ssResults                (div in which to outpu the results)
  * input[type='checkbox'].ssFilter              (optional; checkbox lists for filtering search)
  * input[type='text'].ssFilter  (NOT YET IMPLEMENTED: type-ahead search filter boxes)
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

      //Directory for JSON files. Inside this directory will be a
      //'lower' dir and an 'upper' dir, where the two sets of case-
      //distinguished JSON files are stored.
      this.jsonDirectory = 'staticSearch/'; //Default value. Override if necessary.
      let tmp;
      this.queryBox =
           document.querySelector("input#ssQuery[type='text']");
      if (!this.queryBox){
        throw new Error('Failed to find text input box with id "ssQuery". Cannot provide search functionality.');
      }
      //Essential search button.
      this.searchButton =
           document.querySelector("button#ssDoSearch");
      if (!this.searchButton){
       throw new Error('Failed to find search button. Cannot provide search functionality.');
      }
      else{
        this.searchButton.addEventListener('click', function(){this.doSearch(); return false;}.bind(this));
      }
      //Essential results div.
      this.resultsDiv =
           document.querySelector("div#ssResults");
      if (!this.resultsDiv){
       throw new Error('Failed to find div with id "ssResults". Cannot provide search functionality.');
      }
      //Optional checkbox search filters.
      this.filterCheckboxes =
           Array.from(document.querySelectorAll("input[type='checkbox'][class='ssFilter']"));

      //Object for handling filter checkboxes that will only be used if there
      //are any.
      this.docMetadata = {};

      //Any / all selector for combining filters. TODO.
      this.matchAllFilters = false;

      //Optional type-ahead search filters. NOT IMPLEMENTED IN THE PROJECT YET.
      this.filterTexts   =
           Array.from(document.querySelectorAll("input.ssFilter[type='text']"));

      //Configuration for phrasal searches if found.
      //Default
      this.allowPhrasal = true;
      tmp = document.querySelector("form[data-allowPhrasal]");
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

      //Default set of stopwords
      this.stopwords = ss.stopwords;
      //Now check for a local stopwords file.
      fetch(this.jsonDirectory + 'stopwords.json')
        .then(function(response) {
          return response.json();
        }).then(function(jsonStopwords) {
          this.stopwords = jsonStopwords.words;
        }.bind(this));

      //Boolean: should this instance report the details of its search
      //in human-readable form?
      this.showSearchReport = false;

      //How many results should be shown per page?
      //Default
      this.resultsPerPage = 10;
      tmp = document.querySelector("form[data-resultsPerPage]");
      if (tmp){
        let parsed = parseInt(tmp.getAttribute('data-resultsPerPage'));
        if (!isNaN(parsed)){this.resultsPerPage = parsed;}
      }

      //How many keyword in context strings should be included
      //in search results?
      //Default
      this.kwicLimit = 10;
      tmp = document.querySelector("form[data-kwicLimit]");
      if (tmp){
        let parsed = parseInt(tmp.getAttribute('data-kwicLimit'));
        if (!isNaN(parsed)){this.kwicLimit = parsed;}
      }

      //Result handling object
      this.resultSet = new SSResultSet(this.kwicLimit);

      //Now we're instantiated, check to see if there's a query
      //string that should initiate a search.
      this.parseQueryString();
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/** @function StaticSearch~parseQueryString
  * @description this function is run after the class is instantiated
  *              to check whether there is a query string in the
  *              browser URL. If so, it parses it out and runs the
  *              query.
  *
  * @return {Boolean} true if a search is initiated otherwise false.
  */
  parseQueryString(){
    let searchParams = new URLSearchParams(document.location.search);
    if (searchParams.has('q')){
      this.queryBox.value = searchParams.get('q');
      this.doSearch();
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
    let result = false; //default.
    if (this.parseSearchQuery()){
      if (this.writeSearchReport()){
        this.populateIndex();
        result = true;
      }
    }
    else{
      //Perhaps there are filters without a search string.
      this.listDocsByFilters();
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
    let i;
    //Clear anything in the existing array.
    this.terms = [];
    let strSearch = this.queryBox.value;
    //Start by normalizing whitespace.
    strSearch = strSearch.replace(/((^\s+)|\s+$)/g, '');
    strSearch = strSearch.replace(/\s+/g, ' ');

    //Next, replace curly quotes/apostrophes with straight.
    strSearch = strSearch.replace(/[“”]/g, '"');
    strSearch = strSearch.replace(/[‘’‛]/g, "'");

    //Strip out all other punctuation
    strSearch = strSearch.replace(/[\.',!@#$%\^&*]+/, '');

    //If we're not supporting phrasal searches, get rid of double quotes.
    if (!this.allowPhrasal){
      strSearch = strSearch.replace(/"/g, '');
    }
    else{
    //Get rid of any quote pairs with nothing between them.
      strSearch = strSearch.replace(/""/g, '');
    }

    //Now delete any unmatched double quotes.
    let qCount = 0;
    let lastQPos = -1;
    let tmp = '';
    for (i=0; i<strSearch.length; i++){
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
    let inPhrase = false;
    let strSoFar = '';
    for (let i=0; i<strSearch.length; i++){
      let c = strSearch.charAt(i);
      if (c === '"'){
        this.addSearchItem(strSoFar, inPhrase);
        inPhrase = !inPhrase;
        strSoFar = '';
      }
      else{
        if ((c === ' ')&&(!inPhrase)){
          this.addSearchItem(strSoFark, false);
          strSoFar = '';
        }
        else{
          strSoFar += c;
        }
      }
    }
    this.addSearchItem(strSoFar, inPhrase);
    //We always want to handle the terms in order of
    //precedence, starting with phrases.
    this.terms.sort(function(a, b){return a.type - b.type;});
    console.log(JSON.stringify(this.terms));
    return (this.terms.length > 0);
  }

/** @function StaticSearch~addSearchItem
  * @description this is passed a single component from the
  * search box parser by parseSearchQuery. It constructs a
  * single item from it, and adds that to this.terms.
  * @param {String}   strInput a string of text.
  * @param {Boolean}  isPhrasal whether or not this is a phrasal
  *                             search. This may be true even for
  *                             a single word, if it is to be searched
  *                             unstemmed.
  * @return {Boolean} true if terms found, otherwise false.
  */
  addSearchItem(strInput, isPhrasal){
    //Sanity check
    if (strInput.length < 1){
      return false;
    }
    console.log('Adding: ' + strInput);

    //Set a flag if it starts with a cap.
    let firstLetter = strInput.replace(/^[\+\-]/, '').substring(0, 1);
    let startsWithCap = (firstLetter.toLowerCase() !== firstLetter);

    //Is it a phrase?
    if ((/\s/.test(strInput)) || (isPhrasal)){
    //We need to find the first component which is not a stopword.
      let subterms = strInput.toLowerCase().split(/\s+/);
      let i;
      for (i = 0; i <= subterms.length; i++){
        if (this.stopwords.indexOf(subterms[i]) < 0){
          break;
        }
      }
      if (i < subterms.length){
        this.terms.push({str: strInput, stem: this.stemmer.stem(subterms[i]), capFirst: startsWithCap, type: PHRASE});
      }
    }
    else{
      //Else is it a must-contain?
      if (/^[\+]/.test(strInput)){
        let term = strInput.substring(1).toLowerCase();
        this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), capFirst: startsWithCap, type: MUST_CONTAIN});
      }
      else{
      //Else is it a must-not-contain?
        if (/^[\-]/.test(strInput)){
          let term = strInput.substring(1).toLowerCase();
          this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), capFirst: startsWithCap, type: MUST_NOT_CONTAIN});
        }
        else{
        //Else may-contain.
          let term = strInput.toLowerCase();
          this.terms.push({str: strInput, stem: this.stemmer.stem(term), capFirst: startsWithCap, type: MAY_CONTAIN});
        }

      }
    }
    return (this.terms.length > 0);
  }

/** @function StaticSearch~listDocsByFilters
  * @description this function provides search results
  * based only on the facet filters (if any), to be
  * used when there is no search query, just a selection
  * from the filters.
  *
  * @return {Boolean} true if documents found, otherwise false.
  */
  listDocsByFilters(){
    var self = this;
//Check whether we have filters on the page or not.
    if (this.filterCheckboxes.length < 1){
      return false;
    }
//Check whether any filters have been selected.
    let arrFilters = this.getActiveFiltersAsArray();
    if (arrFilters.length < 1){
      //console.log('No filters set.');
      return false;
    }
    //So we have active filters. Do we have doc
    //metadata yet?
    if ((Object.keys(this.docMetadata).length === 0) &&
       (this.docMetadata.constructor === Object)){
      //We don't have doc metadata yet. Retrieve it
      //and call this again.
      //console.log('Doc metadata not yet retrieved.');
      //TODO: Figure out if there's a less repetitive
      //way to do this.
      return fetch(self.jsonDirectory + 'docs.json')
        .then(function(response) {
          return response.json();
        })
        .then(function(docMeta) {
          self.docMetadata = docMeta;
          self.listDocsByFilters();
        })
        .catch(function(e){
          console.log('Error attempting to retrieve docMetadata: ' + e);
          return function(){self.docMetadata = {'noMetadataFound': true}; return false;}.bind(self);
        }.bind(self));
    }
    else{
      if (this.docMetadata.noMetadataFound == true){
        //console.log('No metadata to work with. Do nothing.');
        return false;
      }
      else{
        //We have doc metadata. We can list documents based
        //on the filters if any.
        //No need for this, since we're not using it.
        //this.resultSet.clear();
        let docLinks = [];
        for (let docUri of Object.keys(this.docMetadata)){
          //console.log(docUri);
          if (this.docMatchesFilters(docUri, arrFilters, this.matchAllFilters)){
            //TODO: Just output a list of documents as links, since
            //there's no real useful info to be had and no sort
            //requirement.
            let newLi = document.createElement('li');
            let newA = document.createElement('a');
            newA.setAttribute('href', docUri);
            //TODO: Replace this with doc title when available.
            newA.appendChild(document.createTextNode(this.docMetadata[docUri].docTitle));
            newLi.appendChild(newA);
            docLinks.push(newLi);
          }
        }
        if (docLinks.length > 0){
          let newUl = document.createElement('ul');
          for (let docLink of docLinks){
            newUl.appendChild(docLink);
          }
          while (this.resultsDiv.firstChild){this.resultsDiv.removeChild(this.resultsDiv.firstChild);}
          this.resultsDiv.appendChild(document.createElement('p')
                         .appendChild(document.createTextNode(
                           this.captionSet.strDocumentsFound + docLinks.length
                         )));
          this.resultsDiv.appendChild(newUl);
          return true;
        }
        else{
          this.reportNoResults(true);
          return false;
        }
      }
    }
  }

/** @function StaticSearch~getActiveFiltersAsArray
  * @description this function harvests the selected filters
  * in the form of a Map, then transforms the result to
  * an array, which can be used in other methods.
  *
  * @return {Array} an array (which might be empty)
  */
  getActiveFiltersAsArray(){
    let filters = new Map();
    for (let cbx of this.filterCheckboxes){
      if (cbx.checked){
        let title = cbx.getAttribute('title');
        let val   = cbx.getAttribute('value');
        if (filters.has(title)){
          let arr = filters.get(title);
          arr.push(val);
          filters.set(title, arr);
        }
        else{
          filters.set(title, new Array(val));
        }
      }
    }
    return Array.from(filters);
  }

/** @function StaticSearch~writeSearchReport
  * @description this outputs a human-readable explanation of the search
  * that's being done, to clarify for users what they've chosen to look for.
  * @return {Boolean} true if the process succeeds, otherwise false.
  */
  writeSearchReport(){
    try{
      let sp = document.querySelector('#searchReport');
      if (sp){sp.parentNode.removeChild(sp);}
      let arrOutput = [];
      let i, d, p, t;
      for (i=0; i<this.terms.length; i++){
        if (!arrOutput[this.terms[i].type]){
          arrOutput[this.terms[i].type] = {type: this.terms[i].type, terms: []};
        }
        arrOutput[this.terms[i].type].terms.push('"' + this.terms[i].str + '"');
      }
      arrOutput.sort(function(a, b){return a.type - b.type;})

      d = document.createElement('div');
      d.setAttribute('id', 'searchReport');

      arrOutput.forEach((obj)=>{
        p = document.createElement('p');
        t = document.createTextNode(this.captionSet[obj.type] + obj.terms.join(', '));
        p.appendChild(t);
        d.appendChild(p);
      });
      this.resultsDiv.insertBefore(d, this.resultsDiv.firstChild);
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

/**
  * @function StaticSearch~getTermsByType
  * @description This method returns an array of indexes in the
  * StaticSearch.terms array, being the terms which match the
  * supplied term type (PHRASE, MUST_CONTAIN etc.).
  * @param {integer} termType One of PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN,
                              MAY_CONTAIN.
  * @return {Array<integer>} An array of zero or more integers.
  */
  getTermsByType(termType){
    let result = [];
    for (let i=0; i<this.terms.length; i++){
      if (this.terms[i].type == termType){
        result.push(i);
      }
    }
    return result;
  }

/**
  * @function StaticSearch~populateIndex
  * @description The task of this function is basically
  * to ensure that the index is ready to handle a search with
  * those tokens. The index is deemed ready when either a) the
  * JSON file for that token has been retrieved and its contents
  * merged into the index, or b) a retrieval has failed, so an
  * empty placeholder has been inserted to signify that there is
  * no such dataset. If search filters are also active, the
  * function checks whether document metadata has been retrieved,
  * and if not, gets that as well.
  *
  * The function works with fetch and promises, and its final
  * .then() calls the processResults function.
  */
  populateIndex(){
    var i, imax, tokensToFind = [], promises = [], emptyIndex,
    jsonSubfolder, needDocMetadata = false;
//We need a self pointer because this will go out of scope.
    var self = this;
    try{
  //For each token in the search string
      for (i=0, imax=this.terms.length; i<imax; i++){
  //Now check whether we already have an index entry for this token
        if (!this.index.hasOwnProperty(this.terms[i].stem)){
  //If not, add it to the array of tokens we want to retrieve.
          tokensToFind.push(this.terms[i].stem);
        }
        if (this.terms[i].capFirst){
          if (!this.index.hasOwnProperty(this.terms[i].str)){
    //If not, add it to the array of tokens we want to retrieve.
            tokensToFind.push(this.terms[i].str);
          }
        }
      }

      //Do we need to get document metadata for filters?
      if ((Object.keys(this.docMetadata).length === 0) &&
         (this.docMetadata.constructor === Object)){
        needDocMetadata = true;
      }

      //If we do need to retrieve JSON index data, then do it
      if ((tokensToFind.length > 0) || (needDocMetadata)){

        console.log(JSON.stringify(tokensToFind));

//Set off fetch operations for the things we don't have yet.
        for (i=0, imax=tokensToFind.length; i<imax; i++){

//We will first add an empty index so that if nothing is found, we won't need
//to search again.
          emptyIndex = {'token': tokensToFind[i], 'instances': []}; //used as return value when nothing retrieved.

          this.tokenFound(emptyIndex);

//Figure out whether we're retrieving a lower-case or an upper-case token.
          jsonSubfolder = (tokensToFind[i].toLowerCase() == tokensToFind[i])? 'lower/' : 'upper/';

//We create an array of fetches to get the json file for each token,
//assuming it's there.
          promises[i] = fetch(self.jsonDirectory + jsonSubfolder + tokensToFind[i] + '.json', {
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
              })
//If something goes wrong, then we store an empty index
//through the notFound function.
              .catch(function(e){
                console.log('Error attempting to retrieve ' + tokensToFind[i] + ': ' + e);
                return function(emptyIndex){self.tokenFound(emptyIndex);}.bind(self, emptyIndex);
              }.bind(self));
            }

        promises[promises.length] = fetch(self.jsonDirectory + 'docs.json')
          .then(function(response) {
            return response.json();
          })
          .then(function(docMeta) {
            self.docMetadata = docMeta;
          }.bind(self))
          .catch(function(e){
            console.log('Error attempting to retrieve docMetadata: ' + e);
            return function(){self.docMetadata = {'noMetadataFound': true};}.bind(self);
          }.bind(self));

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
  * @description Before a request for a JSON file is initially made,
  *              an empty index is stored, indexed under the token
  *              which is being searched, so that whether or not we
  *              successfully retrieve data, we won't have to try
  *              again in a subsequent search in the same session.
  *              Then, when a request for a JSON file for a specific
  *              token results in a JSON file with data, we overwrite
  *              the data in the index, indexed under the token.
  *              Sometimes the data coming in may be an instance
  *              of an empty index, if the retrieval code knows it
  *              got nothing.
  * @param {Object} data the data structure retrieved for the token.
  */
  tokenFound(data){
    try{
      this.index[data.token] = data;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/**
  * @function staticSearch~indexTokenHasDoc
  * @description This function, given an index token and a docUri, searches
  *              to see if there is an entry in the token's instances for
  *              that docUri.
  * @param {String} token the index token to search for.
  * @param {String} docUri the docUri to search for.
  * @return {Boolean} true if found, false if not.
  */
  indexTokenHasDoc(token, docUri){
    let result = false;
    if (this.index[token]){
      for (let i=0; i<this.index[token].instances.length; i++){
        if (this.index[token].instances[i].docUri == docUri){
          result = true;
          break;
        }
      }
    }
    return result;
  }

/**
  * @function StaticSearch~docMatchesFilters
  * @description Checks a document against the set of filters to
  *              determine whether it matches or not. TODO: Add handling
  *              for date filters to this function.
  * @param {String} docUri id of the document to be checked.
  * @param {Array<Array<string>, <Array>>} filters an array of descriptors
  *                each with an array of values.
  * @param {Boolean} matchAll If true, the document must match all
  *                   filters to pass; otherwise, it need only match
  *                   one or more.
  * @return {Boolean} true if the document matches, or if there are no
  *                   filters defined; otherwise false.
  */
  docMatchesFilters(docUri, filters, matchAll){
    let result = true; //default in case there are no filters.
    let doc = this.docMetadata[docUri];
    if (!doc){
      return result;
    }
    for (let f of filters){
      let fName = f[0];
      let fVals = f[1];
      for (let fVal of fVals){
        if ((doc.filters[fName] != null) && (doc.filters[fName].indexOf(fVal) > -1)){
          if (!matchAll){
            return true;
          }
        }
        else{
          if (matchAll){
            return false;
          }
          else{
            result = false;
          }
        }
      }
    }
    return result;
  }

/**
  * @function StaticSearch~reportNoResults
  * @description Reports that no results have been found.
  *              Also optionally configures and runs a
  *              simpler version of the current search, with
  *              phrases tokenized, etc.
  * @param {Boolean} trySimplerSearch a flag to determine whether
  *              this search should be simplified and automatically
  *              run again.
  * @return {Boolean} true if successful, false if not.
  */
  reportNoResults(trySimplerSearch){
    //TODO: NOT IMPLEMENTED YET.
    console.log('No results. Try simpler search? ' + trySimplerSearch);

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
//Debugging only.
      console.log('index: ' + JSON.stringify(this.index));
      console.log('index keys: ' + Object.keys(this.index).toString());

//Start by clearing any previous results.
      this.resultSet.clear();

//The sequence of result processing is highly dependent on the
//query components entered by the user. First, we discover what
//term types we have in the list.
      let phrases           = this.getTermsByType(PHRASE);
      let must_contains     = this.getTermsByType(MUST_CONTAIN);
      let must_not_contains = this.getTermsByType(MUST_NOT_CONTAIN);
      let may_contains      = this.getTermsByType(MAY_CONTAIN);

//For nested functions, we need a reference to this.
      var self = this;

//Now we have a few embedded functions to avoid duplicating code.
/**
  * @function StaticSearch~processResults~processPhrases
  * @description Embedded function to retrieve the results from
  *              phrasal searches.
  * @return true if succeeds, false if not.
  */
      function processPhrases(){
        try{
          for (let phr of phrases){
  //Get the term we decided to use to retrieve index data.
            let stem = self.terms[phr].stem;
  //Make the phrase into a regex for matching.
            let rePhr = new RegExp(self.terms[phr].str, 'i');
  //If that term is in the index (it should be, even if it's empty, but still...)
            if (self.index[stem]){
  //Look at each of the document instances for that term...
              for (let inst of self.index[stem].instances){
  //Create an array to hold the contexts
                let currContexts = [];
  //Now look at each context for that instance, if any...
                for (let cntxt of inst.contexts){
  //Check whether our phrase matches that context (remembering to strip
  //out any <mark> tags)...
                  let unmarkedContext = cntxt.context.replace(/<[^>]+>/g, '');
                  if (rePhr.test(unmarkedContext)){
  //We have a candidate document for inclusion, and a candidate context.
                    let c = unmarkedContext.replace(rePhr, '<mark>' + self.terms[phr].str + '</mark>');
                    currContexts.push({form: self.terms[phr].str, context: c, weight: 2});
                  }
                }
  //If we've found contexts, we know we have a document to add to the results.
                if (currContexts.length > 0){
  //The resultSet object will automatically merge this data if there's already
  //an entry for the document.
                  self.resultSet.set(inst.docUri, {docUri: inst.docUri,
                    docTitle: inst.docTitle,
                    score: inst.score,
                    contexts: currContexts,
                    score: currContexts.length});
                }
              }
            }
          }
          return true;
        }
        catch(e){
          console.log('ERROR: ' + e.message);
          return false;
        }
      }
//End of nested function getPhrasalResults.

/**
  * @function StaticSearch~processResults~processMustNotContains
  * @description Embedded function to remove from the result set all
  *              documents which contain terms which have been designated
  *              as excluded.
  * @return true if succeeds, false if not.
  */
      function processMustNotContains(){
        try{
          for (let mnc of must_not_contains){
            let stem = self.terms[mnc].stem;
            if (self.index[stem]){
//Look at each of the document instances for that term...
              for (let inst of self.index[stem].instances){
//Delete it from the result set.
                if (self.resultSet.has(inst.docUri)){
                  self.resultSet.delete(inst.docUri);
                }
              }
            }
          }
          return true;
        }
        catch(e){
          console.log('ERROR: ' + e.message);
          return false;
        }
      }
//End of nested function processMustNotContains.

/**
  * @function StaticSearch~processResults~processMustContains
  * @description Embedded function to retrieve all documents containing
  *              terms designated as required. This function works in
  *              two ways; if running after a phrasal search has been
  *              done, it simply acts as a filter on the document set
  *              already retrieved; if running as the initial retrieval
  *              mechanism (where there are no phrasal searches), it
  *              populates the result set itself. It's doubly complicated
  *              because it must also eliminate from the existing result
  *              set any document that doesn't contain a term.
  * @param {Array<integer>} indexes a list of indexes into the terms array.
  *              This needs to be a parameter because the function is calls
  *              itself recursively with a reduced array.
  * @param {Boolean} runAsFilter controls which mode the process runs in.
  * @return true if succeeds, false if not.
  */
      function processMustContains(indexes, runAsFilter){
        try{
          if (runAsFilter){
            if (self.resultSet.getSize() < 1){
              return true; //nothing to do.
            }
            for (let must_contain of indexes){
              let stem = self.terms[must_contain].stem;
              if (self.index[stem]){
//Look at each of the document instances for that term...
                for (let inst of self.index[stem].instances){
//We only include it if if matches a document already found for a phrase
//or the first must_contain.
                  if (self.resultSet.has(inst.docUri)){
                    self.resultSet.merge(inst.docUri, inst);
                  }
                }
              }
            }
  //Now weed out results which don't have matches in other terms.
            let docUrisToDelete = [];
            for (let docUri of self.resultSet.mapDocs.keys()){
              console.log(docUri);
              for (let mc of must_contains){
                if (! self.indexTokenHasDoc(self.terms[mc].stem, docUri)){
                  docUrisToDelete.push(docUri);
                }
              }
            }
            self.resultSet.deleteArray(docUrisToDelete);
          }
          else{
//Here we start by processing the first only.
            let stem = self.terms[0].stem;
            if (self.index[stem]){
            //Look at each of the document instances for that term...
              for (let inst of self.index[stem].instances){
                self.resultSet.set(inst.docUri, inst);
              }
            }
            processMustContains(must_contains.slice(1), true);
          }
          return true;
        }
        catch(e){
          console.log('ERROR: ' + e.message);
          return false;
        }
      }
//End of nested function processMustContains.

/**
  * @function StaticSearch~processResults~processMayContains
  * @description Embedded function to process may_contain search terms.
  *              This function runs in two modes: if it's being called
  *              after prior imperative search terms have been processed,
  *              then it adds no new documents to the set, just enhances
  *              their scores. But if there are no imperative search
  *              terms, then all documents found are added to the set.
  * @param {Boolean} addAllFound controls which mode the process runs in.
  * @return true if succeeds, false if not.
  */
      function processMayContains(addAllFound){
        for (let may_contain of may_contains){
          let stem = self.terms[may_contain].stem;
          if (self.index[stem]){
//Look at each of the document instances for that term...
            for (let inst of self.index[stem].instances){
//We only include it if if matches a document already found for a phrase.
              if ((self.resultSet.has(inst.docUri))||(addAllFound)){
//We can call set() here, since the result set will merge if necessary.
                self.resultSet.set(inst.docUri, inst);
              }
            }
          }
        }
      }

      if (phrases.length > 0){
//We have phrases. They take priority. Get results if there are any.
//For each phrase we're looking for...
        processPhrases();
//Continue, because we have results. Now we process any must_not_contains.
        processMustNotContains();

//We can continue. Now we check for any must_contains.
        processMustContains(must_contains, true);

//Finally the may_contains.
        processMayContains(false);
      }
      else{
        if (must_contains.length > 0){
//We have no phrases, but we do have musts, so these are the priority.
          processMustContains(must_contains, false);
//Now we trim down the dataset using any must_not_contains.
          processMustNotContains();
//Finally the may_contains.
          processMayContains(false);
        }
        else{
          if (may_contains.length > 0){
            //We have no phrases or musts, so we fall back to mays.
            processMayContains(true);
            processMustNotContains();
          }
          else{
            console.log('No useful search terms found.');
            return false;
          }
        }
      }

//Now we filter the results based on filter checkboxes, if any.
      let arrFilters = this.getActiveFiltersAsArray();
      console.log(arrFilters);

      if (arrFilters.length > 0){
        let docUrisToDelete = [];
        for (let docUri of self.resultSet.mapDocs.keys()){
          //console.log(docUri);
          if (! this.docMatchesFilters(docUri, arrFilters, this.matchAllFilters)){
            docUrisToDelete.push(docUri);
          }
        }
        console.log(docUrisToDelete);
        this.resultSet.deleteArray(docUrisToDelete);
      }

      this.resultSet.sortByScoreDesc();
      while (this.resultsDiv.firstChild) {
        this.resultsDiv.removeChild(this.resultsDiv.firstChild);
      }
      this.resultsDiv.appendChild(document.createElement('p')
                     .appendChild(document.createTextNode(
                       this.captionSet.strDocumentsFound + this.resultSet.getSize()
                     )));
      this.resultsDiv.appendChild(this.resultSet.resultsAsHtml(this.captionSet.strScore));
      if (this.resultSet.getSize() < 1){
        this.reportNoResults(true);
      }
      return (this.resultSet.getSize() > 0);
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }
}

/** @class SSResultSet
  * @description This is the class that handles the building of the
  * search result set, and then its display, paged or not. An
  * instance of this class is instantiated by the host StaticSearch
  * class. It manages search hits using a Map(), with document ids
  * forming the keys, and values being objects based on the JSON
  * objects returned from the search index queries.
  */
  class SSResultSet{
    constructor(kwicLimit){
      try{
        this.mapDocs = new Map([]);
//The maximum allowed number of keyword-in-context results to be
//included in output.
        this.kwicLimit = kwicLimit;
      }
      catch(e){
        console.log('ERROR: ' + e.message);
      }
    }

/**
  * @function SSResultSet~clear
  * @description Clears all content from the result map.
  * @return {Boolean} true if successful, false if not.
  */
  clear(){
    try{
      this.mapDocs.clear();
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/**
  * @function SSResultSet~has
  * @description Provides access to the Map.prototype.has() function
  * to check whether a document is already in the result set.
  * @param {String} docUri The URI of the document to check, which will
  * be the key to the entry in the map.
  * @return {Boolean} true if this document is in the map; false if not.
  */
    has(docUri){
      return this.mapDocs.has(docUri);
    }
/**
  * @function SSResultSet~set
  * @description Provides access to the Map.prototype.set() function
  * to add data to the result set. This first checks whether there
  * is already an entry for this docUri, and if there is, it merges the
  * data instead; otherwise, it sets the data.
  * @param {String} docUri The URI of the document to check, which will
  * be the key to the entry in the map.
  * @param {Object} data The structured data from the query index.
  * @return {Boolean} true if successful, false if not.
  */
    set(docUri, data){
      try{
        if (this.mapDocs.has(docUri)){
          this.merge(docUri, data);
        }
        else{
          this.mapDocs.set(docUri, data);
//Now we need to truncate the list of kwic contexts in case it's too long.
          this.mapDocs.get(docUri).contexts = this.mapDocs.get(docUri).contexts.slice(0, this.kwicLimit);
        }
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }
/**
  * @function SSResultSet~merge
  * @description Merges an incoming dataset for a document id with an
  * existing entry for that docUri. This involves two steps: first,
  * increment the score for the document, and second, add any keyword-
  * in-context strings from the new item up to the limit of kwics allowed.
  * @param {String} docUri The URI of the document to check, which will
  * be the key to the entry in the map.
  * @param {Object} data The structured data from the query index.
  * @return {Boolean} true if successful, false if not.
  */
    merge(docUri, data){
      try{
        if (!this.mapDocs.has(docUri)){
          this.mapDocs.set(docUri, data);
        }
        else{
          let currEntry = this.mapDocs.get(docUri);
          let i = 0;
          while ((currEntry.contexts.length < this.kwicLimit)&&(i < data.contexts.length)){
            if (currEntry.contexts.indexOf(data.contexts[i]) < 0){
              currEntry.contexts.push(data.contexts[i]);
              currEntry.score += data.score;
            }
            i++;
          }
        }
        return true;
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }

/**
  * @function SSResultSet~delete
  * @description Deletes an existing entry from the map.
  * @param {String} docUri The URI of the document to delete.
  * @return {Boolean} true if the item existed and was successfully
  * deleted, false if not, or if there is an error.
  */
    delete(docUri){
      try{
        console.log('Trying to delete ' + docUri);
        return this.mapDocs.delete(docUri);
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }

/**
  * @function SSResultSet~deleteArray
  * @description Deletes a collection of existing entries from the map.
  * @param {Array.<String>} arrDocUris The URIs of the document to delete.
  * @return {Boolean} true if any of the items existed and was successfully
  * deleted, false if not, or if there is an error.
  */
    deleteArray(arrDocUris){
      let result = false;
      try{
        for (let i=0; i<arrDocUris.length; i++){
          let deleted = this.mapDocs.delete(arrDocUris[i]);
          result = result || deleted;
        }
        return result;
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }

/**
  * @function SSResultSet~getSize
  * @description Returns the number of items in the result set.
  * @return {integer} number of documents in the result set.
  */
    getSize(){
      try{
        return this.mapDocs.size;
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return 0;
      }
    }

/**
  * @function SSResultSet~sortByScoreDesc
  * @description Sorts the collection of documents so that the highest
  *              scoring items come at the top.
  * @return {Boolean} true if successful, false on error.
  */
    sortByScoreDesc(){
      try{
        let s = this.mapDocs.size;
        this.mapDocs = new Map([...this.mapDocs.entries()].sort((a, b) => a[1].score < b[1].score));
        return (s === this.mapDocs.size);
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }

/**
  * @function SSResultSet~resultsAsHtml
  * @description Outputs a ul element containing an li element for each
  *              result in the search; context strings are also included.
  * @param {String} strScore caption for the score assigned to a hit document.
  * @return {Element(ul)} an unordered list ready for insertion into the
  *                       host document.
  */
    resultsAsHtml(strScore){
      let ul = document.createElement('ul');
      for (let [key, value] of this.mapDocs){
        let li = document.createElement('li');
        let a = document.createElement('a');
        a.setAttribute('href', value.docUri);
        let t = document.createTextNode(value.docTitle);
        a.appendChild(t);
        li.appendChild(a);
        t = document.createTextNode(' ' + strScore + value.score);
        li.append(t);
        if (value.contexts.length > 0){
          let ul2 = document.createElement('ul');
          ul2.setAttribute('class', 'kwic');
          for (let c of value.contexts){
            let li2 = document.createElement('li');
            li2.innerHTML = c.context;
            ul2.appendChild(li2);
          }
          li.appendChild(ul2);
        }
        ul.appendChild(li);
      }
      return ul;
    }
  }
