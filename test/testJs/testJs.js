/* This JS belongs and applies only to the StaticSearch
 * test suite, and is never needed in a working search
 * application context. */

//This is a set of automated tests which are intended to check whether
//we're getting the results we expect back from the search object.

var reportDiv = null;


var currTestNum = -1;
var tests =[];

//Simple one-word search.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'elephant';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "elephant".');
    checkResults({
      docsFound: 2, contextsFound: 4, scoreTotal: 4
    });
  }
});

//Another simple one-word search.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'twilight';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "twilight".');
    checkResults({
      docsFound: 2, contextsFound: 3, scoreTotal: 3
    });
  }
});

//One word search word-internal apostrophe search
tests.push({
  setup: function () {
    Sch.queryBox.value = "o'clock";
  },
  check: function (num) {
    console.log("Search hook " + num);
    console.log(`Testing results for word with word - internal apostrophe "o'clock".`);
    checkResults({
      docsFound: 1,
      contextsFound: 2,
      scoreTotal: 2
    })
  }
});

//One word possessive apostrophe search
tests.push({
  setup: function () {
    Sch.queryBox.value = "Porter’s"
  },
  check: function (num) {
    console.log ("Search hook " + num);
    console.log('Testing results for possessive curly apostrophe "Porter’s".');
    checkResults({
      docsFound: 2,
      contextsFound: 4,
      scoreTotal: 4
    })
  }
});

//Another simple one-word search but using a desc filter.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'twilight'; document.querySelector('input[value="Site info files"]').checked = 'checked';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "twilight with Site info files desc filter".');
    checkResults({
      docsFound: 1, contextsFound: 1, scoreTotal: 1
    });
  }
});

//Third simple one-word search.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'across';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "across".', true);
    checkResults({
      docsFound: 2, contextsFound: 2, scoreTotal: 2
    });
  }
});

//Same word with date.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'across'; document.querySelector('input[title="Date range"][id$="_from"]').value = '2000';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "across" in documents since 2000.');
    checkResults({
      docsFound: 1, contextsFound: 1, scoreTotal: 1
    });
  }
});

// Simple one word phrase that should only exist in badthings.html
tests.push({
  setup: function () {
    Sch.queryBox.value = 'ignominious';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "ignominious"');
    checkResults({
      docsFound: 1, contextsFound: 1, scoreTotal: 1
    });
  }
});


//Phrasal search. This one tests ignored inlines.
tests.push({
  setup: function () {
    Sch.queryBox.value = '"summer day—our day"';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "summer day—our day".');
    checkResults({
      docsFound: 2, contextsFound: 2, scoreTotal: 2
    });
  }
});

//Phrasal search with boundary contexts.
tests.push({
  setup: function () {
    Sch.queryBox.value = '"our day Was clouded"';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "our day Was clouded".');
    checkResults({
      docsFound: 1, contextsFound: 1, scoreTotal: 1
    });
  }
});

//Phrasal search with embedded straight apostrophe
tests.push({
  setup: function () {
    Sch.queryBox.value = '"confounds the solver\'s attempt"';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "confounds the solver\'s attempt".');
    checkResults({
      docsFound: 1,
      contextsFound: 1,
      scoreTotal: 1
    })
  }
});

//Phrasal search that ends with punctuation
tests.push({
  setup: function () {
    Sch.queryBox.value = '"document,"';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "document,".');
    checkResults({
      docsFound: 1,
      contextsFound: 2,
      scoreTotal: 2
    })
  }
});

//Phrasal search that starts with a space
tests.push({
  setup: function () {
    Sch.queryBox.value = '" process"'
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase " process".');
    checkResults({
      docsFound: 1,
      contextsFound: 1,
      scoreTotal: 1
    })
  }
});

//Phrasal search with boundary contexts and date filter.
tests.push({
  setup: function () {
    Sch.queryBox.value = '"our day Was clouded"'; document.querySelector('input[title="Date range"][id$="_to"]').value = '2000';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "our day Was clouded" with max date 2000.');
    checkResults({
      docsFound: 0, contextsFound: 0, scoreTotal: 0
    });
  }
});

//Two MUST_CONTAINs with boolean flag.
tests.push({
  setup: function () {
    Sch.queryBox.value = '+green +golden'; document.querySelector('select[title="Worth reading"]').selectedIndex = 2;
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the phrase "+green +golden" with boolean flag "Worth reading" false.');
    checkResults({
      docsFound: 1, contextsFound: 2, scoreTotal: 2
    });
  }
});

//Search based only on filters, no terms.
tests.push({
  setup: function () {
    Sch.queryBox.value = ''; document.querySelector('input[value="Poems"]').checked = 'checked'; document.querySelector('select[title="Worth reading"]').selectedIndex = 1;
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for pure filter search: poems worth reading.');
    checkResults({
      docsFound: 2, contextsFound: 0, scoreTotal: 0
    });
  }
});

//Search for a word that's in the stopword list
tests.push({
  setup: function () {
    Sch.queryBox.value = 'artichoke';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "artichoke", which is in the stopwords list.');
    checkResults({
      docsFound: 0, contextsFound: 0, scoreTotal: 0
    });
  }
});

