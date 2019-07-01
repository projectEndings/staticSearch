"use strict";

//Create an instance of the search object.
var ss;

function setupTests(){
  ss = new StaticSearch();
  document.getElementById('doSearch').addEventListener('click', function(){ss.parseSearchQuery();return false;});
}

window.addEventListener('load', setupTests);
