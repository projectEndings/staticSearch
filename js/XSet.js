
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
  * adds some key operators which are missing from that class
  * in the current version of ECMAScript. Those methods are
  * named with a leading x in case a future version of ECMAScript
  * adds native versions.
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
/** @function XSet~xUnion
  * @param {!XSet} xSet2 another instance of the XSet class.
  * @description this computes the union of the two sets (all
  * items appearing in either set) and returns the result as
  * another XSet instance.
  * @return {!XSet} a new instance of XSet including all items
  * from both sets.
  */
  xUnion(xSet2){
    return new XSet([...this, ...xSet2]);
  }
/** @function XSet~xIntersection
  * @param {XSet} xSet2 another instance of the XSet class.
  * @description this computes the intersection of the two sets
  * (items appearing in both sets) and returns the result as
  * another XSet instance.
  * @return {XSet} a new instance of XSet only the items
  * appearing in both sets.
  */
  xIntersection(xSet2){
    return new XSet([...this].filter(x => xSet2.has(x)));
  }
/** @function XSet~xDifference
  * @param {XSet} xSet2 another instance of the XSet class.
  * @description this computes the set of items which appear
  * in this set but not in the parameter set.
  * @return {XSet} a new instance of XSet only the items
  * which appear in this set but not in xSet2.
  */
  xDifference(xSet2){
    return new XSet([...this].filter(x => !xSet2.has(x)));
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
