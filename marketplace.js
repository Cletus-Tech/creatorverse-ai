(function(){
'use strict';
var sb=null, listings=[], categories=[], session=null;
var $=function(id){return document.getElementById(id)};
function status(message){var el=$('market-status');if(el)el.textContent=message}
function feedback(message){var el=$('seller-feedback');if(el)el.textContent=message}
function money(value){if(value===null||value===undefined)return 'Price on request';if(Number(value)===0)return 'Free';return '₦'+Number(value).toLocaleString('en-NG')}
function safe(value){return String(value==null?'':value)}
function escapeText(value){return safe(value).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function render(){
 var host=$('market-listings');if(!host)return;
 var q=(($('market-query')||{}).value||'').trim().toLowerCase();
 var institution=(($('market-institution')||{}).value||'').trim().toLowerCase();
 var cat=(($('market-category')||{}).value||'');
 var kind=(($('market-kind')||{}).value||'');
 var rows=listings.filter(function(x){
  var hay=[x.title,x.description,x.institution,x.campus,x.location_label].join(' ').toLowerCase();
  return (!q||hay.indexOf(q)>-1)&&(!institution||safe(x.institution).toLowerCase().indexOf(institution)>-1)&&(!cat||x.category_id===cat)&&(!kind||x.listing_type===kind);
 });
 $('market-count').textContent=rows.length+' approved listing'+(rows.length===1?'':'s');
 if(!rows.length){host.innerHTML='<div class="market-empty">No approved listings match these filters yet. Try another search or check back soon.</div>';return}
 host.innerHTML=rows.map(function(x){
  var photo=(x.image_urls&&x.image_urls.length)?x.image_urls[0]:'';
  var category=categories.find(function(c){return c.id===x.category_id});
  return '<article class="market-listing">'+(photo?'<img class="market-listing-photo" src="'+escapeText(photo)+'" alt="" loading="lazy" referrerpolicy="no-referrer">':'<div class="market-listing-placeholder">CreatorVerse Marketplace</div>')+
  '<div class="market-listing-body"><span class="market-listing-tag">'+escapeText(category?category.name:x.listing_type)+'</span><h3>'+escapeText(x.title)+'</h3><p>'+escapeText(x.description)+'</p><strong class="market-price">'+money(x.price_ngn)+'</strong><small>'+escapeText([x.campus,x.institution].filter(Boolean).join(' · ')||x.location_label||'Campus listing')+'</small></div></article>';
 }).join('');
}
function fillCategories(){
 var select=$('market-category');if(!select)return;
 categories.forEach(function(c){var o=document.createElement('option');o.value=c.id;o.textContent=c.name;select.appendChild(o)});
}
async function loadCatalogue(){
 if(!sb)return;
 try{
  var c=await sb.from('marketplace_categories').select('id,name,active').eq('active',true).order('name');
  if(c.error)throw c.error;categories=c.data||[];fillCategories();
  var r=await sb.from('marketplace_listings').select('id,category_id,title,description,listing_type,price_ngn,location_label,institution,campus,image_urls,created_at').eq('status','published').order('created_at',{ascending:false}).limit(60);
  if(r.error)throw r.error;listings=r.data||[];render();
  status(listings.length?'Showing approved Marketplace listings. Checkout and order tracking are not enabled yet.':'Marketplace is connected. No approved listings have been published yet.');
 }catch(e){
  console.info('Marketplace catalogue is not available yet:',e.message);
  status('Marketplace preview: the database migration has not been applied or the catalogue is not available yet. You can still explore the planned categories.');
  var host=$('market-listings');if(host)host.innerHTML='<div class="market-empty">Live listings will appear here after the Marketplace database is enabled and sellers are approved.</div>';
 }
}
async function openSeller(){
 if(!sb){feedback('Account services are still loading. Please try again shortly.');return}
 var s=await sb.auth.getSession();session=s.data&&s.data.session;
 if(!session){location.href='login.html?next='+encodeURIComponent('marketplace.html');return}
 var d=$('seller-dialog');if(d&&d.showModal)d.showModal();
 try{
  var existing=await sb.from('marketplace_sellers').select('id,display_name,status,review_note').eq('user_id',session.user.id).maybeSingle();
  if(existing.error)throw existing.error;
  if(existing.data){feedback('Your seller application is '+existing.data.status+'.'+(existing.data.review_note?' Review note: '+existing.data.review_note:''));var f=$('seller-form');if(f){f.querySelectorAll('input,select,textarea,button[type=submit]').forEach(function(el){el.disabled=true})}}
 }catch(e){feedback('Seller applications will become available when the Marketplace database migration is applied.')}
}
async function submitSeller(e){
 e.preventDefault();if(!sb){feedback('Account services are unavailable.');return}
 var s=await sb.auth.getSession();session=s.data&&s.data.session;
 if(!session){location.href='login.html?next='+encodeURIComponent('marketplace.html');return}
 var f=$('seller-form'),b=f.querySelector('button[type=submit]'),data=new FormData(f);
 var payload={user_id:session.user.id,display_name:String(data.get('display_name')||'').trim(),seller_type:data.get('seller_type'),institution:String(data.get('institution')||'').trim()||null,campus:String(data.get('campus')||'').trim()||null,bio:String(data.get('bio')||'').trim()||null};
 b.disabled=true;feedback('Submitting your application…');
 try{
  var result=await sb.from('marketplace_sellers').insert(payload).select('id,status').single();
  if(result.error)throw result.error;
  feedback('Application submitted. Your seller profile is pending review. You will be able to create listings after verification.');
  f.reset();f.querySelectorAll('input,select,textarea,button[type=submit]').forEach(function(el){el.disabled=true});
 }catch(err){feedback(/duplicate|unique/i.test(err.message)?'You already have a seller application. Contact support if you need help.':/relation .* does not exist|schema cache/i.test(err.message)?'Seller applications are not live yet. The Marketplace database migration must be applied first.':err.message||'Could not submit application. Please try again.')}
 finally{b.disabled=false}
}
function init(){
 $('seller-open')&&$('seller-open').addEventListener('click',openSeller);
 $('seller-close')&&$('seller-close').addEventListener('click',function(){$('seller-dialog').close()});
 $('seller-form')&&$('seller-form').addEventListener('submit',submitSeller);
 ['market-query','market-institution','market-category','market-kind'].forEach(function(id){var el=$(id);if(el)el.addEventListener('input',render);if(el)el.addEventListener('change',render)});
 $('market-search')&&$('market-search').addEventListener('submit',function(e){e.preventDefault();render();$('live-market').scrollIntoView({behavior:'smooth',block:'start'})});
 if(window.CV_SB){sb=window.CV_SB;loadCatalogue()}
 document.addEventListener('cv-ready',function(){sb=window.CV_SB;loadCatalogue()},{once:true});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();