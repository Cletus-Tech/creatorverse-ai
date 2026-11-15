(function(){
 'use strict';
 var key='cv-home-theme';
 var buttons=Array.prototype.slice.call(document.querySelectorAll('[data-cv-theme-choice]'));
 if(!buttons.length)return;
 function apply(theme,save){
  theme=theme==='light'?'light':'dark';
  if(window.CVApplyTheme)window.CVApplyTheme(theme,save);
  else {
   document.body.setAttribute('data-cv-theme',theme);
   document.documentElement.setAttribute('data-cv-theme',theme);
   document.body.setAttribute('data-cv-home-theme',theme);
   if(save){try{localStorage.setItem(key,theme)}catch(e){}}
  }
  buttons.forEach(function(button){button.setAttribute('aria-pressed',button.getAttribute('data-cv-theme-choice')===theme?'true':'false')});
 }
 buttons.forEach(function(button){button.addEventListener('click',function(){apply(button.getAttribute('data-cv-theme-choice'),true)})});
 var saved='dark';try{var value=localStorage.getItem(key);if(value==='light'||value==='dark')saved=value}catch(e){}
 apply(saved,false);
})();