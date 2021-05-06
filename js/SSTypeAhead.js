
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
  *              
  */
  constructor(rootEl, filterData){
    this.rootEl = rootEl;
    this.input = this.rootEl.getElementsByTagName('input')[0];
    this.vals = vals;
    this.input.addEventListener('input', this.suggest.bind(this));
    this.input.addEventListener('keydown', this.keyOnInput.bind(this));
    this.input.setAttribute('autocomplete', 'off');
    this.rootEl.setAttribute('tabindex', '0');
    this.rootEl.addEventListener('keydown', function(e){this.escape(e);}.bind(this));
    this.menu = document.createElement('menu');
    this.rootEl.appendChild(this.menu);
    this.checkboxes = document.createElement('div');
    this.checkboxes.classList.add('ssSuggest');
    this.rootEl.appendChild(this.checkboxes);
    this.rootEl.addEventListener('blur', function(e){this.blurring(e);}.bind(this), true);
  }
  
  clearSuggestions(){
    this.menu.innerHTML = '';
  }
  
  clearCheckboxes(){
    this.checkboxes.innerHTML = '';
  }
  
  escape(e){
    if (e.which === 27){
      this.clearSuggestions();
    }
  }
  
  blurring(e){
    if (!e.currentTarget.contains(e.relatedTarget)){
      this.clearSuggestions();
    }
  }
  
  populate(){
    if (this.input.value.length < 3){
      return;
    }
    let re = new RegExp(this.input.value, 'i');
    for (let v of this.vals){
      if (v.match(re)){
        console.log(v);
        let d = document.createElement('div');
        d.setAttribute('data-val', v);
        d.classList.add('select');
        d.appendChild(document.createTextNode(v));
        d.setAttribute('tabindex', '0');
        d.addEventListener('click', function(e){this.select(e)}.bind(this));
        d.addEventListener('keydown', function(e){this.keyOnSelection(e);}.bind(this));
        this.menu.appendChild(d);
      }
    }
  }
  
  suggest(){
    this.clearSuggestions();
    this.populate();
  }
  
  keyOnInput(e){
    if ((e.which === 40)&&(this.menu.firstElementChild)){
      this.menu.firstElementChild.focus();
    }
  }
  
  keyOnSelection(e){
    let el = e.target;
    switch (e.which){
      case 13: 
        this.select(e);
        break;
      case 38:
        el.previousElementSibling ? el.previousElementSibling.focus() : this.input.focus();
        break;
      case 40:
        el.nextElementSibling ? el.nextElementSibling.focus() : el.parentNode.firstElementChild.focus();
        break;
      default:
    }
    
  }
  
  select(e){
    let val = e.target.getAttribute('data-val');
    //Check for an existing one:
    for (let c of this.checkboxes.querySelectorAll('span[data-val]')){
      if (c.getAttribute('data-val') == val){
        return;
      }
    }
    //Don't have one yet, so add one.
    let id = val.replace(/\W/g, '_');
    let s = document.createElement('span');
    s.setAttribute('data-val', val);
    let c = document.createElement('input');
    c.setAttribute('type', 'checkbox');
    c.setAttribute('checked', 'checked');
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
  
  removeCheckbox(e){
    e.target.parentNode.parentNode.removeChild(e.target.parentNode);
  }
  
}
