"use strict";

var testData;  
var xmlhttp = new XMLHttpRequest();
xmlhttp.onreadystatechange = function() {
  if (this.readyState == 4 && this.status == 200) {
    testData = JSON.parse(this.responseText);
    runTests();
  }
};
xmlhttp.open("GET", "porter2TestData.json", true);
xmlhttp.send();

function runTests(){
  showLog('Retrieved test file ' + testData.title);
  showLog('Test data has ' + testData.voc.length + ' input vocabulary items, and ' + testData.output.length + ' output items.');
}

function showLog(msg){
  var li = document.createElement('li');
  var t = document.createTextNode(msg);
  li.appendChild(t);
  document.getElementById('log').appendChild(li);
}