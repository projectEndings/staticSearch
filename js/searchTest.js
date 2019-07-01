"use strict";

//Create an instance of the search object.
var ss;

var searchQueryTests = [
  '+yellow  -red "two colours"  green'
];

function setupTests(){
  ss = new StaticSearch();
  document.getElementById('doSearch').addEventListener('click', function(){ss.parseSearchQuery();return false;});
  document.getElementById('searchQuery').value = searchQueryTests[0];
}

window.addEventListener('load', setupTests);