//Search for a word that has no whitespace around it, just linebreaks.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'dog';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "dog", which in one document has no spaces around it, just linebreaks.');
    
    checkResults({
      docsFound: 2, contextsFound: 4, scoreTotal: 4
    });
  }
});

//Search for a couple of words that contain combining diacritics and 
//cannot be inadvertently converted to composed chars (puq̈uist, puc̈ist).
tests.push({
  setup: function () {
    Sch.queryBox.value = 'puq̈uist, puc̈ist';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "puq̈uist" and "puc̈ist", which both appear in one document.');
    
    checkResults({
      docsFound: 1, contextsFound: 2, scoreTotal: 2
    });
  }
});


//Search using the number filter.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'dog'; document.querySelector('input[title="Number of animal names"][id$="_from"]').value = '3';
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the word "dog", in a document mentioning at least three animals.');
    checkResults({
      docsFound: 2, contextsFound: 4, scoreTotal: 4
    });
  }
});

//Search using the a wildcard.
tests.push({
  setup: function () {
    Sch.queryBox.value = 'att*'
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the wildcard "att*", which should find "attempt" and "attached".');
    checkResults({
      docsFound: 2, contextsFound: 2, scoreTotal: 2
    });
  }
});

//Search for a single word as a phrase, to test word-boundaries etc.
tests.push({
  setup: function () {
    Sch.queryBox.value = '"dog"'
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the one-word phrase "dog", which should find 3 instances in one file.');
    checkResults({
      docsFound: 1, contextsFound: 3, scoreTotal: 3
    });
  }
});
//Clear the search box and just test the feature filter.
tests.push({
  setup: function () {
    Sch.queryBox.value = ''; Sch.mapFeatFilters. get ('People involved').setCheckboxes([ 'Rick Holmes', 'Captain Janeway']);
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for the feature filter with two names, which should find 5 documents.');
    checkResults({
      docsFound: 5, contextsFound: 0, scoreTotal: 0
    });
  }
});
//Testing for a word within a context
tests.push({
  setup: function () {
    Sch.queryBox.value = 'Porter';
    document.querySelector('.ssSearchInCheckboxList input[value="Citations"]').checked = true;
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for "Porter" only in Citations');
    checkResults({
      docsFound: 1, contextsFound: 1, scoreTotal: 1
    });
  }
});
//Testing for a wildcard within a context
tests.push({
  setup: function () {
    Sch.queryBox.value = 'con*';
    document.querySelector('.ssSearchInCheckboxList input[value="Quotations"]').checked = true;
  },
  check: function (num) {
    console.log('Search hook ' + num);
    console.log('Testing results for wildcard "con*" only in Quotations');
    checkResults({
      docsFound: 1, contextsFound: 6, scoreTotal: 12
    });
  }
});

var startTime = null;


function runTests() {
  startTime = performance.now();
  reportDiv = document.querySelector('div#testResults');
  
  //Turn off browser history tracking otherwise life gets complicated
  //when running a sequence of automated tests.
  Sch.storeSearchesInBrowserHistory = false;
  //Turning on the report functionality so we have better clues
  //when things go wrong.
  Sch.showSearchReport = true;
  
  reportResults('Running automated tests', true);
}

function reportResults(msg, succeed) {
  let timeSoFar = performance.now() - startTime;
  reportDiv.innerHTML = '<p class="' + (succeed ? 'success': 'failure') + '"> Test #' + (currTestNum + 1) + ': ' + msg + '. Time so far: ' + timeSoFar + '.</p>' + reportDiv.innerHTML;
  if (succeed) {
    Sch.clearSearchForm();
    currTestNum++;
    if (currTestNum >= tests.length) {
      reportDiv.innerHTML = '<p class="success">Done! Total time: ' + (performance.now() - startTime) + '.</p>' + reportDiv.innerHTML;
      Sch.searchFinishedHook = function () {
      };
      //Set this back, so we can do other testing manually.
      Sch.storeSearchesInBrowserHistory = true;
      return;
    }
    tests[currTestNum].setup.call();
    Sch.searchFinishedHook = tests[currTestNum].check;
    Sch.doSearch();
  }
}

//This calls the search object's resultSet instance to get a
//set of totals to compare with what we expect.
function checkResults(obj) {
  let results = Sch.resultSet.resultsAsObject();
  let msg = 'Hit documents: expected ' + obj.docsFound;
  msg += '; found ' + results.docsFound + '. ';
  msg += 'Hit contexts: expected ' + obj.contextsFound;
  msg += '; found ' + results.contextsFound + '. ';
  msg += 'Total of all scores: expected ' + obj.scoreTotal;
  msg += '; found ' + results.scoreTotal + '. ';
  msg += ' (' + Sch.queryBox.value + ')';
  let succeed = ((obj.docsFound === results.docsFound) &&(obj.contextsFound === results.contextsFound) &&(obj.scoreTotal === results.scoreTotal));
  reportResults(msg, succeed);
}

window.addEventListener('load', runTests);