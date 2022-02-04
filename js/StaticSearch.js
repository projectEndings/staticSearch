
/*             StaticSearch.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/** This file is part of the projectEndings staticSearch
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  * The code is licensed under both MPL and BSD.
  */

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
  * input[type='checkbox'].staticSearch_desc  (optional; checkbox lists for filtering based on text labels)
  * input[type='text'].staticSearch_date      (optional; textboxes for date filters)
  * input[type='number'].staticSearch_num      (optional; inputs for numerical filters)
  * input[type='checkbox'].staticSearch_bool  (optional: checkboxes for boolean filters)
  * input[type='text'].staticSearch_text  (NOT YET IMPLEMENTED: type-in search filter boxes)
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
/** 
  * constructor
  * @description The constructor has no paramaters since it
  *              reads everything it requires from the host
  *              HTML page. 
  */
  constructor(){
    try {
    
      //Captions are done first, since we need one for the splash screen.
      this.captions = ss.captions; //Default; override this if you wish by setting the property after instantiation.
      this.captionLang  = document.getElementsByTagName('html')[0].getAttribute('lang') || 'en'; //Document language.
      if (this.captions.has(this.captionLang)){
        this.captionSet   = this.captions.get(this.captionLang); //Pointer to the caption object we're going to use.
      }
      else{
        this.captionSet   = this.captions.get('en');
      }
      
      this.splashMessage = document.getElementById('ssSplashMessage');
      if (this.splashMessage !== null){
        //Set the caption in the splash screen.
        this.splashMessage.innerText = this.captionSet.strLoading;
        
        //Now we "show" the splash screen.
        document.body.classList.add('ssLoading');
      }

      
      this.ssForm = document.querySelector('#ssForm');
      if (!this.ssForm){
        throw new Error('Failed to find search form. Search functionality will probably break.');
      }
      //Directory where all of the JSONs are stored
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

      //Essential query text box.
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

      //Optional second search button
      this.searchButton2 =
           document.querySelector("button#ssDoSearch2");
      if (this.searchButton2){
        this.searchButton2.addEventListener('click', function(){this.doSearch(); return false;}.bind(this));
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

      // Search in fieldset name for the URL
      this.searchInFieldset = document.querySelector('.ssSearchInFilters > fieldset');
      if (this.searchInFieldset){
        this.searchInFieldsetName = this.searchInFieldset.title;
      }

      //Optional search filters:
      //Search in filters
      this.searchInFilterCheckboxes =
           Array.from(document.querySelectorAll("input[type='checkbox'].staticSearch_searchIn"));

      //Description label filters
      this.descFilterCheckboxes =
           Array.from(document.querySelectorAll("input[type='checkbox'].staticSearch_desc"));
      //Date filters
      this.dateFilterTextboxes =
           Array.from(document.querySelectorAll("input[type='text'].staticSearch_date"));
      //Number filters
      this.numFilterInputs =
           Array.from(document.querySelectorAll("input[type='number'].staticSearch_num"));
      //Boolean filters
      this.boolFilterSelects =
           Array.from(document.querySelectorAll("select.staticSearch_bool"));


      //Feature filters will eventually have checkboxes, but they don't yet.
      this.featFilterCheckboxes = [];
      //However they do have inputs.
      this.featFilterInputs = 
            Array.from(document.querySelectorAll("input[type='text'].staticSearch_feat"));
      //And we set them all to disabled initially
      for (let ffi of this.featFilterInputs){
        ffi.disabled = true;
      }
      //We need an array in which to store any possible feature filters that 
      //need to be created based on settings in the URL query string.
      this.mapFeatFilters = new Map();

      //Now we have some properties that will may be used later if required.
      this.paginationBtnDiv = null;
      this.showMoreBtn      = null;
      this.showAllBtn       = null;
      /** @type {!Array<string>} */
      this.normalizedQuery  = [];
      
      //An object which will be filled with a complete list of all the
      //individual stems indexed for the site. Data retrieved later by
      //AJAX.
      this.stems = null;

      //A string which will contain a chain of all the distinct word-forms 
      //on the site, used to support wildcard searches.
      this.wordString = '';

      //A Map object that will be populated with filter data retrieved by AJAX.
      this.mapFilterData = new Map();

      //A Map object that will track the retrieval of search filter data and
      //other JSON files we need to get. Note: one of the files is txt, not JSON.
      this.mapJsonRetrieved = new Map();

      //A Map object which will be repopulated on every search initiation,
      //containing the set of active document filters to apply to the search.
      this.mapActiveFilters = new Map();

      //An XSet object which will contain a list of docUris which pass the
      //test of the currently-configured set of filters. This is recreated
      //for every search.
      this.docsMatchingFilters = new XSet();

      //An XSet object that will contain a list of active contexts
      this.activeContexts = new XSet();

      //Any / all selector for combining filters. TODO. MAY NOT BE USED.
      this.matchAllFilters = false;

      //Nested convenience function for getting int values from form attributes.
      this.getConfigInt = function getConfigInt(ident, defaultVal){
        let i = parseInt(this.ssForm.getAttribute('data-' + ident.toLowerCase()), 10);
        return (isNaN(i))? defaultVal : i;
      }

      //Nested convenience function for getting string values from form attributes.
      this.getConfigStr = function getConfigStr(ident, defaultVal){
        let str = this.ssForm.getAttribute('data-' + ident.toLowerCase());
        return (str != null)? str : defaultVal;
      }

      //Nested convenience function for getting bool values from form attributes.
      //This allows latitude in how bools are specified.
      this.getConfigBool = function getConfigBool(ident, defaultVal){
        let b = this.ssForm.getAttribute('data-' + ident.toLowerCase());
        return (/^\s*(y|Y|yes|true|True|1)\s*$/.test(b))? true : (/^\s*(n|N|no|false|False|0)\s*$/.test(b))? false: defaultVal;
      }

      //Configuration for phrasal searches if found. Default true.
      this.allowPhrasal = this.getConfigBool('allowphrasal', true);

      //Configuration for use of wildcards. Default false.
      this.allowWildcards = this.getConfigBool('allowwildcards', false);

      //Configuration for use of experimental scroll-to-text-fragment feature. 
      //Default false, and also depends on browser support.
      this.scrollToTextFragment = ((this.getConfigBool('scrolltotextfragment', false)) && ('fragmentDirective' in document));

      //String for leading and trailing truncations of KWICs.
      this.kwicTruncateString = this.getConfigStr('kwictruncatestring', '...');

      //Regex for removing truncate strings
      let escTrunc = this.kwicTruncateString.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      this.reKwicTruncateStr = new RegExp('(^' + escTrunc + ')|(' + escTrunc + '$)', 'g');

      //Limit to the weight of JSON that will be downloaded for a 
      //single wildcard term. NOT CURRENTLY USED. Default 1MB.
      this.downloadLimit = this.getConfigInt('downloadLimit', 1000000);

      //Limit the number of results that can be rendered for any given search
      this.resultsLimit = this.getConfigInt('resultslimit', 2000);

      //Configuration for minimum length of a term to be searched.
      this.minWordLength = this.getConfigInt('minwordlength', 3);

      //A flag for easier debugging.
      this.debug = false;

      //Configuration of a specific version string to avoid JSON caching.
      this.versionString = this.ssForm.getAttribute('data-versionString');

      //Associative array for storing retrieved JSON search string data.
      //Any retrieved data stored in here is retained between searches
      //to avoid having to retrieve it twice.
      this.index = {};

      //Porter2 stemmer object.
      this.stemmer = new SSStemmer();

      //Array of terms parsed out of search string. This is emptied
      //at the beginning of every new search.
      this.terms = new Array();

      //An arbitrary limit on the number of stems we will search for in 
      //any given search. TODO: May need to provide an error message 
      //for this. Default 50.
      this.termLimit = this.getConfigInt('termLimit', 50);

      //An array to collect terms which are to be ignored in the search
      //because they are too short or are in the stopword list.
      this.discardedTerms = [];

      //A pattern to check the search string to ensure that it's not going
      //to retrieve a million words. 
      this.termPattern = new RegExp('^([\\*\\?\\[\\]]*[^\\*\\?\\[\\]]){' + this.minWordLength + ',}[\\*\\?\\[\\]]*$');

      //Characters to be discarded in all but phrasal
      this.charsToDiscardPattern = /[\.,!;:@#$%”“\^&]/g;
      if (!this.allowWildcards){
          this.charsToDiscardPattern = /[\.,!;:@#$%\^&*?\[\]]/g;
         
      };

      //Default set of stopwords
      /** @type {!Array} this.stopwords */
      this.stopwords = ss.stopwords; //temporary default.

      //The collection of JSON filter files that we need to retrieve.
      this.jsonToRetrieve = [];
      this.jsonToRetrieve.push({id: 'ssStopwords', path: this.jsonDirectory + 'ssStopwords' + this.versionString + '.json'});
      this.jsonToRetrieve.push({id: 'ssTitles', path: this.jsonDirectory + 'ssTitles' + this.versionString + '.json'});
      this.jsonToRetrieve.push({id: 'ssWordString', path: this.jsonDirectory + 'ssWordString' + this.versionString + '.txt'});
      for (var f of document.querySelectorAll('fieldset.ssFieldset[id], fieldset.ssFieldset select[id]')){
        this.jsonToRetrieve.push({id: f.id, path: this.jsonDirectory + 'filters/' + f.id + this.versionString + '.json'});
      }
      //Flag to be set when all JSON is retrieved, to save laborious checking on
      //every search.
      this.allJsonRetrieved = false;

      // Flag for telling whether we are currently doing a search;
      // which starts off false, but may be set to true later on
      this.isSearching = false;


      //Boolean: should this instance report the details of its search
      //in human-readable form?
      this.showSearchReport = false;

      //How many results should be shown per page? Default to 0,
      //which means all
      this.resultsPerPage = this.getConfigInt('resultsPerPage', 0);

      // If we're paginating the results, we may need some
      // other properties
      if (this.resultsPerPage > 0){
        // The selector for the result items (we define it here since it's conceivable that the
        // results may be structured differently)
        this.resultItemsSelector = `:scope > ul > li`;
        // Current page is 0
        this.currPage = 0;
        // And some null variables that are used iff the results are paginated
        this.currItem = null;
        this.resultItems = null;
      }

      //How many keyword in context strings should be included
      //in search results? Default 10.
      this.maxKwicsToShow = this.getConfigInt('maxKwicsToShow', 10);

      //Result handling object
      this.resultSet = new SSResultSet(this.maxKwicsToShow, this.scrollToTextFragment, this.reKwicTruncateStr);

      //This allows the user to navigate through searches using the back and
      //forward buttons; to avoid repeatedly pushing state when this happens,
      //we pass popping = true.
      window.onpopstate = function(){this.parseUrlQueryString(true)}.bind(this);

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
      this.parseUrlQueryString();
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/** @function staticSearch~jsonRetrieved
  * @description this function is called whenever a resource is retrieved
  *              by the trickle-download process initiated on startup. It
  *              stores the data in the right place, and sets a flag to say
  *              that the data has been retrieved (or was not available).
  *
  * @param {*} json
  *             the JSON retrieved by the AJAX request (not always
  *             actually JSON).
  * @param {!string} path the path from which it was retrieved.
  * @suppress {missingProperties} The compiler doesn't know about properties 
  * of the json param, which could be one of several types of thing.
  * 
  */
  jsonRetrieved(json, path){
    if (path.match(/ssStopwords.*json$/)){
      this.stopwords = json.words;
      this.mapJsonRetrieved.set('ssStopwords', GOT);
      return;
    }
    if (path.match(/ssWordString.*txt$/)){
      this.wordString = json; //Not really JSON in this one case.
      this.mapJsonRetrieved.set('ssWordString', GOT);
      return;
    }
    if (path.match(/ssTitles.*json$/)){
      /** @suppress {checkTypes} Compiler is ignorant of the type of json. */
      this.resultSet.titles = new Map(Object.entries(json));
      this.mapJsonRetrieved.set('ssTitles', GOT);
      return;
    }
    if (path.match(/\/filters\//)){
      this.mapFilterData.set(json.filterName, json);
      this.mapJsonRetrieved.set(json.filterId, GOT);
      if (path.match(/ssFeat/)){
        this.setupFeatFilter(json.filterId, json.filterName);
      }
      return;
    }
  }

/** @function staticSearch~getJson
  * @description this function trickle-downloads a series of resource files
  *              which the object has determined it may need, getting
  *              them one at a time to avoid saturating the connection;
  *              while this is happening, a live search may be initiated
  *              which needs to get a lot of resources quickly.
  *
  * @param {number} jsonIndex the index of the item in the array of items
  *               that need to be retrieved.
  */
  async getJson(jsonIndex){
    if (jsonIndex < this.jsonToRetrieve.length){
      try{
        if (this.mapJsonRetrieved.get(this.jsonToRetrieve[jsonIndex].id) != GOT){
          this.mapJsonRetrieved.set(this.jsonToRetrieve[jsonIndex].id, GETTING);
          let fch = await fetch(this.jsonToRetrieve[jsonIndex].path);
          let json = /.*\.txt$/.test(this.jsonToRetrieve[jsonIndex].path)? await fch.text() : await fch.json();
          this.jsonRetrieved(json, this.jsonToRetrieve[jsonIndex].path);
        }
        else{
          return this.getJson(jsonIndex + 1);
        }
      }
      catch(e){
        console.log('ERROR: failed to retrieve resource ' + this.jsonToRetrieve[jsonIndex].path + ': ' + e.message);
        this.mapJsonRetrieved.set(this.jsonToRetrieve[jsonIndex].id, FAILED);
      }
      return this.getJson(jsonIndex + 1);
    }
    else{
      this.allJsonRetrieved = true;
      document.body.classList.remove('ssLoading');
    }
  }

/** @function StaticSearch~setupFeatFilter
  * @description this function runs when the json for a specific
  *              feature filter is retrieved; it enables the 
  *              control and assigns functionality events to it.
  * @param {!string} filterId the id of the filter to set up.
  * @param {!string} filterName the string name of the filter.
  * @return {boolean} true if a filter is found and set up, else false.
  */
  setupFeatFilter(filterId, filterName){
    let featFilter = document.getElementById(filterId);
    if (featFilter !== null){
      try{
        //Now we set up the control as a typeahead.
        let filterData = this.mapFilterData.get(filterName);
        this.mapFeatFilters.set(filterName, new SSTypeAhead(featFilter, filterData, filterName, this.minWordLength));
        //Re-enable it.
        let inp = featFilter.querySelector('input');
        inp.disabled = false;
      }
      catch(e){
        console.log('ERROR: failed to set up feature filter ' + filterId + ': ' + e);
        return false;
      }
    }
    else{
      console.log('ERROR: failed to find feature filter ' + filterId);
      return false;
    }
  }

/** @function StaticSearch~parseUrlQueryString
  * @description this function is run after the class is instantiated
  *              to check whether there is a search string in the
  *              browser URL. If so, it parses it out and runs the
  *              query.
  *
  * @param {!boolean} popping specifies whether this parse has been triggered
  *                  by window.onpopstate (meaning the user is moving through
  *                  the browser history)
  * @return {boolean} true if a search is initiated otherwise false.
  */
  async parseUrlQueryString(popping = false){
    let searchParams = new URLSearchParams(decodeURI(document.location.search));
    //Do we need to do a search?
    let searchToDo = false; //default

    //Keep an array of all the elements we configure so we can traverse
    //the hierarchy and open any closed details elements above them.
    let changedControls = [];

    if (searchParams.has('q')){
      let currQ = searchParams.get('q').trim();
      if (currQ !== ''){
        this.queryBox.value = searchParams.get('q');
        searchToDo = true;
        changedControls.push(this.queryBox);
      }
    }

    for (let cbx of this.searchInFilterCheckboxes){
      if ((searchParams.has(this.searchInFieldsetName)) && (searchParams.getAll(this.searchInFieldsetName).indexOf(cbx.value) > -1)){
          cbx.checked = true;
          searchToDo = true;
          changedControls.push(cbx);
      } else {
        cbx.checked = false;
      }
    }

    for (let cbx of this.descFilterCheckboxes){
      let key = cbx.getAttribute('title');
      if ((searchParams.has(key)) && (searchParams.getAll(key).indexOf(cbx.value) > -1)){
          cbx.checked = true;
          searchToDo = true;
          changedControls.push(cbx);
      }
      else{
        cbx.checked = false;
      }
    }
    //Have to do something similar but way more clever for the ssFeat filters.
    //For each feature filter
    for (let inp of this.featFilterInputs){
    //check whether it's mentioned in the search params
      let key = inp.getAttribute('title');
      let filterId = inp.parentNode.id;
      if (searchParams.has(key)){
        searchToDo = true;
        changedControls.push(inp);
    //if so, check whether its typeahead control has been set up yet.
        if (!this.mapFeatFilters.has(key)){
    //If not, await its JSON retrieval, and set it up.
          let fch = await fetch(this.jsonDirectory + 'filters/' + filterId + this.versionString + '.json');
          let json = await fch.json();
          this.mapFilterData.set(json.filterName, json);
          this.setupFeatFilter(json.filterId, json.filterName);
        }
    //Then set its checkboxes appropriately.
        this.mapFeatFilters.get(key).setCheckboxes(searchParams.getAll(key));
      }
    }
    for (let txt of this.dateFilterTextboxes){
      let key = txt.getAttribute('title') + txt.id.replace(/^.+((_from)|(_to))$/, '$1');
      if ((searchParams.has(key)) && (searchParams.get(key).length > 3)){
        txt.value = searchParams.get(key);
        searchToDo = true;
        changedControls.push(txt);
      }
      else{
        txt.value = '';
      }
    }
    for (let num of this.numFilterInputs){
      let key = num.getAttribute('title') + num.id.replace(/^.+((_from)|(_to))$/, '$1');
      if ((searchParams.has(key)) && (searchParams.get(key).length > 0)){
        num.value = searchParams.get(key);
        searchToDo = true;
        changedControls.push(num);
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
          changedControls.push(sel);
          break;
        case 'false':
          sel.selectedIndex = 2;
          searchToDo = true;
          changedControls.push(sel);
          break;
        default:
          sel.selectedIndex = 0;
      }
    }

    if (searchToDo === true){
      //Open any ancestor details elements.
      this.openAncestorElements(changedControls);

      this.doSearch(popping);
      return true;
    }
    else{
      return false;
    }
  }

/** @function StaticSearch~openAncestorElements
 * @param {Array} startingElements The array of elements from which
 *                to search up the tree for ancestors which need to
 *                be opened. For each element, any ancestor details
 *                element is opened so that the starting control
 *                is not hidden.
 * @return {boolean} true if any change is made, otherwise false.
 */
  openAncestorElements(startingElements){
    let retVal = false;
    startingElements.forEach(function(ctrl){
      let d = ctrl.closest('details:not([open])');
      while (d !== null){
        d.open = true;
        retVal = true;
        d = d.closest('details:not([open])');
      }
    });
    return retVal;
  }

/** @function StaticSearch~doSearch
  * @description this function initiates the search process,
  *              taking it as far as creating the promises
  *              for retrieval of JSON files. After that, the
  *              resolution of the promises carries the process
  *              on.
  * @param {!boolean} popping specifies whether this parse has been triggered
  *                  by window.onpopstate (meaning the user is moving through
  *                  the browser history)
  * @return {boolean} true if a search is initiated otherwise false.
  * 
  */
  doSearch(popping = false){
  //We start by intercepting any situation in which we may need the
  //ssWordString resource, but we don't yet have it.
    if (this.allowWildcards){
      if (/[\[\]?*]/.test(this.queryBox.value)){
        var self = this;
        if (this.mapJsonRetrieved.get('ssWordString') != GOT){
          let promise = fetch(self.jsonDirectory + 'ssWordString' + self.versionString + '.txt', self.fetchHeaders)
            .then(function(response) {
              return response.text();
            }.bind(this))
            .then(function(text) {
              self.wordString = text;
              self.mapJsonRetrieved.set('ssWordString', GOT);
              self.doSearch();
            }.bind(this))
            .catch(function(e){
              console.log('Error attempting to retrieve word list: ' + e);
            }.bind(this));
          return false;
        }
      }
    }
    // Now initialize that we're searching
    this.isSearching = true;
     //And now setup the timeout
    this.setupSearchingDiv();
    this.docsMatchingFilters.filtersActive = false; //initialize.
    let result = false; //default.
    this.discardedTerms = []; //Clear discarded terms.
    if (this.parseSearchQuery()){
      if (this.writeSearchReport()){
        this.populateIndexes();
        if (!popping){
          this.setQueryString();
        }
        result = true;
      }
      else{
        this.isSearching = false;
      }
    }
    else{
      this.isSearching = false;
    }
    window.scroll({ top: this.resultsDiv.offsetTop, behavior: "smooth" });
    return result;
  }

  /** @function StaticSearch~setupSearchingDiv
   * @description this function sets up the "Searching..." popup message,
   * by adding a class to the document body that makes the ssSearching div
   * appear; it then sets polls to see whether StaticSearch.isSearching has been
   * set back to false and, if so, removes the class
   *
   */
  setupSearchingDiv() {
    let self = this;
    // Just check before initiating that it
    // hasn't already been initiated
    if (!document.body.classList.contains('ssSearching')){
      // Add the searching class to the body;
      document.body.classList.add('ssSearching');
      // And now create the timeout function that calls itself
      // to see whether a searching is still ongoing
      const timeout = function(){
        if (!self.isSearching){
          document.body.classList.remove('ssSearching');
          return;
        }
        window.setTimeout(timeout, 100);
      }
      timeout();
    }
  }





  /** @function StaticSearch~setQueryString
  * @description this function is run once a search is initiated,
  * and it takes the search parameters and creates a browser URL
  * search string, then pushes this into the History object so that
  * all searches are bookmarkable.
  *
  * @return {boolean} true if successful, otherwise false.
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

        //Search in filter handling
        for (let cbx of this.searchInFilterCheckboxes){
          if (cbx.checked){
            search.push(this.searchInFieldsetName + "=" + cbx.value);
          }
        }

        for (let cbx of this.descFilterCheckboxes){
          if (cbx.checked){
            search.push(cbx.title + '=' + cbx.value);
          }
        }
        //Feature filter checkboxes need to be discovered first, since 
        //they're mutable.
        this.featFilterCheckboxes = 
          Array.from(document.querySelectorAll("input[type='checkbox'].staticSearch_feat"));
        for (let cbx of this.featFilterCheckboxes){
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
  * @return {boolean} true if no errors occur, otherwise false.
  */
  parseSearchQuery(){
    try{
      let i;
      //Clear anything in the existing array.
      this.terms = [];
      this.normalizedQuery = [];
      let strSearch = this.queryBox.value;

      //Start by normalizing whitespace.
      strSearch = strSearch.replace(/((^\s+)|\s+$)/g, '');
      strSearch = strSearch.replace(/\s+/g, ' ');

      //Next, replace curly apostrophes with straight.
      strSearch = strSearch.replace(/[‘’‛]/g, "'");
      
      //Then remove any leading or trailing apostrophes
      strSearch = strSearch.replace(/(^'|'$)/g,'');


      //If we're not supporting phrasal searches, get rid of double quotes.
      if (!this.allowPhrasal){
        strSearch = strSearch.replace(/"/g, '');
      }
      //Otherwise, we rationalize the quotation marks
      else{
      //Get rid of any quote pairs with nothing between them.
        strSearch = strSearch.replace(/""/g, '');
        //Now delete any unmatched double quotes
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
      }

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
          // If we're not in a phrase, and encounter some sort of punctuation, then skip it
          if (this.charsToDiscardPattern.test(c) && (!inPhrase)) {
            // Just skip the bit of punctuation
          } else if ((c === ' ') && (!inPhrase)){
            this.addSearchItem(strSoFar, false);
            strSoFar = '';
          } else{
            strSoFar += c;
          }
        }
      }
      this.addSearchItem(strSoFar, inPhrase);
     
      // Now clear the queryBox and replace its contents
      // By joining the normalized query
      this.queryBox.value = this.normalizedQuery.join(" ");
      

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
  * @param {!string}   strInput a string of text.
  * @param {!boolean}  isPhrasal whether or not this is a phrasal
  *                             search. This may be true even for
  *                             a single word, if it is to be searched
  *                             unstemmed.
  * @return {boolean} true if terms found, otherwise false.
  */
  addSearchItem(strInput, isPhrasal){


    //Sanity check
    if (strInput.length < 1){
      return false;
    }

    //Broadness check
    if (!isPhrasal && !this.termPattern.test(strInput)){
      this.normalizedQuery.push(strInput);
      this.discardedTerms.push(strInput);
      return false;
    }

    //Stopword check
    if (this.stopwords.indexOf(strInput.toLowerCase()) > -1){
      this.normalizedQuery.push(strInput);
      this.discardedTerms.push(strInput);
      return false;
    }

    //Is it a phrase?
    if ((/\s/.test(strInput)) || (isPhrasal)){

    // If this is a phrasal, we need to surround with quotation marks
    // before we push to the normalized query
    this.normalizedQuery.push('"' + strInput + '"');

    //We need to find the first component which is not a stopword.
    /** @suppress {missingProperties} Compiler doesn't know about String.prototype.replaceAll(). */
      let subterms = strInput.trim().toLowerCase().split(/\s+/).map(term => term.replaceAll(this.charsToDiscardPattern,''));
      let i;
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
      //Push the string to the normalized query
      this.normalizedQuery.push(strInput);
      //Else is it a wildcard? Wildcards are expanded to a sequence of matching terms.
      if (this.allowWildcards && /[\[\]?*]/.test(strInput)){
        let re = this.wildcardToRegex(strInput);
        let matches = [...this.wordString.matchAll(re)];
        //Now we have a nested array of matches. We need to stem and filter.
        let stems = [];
        for (let m of matches){
          let mStem = this.stemmer.stem(m[1].toLowerCase());
          let term = m[0].replace(/[\|]/g, '');
          if (this.terms.length < this.termLimit){
            if (this.allowPhrasal){
              this.terms.push({str: term, stem: mStem, type: PHRASE});
            }
            else{
              this.terms.push({str: term, stem: mStem, type: MAY_CONTAIN});
            }
          }
        }
      }
      else{
        //Else is it a must-contain?
        if (/^[\+]/.test(strInput)){
          let term = strInput.substring(1).toLowerCase();
          this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), type: MUST_CONTAIN});
        }
        else{
        //Else is it a must-not-contain?
          if (/^[\-]/.test(strInput)){
            let term = strInput.substring(1).toLowerCase();
            this.terms.push({str: strInput.substring(1), stem: this.stemmer.stem(term), type: MUST_NOT_CONTAIN});
          }
          else{
          //Else may-contain.
            let term = strInput.toLowerCase();
            this.terms.push({str: strInput, stem: this.stemmer.stem(term),  type: MAY_CONTAIN});
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
  * @return {boolean} true on success, false on failure.
  */
  clearSearchForm(){
    try{
      this.queryBox.value = '';

      for (let cbx of this.searchInFilterCheckboxes){
        cbx.checked = false;
      }

      for (let cbx of this.descFilterCheckboxes){
        cbx.checked = false;
      }
      //Feature filter checkboxes need to be discovered first, since 
      //they're mutable.
      this.featFilterCheckboxes = 
        Array.from(document.querySelectorAll("input[type='checkbox'].staticSearch_feat"));
      for (let cbx of this.featFilterCheckboxes){
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
      return true;
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
  * @return {boolean} true on success, false on failure.
  */
  processFilters(){
    try{
      this.docsMatchingFilters = this.getDocIdsForFilters();
      this.activeContexts = new XSet(this.searchInFilterCheckboxes.filter(cbx => cbx.checked).map(c => c.id));
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
    * @suppress {missingProperties} The compiler doesn't know about the 
    * docs property.
    */
    getDocIdsForFilters(){

      var xSets = [];
      var currXSet;

      //Find each desc or feat fieldset and get its descriptor.
      let filters = document.querySelectorAll('fieldset[id ^= "ssDesc"], fieldset[id ^="ssFeat"]');
      for (let filter of filters){
        currXSet = new XSet();
        let filterName = filter.getAttribute('title');
        let cbxs = filter.querySelectorAll('input[type="checkbox"]:checked');
        if ((cbxs.length > 0) && (this.mapFilterData.has(filterName))){
          for (let cbx of cbxs){
            currXSet.addArray(this.mapFilterData.get(filterName)[cbx.id].docs);
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
        if ((sel > 0) && (this.mapFilterData.has(boolName)) && (this.mapFilterData.get(boolName)[valueId] !== undefined)){
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

      //Find each number pair and get its descriptor.
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
  * @description This outputs a human-readable explanation of the search
  *              that's being done, to clarify for users what they've chosen 
  *              to look for. Note that the output div is hidden by default. 
  *              NOTE: This does not yet include filter information.
  * @return {boolean} true if the process succeeds, otherwise false.
  */
  writeSearchReport(){
    if (this.showSearchReport){
      try{
        let sr = document.querySelector('#searchReport');
        if (sr){sr.parentNode.removeChild(sr);}
        let arrOutput = [];
        let i, d, p, t;
        for (i=0; i<this.terms.length; i++){
          if (!arrOutput[this.terms[i].type]){
            arrOutput[this.terms[i].type] = {type: this.terms[i].type, terms: []};
          }
          arrOutput[this.terms[i].type].terms.push(`"${this.terms[i].str}" (${this.terms[i].stem})`);
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
        //this.resultsDiv.insertBefore(d, this.resultsDiv.firstChild);
        this.resultsDiv.parentNode.insertBefore(d, this.resultsDiv);
        return true;
      }
      catch(e){
        console.log('ERROR: ' + e.message);
        return false;
      }
    }
    return true;
  }

/**
  * @function StaticSearch~getTermsByType
  * @description This method returns an array of indexes in the
  * StaticSearch.terms array, being the terms which match the
  * supplied term type (PHRASE, MUST_CONTAIN etc.).
  * @param {!number} termType One of PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN,
                              MAY_CONTAIN.
  * @return {!Array<number>} An array of zero or more integers.
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
  * for required stems and filters have been retrieved and their
  * contents merged into the required structures, or b) a retrieval
  * has failed, so an empty placeholder has been inserted to signify
  * that there is no such dataset.
  *
  * The function works with fetch and promises, and its final
  * .then() calls the processResults function.
  * @suppress {missingProperties} The compiler doesn't know about
  * properties such as json.filterId.
  */
  populateIndexes(){
    var i, imax, stemsToFind = [], promises = [], emptyIndex, filterSelector, filterIds;
//We need a self pointer because this will go out of scope.
    var self = this;
    try{
  //For each stem in the search string
      for (i=0, imax=this.terms.length; i<imax; i++){
  //Now check whether we already have an index entry for this stem
        if (!this.index.hasOwnProperty(this.terms[i].stem)){
  //If not, add it to the array of stems we want to retrieve.
          stemsToFind.push(this.terms[i].stem);
        }
      }

      filterIds = new Set();
      //Do we need to get document metadata for filters?
      if (this.allJsonRetrieved === false){
        //First get a list of active filters.

        for (let ctrl of document.querySelectorAll('input[type="checkbox"].staticSearch_desc:checked, input[type="checkbox"].staticSearch_feat:checked')){
          let filterId = ctrl.id.split('_')[0];
          if (this.mapJsonRetrieved.get(filterId) != GOT){
            filterIds.add(filterId);
          }
        }
        for (let ctrl of document.querySelectorAll('select.staticSearch_bool')){
          if (ctrl.selectedIndex > 0){
            let filterId = ctrl.id.split('_')[0];
            if (this.mapJsonRetrieved.get(filterId) != GOT){
              filterIds.add(filterId);
            }
          }
        }
        for (let ctrl of document.querySelectorAll('input[type="text"].staticSearch_date')){
          if (ctrl.value.length > 3){
            let filterId = ctrl.id.split('_')[0];
            if (this.mapJsonRetrieved.get(filterId) != GOT){
              filterIds.add(filterId);
            }
          }
        }
        for (let ctrl of document.querySelectorAll('input[type="number"].staticSearch_num')){
          if (ctrl.value.length > 0){
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
              /** @suppress {checkTypes} The compiler doesn't know the json thing is an object with entries. */
              self.resultSet.titles = new Map(Object.entries(json));
              self.mapJsonRetrieved.set('ssTitles', GOT);
            }.bind(self))
            .catch(function(e){
              console.log('Error attempting to retrieve title list: ' + e);
            }.bind(self));
        }
//For glob searching, we'll need to care about the string of words too.
        if (this.allowWildcards == true){
          if (this.mapJsonRetrieved.get('ssWordString') != GOT){
            promises[promises.length] = fetch(self.jsonDirectory + 'ssWordString' + this.versionString + '.txt', this.fetchHeaders)
              .then(function(response) {
                return response.text();
              })
              .then(function(text) {
                self.wordString = text;
                self.mapJsonRetrieved.set('ssWordString', GOT);
              }.bind(self))
              .catch(function(e){
                console.log('Error attempting to retrieve word string: ' + e);
              }.bind(self));
          }
        }
      }

      //If we do need to retrieve JSON index data, then do it
      if (stemsToFind.length > 0){

//Set off fetch operations for the things we don't have yet.
        for (i=0, imax=stemsToFind.length; i<imax; i++){

//We will first add an empty index so that if nothing is found, we won't need
//to search again.
          emptyIndex = {'stem': stemsToFind[i], 'instances': []}; //used as return value when nothing retrieved.

          this.stemFound(emptyIndex);

//We create an array of fetches to get the json file for each stem,
//assuming it's there.
          promises[promises.length] = fetch(self.jsonDirectory + 'stems/' + stemsToFind[i] + this.versionString + '.json', this.fetchHeaders)
//If we get a response, and it looks good
              .then(function(response){
                if ((response.status >= 200) &&
                    (response.status < 300) &&
                    (response.headers.get('content-type')) &&
                    (response.headers.get('content-type').includes('application/json'))) {
//then we ask for response.json(), which is itself a promise, to which we add a .then to store the data.
                  return response.json().then(function(data){ self.stemFound(data); }.bind(self));
                }
              })
//If something goes wrong, then we store an empty index
//through the notFound function.
              .catch(function(e){
                console.log('Error attempting to retrieve ' + stemsToFind[i] + ': ' + e);
                return function(emptyIndex){self.stemFound(emptyIndex);}.bind(self, emptyIndex);
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
  * @function StaticSearch~stemFound
  * @description Before a request for a JSON file is initially made,
  *              an empty index is stored, indexed under the stem
  *              which is being searched, so that whether or not we
  *              successfully retrieve data, we won't have to try
  *              again in a subsequent search in the same session.
  *              Then, when a request for a JSON file for a specific
  *              stem results in a JSON file with data, we overwrite
  *              the data in the index, indexed under the stem.
  *              Sometimes the data coming in may be an instance
  *              of an empty index, if the retrieval code knows it
  *              got nothing.
  * @param {Object} data the data structure retrieved for the stem.
  */
  stemFound(data){
    try{
      this.index[data.stem] = data;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
    }
  }

/**
  * @function staticSearch~indexStemHasDoc
  * @description This function, given an index stem and a docUri, searches
  *              to see if there is an entry in the stem's instances for
  *              that docUri.
  * @param {!string} stem the index stem to search for.
  * @param {!string} docUri the docUri to search for.
  * @return {boolean} true if found, false if not.
  */
  indexStemHasDoc(stem, docUri){
    let result = false;
    if (this.index[stem]){
      for (let i=0; i<this.index[stem].instances.length; i++){
        if (this.index[stem].instances[i].docUri == docUri){
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
  * @return {boolean} true if successful, false if not.
  */
  clearResultsDiv(){
    while (this.resultsDiv.firstChild) {
      this.resultsDiv.removeChild(this.resultsDiv.firstChild);
    }
    return true;
  }


/**
  * @function StaticSearch~reportNoResults
  * @description Reports that no results have been found.
  *              Also optionally configures and runs a
  *              simpler version of the current search, with
  *              phrases tokenized, etc.
  * @param {!boolean} trySimplerSearch a flag to determine whether
  *              this search should be simplified and automatically
  *              run again.
  * @return {boolean} true if successful, false if not.
  */
  reportNoResults(trySimplerSearch){
    //TODO: NOT IMPLEMENTED YET.
    console.log('No results. Try simpler search? ' + trySimplerSearch);
    return true;
  }

  /**
   * @function StaticSearch~reportTooManyResults
   * @description Reports, both in the results and the console,
   *              that the number of results found exceed
   *              the configured limit (StaticSearch.resultsLimit)
   *              and cannot be displayed.
   * @return {boolean} true if successful, false if not
   */
  reportTooManyResults() {
    try {
      console.log(`Found ${this.resultSet.getSize()} results, which exceeds the ${this.resultsLimit} maximum.`);
      let pTooManyResults = document.createElement('p');
      pTooManyResults.append(this.captionSet.strTooManyResults);
      this.resultsDiv.appendChild(pTooManyResults);
      return true;
    } catch (e) {
      console.log('ERROR: ' + e);
      return false;
    }
  }


  /**
  * @function StaticSearch~processResults
  * @description When we are satisfied that all relevant search data
  *              has been retrieved and added to the index, this
  *              function is called to process the search and show
  *              any results found.
  * @return {boolean} true if there are results to show; false if not.
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
  3. There are active filters but no search terms
     (although search terms may have been discarded).
  4. There are no active filters and no search terms 
     (although search terms may have been discarded).

  For #1, process the term searches into the result set, and then
     filter it using the active filter matching doc list.
  For #2, process the results into the result set, but don't filter it.
  For #3, construct the result set directly from the filter doc list,
     passing only ids and titles, for a simple listing display.
  For #4, do nothing at all (or possibly display an error message).

  For cases #1 and #2 (i.e. where there is a search term), there may be
  active context filters; those are a bit different, since they do not require
  any fetching (all of that information is contained within the JSON).

  */
//Since we have to handle discarded search terms in the same
//manner whatever the scenario, we do them first.
let pDiscarded = null;
if (this.discardedTerms.length > 0){
  let txt = this.captionSet.strDiscardedTerms + ' ' + this.discardedTerms.join(', ');
  pDiscarded = document.createElement('p');
  pDiscarded.classList.add('ssDiscarded');
  pDiscarded.append(txt);
  //pDiscarded.appendChild(txt);
}

//Easy ones first: #4
      if ((this.terms.length < 1)&&(this.docsMatchingFilters.size < 1)){

        this.clearResultsDiv();
        if (pDiscarded !== null){
          this.resultsDiv.appendChild(pDiscarded);
        }
        let pFound = document.createElement('p');
        pFound.append(this.captionSet.strDocumentsFound + '0');
        this.resultsDiv.appendChild(pFound);
        this.isSearching = false;
        this.searchFinishedHook(1);
        return false;
      }
//#3
      if ((this.terms.length < 1)&&(this.docsMatchingFilters.size > 0)){
        this.resultSet.addArray([...this.docsMatchingFilters]);
        this.resultSet.sortByScoreDesc();

        this.clearResultsDiv();
        if (pDiscarded !== null){
          this.resultsDiv.appendChild(pDiscarded);
        }
        let pFound = document.createElement('p');
        pFound.append(this.captionSet.strDocumentsFound + this.resultSet.getSize());
        this.resultsDiv.appendChild(pFound);
        //Switch depending on the result size:
        //Report that there are no results
        if (this.resultSet.getSize() < 1){
          this.reportNoResults(true);
          // Else if the number of results is greater than the limit.
        } else if (this.resultSet.getSize() > this.resultsLimit){
            this.reportTooManyResults();
        } else {
          // Otherwise, render the results, optionally paginated.
          this.resultsDiv.appendChild(this.resultSet.resultsAsHtml(this.captionSet.strScore));
          if (this.resultsPerPage > 0 && this.resultsPerPage < this.resultSet.getSize()){
            this.paginateResults();
          }
        }
        this.isSearching = false;
        this.searchFinishedHook(2);
        return (this.resultSet.getSize() > 0);
      }

//The sequence of result processing is highly dependent on the
//query components entered by the user. First, we discover what
//term types we have in the list.
      /** @type {!Array<number>} */
      let phrases           = this.getTermsByType(PHRASE);
      /** @type {!Array<number>} */
      let must_contains     = this.getTermsByType(MUST_CONTAIN);
      /** @type {!Array<number>} */
      let must_not_contains = this.getTermsByType(MUST_NOT_CONTAIN);
      /** @type {!Array<number>} */
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
            let str = self.terms[phr].str;
            let phraseRegex = self.phraseToRegex(str);
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
                  if (phraseRegex.test(unmarkedContext)){
  //We have a candidate document for inclusion, and a candidate context.
                    let c = unmarkedContext.replace(phraseRegex, '<mark>' + '$&' + '</mark>');
                    currContexts.push(
                    {form: str, context: c, weight: 2, fid: cntxt.fid ? cntxt.fid : '', prop: cntxt.prop ? cntxt.prop : {}, in: cntxt.in ? cntxt.in : []});
                  }
                }
  //If we've found contexts, we know we have a document to add to the results.
                if (currContexts.length > 0){
  //The resultSet object will automatically merge this data if there's already
  //an entry for the document.
                  self.resultSet.set(inst.docUri, {docUri: inst.docUri,
                    docTitle: inst.docTitle,
                    //score: inst.score, //See below: which is right? TODO.
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
  * @param {!Array<number>} indexes a list of indexes into the terms array.
  *              This needs to be a parameter because the function is calls
  *              itself recursively with a reduced array.
  * @param {!boolean} runAsFilter controls which mode the process runs in.
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
                if (! self.indexStemHasDoc(self.terms[mc].stem, docUri)){
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
  * @param {!boolean} addAllFound controls which mode the process runs in.
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
            this.isSearching = false;
            this.searchFinishedHook(3);
            return false;
          }
        }
      }

//Now we filter the results based on filter checkboxes, if any.
//This is #1
      if (this.docsMatchingFilters.filtersActive == true){
        this.resultSet.filterBySet(this.docsMatchingFilters);
      }

      // Now process the resultSet and filter out any contexts
      // and docs that by active contexts, if any
      if (this.activeContexts.size > 0){
   
        this.resultSet.filterByContexts(this.activeContexts);
      }


      this.resultSet.sortByScoreDesc();
      this.clearResultsDiv();
      if (pDiscarded !== null){
        this.resultsDiv.appendChild(pDiscarded);
      }
      let pFound = document.createElement('p');
      pFound.append(this.captionSet.strDocumentsFound + this.resultSet.getSize());
      this.resultsDiv.appendChild(pFound);
      //Switch depending on the result size:
      //Report that there are no results
      if (this.resultSet.getSize() < 1){
        this.reportNoResults(true);
        // Else if the number of results is greater than the limit.
      } else if (this.resultSet.getSize() > this.resultsLimit){
        this.reportTooManyResults();
      } else {
        // Otherwise, render the results, optionally paginated.
        this.resultsDiv.appendChild(this.resultSet.resultsAsHtml(this.captionSet.strScore));
        if (this.resultsPerPage > 0 && this.resultsPerPage < this.resultSet.getSize()){
          this.paginateResults();
        }
      }
      this.isSearching = false;
      this.searchFinishedHook(4);
      return (this.resultSet.getSize() > 0);
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      this.isSearching = false;
      this.searchFinishedHook(5);
      return false;
    }
  }


  /**
   * @function StaticSearch~paginateResults
   * @description This method adds pagination controls to the results and adds
   * a number of properties to the StaticSearch object to handle pagination. It first
   * checks whether or not it needs to add anything to the page, and, if it does,
   * then adds the Show More / Show All buttons to the bottom of the results div
   * and adds some functionality to the buttons.
   * @return {boolean} true if necessary; false if unnecessary
   */
  paginateResults() {
    try{
      // Get the list of all result items using the configured selector; we do this here
      // in case ResultsAsHTML is modified in such a way that it invalidates the default
      // selector
      this.resultItems = this.resultsDiv.querySelectorAll(this.resultItemsSelector);

      // Construct all of the widgets (using the longhand createElement method, since
      // we have to hook event listeners to the buttons)
      this.paginationBtnDiv = document.createElement('div');
      this.paginationBtnDiv.setAttribute('id', 'ssPagination');
      this.showMoreBtn = document.createElement('button');
      this.showMoreBtn.setAttribute('id', 'ssShowMore');
      this.showMoreBtn.innerHTML = this.captionSet.strShowMore;
      this.showAllBtn = document.createElement('button');
      this.showAllBtn.setAttribute('id', 'ssShowAll');
      this.showAllBtn.innerHTML = this.captionSet.strShowAll;
      this.paginationBtnDiv.appendChild(this.showMoreBtn);
      this.paginationBtnDiv.appendChild(this.showAllBtn);
      this.resultsDiv.appendChild(this.paginationBtnDiv);

      // Now start the pagination
      this.showMoreResults();

      // And add the pagination functions to the respective buttons
      this.showMoreBtn.addEventListener('click', this.showMoreResults.bind(this));
      this.showAllBtn.addEventListener('click', this.showAllResults.bind(this));
      return true;
    } 
    catch(e) {
      console.log('ERROR ' + e.message);
      return false;
    }
  }

  /**
   * @function StaticSearch~showAllResults
   * @description Method to show all of the results (i.e. removing the hidden item's
   * class that instructs all of its siblings to hide) and hide the pagination
   * widget.
   * @return {boolean} true if successful, false if not.
   */
  showAllResults(){
    try{
      this.currItem.classList.remove('ssPaginationEnd');
      this.paginationBtnDiv.style.display = "none";
      return true;
    } catch(e) {
      console.log('ERROR ' + e.message);
      return false;
    }

  }

  /**
   * @function StaticSearch~showMoreResults
   * @description Method to show more results based off of the current page
   * and the number of results to show. If we're on the last page, then the
   * "Show More" is simply a proxy for showAll; otherwise, it shifts the
   * hidden class from the last item to the next one in the sequence.
   * @return {boolean} true if successful, false if not.
   */
  showMoreResults(){
    try{
      this.currPage++;
      let nextItemNum = (this.currPage * this.resultsPerPage) - 1;
      if (this.currItem !== null){
        this.currItem.classList.remove('ssPaginationEnd');
      }
      if (nextItemNum >= this.resultSet.getSize()){
        this.showAllResults();
        return true;
      }
      this.currItem = this.resultItems[nextItemNum];
      this.currItem.classList.add('ssPaginationEnd');
      return true;
    } catch(e){
        console.log('ERROR ' + e.message);
        return false;
    }
  }


  /** @function StaticSearch~phraseToRegex
   *  @description This method takes a phrase and converts it
   *  into the regular expression that will be matched against
   *  contexts. This function first escapes all characters
   *  to prevent from unintentional regular expression, then expands all
   *  apostrophes (i.e. treating U+0027, U+2018, U+2019, U+201B as equivalent) and
   *  all quotation marks.
   * @param {!string} str a string of text
   * @return {RegExp|null} a regular expression, or null if one can't be constructed
   */
  phraseToRegex(str){
    //Escape the phrase to have proper punctuation matching
    let esc = str.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    //Expand the apostrophes into a character class
    let strRe = esc.replace(/'/g, "['‘’‛]").replace(/[“”]/g, '[“”"]');
    //Set starting anchor
    if (/^\w/.test(str)){
      strRe = '\\b' + strRe;
    }
    //Set ending anchor
    if (/\w$/.test(str)){
      strRe = strRe + '\\b';
    }
    // Test the regex and return null if it's broken
    try{
      //Make the phrase into a regex for matching.
      let re = new RegExp(strRe);
      return re;
    }
    catch(e){
      console.log('Invalid regex from phrase created: ' + strRe);
      return null;
    }
  }


/** @function StaticSearch~wildcardToRegex
  * @description This method is provided with a single token as 
  * input. The token should contain wildcard characters (asterisk,
  * question mark and square brackets). The function converts this
  * to a JS regular expression. For example: th*n[gk]? would 
  * become /^th.*[gk].$/. The regex is created with leading and
  * trailing pipe characters, because the string of words against
  * which it will be matched uses these as delimiters, and it has
  * a capturing group for the content between the pipes. Because of
  * the use of the pipe delimiter, a negative character class [^\\|]
  * (i.e. 'not a pipe') is used in place of a dot.
  * @param {!string}   strToken a string of text with no spaces.
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
    let strRe  = esc.replace(/[\?]/g, '[^\\|]').replace(/[\*]/g, '[^\\|]$&?');
    //Test the regex, and return it if OK, otherwise return null.
    try{
      let re = new RegExp('\\|(' + strRe + ')\\|', 'gi');
      return re;
    }
    catch(e){
      console.log('Invalid regex created: ' + strRe);
      return null;
    }
  }
}

