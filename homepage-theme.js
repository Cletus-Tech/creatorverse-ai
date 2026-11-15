(function(){
 'use strict';
 var key='cv-home-theme';
 var root=document.body;
 var html=document.documentElement;
 var themeLink=document.querySelector('link[href*="homepage-theme.css"]');
 /* layout.js injects shared styles dynamically; move this page-specific stylesheet after them
    so its theme rules win the cascade instead of being silently overwritten by the reference skin. */
 if(themeLink&&themeLink.parentNode)themeLink.parentNode.appendChild(themeLink);
 var buttons=Array.prototype.slice.call(document.querySelectorAll('[data-cv-theme-choice]'));
 if(!root||!root.classList.contains('cv-home-page')||!buttons.length)return;
 var saved=null;try{saved=localStorage.getItem(key)}catch(e){}
 var current=saved==='light'||saved==='dark'?saved:'dark';
 function apply(theme,save){
  current=theme==='light'?'light':'dark';
  root.setAttribute('data-cv-theme',current);
  html.setAttribute('data-cv-home-theme',current);
  buttons.forEach(function(button){
   var active=button.getAttribute('data-cv-theme-choice')===current;
   button.setAttribute('aria-pressed',active?'true':'false');
  });
  var meta=document.querySelector('meta[name="theme-color"]');
  if(meta)meta.setAttribute('content',current==='light'?'#f3f8f2':'#07140f');
  if(save){try{localStorage.setItem(key,current)}catch(e){}}
 }
 buttons.forEach(function(button){button.addEventListener('click',function(){apply(button.getAttribute('data-cv-theme-choice'),true)})});
 apply(current,false);
})();