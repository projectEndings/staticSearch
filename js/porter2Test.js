"use strict";

/* INLINE TEST DATA FOR TESTING FUNCTIONS */
var preflightData =[["'yesterday", 'YesterdaY'],
 ['wayfair', 'waYfair'],
 ['knees', 'knees'],
 ['knell', 'knell'],
 ['abeyance', 'abeYance'],
 ['abjectness', 'abjectness'],
 ['able', 'able'],
 ['authenticity', 'authenticity'],
 ['bleed', 'bleed'],
 ['conversational', 'conversational']];
 
 var step0Data=[["apostrophe'", 'apostrophe'],
 ["authors'", 'authors'],
 ["apostrophe's'", 'apostrophe'],
 ['book', 'book'],
 ['knees', 'knees'],
 ['knell', 'knell'],
 ['able', 'able'],
 ['achilles', 'achilles'],
 ['authenticity', 'authenticity'],
 ['bleed', 'bleed'],
 ['conversational', 'conversational']];
 
 var R1R2Data=[['generates', {r1: 'ates',  r2: 'es', r1of: 6, r2of: 8}],
 ['communication', {r1: 'ication',  r2: 'ation', r1of: 7, r2of: 9}],
 ['asking', {r1: 'king',  r2: 'g', r1of: 3, r2of: 6}],
 ['adumbration', {r1: 'umbration',  r2: 'bration', r1of: 3, r2of: 5}],
 ['distortion', {r1: 'tortion',  r2: 'tion', r1of: 4, r2of: 7}],
 ['ow', {r1: '',  r2: '', r1of: 3, r2of: 3}],
 ['proceed', {r1: 'eed',  r2: '', r1of: 5, r2of: 8}],
 ['chickenfeed', {r1: 'kenfeed',  r2: 'feed', r1of: 5, r2of: 8}],
 ['beautiful', {r1: 'iful',  r2: 'ul', r1of: 6, r2of: 8}],
 ['beauty', {r1: 'y',  r2: '', r1of: 6, r2of: 7}],
 ['beau', {r1: '',  r2: '', r1of: 5, r2of: 5}],
 ['animadversion', {r1: 'imadversion',  r2: 'adversion', r1of: 3, r2of: 5}],
 ['sprinkled', {r1: 'kled',  r2: '', r1of: 6, r2of: 10}],
 ['eucharist', {r1: 'harist',  r2: 'ist', r1of: 4, r2of: 7}],
 ['knees', {r1: '',  r2: '', r1of: 6, r2of: 6}],
 ['knell', {r1: 'l',  r2: '', r1of: 5, r2of: 6}],
 ['abeYance', {r1: 'eYance',  r2: 'ance', r1of: 3, r2of: 5}],
 ['abilities', {r1: 'ilities',  r2: 'ities', r1of: 3, r2of: 5}],
 ['abjectness', {r1: 'jectness',  r2: 'tness', r1of: 3, r2of: 6}],
 ['able', {r1: 'le',  r2: '', r1of: 3, r2of: 5}],
 ['achilles', {r1: 'hilles',  r2: 'les', r1of: 3, r2of: 6}],
 ['authenticity', {r1: 'henticity',  r2: 'ticity', r1of: 4, r2of: 7}],
 ['bleed', {r1: '',  r2: '', r1of: 6, r2of: 6}],
 ['conversational', {r1: 'versational',  r2: 'sational', r1of: 4, r2of: 7}]];

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
  showLog('Retrieved test file ' + testData.title, 'ok');
  showLog('Test data has ' + testData.voc.length + ' input vocabulary items, and ' + testData.output.length + ' output items.', 'ok');
  var pt2 = new(PT2);
  for (var i=0; i<preflightData.length; i++){
    var result = pt2.preflight(preflightData[i][0]);
    showTestLog('preflight', preflightData[i][0], preflightData[i][1], result);
  }
  for (var i=0; i<step0Data.length; i++){
    var result = pt2.step0(step0Data[i][0]);
    showTestLog('step0', step0Data[i][0], step0Data[i][1], result);
  }
  for (var i=0; i<R1R2Data.length; i++){
    var result = pt2.getR1AndR2(R1R2Data[i][0]);
    if (Object.prototype.toString.call(result) == Object.prototype.toString.call(R1R2Data[i][1])){
      showLog('getR1AndR2 with input ' +  R1R2Data[i][0] + ' was correct: ' + Object.prototype.toString.call(result), 'ok');
    }
    else{
       showLog('getR1AndR2 with input ' +  R1R2Data[i][0] + ' was incorrect: ' + result, 'broken');
    }
  }
  
}

function showLog(msg, msgType){
  var li = document.createElement('li');
  li.setAttribute('class', msgType);
  var t = document.createTextNode(msg);
  li.appendChild(t);
  document.getElementById('log').appendChild(li);
}

function showTestLog(func, input, expected, result){
  if (expected === result){
    showLog('Input ' + input + ' to function ' + func + ' gave expected result ' + result, 'ok');
  }
  else{
    showLog('Input ' + input + ' to function ' + func+ ' gave result ' + result + ' instead of ' + expected + '!', 'broken');
  }
}
