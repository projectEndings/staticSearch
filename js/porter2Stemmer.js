/*           porter2Stemmer.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/* This file is an implementation of the
 * Porter2 stemmer as described  here:
 *
 * https://snowballstem.org/algorithms/english/stemmer.html
 *
 * If is part of the projectEndings staticSearch
 * project.
 *
 * Free to anyone for any purpose, but
 * acknowledgement would be appreciated. */

"use strict";

/*  We use a class to put everything in our
 *  Pt2 'namespace' (= Porter2). */

class PT2{
  // A character class of vowels
    reVowel                       = /[aeiouy]/;
  //A character class of non-vowels
    reNonVowel                    = /[^aeiouy]/;
  // A regex for determining whether a token ends with a short syllable
    reEndsWithShortSyllable       = new RegExp(this.reVowel + this.reNonVowel + '[^aeiouywxY]$');
  // A regex for doubled consonants
    reDbl                         = /((bb)|(dd)|(ff)|(gg)|(mm)|(nn)|(pp)|(rr)|(tt))/;
  // A regular expression which returns R1, defined as "the region after
  // the first non-vowel following a vowel, or the end of the word if
  // there is no such non-vowel".
  //See exceptional cases below. It also returns R2 when applied to R1.
    reR1R2                        = new RegExp('^.*?' + this.vowel + this/nonVowel, '(.*)$');
  // A regular expression which for the exceptions: "If the words begins gener,
  // commun or arsen, set R1  to be the remainder of the word."
    reR1Except                    = /^(gener|commun|arsen)(.*)$/;
  // arrStep2Seq is an array of items, each of which is a three-item
  // array consisting of a suffix to match, a suffix to replace (which
  // may be the same, or may be shorter) and a replacement string.
  // NOTE: When browser support for lookbehinds is available, this
  // can be simplified.
    arrStep2Seq = [
                    ['ousness', 'ousness','ous'],
                    ['iveness', 'iveness','ive'],
                    ['fulness', 'fulness','ful'],
                    ['ization', 'ization','ize'],
                    ['ational', 'ational','ate'],
                    ['biliti', 'biliti','ble'],
                    ['tional', 'tional','tion'],
                    ['lessli', 'lessli','less'],
                    ['ousli', 'ousli','ous'],
                    ['fulli', 'fulli','ful'],
                    ['iviti', 'iviti','ive'],
                    ['entli', 'entli','ent'],
                    ['alism', 'alism','al'],
                    ['aliti', 'aliti','al'],
                    ['enci', 'enci','ence'],
                    ['anci', 'anci','ance'],
                    ['abli', 'abli','able'],
                    ['izer', 'izer','ize'],
                    ['ation', 'ation','ate'],
                    ['ator', 'ator','ate'],
                    ['alli', 'alli','al'],
                    ['bli', 'bli','ble'],
                    ['logi', 'ogi','og'],
                    ['[cdeghkmnrt]li', 'li', '']
                  ];
  // step3Seqis a list of suffixes to
  // be evaluated against a token; as soon as one is matched, the rest
  // are ignored, and if the match location is in R1 (or in R2 for
  // -ative, a replacement operation is done.
  // The format is:
  //   whichR, match, replacement
  // where whichR is either 1 or 2.
  // So for example: "ative" matches, but the match must be in R2 to
  // satisfy the condition.
    arrStep3Seq = [
                    [1, 'ational', 'ate'],
                    [1, 'tional', 'tion'],
                    [1, 'alize', 'al'],
                    [1, 'icate', 'ic'],
                    [1, 'iciti', 'ic'],
                    [2, 'ative', ''],
                    [1, 'ical', 'ic'],
                    [1, 'ness', ''],
                    [1, 'ful', '']
                  ];


}

/* VARIABLES */
