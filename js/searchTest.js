"use strict";

//Create an instance of the search object.
var Sch;

var searchQueryTests = [
  'appearance',
  '+document +flow +specialized',
  'note "document contains" flow specialized +context',
  '+yellow  -red "two colours" better  Green ambiguous'
];

function setupTests(){
  Sch = new StaticSearch();
  if (document.getElementById('searchQuery').value == ''){
    document.getElementById('searchQuery').value = searchQueryTests[1];
  }
}

window.addEventListener('load', setupTests);
