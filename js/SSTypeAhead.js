
/*            SSTypeAhead.js               */
/* Authors: Martin Holmes and Joey Takeda. */
/*        University of Victoria.          */

/** This file is part of the projectEndings staticSearch
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  * The code is licensed under both MPL and BSD.
  */
  
/** @class SSTypeAhead
  * @description This class turns a text input control
  *              into a typeahead control that can generate
  *              label/checkbox groups for search filter 
  *              items based on a JSON dataset.
  */
  class SSTypeAhead{
/** 
  * constructor
  * @description The constructor receives two parameters, the
  *              containing element (usually a fieldset) and 
  *              the filter data that includes all the individual
  *              ids and values it needs to provide typeahead 
  *              functionality and generate label/checkbox groups
  *              from user selections.
  * @param {!Element} rootEl the wrapper element containing the 
  *              input control, and which will also contain the 
  *              generated content.
  * @param {!Object} filterData the set of filter data retrieved 
  *              as JSON by the StaticSearch instance which is 
  *              creating this control.
  * @param {!string} filterName the textual descriptive name of the 
  *              filter.
  *              
  */
  constructor(rootEl, filterData, filterName, minWordLength){
    this.rootEl = rootEl;
    this.filterData = filterData;
    this.filterName = filterName;
    this.minWordLength = minWordLength;
    this.reId = /^ssFeat\d+_\d+$/;
    //Because so much staticSearch filter handling is based on 
    //the string values of items rather than ids, we create a map
    //of values to ids.
    this.filterMap = new Map();
    for (let key of Object.keys(this.filterData)){
      if (this.reId.test(key)){
        this.filterMap.set(this.filterData[key].name, key);
      }
    };
    
    this.input = this.rootEl.getElementsByTagName('input')[0];
    this.input.addEventListener('input', this.suggest.bind(this));
    this.input.addEventListener('keydown', ss.debounce(function(e){this.keyOnInput(e);}.bind(this)), 500);
    this.input.setAttribute('autocomplete', 'off');
    this.rootEl.setAttribute('tabindex', '0');
    this.rootEl.addEventListener('keydown', function(e){this.escape(e.key);}.bind(this));
    this.menu = document.createElement('menu');
    this.rootEl.appendChild(this.menu);
    this.checkboxes = document.createElement('div');
    this.checkboxes.classList.add('ssSuggest');
    this.rootEl.appendChild(this.checkboxes);
    this.rootEl.addEventListener('click', function(e){this.blurringMenu(e);}.bind(this), true);

    //Flag to track whether we're already working.
    this.populating = false;
  }
  
  /** @function SSTypeAhead~clearSuggestions
  * @description This simply empties the drop-down suggestions menu.
  */
  clearSuggestions(){
    this.menu.innerHTML = '';
  }
  
  /** @function SSTypeAhead~escape
  * @description This is called when a key is pressed, and it simply 
                 clears the suggestions menu if the key is Escape.
  * @param {string} key the KeyboardEvent.key DOMString value for the key pressed.
  */
  escape(key){
    if (key === 'Escape'){
      this.clearSuggestions();
    }
  }
  
  /** @function SSTypeAhead~blurringMenu
  * @description This is called when the container root element is clicked.
  *              Its purpose is to clear the current suggestions menu when 
  *              the user stops interacting with the control. Along with the
  *              escape key, this gives the user a way to close the menu.
  * @param {Event} e the click event.
  */
  blurringMenu(e){
    if (e.target == e.currentTarget){
      this.clearSuggestions();
    }
  }
  
  /** @function SSTypeAhead~populate
  * @description This searches through the list of values for the control
  *              and creates a suggestion menu item for each one that 
  *              matches.
  */
  populate(){
    if ((this.populating)||(this.input.value.length < this.minWordLength)){
      return;
    }
    this.populating = true;
    try{
      let re = new RegExp(this.input.value, 'i');
      /*for (let i=2; i<Object.entries(this.filterData).length; i++){
        let id = Object.entries(this.filterData)[i][0];
        let name = Object.entries(this.filterData)[i][1].name;
        if ((name.match(re))&&(this.reId.test(id))){
          let d = document.createElement('div');
          d.setAttribute('data-val', name);
          d.setAttribute('data-id', id);
          d.classList.add('select');
          d.appendChild(document.createTextNode(name));
          d.setAttribute('tabindex', '0');
          d.addEventListener('click', function(e){this.select(e);}.bind(this));
          d.addEventListener('keydown', function(e){this.keyOnSelection(e);}.bind(this));
          this.menu.appendChild(d);
        }
      }*/
      //New approach from JT for more speed.
      // JT added new map approach
      this.filterMap.forEach((id, name) => {
        if (name.match(re) && this.reId.test(id)){
            let d = document.createElement('div');
            d.setAttribute('data-val', name);
            d.setAttribute('data-id', id);
            d.classList.add('select');
            d.appendChild(document.createTextNode(name));
            d.setAttribute('tabindex', '0');
            d.addEventListener('click', function(e){this.select(e);}.bind(this));
            d.addEventListener('keydown', function(e){this.keyOnSelection(e);}.bind(this));
            this.menu.appendChild(d); 
        }
      });
    }
    finally{
      this.populating = false;
    }
  }
  
  /** @function SSTypeAhead~suggest
  * @description This clears existing suggestions and constructs a new set.
  */  
  suggest(){
    this.clearSuggestions();
    this.populate();
  }
  
  /** @function SSTypeAhead~keyOnInput
  * @description This is called when a key is pressed on the input, and if it's
  *              the down arrow, it navigates the focus down into the suggestion
  *              list.
  * @param {Event} e the KeyboardEvent for the key pressed.
  */  
  keyOnInput(e){
    if ((e.key === 'ArrowDown')&&(this.menu.firstElementChild)){
      this.menu.firstElementChild.focus();
      e.preventDefault();
    }
  }

  /** @function SSTypeAhead~keyOnSelection
  * @description This is called when a key is pressed on the menu, and if it's
  *              the down arrow, it navigates the focus down into the suggestion
  *              list.
  * @param {Event} e the KeyboardEvent for the key pressed.
  */    
  keyOnSelection(e){
    let el = e.target;
    switch (e.key){
      case 'Enter': 
        this.select(e);
        break;
      case 'ArrowUp':
        el.previousElementSibling ? el.previousElementSibling.focus() : this.input.focus();
        break;
      case 'ArrowDown':
        el.nextElementSibling ? el.nextElementSibling.focus() : el.parentNode.firstElementChild.focus();
        break;
      default:
    }
    e.preventDefault();
  }

  /** @function SSTypeAhead~select
  * @description This creates a new checkbox + label block for 
  *              the selected item in the menu, unless there is
  *              already one there.
  * @param {Event} e the KeyboardEvent for the key pressed.
  */     
  select(e){
    let id = e.target.getAttribute('data-id');
    let val = e.target.getAttribute('data-val');
    this.addCheckbox(val);
  }
  
  /** @function SSTypeAhead~addCheckbox
  * @description This creates a new checkbox + label block for 
  *              the selected item in the menu, or based on 
  *              a call from outside unless there is already 
  *              already one there, in which case we check it.
  * @param {!string} val the text value for the checkbox.
  */  
  addCheckbox(val){
    let id = this.filterMap.get(val);
    if (!id){return;}
    //Check for an existing one:
    for (let c of this.checkboxes.querySelectorAll('input')){
      if (c.getAttribute('id') == id){
        //We just check it if it's already there.
        c.checked = true;
        return;
      }
    }
    //Don't have one yet, so add one.
    let s = document.createElement('span');
    s.setAttribute('data-val', val);
    let c = document.createElement('input');
    c.setAttribute('type', 'checkbox');
    c.setAttribute('checked', 'checked');
    c.setAttribute('title', this.filterName);
    c.setAttribute('value', val);
    c.setAttribute('class', 'staticSearch_feat');
    c.setAttribute('id', id);
    s.appendChild(c);
    let l = document.createElement('label');
    l.setAttribute('for', id);
    l.appendChild(document.createTextNode(val));
    s.appendChild(l);
    let b = document.createElement('button');
    b.appendChild(document.createTextNode('\u2718'));
    b.addEventListener('click', function(e){this.removeCheckbox(e);}.bind(this));
    s.appendChild(b);
    this.checkboxes.appendChild(s);
  }
  
  /** @function SSTypeAhead~setCheckboxes
  * @description This is provided with an Array of value strings,
  *              and for each one, it either creates a new checkbox
  *              or checks an existing one; then checkboxes not 
  *              included in the array are unchecked. This allows the
  *              external caller to set the entire status of the control
  *              based e.g. on a URL query string.
  * @param {!Array} arrVals the Array of string values.
  */  
  setCheckboxes(arrVals){
  //First uncheck any existing items which aren't in the list.
    for (let c of this.checkboxes.querySelectorAll('input')){
      if (arrVals.indexOf(c.getAttribute('value')) < 0){
        c.checked = false;
      }
    }
  //Now create any new ones we need.
    for (let val of arrVals){
      this.addCheckbox(val);
    }
  }
  
  /** @function SSTypeAhead~removeCheckbox
  * @description This is called by e.g. a click on the little
  *              button that each checkbox block has, enabling
  *              its removal if the user doesn't want it any more.
  * @param {Event} e the event that triggers the removal.
  */   
  removeCheckbox(e){
    e.target.parentNode.parentNode.removeChild(e.target.parentNode);
  }
}
