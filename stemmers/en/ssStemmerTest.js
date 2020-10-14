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
 ['conversational', 'conversational'],
 ['knave', 'knave'],
 ['knaves', 'knaves'],
 ['knife', 'knife'],
 ['knives', 'knives'],
 ['badly', 'badly']];

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
 ['conversational', 'conversational'],
 ['knave', 'knave'],
 ['knaves', 'knaves'],
 ['knife', 'knife'],
 ['knives', 'knives'],
 ['badly', 'badly']];

 var step1Data=[['lasses', 'lass'],
 ['exceedingly', 'exceed'],
 ['ties', 'tie'],
 ['cries', 'cri'],
 ['gas', 'gas'],
 ['kiwis', 'kiwi'],
 ['cries', 'cri'],
 ['gaps', 'gap'],
 ['cry', 'cri'],
 ['by', 'by'],
 ['say', 'say'],
 ['knees', 'knee'],
 ['knell', 'knell'],
 ['abilities', 'abiliti'],
 ['abjectness', 'abjectness'],
 ['able', 'able'],
 ['achilles', 'achille'],
 ['authenticity', 'authenticiti'],
 ['bleed', 'bleed'],
 ['conversational', 'conversational'],
 ['knave', 'knave'],
 ['knaves', 'knave'],
 ['knife', 'knife'],
 ['knives', 'knive'],
 ['badly', 'badli']];

 var step2Data=[['abiliti', 'abiliti'],
 ['abjectness', 'abjectness'],
 ['able', 'able'],
 ['achille', 'achille'],
 ['authenticiti', 'authenticiti'],
 ['conversational', 'conversate'],
 ['knave', 'knave'],
 ['knife', 'knife'],
 ['knive', 'knive'],
 ['badli', 'bad']];

 var step3Data=[['abjectness', 'abject'],
 ['able', 'able'],
 ['achille', 'achille'],
 ['authenticiti', 'authentic'],
 ['conversate', 'conversate'],
 ['knave', 'knave'],
 ['knife', 'knife'],
 ['knive', 'knive']];

 var step4Data=[['abeYance', 'abeY'],
 ['able', 'able'],
 ['achille', 'achille'],
 ['knave', 'knave'],
 ['knife', 'knife'],
 ['knive', 'knive']];

 var step5Data=[['able', 'abl'],
 ['achille', 'achill'],
 ['knave', 'knave'],
 ['knife', 'knife'],
 ['knive', 'knive']];

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
 ['conversational', {r1: 'versational',  r2: 'sational', r1of: 4, r2of: 7}],
 ['knave', {r1: 'e', r2: '', r1of: 5, r2of: 6}],
 ['knaves', {r1: 'es', r2: '', r1of: 5, r2of: 7}],
 ['knife', {r1: 'e', r2: '', r1of: 5, r2of: 6}],
 ['knives', {r1: 'es', r2: '', r1of: 5, r2of: 7}],
 ['badly', {r1: 'ly', r2: '', r1of: 4, r2of: 6}]];

 var wordIsShortData=[['bed', true],
 ['shed', true],
 ['shred', true],
 ['bead', false],
 ['embed', false],
 ['beds', false],
 ['knees', false],
 ['knell', false],
 ['abeYance', false],
 ['abilities', false],
 ['abjectness', false],
 ['able', false],
 ['achilles', false],
 ['authenticity', false],
 ['bleed', false],
 ['conversational', false],
 ['knave', false],
 ['knaves', false],
 ['knife', false],
 ['knives', false],
 ['badly', false]];

 var stemData=[
                ['consign', 'consign'],
                ['consigned', 'consign'],
                ['consigning', 'consign'],
                ['consignment', 'consign'],
                ['consist', 'consist'],
                ['consisted', 'consist'],
                ['consistency', 'consist'],
                ['consistent', 'consist'],
                ['consistently', 'consist'],
                ['consisting', 'consist'],
                ['consists', 'consist'],
                ['consolation', 'consol'],
                ['consolations', 'consol'],
                ['consolatory', 'consolatori'],
                ['console', 'consol'],
                ['consoled', 'consol'],
                ['consoles', 'consol'],
                ['consolidate', 'consolid'],
                ['consolidated', 'consolid'],
                ['consolidating', 'consolid'],
                ['consoling', 'consol'],
                ['consolingly', 'consol'],
                ['consols', 'consol'],
                ['consonant', 'conson'],
                ['consort', 'consort'],
                ['consorted', 'consort'],
                ['consorting', 'consort'],
                ['conspicuous', 'conspicu'],
                ['conspicuously', 'conspicu'],
                ['conspiracy', 'conspiraci'],
                ['conspirator', 'conspir'],
                ['conspirators', 'conspir'],
                ['conspire', 'conspir'],
                ['conspired', 'conspir'],
                ['conspiring', 'conspir'],
                ['constable', 'constabl'],
                ['constables', 'constabl'],
                ['constance', 'constanc'],
                ['constancy', 'constanc'],
                ['constant', 'constant'],
                ['knack', 'knack'],
                ['knackeries', 'knackeri'],
                ['knacks', 'knack'],
                ['knag', 'knag'],
                ['knave', 'knave'],
                ['knaves', 'knave'],
                ['knavish', 'knavish'],
                ['kneaded', 'knead'],
                ['kneading', 'knead'],
                ['knee', 'knee'],
                ['kneel', 'kneel'],
                ['kneeled', 'kneel'],
                ['kneeling', 'kneel'],
                ['kneels', 'kneel'],
                ['knees', 'knee'],
                ['knell', 'knell'],
                ['knelt', 'knelt'],
                ['knew', 'knew'],
                ['knick', 'knick'],
                ['knif', 'knif'],
                ['knife', 'knife'],
                ['knight', 'knight'],
                ['knightly', 'knight'],
                ['knights', 'knight'],
                ['knit', 'knit'],
                ['knits', 'knit'],
                ['knitted', 'knit'],
                ['knitting', 'knit'],
                ['knives', 'knive'],
                ['knob', 'knob'],
                ['knobs', 'knob'],
                ['knock', 'knock'],
                ['knocked', 'knock'],
                ['knocker', 'knocker'],
                ['knockers', 'knocker'],
                ['knocking', 'knock'],
                ['knocks', 'knock'],
                ['knopp', 'knopp'],
                ['knot', 'knot'],
                ['knots', 'knot'],
                ['skis', 'ski'],
                ['dying', 'die'],
                ['news', 'news'],
                ['herrings', 'herring'],
                ['proceed', 'proceed']
              ];

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

function runTests(){
  showLog('Retrieved test file ' + testData.title, 'ok');
  showLog('Test data has ' + testData.voc.length + ' input vocabulary items, and ' + testData.output.length + ' output items.', 'ok');
  var ssStemmer = new(SSStemmer);
  for (var i=0; i<preflightData.length; i++){
    var result = ssStemmer.preflight(preflightData[i][0]);
    showTestLog('preflight', preflightData[i][0], preflightData[i][1], result);
  }
  for (var i=0; i<R1R2Data.length; i++){
    var result = ssStemmer.getR1AndR2(R1R2Data[i][0]);
    var jsonResult = JSON.stringify(result);
    var jsonExpected = JSON.stringify(R1R2Data[i][1]);
    showTestLog('getR1AndR2', R1R2Data[i][0], jsonExpected, jsonResult);
  }
  for (var i=0; i<step0Data.length; i++){
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
    errorCount++;
    document.getElementById('errorCount').innerHTML = errorCount;
    showLog('Input ' + input + ' to function ' + func+ ' gave result ' + result + ' instead of ' + expected + '!', 'broken');
  }
}
