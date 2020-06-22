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
/**
  * @constant PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN, WILDCARD
  * @type {Number}
  * @description Constants representing different types of search command.
  */

  const PHRASE               = 0;
  const MUST_CONTAIN         = 1;
  const MUST_NOT_CONTAIN     = 2;
  const MAY_CONTAIN          = 3;
  const WILDCARD             = 4;

/**@constant arrTermTypes
   * @type {Array}
   * @description array of PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN
   *              used so we can easily iterate through them.
   */
  const arrTermTypes = [PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN, WILDCARD];

/**
  * @constant TO_GET, GETTING, GOT, FAILED
  * @type {Number}
  * @description Constants representing states of files that may be
  *              retrieved by AJAX.
  */

  const TO_GET  = 0;
  const GETTING = 1;
  const GOT     = 2;
  const FAILED  = 3;

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
  ss.captions['en'].strSearching         = 'Searching...';
  ss.captions['en'].strDocumentsFound    = 'Documents found: ';
  ss.captions['en'][PHRASE]              = 'Exact phrase: ';
  ss.captions['en'][MUST_CONTAIN]        = 'Must contain: ';
  ss.captions['en'][MUST_NOT_CONTAIN]    = 'Must not contain: ';
  ss.captions['en'][MAY_CONTAIN]         = 'May contain: ';
  ss.captions['en'][WILDCARD]            = 'Wildcard term: ';
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
  * button#ssDoSearch            (button for invoking search)
  * div#ssSearching              (div containing message to show search is under way)
  * div#ssResults                (div in which to output the results)
  * input[type='checkbox'].staticSearch.desc  (optional; checkbox lists for filtering based on text labels)
  * input[type='text'].staticSearch.date      (optional; textboxes for date filters)
  * input[type='number'].staticSearch.num      (optional; inputs for numerical filters)
  * input[type='checkbox'].staticSearch.bool  (optional: checkboxes for boolean filters)
  * input[type='text'].staticSearch.text  (NOT YET IMPLEMENTED: type-in search filter boxes)
  *
  * The first is mandatory, although the user is
  * not required to use it; they may choose simply
  * to retrieve filtered lists of documents.
  * The second is mandatory, although the user may also invoke
  * search by pressing return while the text box has focus.
  * The third is mandatory, because there must be somewhere to
  * show the results of a search.
  * The rest are optional, but if present,
  * they will be incorporated.
  */
