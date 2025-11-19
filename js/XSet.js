
/*                 XSet.js                 */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/** This file is part of the projectEndings staticSearch
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  * The code is licensed under both MPL and BSD.
  */
  
/** @class XSet
  * @extends Set
  * @description This class inherits from the Set class but
  * adds a single property and a convenience function for 
  * adding items directly from an array.
  */
  class XSet extends Set{
/** 
  * constructor
  * @description The constructor receives a single optional parameter
  *              which if present is used by the ancestor Set object
  *              constructor.
  * @param {Iterable=} iterable An optional Iterable object. If an 
  *              iterable object is passed, all of its elements will 
  *              be added to the new XSet.
  *              
  */
  constructor(iterable){
    super(iterable);
    this.filtersActive = false; //Used when a set is empty, to distinguish
                             //between filters-active-but-no-matches-found
                             //and no-filters-selected.
  }

/** @function XSet~addArray
  * @param {!Array} arr an array of values that are to be added.
  * @description this is a convenience function for adding a set of
  * values in a single operation.
  */
  addArray(arr){
    for (let item of arr){
      this.add(item);
    }
  }
}
