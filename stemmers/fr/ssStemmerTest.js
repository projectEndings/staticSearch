"use strict";

/* INLINE TEST DATA FOR TESTING FUNCTIONS */
var preflightData =[['jouer', 'joUer'],
 ['ennuie', 'ennuIe'],
 ['yeux', 'Yeux'],
 ['quand', 'qUand'],
 ['aïeux', 'aHieux'],
 ['exiguë', 'exiguHe']];
 
var RVR1R2Data=[['aimer', {rv: 'er', r1: 'er',  r2: '', rvof: 4, r1of: 4, r2of: 6}],
                ['voler', {rv: 'ler', r1: 'er',  r2: '', rvof: 3, r1of: 4, r2of: 6}],
                ['paris', {rv: 'is', r1: 'is',  r2: '', rvof: 4, r1of: 4, r2of: 6}],
                ['adorer', {rv: 'rer', r1: 'orer',  r2: 'er', rvof: 4, r1of: 3, r2of: 5}],
                ['fameusement', {rv: 'meusement', r1: 'eusement',  r2: 'ement', rvof: 3, r1of: 4, r2of: 7}]];

var step1aData = [['vacances', 'vacances'], ['surréalisme', 'surréal']];

var testData;
var errorCount = 0;
var xmlhttp = new XMLHttpRequest();
xmlhttp.onreadystatechange = function() {
  if (this.readyState == 4 && this.status == 200) {
    testData = JSON.parse(this.responseText);
    runTests();
  }
};
xmlhttp.open("GET", "ssStemmerTestData.json", true);
xmlhttp.send();

var ssStemmer;

function runTests(){
  showLog('Retrieved test file ' + testData.title, 'ok');
  showLog('Test data has ' + testData.voc.length + ' input vocabulary items, and ' + testData.output.length + ' output items.', 'ok');
  ssStemmer = new(SSStemmer);
  for (var i=0; i<preflightData.length; i++){
    let result = ssStemmer.preflight(preflightData[i][0]);
    showTestLog('preflight', preflightData[i][0], preflightData[i][1], result);
  }
  for (var i=0; i<RVR1R2Data.length; i++){
    let result = ssStemmer.getRVR1R2(RVR1R2Data[i][0]);
    let jsonResult = JSON.stringify(result);
    let jsonExpected = JSON.stringify(RVR1R2Data[i][1]);
    showTestLog('getRVR1R2', RVR1R2Data[i][0], jsonExpected, jsonResult);
  }
  for (var i=0; i<step1aData.length; i++){
    let RVR1R2 = ssStemmer.getRVR1R2(step1aData[i][0])
    let r2of = RVR1R2.r2of;
    var result = ssStemmer.step1a(step1aData[i][0], r2of);
    showTestLog('step1a', step1aData[i][0], step1aData[i][1], result);
  }
  /*for (var i=0; i<step0Data.length; i++){
    var result = ssStemmer.step0(step0Data[i][0]);
    showTestLog('step0', step0Data[i][0], step0Data[i][1], result);
  }
  for (var i=0; i<wordIsShortData.length; i++){
    var r1of = ssStemmer.getR1AndR2(wordIsShortData[i][0]).r1of;
    var result = ssStemmer.wordIsShort(wordIsShortData[i][0], r1of);
    showTestLog('wordIsShort', wordIsShortData[i][0], wordIsShortData[i][1], result);
  }
  for (var i=0; i<step1Data.length; i++){
    var r1of = ssStemmer.getR1AndR2(step1Data[i][0]).r1of;
    var result = ssStemmer.step1(step1Data[i][0], r1of);
    showTestLog('step1', step1Data[i][0], step1Data[i][1], result);
  }
  for (var i=0; i<step2Data.length; i++){
    var r1of = ssStemmer.getR1AndR2(step2Data[i][0]).r1of;
    var result = ssStemmer.step2(step2Data[i][0], r1of);
    showTestLog('step2', step2Data[i][0], step2Data[i][1], result);
  }
  for (var i=0; i<step3Data.length; i++){
    var R1R2 = ssStemmer.getR1AndR2(step2Data[i][0])
    var r1of = R1R2.r1of;
    var r2of = R1R2.r2of;
    var result = ssStemmer.step3(step3Data[i][0], r1of, r2of);
    showTestLog('step3', step3Data[i][0], step3Data[i][1], result);
  }
  for (var i=0; i<step4Data.length; i++){
    var r2of = ssStemmer.getR1AndR2(step4Data[i][0]).r2of;
    var result = ssStemmer.step4(step4Data[i][0], r2of);
    showTestLog('step4', step4Data[i][0], step4Data[i][1], result);
  }
  for (var i=0; i<step5Data.length; i++){
    var R1R2 = ssStemmer.getR1AndR2(step5Data[i][0])
    var r1of = R1R2.r1of;
    var r2of = R1R2.r2of;
    var result = ssStemmer.step5(step5Data[i][0], r1of, r2of);
    showTestLog('step5', step5Data[i][0], step5Data[i][1], result);
  }
  for (var i=0; i<stemData.length; i++){
    var result = ssStemmer.stem(stemData[i][0]);
    showTestLog('stem', stemData[i][0], stemData[i][1], result);
  }
  for (var i=0; i<testData.voc.length; i++){
    var result = ssStemmer.stem(testData.voc[i]);
    showTestLog('stem', testData.voc[i], testData.output[i], result);
  }*/
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
    errorCount++;
    document.getElementById('errorCount').innerHTML = errorCount;
    showLog('Input ' + input + ' to function ' + func+ ' gave result ' + result + ' instead of ' + expected + '!', 'broken');
  }
}