class StaticSearch{
  constructor(){
    try {
      this.ssForm = document.querySelector('#ssForm');
      if (!this.ssForm){
        throw new Error('Failed to find search form. Search functionality will probably break.');
      }
      //Directory for JSON files. Inside this directory will be a
      //'lower' dir and an 'upper' dir, where the two sets of case-
      //distinguished JSON files are stored.
      this.jsonDirectory = this.ssForm.getAttribute('data-ssfolder') || 'staticSearch'; //Where to find all the stuff.
      this.jsonDirectory += '/';

      //Headers used for all AJAX fetch requests.
      this.fetchHeaders = {
              credentials: 'same-origin',
              cache: 'default',
              headers: {'Accept': 'application/json'},
              method: 'GET',
              redirect: 'follow',
              referrer: 'no-referrer'
        };
      let tmp;
      this.queryBox =
           document.querySelector("input#ssQuery[type='text']");
      if (!this.queryBox){
        throw new Error('Failed to find text input box with id "ssQuery". Cannot provide search functionality.');
      }
      else{
        this.queryBox.focus();
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
      //Clear button will be there if there are filter controls.
      this.clearButton = document.querySelector("button#ssClear");
      if (this.clearButton){
        this.clearButton.addEventListener('click', function(){this.clearSearchForm(); return false;}.bind(this));
      }

      //Essential "searching under way" message div.
      this.searchingDiv =
           document.querySelector("div#ssSearching");
      if (!this.searchingDiv){
       throw new Error('Failed to find div with id "ssSearching". Cannot provide search functionality.');
      }

      //Essential results div.
      this.resultsDiv =
           document.querySelector("div#ssResults");
      if (!this.resultsDiv){
       throw new Error('Failed to find div with id "ssResults". Cannot provide search functionality.');
      }

      //Optional search filters:
      //Description label filters
      this.descFilterCheckboxes =
           Array.from(document.querySelectorAll("input[type='checkbox'][class='staticSearch.desc']"));
      //Date filters
      this.dateFilterTextboxes =
           Array.from(document.querySelectorAll("input[type='text'][class='staticSearch.date']"));
      //Number filters
      this.numFilterInputs =
           Array.from(document.querySelectorAll("input[type='number'][class='staticSearch.num']"));
      //Boolean filters
      this.boolFilterSelects =
           Array.from(document.querySelectorAll("select[class='staticSearch.bool']"));

      //An object which will be filled with a complete list of all the
      //individual tokens indexed for the site. Data retrieved later by
      //AJAX.
      this.tokens = null;

      //A Map object that will be populated with filter data retrieved by AJAX.
      this.mapFilterData = new Map();

      //A Map object that will track the retrieval of search filter data and
      //other JSON files we need to get.
      this.mapJsonRetrieved = new Map();

      //A Map object which will be repopulated on every search initiation,
      //containing the set of active document filters to apply to the search.
      this.mapActiveFilters = new Map();

      //An XSet object which will contain a list of docUris which pass the
      //test of the currently-configured set of filters. This is recreated
      //for every search.
      this.docsMatchingFilters = new XSet();

      //Any / all selector for combining filters. TODO. MAY NOT BE USED.
      this.matchAllFilters = false;

      //Configuration for phrasal searches if found.
      //Default
      this.allowPhrasal = true;
      tmp = document.querySelector("form[data-allowPhrasal]");
      if (tmp && !/(y|Y|yes|true|True|1)/.test(tmp.getAttribute('data-allowphrasal'))){
        this.allowPhrasal = false;
      }

      //Configuration for use of wildcards. Defaults to false.
      this.allowWildcards = false;
      tmp = document.querySelector("form[data-allowWildcards]");
      if (tmp && /(y|Y|yes|true|True|1)/.test(tmp.getAttribute('data-allowwildcards'))){
        this.allowWildcards = true;
      }

      //Configuration of a specific version string to avoid JSON caching.
      this.versionString = this.ssForm.getAttribute('data-versionString');

      //Associative array for storing retrieved JSON search string data.
      //Any retrieved data stored in here is retained between searches
      //to avoid having to retrieve it twice.
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

      //The collection of JSON filter files that we need to retrieve.
      this.jsonToRetrieve = [];
      this.jsonToRetrieve.push({id: 'ssStopwords', path: this.jsonDirectory + 'ssStopwords' + this.versionString + '.json'});
      this.jsonToRetrieve.push({id: 'ssTitles', path: this.jsonDirectory + 'ssTitles' + this.versionString + '.json'});
      this.jsonToRetrieve.push({id: 'ssTokens', path: this.jsonDirectory + 'ssTokens' + this.versionString + '.json'});
      for (var f of document.querySelectorAll('fieldset.ssFieldset[id], fieldset.ssFieldset select[id]')){
        this.jsonToRetrieve.push({id: f.id, path: this.jsonDirectory + 'filters/' + f.id + this.versionString + '.json'});
      }
      //Flag to be set when all JSON is retrieved, to save laborious checking on
      //every search.
      this.allJsonRetrieved = false;

      //Default set of stopwords
      this.stopwords = ss.stopwords; //temporary default.

      //Boolean: should this instance report the details of its search
      //in human-readable form?
      this.showSearchReport = false;

      //How many results should be shown per page?
      //Default. NOT USED, AND PROBABLY POINTLESS.
      this.resultsPerPage = 10;
      tmp = document.querySelector("form[data-resultsperpage]");
      if (tmp){
        let parsed = parseInt(tmp.getAttribute('data-resultsperpage'));
        if (!isNaN(parsed)){this.resultsPerPage = parsed;}
      }

      //How many keyword in context strings should be included
      //in search results?
      //Default
      this.maxKwicsToShow = 10;
      tmp = document.querySelector("form[data-maxkwicstoshow]");
      if (tmp){
        let parsed = parseInt(tmp.getAttribute('data-maxkwicstoshow'));
        if (!isNaN(parsed)){this.maxKwicsToShow = parsed;}
      }

      //Result handling object
      this.resultSet = new SSResultSet(this.maxKwicsToShow);

      //This allows the user to navigate through searches using the back and
      //forward buttons; to avoid repeatedly pushing state when this happens,
      //we pass popping = true.
      window.onpopstate = function(){this.parseQueryString(true)}.bind(this);

      //We may need to turn off the browser history manipulation to do
      //automated tests, so make this switchable.
      this.storeSearchesInBrowserHistory = true;

      //Now we can start trickle-downloading the various JSON files.
      this.getJson(0);

      //We add a hook which external code can call to be notified when a
      //search has completed.
      this.searchFinishedHook = function(num){};

      //Now we're instantiated, check to see if there's a query
      //string that should initiate a search.
      this.parseQueryString();
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/** @function staticSearch~jsonRetrieved
  * @description this function is called whenever a JSON resource is retrieved
  *              by the trickle-download process initiated on startup. It
  *              stores the data in the right place, and sets a flag to say
  *              that the data has been retrieved (or was not available).
  *
  * @param json {json} the JSON retrieved by the AJAX request.
  * @param path {String} the path from which it was retrieved.
  */
  jsonRetrieved(json, path){
    if (path.match(/ssStopwords.*json$/)){
      this.stopwords = json.words;
      this.mapJsonRetrieved.set('ssStopwords', GOT);
      return;
    }
    if (path.match(/ssTokens.*json$/)){
      this.tokens = new Map(Object.entries(json));
      this.mapJsonRetrieved.set('ssTokens', GOT);
      return;
    }
    if (path.match(/ssTitles.*json$/)){
      this.resultSet.titles = new Map(Object.entries(json));
      this.mapJsonRetrieved.set('ssTitles', GOT);
      return;
    }
    if (path.match(/\/filters\//)){
      this.mapFilterData.set(json.filterName, json);
      this.mapJsonRetrieved.set(json.filterId, GOT);
      return;
    }
  }

/** @function staticSearch~getJson
  * @description this function trickle-downloads a series of JSON files
  *              which the object has determined it may need, getting
  *              them one at a time to avoid saturating the connection;
  *              while this is happening, a live search may be initiated
  *              which needs to get a lot of resources quickly.
  *
  * @param jsonIndex {Number} the index of the item in the array of items
  *               that need to be retrieved.
  */
  async getJson(jsonIndex){
    if (jsonIndex < this.jsonToRetrieve.length){
      try{
        if (this.mapJsonRetrieved.get(this.jsonToRetrieve[jsonIndex].id) != GOT){
          this.mapJsonRetrieved.set(this.jsonToRetrieve[jsonIndex].id, GETTING);
          let fch = await fetch(this.jsonToRetrieve[jsonIndex].path);
          let json = await fch.json();
          this.jsonRetrieved(json, this.jsonToRetrieve[jsonIndex].path);
        }
        else{
          return this.getJson(jsonIndex + 1);
        }
      }
      catch(e){
        console.log('ERROR: failed to retrieve JSON resource ' + this.jsonToRetrieve[jsonIndex].path + ': ' + e.message);
        this.mapJsonRetrieved.set(this.jsonToRetrieve[jsonIndex].id, FAILED);
      }
      return this.getJson(jsonIndex + 1);
    }
    else{
      this.allJsonRetrieved = true;
    }
  }

/** @function StaticSearch~parseQueryString
  * @description this function is run after the class is instantiated
  *              to check whether there is a search string in the
  *              browser URL. If so, it parses it out and runs the
  *              query.
  *
  * @param {Boolean} popping specifies whether this parse has been triggered
  *                  by window.onpopstate (meaning the user is moving through
  *                  the browser history)
  * @return {Boolean} true if a search is initiated otherwise false.
  */
  parseQueryString(popping = false){
    let searchParams = new URLSearchParams(decodeURI(document.location.search));
    //Do we need to do a search?
    let searchToDo = false; //default

    if (searchParams.has('q')){
      this.queryBox.value = searchParams.get('q');
      searchToDo = true;
    }
    for (let cbx of this.descFilterCheckboxes){
      let key = cbx.getAttribute('title');
      if ((searchParams.has(key)) && (searchParams.getAll(key).indexOf(cbx.value) > -1)){
          cbx.checked = true;
          searchToDo = true;
      }
      else{
        cbx.checked = false;
      }
    }
    for (let txt of this.dateFilterTextboxes){
      let key = txt.getAttribute('title') + txt.id.replace(/^.+((_from)|(_to))$/, '$1');
      if ((searchParams.has(key)) && (searchParams.get(key).length > 3)){
        txt.value = searchParams.get(key);
        searchToDo = true;
      }
      else{
        txt.value = '';
      }
    }
    for (let num of this.numFilterInputs){
      let key = num.getAttribute('title') + num.id.replace(/^.+((_from)|(_to))$/, '$1');
      if ((searchParams.has(key)) && (searchParams.get(key).length > 3)){
        num.value = searchParams.get(key);
        searchToDo = true;
      }
      else{
        num.value = '';
      }
    }
    for (let sel of this.boolFilterSelects){
      let key = sel.getAttribute('title');
      let val = (searchParams.has(key))? searchParams.get(key) : '';
      switch (val){
        case 'true':
          sel.selectedIndex = 1;
          searchToDo = true;
          break;
        case 'false':
          sel.selectedIndex = 2;
          searchToDo = true;
          break;
        default:
          sel.selectedIndex = 0;
      }
    }

    if (searchToDo === true){
      this.doSearch(popping);
      return true;
    }
    else{
      return false;
    }
  }

/** @function StaticSearch~doSearch
  * @description this function initiates the search process,
  *              taking it as far as creating the promises
  *              for retrieval of JSON files. After that, the
  *              resolution of the promises carries the process
  *              on.
  * @param {Boolean} popping specifies whether this parse has been triggered
  *                  by window.onpopstate (meaning the user is moving through
  *                  the browser history)
  * @return {Boolean} true if a search is initiated otherwise false.
  */
  doSearch(popping = false){
    setTimeout(function(){
                this.searchingDiv.style.display = 'block';
                document.body.style.cursor = 'progress';}.bind(this), 0);
    this.docsMatchingFilters.filtersActive = false; //initialize.
    let result = false; //default.
    if (this.parseSearchQuery()){
      if (this.writeSearchReport()){
        this.populateIndexes();
        if (!popping){
          this.setQueryString();
        }
        result = true;
      }
      else{
        this.searchingDiv.style.display = 'none';
        document.body.style.cursor = 'default';
      }
    }
    else{
      this.searchingDiv.style.display = 'none';
      document.body.style.cursor = 'default';
    }
    window.scroll({ top: this.resultsDiv.offsetTop, behavior: "smooth" });
    /*this.resultsDiv.scrollIntoView({behavior: "smooth", block: "nearest"});*/
    return result;
  }

/** @function StaticSearch~setQueryString
  * @description this function is run once a search is initiated,
  * and it takes the search parameters and creates a browser URL
  * search string, then pushes this into the History object so that
  * all searches are bookmarkable.
  *
  * @return {Boolean} true if successful, otherwise false.
  */
  setQueryString(){
    try{
      if (this.storeSearchesInBrowserHistory == true){
        let url = window.location.href.split(/[?#]/)[0];
        let search = [];
        let q = this.queryBox.value.replace(/\s+/, ' ').replace(/(^\s+)|(\s+$)/g, '');
        if (q.length > 0){
          search.push('q=' + q);
        }
        for (let cbx of this.descFilterCheckboxes){
          if (cbx.checked){
            search.push(cbx.title + '=' + cbx.value);
          }
        }
        for (let txt of this.dateFilterTextboxes){
          if (txt.value.match(/\d\d\d\d(-\d\d(-\d\d)?)?/)){
            let key = txt.getAttribute('title') + txt.id.replace(/^.+((_from)|(_to))$/, '$1');
            search.push(key + '=' + txt.value);
          }
        }
        for (let num of this.numFilterInputs){
          if (num.value.match(/[\d\-\.]+/)){
            let key = num.getAttribute('title') + num.id.replace(/^.+((_from)|(_to))$/, '$1');
            search.push(key + '=' + num.value);
          }
        }
        for (let sel of this.boolFilterSelects){
          if (sel.selectedIndex > 0){
            search.push(sel.getAttribute('title') + '=' + ((sel.selectedIndex == 1)? 'true' : 'false'));
          }
        }

        if (search.length > 0){
          url += '?' + encodeURI(search.join('&'));
          history.pushState({time: Date.now()}, '', url);
        }
      }
      /*else{
        console.log('Not storing search in browser history.');
      }*/
      return true;
    }
    catch(e){
      console.log('ERROR: failed to push search into browser history: ' + e.message);
    }
  }


/** @function StaticSearch~parseSearchQuery
  * @description this retrieves the content of the text
  * search box and parses it into an array of term items
  * ready for analysis against retrieved results. Even if
  * no search terms are found, it returns true so that filter-only
  * searches may proceed.
  *
  * @return {Boolean} true if no errors occur, otherwise false.
  */
  parseSearchQuery(){
    try{
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

      //Strip out all other punctuation that isn't between numbers. We do this
      //slightly differently depending on whether wildcard searching is enabled.
      if (this.allowWildcards){
        strSearch = strSearch.replace(/(^|[^\d])[\.',!;:@#$%\^&]+([^\d]|$)/g, '$1$2');
      }
      else{
        strSearch = strSearch.replace(/(^|[^\d])[\.',!;:@#$%\^&*?\[\]]+([^\d]|$)/g, '$1$2');
      }

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
            this.addSearchItem(strSoFar, false);
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
      //return (this.terms.length > 0);
//Even if we found no terms to search for, we should go
//ahead with the search, either listing all the documents
//or listing them based on the filters.
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }

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
      //Else is it a wildcard?
      if (this.allowWildcards && /[\[\]?*]/.test(strInput)){
        console.log('Wildcard found...');
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
    }
    return (this.terms.length > 0);
  }

/** @function StaticSearch~clearSearchForm
  * @description this function removes all previously-selected
  * filter control settings, and empties the search query box.
  *
  * @return {Boolean} true on success, false on failure.
  */
  clearSearchForm(){
    try{
      this.queryBox.value = '';
      for (let cbx of this.descFilterCheckboxes){
        cbx.checked = false;
      }
      for (let txt of this.dateFilterTextboxes){
        txt.value = '';
      }
      for (let num of this.numFilterInputs){
        num.value = '';
      }
      for (let sel of this.boolFilterSelects){
        sel.selectedIndex = 0;
      }
    }
    catch(e){
      console.log('Error attempting to clear search form: ' + e);
      return false;
    }
  }

/** @function StaticSearch~processFilters
  * @description this function calls StaticSearch~getDocIdsForFilters(),
  * and if the function succeeds, it sets the docsMatchingFilters to
  * the returned XSet and returns true, otherwise it clears the current
  * set of filters (THINK: IS THIS CORRECT BEHAVIOUR?) and returns false.
  *
  * @return {Boolean} true on success, false on failure.
  */
  processFilters(){
    try{
      this.docsMatchingFilters = this.getDocIdsForFilters();
      return true;
    }
    catch(e){
      console.log('Error attempting to generate the set of docs matching filters: ' + e);
      return false;
    }
  }

  /** @function StaticSearch~getDocIdsForFilters
    * @description this function gets the set of currently-configured
    * filters by analyzing the form elements, then returns a
    * set (in the form of an XSet object) of all the document ids
    * that qualify according to the filters.
    *
    * @return {XSet} an XSet object (which might be empty) with an added
    * boolean property filtersActive which specifies whether filters have
    * been configured by the user.
    */
    getDocIdsForFilters(){

      var xSets = [];
      var currXSet;

      //Find each desc fieldset and get its descriptor.
      let descs = document.querySelectorAll('fieldset[id ^= "ssDesc"]');
      for (let desc of descs){
        currXSet = new XSet();
        let descName = desc.getAttribute('title');
        let cbxs = desc.querySelectorAll('input[type="checkbox"]:checked');
        if ((cbxs.length > 0) && (this.mapFilterData.has(descName))){
          for (let cbx of cbxs){
            currXSet.addArray(this.mapFilterData.get(descName)[cbx.id].docs);
          }
          xSets.push(currXSet);
        }
      }

      //Find each bool selector and get its descriptor.
      let bools = document.querySelectorAll('select[id ^= "ssBool"]');
      for (let bool of bools){
        let sel = bool.selectedIndex;
        let valueId = bool.id + '_' + bool.selectedIndex;
        let boolName = bool.getAttribute('title');
        if ((sel > 0) && (this.mapFilterData.has(boolName))){
          currXSet = new XSet();
          currXSet.addArray(this.mapFilterData.get(boolName)[valueId].docs);
          xSets.push(currXSet);
        }
      }

      //Find each date pair and get its descriptor.
      let dates = document.querySelectorAll('fieldset[id ^= "ssDate"]');
      for (let date of dates){
        let dateName = date.title;
        if (this.mapFilterData.has(dateName)){
          let docs = this.mapFilterData.get(dateName).docs;
          //If it's a from date, partial dates are OK because the date constructor
          //defaults to -01-01.
          let fromDate = null;
          let toDate = null;
          let fromVal = date.querySelector('input[type="text"][id $= "_from"]').value;
          if (fromVal.length > 0){
            currXSet = new XSet();
            fromDate = new Date(fromVal);
            for (const docUri in docs){
              if ((docs[docUri].length > 0) && (new Date(docs[docUri][docs[docUri].length-1]) >= fromDate)){
                currXSet.add(docUri);
              }
            }
            xSets.push(currXSet);
          }
          //If it's a to date, we have to append stuff.
          let toVal = date.querySelector('input[type="text"][id $= "_to"]').value;
          if (toVal.length > 0){
            currXSet = new XSet();
            switch (toVal.length){
              case 10: toDate = new Date(toVal); break;
              case 4:  toDate = new Date(toVal + '-12-31'); break;
              case 7:  toDate = new Date(toVal.replace(/(\d\d\d\d-)((0[13578])|(1[02]))$/, '$1$2-31').replace(/(\d\d\d\d-)((0[469])|(11))$/, '$1$2-30').replace(/02$/, '02-28')); break;
              default: toDate = new Date('3000'); //random future date.
            }
            for (const docUri in docs){
              if ((docs[docUri].length > 0) && (new Date(docs[docUri][0]) <= toDate)){
                currXSet.add(docUri);
              }
            }
            xSets.push(currXSet);
          }
        }
      }

      //Find each date pair and get its descriptor.
      let nums = document.querySelectorAll('fieldset[id ^= "ssNum"]');
      for (let num of nums){
        let numName = num.title;
        if (this.mapFilterData.has(numName)){
          let docs = this.mapFilterData.get(numName).docs;
          let fromNum = null;
          let toNum = null;
          let fromVal = num.querySelector('input[type="number"][id $= "_from"]').value;
          if (fromVal.length > 0){
            currXSet = new XSet();
            fromNum = parseFloat(fromVal);
            for (const docUri in docs){
              if ((docs[docUri].length > 0) && (parseFloat(docs[docUri][docs[docUri].length-1]) >= fromNum)){
                currXSet.add(docUri);
              }
            }
            xSets.push(currXSet);
          }
          let toVal = num.querySelector('input[type="number"][id $= "_to"]').value;
          if (toVal.length > 0){
            currXSet = new XSet();
            toNum = parseFloat(toVal);
            for (const docUri in docs){
              if ((docs[docUri].length > 0) && (parseFloat(docs[docUri][0]) <= toNum)){
                currXSet.add(docUri);
              }
            }
            xSets.push(currXSet);
          }
        }
      }

      if (xSets.length > 0){
        let result = xSets[0];
        for (var i=1; i<xSets.length; i++){
          result = result.xIntersection(xSets[i]);
        }
        result.filtersActive = true;
        return result;
      }
      else{
      //This represents a situation in which we appear to have filters active,
      //but they don't match any of the known types, so behave as though no
      //filters were specified.
        let result = new XSet();
        result.filtersActive = false;
        return result;
      }
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
  * @function StaticSearch~populateIndexes
  * @description The task of this function is basically
  * to ensure that the various indexes (search terms and facet filters)
  * are ready to handle a search, in that attempts have been made to
  * retrieve all JSON files relating to the current search.
  * The index is deemed ready when either a) all the JSON files
  * for required tokens and filters have been retrieved and their
  * contents merged into the required structures, or b) a retrieval
  * has failed, so an empty placeholder has been inserted to signify
  * that there is no such dataset.
  *
  * The function works with fetch and promises, and its final
  * .then() calls the processResults function.
  */
  populateIndexes(){
    var i, imax, tokensToFind = [], promises = [], emptyIndex,
    jsonSubfolder, filterSelector, filterIds;
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

      filterIds = new Set();
      //Do we need to get document metadata for filters?
      if (this.allJsonRetrieved === false){
        //First get a list of active filters.

        for (let ctrl of document.querySelectorAll('input[type="checkbox"][class="staticSearch.desc"]:checked')){
          let filterId = ctrl.id.split('_')[0];
          if (this.mapJsonRetrieved.get(filterId) != GOT){
            filterIds.add(filterId);
          }
        }
        for (let ctrl of document.querySelectorAll('select[class="staticSearch.bool"]')){
          if (ctrl.selectedIndex > 0){
            let filterId = ctrl.id.split('_')[0];
            if (this.mapJsonRetrieved.get(filterId) != GOT){
              filterIds.add(filterId);
            }
          }
        }
        for (let ctrl of document.querySelectorAll('input[type="text"][class="staticSearch.date"]')){
          if (ctrl.value.length > 3){
            let filterId = ctrl.id.split('_')[0];
            if (this.mapJsonRetrieved.get(filterId) != GOT){
              filterIds.add(filterId);
            }
          }
        }
        for (let ctrl of document.querySelectorAll('input[type="number"][class="staticSearch.num"]')){
          if (ctrl.value.length > 3){
            let filterId = ctrl.id.split('_')[0];
            if (this.mapJsonRetrieved.get(filterId) != GOT){
              filterIds.add(filterId);
            }
          }
        }
        //Create promises for all of the required filters.
        for (let filterId of filterIds){
          promises[promises.length] = fetch(self.jsonDirectory + 'filters/' + filterId + this.versionString + '.json', this.fetchHeaders)
            .then(function(response) {
              return response.json();
            })
            .then(function(json) {
              self.mapFilterData.set(json.filterName, json);
              self.mapJsonRetrieved.set(json.filterId, GOT);
            }.bind(self))
            .catch(function(e){
              console.log('Error attempting to retrieve filter data: ' + e);
            }.bind(self));
        }
        //What else do we need to retrieve?

        //Get the stopwords if needed.
        if (this.mapJsonRetrieved.get('ssStopwords') != GOT){
          promises[promises.length] = fetch(self.jsonDirectory + 'ssStopwords' + this.versionString + '.json', this.fetchHeaders)
            .then(function(response) {
              return response.json();
            })
            .then(function(json) {
              self.stopwords = json.words;
              self.mapJsonRetrieved.set('ssStopWords', GOT);
            }.bind(self))
            .catch(function(e){
              console.log('Error attempting to retrieve stopword list: ' + e);
            }.bind(self));
        }

        if (this.mapJsonRetrieved.get('ssTitles') != GOT){
          promises[promises.length] = fetch(self.jsonDirectory + 'ssTitles' + this.versionString + '.json', this.fetchHeaders)
            .then(function(response) {
              return response.json();
            })
            .then(function(json) {
              self.resultSet.titles = new Map(Object.entries(json));
              self.mapJsonRetrieved.set('ssTitles', GOT);
            }.bind(self))
            .catch(function(e){
              console.log('Error attempting to retrieve title list: ' + e);
            }.bind(self));
        }
//For glob searching, we'll need to care about the list of tokens too.
        if (this.allowWildcards == true){
          if (this.mapJsonRetrieved.get('ssTokens') != GOT){
            promises[promises.length] = fetch(self.jsonDirectory + 'ssTokens' + this.versionString + '.json', this.fetchHeaders)
              .then(function(response) {
                return response.json();
              })
              .then(function(json) {
                self.tokens = new Map(Object.entries(json));
                self.mapJsonRetrieved.set('ssTokens', GOT);
              }.bind(self))
              .catch(function(e){
                console.log('Error attempting to retrieve token list: ' + e);
              }.bind(self));
          }
        }
      }

      //If we do need to retrieve JSON index data, then do it
      if (tokensToFind.length > 0){

//Set off fetch operations for the things we don't have yet.
        for (i=0, imax=tokensToFind.length; i<imax; i++){

//We will first add an empty index so that if nothing is found, we won't need
//to search again.
          emptyIndex = {'token': tokensToFind[i], 'instances': []}; //used as return value when nothing retrieved.

          this.tokenFound(emptyIndex);

//Figure out whether we're retrieving a lower-case or an upper-case token.
//TODO: Do we need to worry about camel-case?
          jsonSubfolder = (tokensToFind[i].toLowerCase() == tokensToFind[i])? 'lower/' : 'upper/';

//We create an array of fetches to get the json file for each token,
//assuming it's there.
          promises[promises.length] = fetch(self.jsonDirectory + jsonSubfolder + tokensToFind[i] + this.versionString + '.json', this.fetchHeaders)
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
      }

      //Now set up a Promise.all to fire the rest of the work when all fetches have
      //completed or failed.
      if (promises.length > 0){
        Promise.all(promises).then(function(values) {
          this.processResults();
        }.bind(self));
      }
      //Otherwise we can just do the search with the index data we already have.
      else{
        setTimeout(function(){this.processResults();}.bind(self), 0);
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
  * @function StaticSearch~clearResultsDiv
  * @description This clears out and sets up the results div, ready for
  * reporting of results.
  * @return {Boolean} true if successful, false if not.
  */
  clearResultsDiv(){
    while (this.resultsDiv.firstChild) {
      this.resultsDiv.removeChild(this.resultsDiv.firstChild);
    }
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

//Start by clearing any previous results.
      this.resultSet.clear();

//Process any filters that may be active.
      this.processFilters();

//Now we have to fork, depending on whether we have search terms and filters
//or not. There are several scenarios:
/*
  1. There are active filters and also search terms.
  2. There are search terms but no active filters.
  3. There are active filters but no search terms.
  4. There are no active filters and no search terms.

  For #1, process the term searches into the result set, and then
     filter it using the active filter matching doc list.
  For #2, process the results into the result set, but don't filter it.
  For #3, construct the result set directly from the filter doc list,
     passing only ids and titles, for a simple listing display.
  For #4, do nothing at all (or possibly display an error message).
  */

//Easy ones first: #4
      if ((this.terms.length < 1)&&(this.docsMatchingFilters.size < 1)){
        this.clearResultsDiv();
        this.resultsDiv.appendChild(document.createElement('p')
                       .appendChild(document.createTextNode(
                         this.captionSet.strDocumentsFound + '0'
                       )));
        this.searchFinishedHook(1);
        this.searchingDiv.style.display = 'none';
        document.body.style.cursor = 'default';
        return false;
      }
//#3
      if ((this.terms.length < 1)&&(this.docsMatchingFilters.size > 0)){
        this.resultSet.addArray([...this.docsMatchingFilters]);
        this.clearResultsDiv();
        this.resultsDiv.appendChild(document.createElement('p')
                       .appendChild(document.createTextNode(
                         this.captionSet.strDocumentsFound + this.resultSet.getSize()
                       )));
        this.resultsDiv.appendChild(this.resultSet.resultsAsHtml(this.captionSet.strScore));
        if (this.resultSet.getSize() < 1){
          this.reportNoResults(true);
        }
        this.searchFinishedHook(2);
        this.searchingDiv.style.display = 'none';
        document.body.style.cursor = 'default';
        return (this.resultSet.getSize() > 0);
      }

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
//End of nested function processPhrases.

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
//End of nested function processMayContains.

//Main function code resumes here.
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
            this.searchFinishedHook(3);
            this.searchingDiv.style.display = 'none';
            document.body.style.cursor = 'default';
            return false;
          }
        }
      }

//Now we filter the results based on filter checkboxes, if any.
//This is #1
      if (this.docsMatchingFilters.filtersActive == true){
        this.resultSet.filterBySet(this.docsMatchingFilters);
      }

      this.resultSet.sortByScoreDesc();
      this.clearResultsDiv();
      this.resultsDiv.appendChild(document.createElement('p')
                     .appendChild(document.createTextNode(
                       this.captionSet.strDocumentsFound + this.resultSet.getSize()
                     )));
      this.resultsDiv.appendChild(this.resultSet.resultsAsHtml(this.captionSet.strScore));
      if (this.resultSet.getSize() < 1){
        this.reportNoResults(true);
      }
      this.searchFinishedHook(4);
      this.searchingDiv.style.display = 'none';
      document.body.style.cursor = 'default';
      return (this.resultSet.getSize() > 0);
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      this.searchFinishedHook(5);
      this.searchingDiv.style.display = 'none';
      document.body.style.cursor = 'default';
      return false;
    }
  }

/** @function StaticSearch~wildcardToRegex
  * @description This method is provided with a single token as 
  * input. The token should contain wildcard characters (asterisk,
  * question mark and square brackets). The function converts this
  * to a JS regular expression. For example: th*n[gk]? would 
  * become /^th.*[gk].?$/.
  * @param {String}   strToken a string of text with no spaces.
  * @return {RegExp | null} a regular expression; or null if one 
  *                         cannot be constructed.
  */

  wildcardToRegex(strToken){
    //First check that we have a proper token.
    if (strToken.match(/[\s"]]/)){
      return null;
    }
    //Generate the regex.
    let esc = strToken.replace(/[.+^${}()|\\]/g, '\\$&');
    let strRe  = esc.replace(/[\*\?]/g, '\.$&');
    //Test the regex, and return it if OK, otherwise return null.
    try{
      let re = new RegExp('^' + strRe + '$');
      return re;
    }
    catch(e){
      console.log('Invalid regex created: ' + strRe);
      return null;
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
  constructor(maxKwicsToShow){
    try{
      this.mapDocs = new Map([]);
      //The maximum allowed number of keyword-in-context results to be
      //included in output.
      this.maxKwicsToShow = maxKwicsToShow;
      //A list of titles indexed by docUri is retrieved by AJAX
      //and set later.
      this.titles = null;
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
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

/** @function SSResultSet~addArray
  * @description Adds an array of document uris to the result set. Used when
  * only facet filters are provided, so there are no hits or document scores
  * involved.
  * @param {Array<string>} docUris The array of document URIs to add.
  * @return {Boolean} true if successful; false if not.
  */
  addArray(docUris){
    try{
      for (let docUri of docUris){
        this.mapDocs.set(docUri, {docUri: docUri, score: 0, contexts: []});
      }
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
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
          this.mapDocs.get(docUri).contexts = this.mapDocs.get(docUri).contexts.slice(0, this.maxKwicsToShow);
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
  * in-context strings from the new item.
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
          while (i < data.contexts.length){
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
  * @function SSResultSet~filterBySet
  * @description Deletes any entry in the list which doesn't match an item
  * in the paramter set.
  * @param {Set.<String>} acceptableDocUris The URIs of docs to retain.
  * @return {Boolean} true if any items remain, false if not.
  */
    filterBySet(acceptableDocUris){
      try{
        for (let [key, value] of this.mapDocs){
          if (! acceptableDocUris.has(key)){
            this.mapDocs.delete(key);
          }
        }
        return (this.mapDocs.size > 0);
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
  * @function SSResultSet~getContextCount
  * @description Returns the number of kwic contexts in the result set.
  * @return {integer} number of kwic contexts in the result set.
  */
    getContextCount(){
      try{
        let arr = [];
        for (let [key, value] of this.mapDocs){
          arr.push(value.contexts.length);
        }
        return arr.reduce(function(a, b){return a + b;}, 0);
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
        this.mapDocs = new Map([...this.mapDocs.entries()].sort((a, b) => b[1].score - a[1].score));
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
  *              result in the search; context strings are also included,
  *              and where a document has a defined docImage, that is also
  *              included.
  * @param {String} strScore caption for the score assigned to a hit document.
  * @return {Element(ul)} an unordered list ready for insertion into the
  *                       host document.
  */
    resultsAsHtml(strScore){
      let ul = document.createElement('ul');
      for (let [key, value] of this.mapDocs){
        let li = document.createElement('li');
        let d = document.createElement('div');
        let docTitle = this.getTitleByDocId(value.docUri);
        let imgPath = this.getThumbnailByDocId(value.docUri);
        //If there is a docImage, include it.
        if (imgPath.length > 0){
          let imgA = document.createElement('a');
          imgA.setAttribute('href', value.docUri);
          let img = document.createElement('img');
          img.setAttribute('alt', docTitle);
          img.setAttribute('title', docTitle);
          img.setAttribute('src', imgPath);
          imgA.appendChild(img);
          li.appendChild(imgA);
        }
        let a = document.createElement('a');
        a.setAttribute('href', value.docUri);
        let t = document.createTextNode(docTitle);
        a.appendChild(t);
        d.appendChild(a);

        if (value.score > 0){
          t = document.createTextNode(' ' + strScore + value.score);
          d.append(t);
        }
        if (value.contexts.length > 0){
          //Sort these in document order.
          value.contexts.sort(function(a, b){return a.pos - b.pos;});
          let ul2 = document.createElement('ul');
          ul2.setAttribute('class', 'kwic');
          for (let i=0; i<Math.min(value.contexts.length, this.maxKwicsToShow); i++){
            let li2 = document.createElement('li');
            li2.innerHTML = value.contexts[i].context;
            ul2.appendChild(li2);
          }
          d.appendChild(ul2);
        }
        li.appendChild(d);
        ul.appendChild(li);
      }
      return ul;
    }

/** @function SSResultSet~getTitleByDocId
  * @description this function returns the title of a document based on
  *              its id.
  * @param {String} docId the id of the document.
  * @return {String} the title, or a placeholder if not found.
  */
    getTitleByDocId(docId){
      try{
        return this.titles.get(docId)[0];
      }
      catch(e){
        return '[No title]';
      }
    }

/** @function SSResultSet~getThumbnailByDocId
  * @description this function returns a thumbnail image for a document
  *              based on its id. If no thumbnail is defined in the ssTitles
  *              JSON, it returns an empty string.
  * @param {String} docId the id of the document.
  * @return {String} the relative path to an image, or an empty string.
  */
    getThumbnailByDocId(docId){
      try{
        if (this.titles.get(docId).length > 1){
          return this.titles.get(docId)[1];
        }
        else{
          return '';
        }
      }
      catch(e){
        return '';
      }
    }

/**
  * @function SSResultSet~resultsAsObject
  * @description Outputs an object containing result set counts, to be
  *              used in automated testing.
  * @return {Object} an object structure containing counts of docs found,
  *                  total contexts, and total score. Totting them up in
  *                  this way doesn't mean anything in particular, but it
  *                  provides a quick way to check whether things have
  *                  changed and a test is not returning what it used to.
  */
    resultsAsObject(){
      let scoreTotal = 0;
      let contextsTotal = 0;
      for (let [key, value] of this.mapDocs){
        scoreTotal += value.score;
        contextsTotal += value.contexts.length;
      }
      return {
        docsFound: this.mapDocs.size,
        contextsFound: contextsTotal,
        scoreTotal: scoreTotal
      }
    }
  }

/** @class XSet
  * @extends Set
  * @description This class inherits from the Set class but
  * adds some key operators which are missing from that class
  * in the current version of ECMAScript. Those methods are
  * named with a leading x in case a future version of ECMAScript
  * adds native versions.
  */
  class XSet extends Set{
    constructor(iterable){
      super(iterable);
      this.filtersActive = false; //Used when a set is empty, to distinguish
                               //between filters-active-but-no-matches-found
                               //and no-filters-selected.
    }
/** @function XSet~xUnion
  * @param {XSet} xSet2 another instance of the XSet class.
  * @description this computes the union of the two sets (all
  * items appearing in either set) and returns the result as
  * another XSet instance.
  * @return {XSet} a new instance of XSet including all items
  * from both sets.
  */
    xUnion(xSet2){
      return new XSet([...this, ...xSet2]);
    }
/** @function XSet~xIntersection
  * @param {XSet} xSet2 another instance of the XSet class.
  * @description this computes the intersection of the two sets
  * (items appearing in both sets) and returns the result as
  * another XSet instance.
  * @return {XSet} a new instance of XSet only the items
  * appearing in both sets.
  */
    xIntersection(xSet2){
      return new XSet([...this].filter(x => xSet2.has(x)));
    }
  /** @function XSet~xDifference
    * @param {XSet} xSet2 another instance of the XSet class.
    * @description this computes the set of items which appear
    * in this set but not in the parameter set.
    * @return {XSet} a new instance of XSet only the items
    * which appear in this set but not in xSet2.
    */
    xDifference(xSet2){
      return new XSet([...this].filter(x => !xSet2.has(x)));
    }
/** @function XSet~addArray
  * @param {Array} arr an array of values that are to be added.
  * @description this is a convenience function for adding a set of
  * values in a single operation.
  */
    addArray(arr){
      for (let item of arr){
        this.add(item);
      }
    }
  }
