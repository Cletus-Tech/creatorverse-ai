(function(){
'use strict';
var attempts=0;
function apply(){
 var cfg=window.CV_CONFIG;
 if(!cfg||!cfg.supabaseUrl||!cfg.supabaseAnonKey){
  if(attempts++<40)setTimeout(apply,150);
  return;
 }
 var url=cfg.supabaseUrl.replace(/\/$/,'')+'/rest/v1/site_content?select=key,value&key=eq.founder';
 fetch(url,{headers:{apikey:cfg.supabaseAnonKey,Authorization:'Bearer '+cfg.supabaseAnonKey}})
 .then(function(r){if(!r.ok)throw new Error('Social settings unavailable');return r.json()})
 .then(function(rows){
  if(!rows||!rows.length||!rows[0].value)return;
  var founder=JSON.parse(rows[0].value),socials=founder.socials||{};
  document.querySelectorAll('[data-social]').forEach(function(a){
   var value=socials[a.getAttribute('data-social')];
   if(typeof value==='string'&&/^https:\/\//i.test(value.trim())){
    a.href=value.trim();a.target='_blank';a.rel='noopener noreferrer';a.removeAttribute('aria-disabled');
   }
  });
 }).catch(function(){});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',apply,{once:true});else apply();
})();