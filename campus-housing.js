(function(){
'use strict';
var $=function(id){return document.getElementById(id);};
var tabButtons=Array.from(document.querySelectorAll('[data-tab]'));
var tabIds={roommates:'tabRoommates',lodges:'tabLodges'};
var campus=$('campusSelect');
var campusLabel=$('currentCampusLabel');
var campusStorageKey='cv-housing-campus';
var validCampuses=campus?Array.from(campus.options).map(function(o){return o.value;}):[];

function activate(name,moveFocus){
 var room=name==='roommates';
 var activeId=room?'tabRoommates':'tabLodges';
 var panelId=room?'sectionRoommates':'sectionLodges';
 ['roommates','lodges'].forEach(function(key){
  var button=$(tabIds[key]);
  var panel=$(key==='roommates'?'sectionRoommates':'sectionLodges');
  var active=key===name;
  if(button){
   button.classList.toggle('active',active);
   button.setAttribute('aria-selected',String(active));
   button.setAttribute('tabindex',active?'0':'-1');
  }
  if(panel)panel.hidden=!active;
 });
 if(moveFocus&&$(activeId))$(activeId).focus();
 if(history.replaceState){
  try{var url=new URL(location.href);url.hash=name==='lodges'?'lodges':'roommates';history.replaceState(null,'',url.pathname+url.search+url.hash);}catch(e){}
 }
}

tabButtons.forEach(function(button){
 button.addEventListener('click',function(){activate(button.dataset.tab,false);});
});
['tabRoommates','tabLodges'].forEach(function(id){
 var button=$(id);if(!button)return;
 button.addEventListener('keydown',function(e){
  if(['ArrowLeft','ArrowRight','Home','End'].indexOf(e.key)<0)return;
  e.preventDefault();
  var next=e.key==='Home'?'roommates':e.key==='End'?'lodges':
   (button.id==='tabRoommates'?'lodges':'roommates');
  activate(next,true);
 });
});

if(campus&&campusLabel){
 try{
  var saved=sessionStorage.getItem(campusStorageKey);
  if(validCampuses.indexOf(saved)>-1)campus.value=saved;
 }catch(e){}
 campusLabel.textContent=campus.value;
 campusLabel.setAttribute('aria-live','polite');
 campus.addEventListener('change',function(){
  campusLabel.textContent=campus.value;
  try{sessionStorage.setItem(campusStorageKey,campus.value);}catch(e){}
 });
}

var initial=location.hash==='#lodges'?'lodges':'roommates';
activate(initial,false);

var reset=$('resetRoommateFilters');
if(reset)reset.addEventListener('click',function(){
 ['filterGender','filterBudget','filterSleep','filterCleanliness','filterLevel'].forEach(function(id){
  var field=$(id);if(field)field.value='all';
 });
});
})();