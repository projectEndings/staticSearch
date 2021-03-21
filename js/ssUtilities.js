
/*              ssUtilities.js             */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/** This file is part of the projectEndings staticSearch
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  * The code is licensed under both MPL and BSD.
  */

 /** WARNING:
   * This lib has "use strict" defined. You may
   * need to remove that if you are mixing this
   * code with non-strict JavaScript.
   */

/* jshint strict:false */
/* jshint esversion: 6*/
/* jshint strict: global*/
/* jshint browser: true */

"use strict";

/**
  * First some constant values for categorizing term types.
  * I would like to put these inside the class, but I can't
  * find an elegant way to do that.
  */
/**
  * @constant PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN, WILDCARD
  * @type {Number}
  * @description Constants representing different types of search command. Note
  *              that WILDCARD is not currently used, but will be if the 
  *              implementation of wildcards is changed.
  */
  /** @type {!number} */
  const PHRASE               = 0;
  /** @type {!number} */
  const MUST_CONTAIN         = 1;
  /** @type {!number} */
  const MUST_NOT_CONTAIN     = 2;
  /** @type {!number} */
  const MAY_CONTAIN          = 3;
  /** @type {!number} */
  const WILDCARD             = 4;

/**@constant arrTermTypes
   * @type {Array}
   * @description array of PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN,
   *              WILDCARD used so we can easily iterate through them.
   */
  const arrTermTypes = [PHRASE, MUST_CONTAIN, MUST_NOT_CONTAIN, MAY_CONTAIN, WILDCARD];

/**
  * @constant TO_GET, GETTING, GOT, FAILED
  * @type {Number}
  * @description Constants representing states of files that may be
  *              retrieved by AJAX.
  */

  const TO_GET  = 0;
  const GETTING = 1;
  const GOT     = 2;
  const FAILED  = 3;

/**
  * Components in the ss namespace that are used by default, but
  * which may easily be overridden by the project.
  */
/**
  * Our handy namespace
  * @namespace ss
  */
  var ss = {};

/**
  * @property ss.captions
  * @type {Array}
  * @description ss.captions is the an array of languages (default contains
  * only en and fr), each of which has some caption properties. Extend
  * by adding new languages or replace if necessary.
  */
  //English
  ss.captions = [];
  ss.captions['en'] = {};
  ss.captions['en'].strSearching         = 'Searching...';
  ss.captions['en'].strDocumentsFound    = 'Documents found: ';
  ss.captions['en'][PHRASE]              = 'Exact phrase: ';
  ss.captions['en'][MUST_CONTAIN]        = 'Must contain: ';
  ss.captions['en'][MUST_NOT_CONTAIN]    = 'Must not contain: ';
  ss.captions['en'][MAY_CONTAIN]         = 'May contain: ';
  ss.captions['en'][WILDCARD]            = 'Wildcard term: ';
  ss.captions['en'].strScore             = 'Score: ';
  ss.captions['en'].strSearchTooBroad    = 'Your search is too broad. Include more letters in every term.';
  ss.captions['en'].strDiscardedTerms    = 'Not searched (too common or too short): ';
  ss.captions['en'].strShowMore          = 'Show more';
  ss.captions['en'].strShowAll           = 'Show all';
  ss.captions['en'].strTooManyResults    = 'Your search returned too many results. Include more filters or more search terms.'
  //French
  ss.captions['fr'] = {};
  ss.captions['fr'].strSearching         = 'Recherche en cours...';
  ss.captions['fr'].strDocumentsFound    = 'Documents localisés: ';
  ss.captions['fr'][PHRASE]              = 'Phrase exacte: ';
  ss.captions['fr'][MUST_CONTAIN]        = 'Doit contenir: ';
  ss.captions['fr'][MUST_NOT_CONTAIN]    = 'Ne doit pas contenir: ';
  ss.captions['fr'][MAY_CONTAIN]         = 'Peut contenir: ';
  ss.captions['fr'][WILDCARD]            = 'Caractère générique: ';
  ss.captions['fr'].strScore             = 'Score: ';
  ss.captions['fr'].strSearchTooBroad    = 'Votre recherche est trop large. Inclure plus de lettres dans chaque terme.';
  ss.captions['fr'].strDiscardedTerms    = 'Recherche inaboutie (termes trop fréquents ou trop brefs): ';
  ss.captions['fr'].strShowMore          = 'Montrez plus';
  ss.captions['fr'].strShowAll           = 'Montrez tout';
  ss.captions['fr'].strTooManyResults    = 'Votre recherche a obtenu trop de résultats. Il faut inclure plus de filtres ou plus de termes de recherche.';

/**
  * @property ss.stopwords
  * @type {Array}
  * @description a simple array of stopwords. Extend
  * by adding new items or replace if necessary. If a local
  * stopwords.json file exists, that will be loaded and overwrite
  * this set.
  */
  ss.stopwords = new Array('i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', 'should', 'now');
  