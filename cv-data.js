(function(){var C=window.CV_CONFIG||{};
function legacy(){return fetch('categories.json').then(function(r){return r.json()}).catch(function(){return[]})}
window.CV_CATS=function(){if(!C.supabaseUrl||!C.supabaseAnonKey)return legacy();
 return fetch(C.supabaseUrl+'/rest/v1/categories?published=eq.true&order=position&select=slug,title,description,image_url,topics',{headers:{apikey:C.supabaseAnonKey,Authorization:'Bearer '+C.supabaseAnonKey}}).then(function(r){return r.json()}).then(function(d){return Array.isArray(d)&&d.length?d.map(function(x){return{slug:x.slug,title:x.title,description:x.description||'',image_url:x.image_url,topics:x.topics||[]}}):legacy()}).catch(legacy)}})();
