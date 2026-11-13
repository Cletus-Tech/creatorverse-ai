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

async function loadSellerWorkspace(){
 var host=$('seller-workspace-content');if(!host)return;
 if(!sb){host.textContent='Account services are loading…';return}
 var auth=await sb.auth.getSession();var current=auth.data&&auth.data.session;
 if(!current){host.innerHTML='<div class="market-empty">Sign in to manage your seller profile and listings. <a href="login.html?next=marketplace.html">Sign in</a></div>';return}
 var seller=await sb.from('marketplace_sellers').select('id,display_name,status,review_note').eq('user_id',current.user.id).maybeSingle();
 if(seller.error){host.textContent='Seller workspace will be available after the Marketplace database is enabled.';return}
 if(!seller.data){host.innerHTML='<div class="market-empty">You do not have a seller profile yet. Use “Become a seller” to apply.</div>';return}
 var profile=seller.data;
 var badge=profile.status==='verified'?'Verified seller':profile.status==='pending'?'Application under review':profile.status==='rejected'?'Application needs attention':'Seller account suspended';
 host.innerHTML='<div class="seller-summary"><div><strong>'+escapeText(profile.display_name)+'</strong><span>'+escapeText(badge)+'</span>'+(profile.review_note?'<p>'+escapeText(profile.review_note)+'</p>':'')+'</div></div><div id="seller-listing-tools"></div><div id="seller-own-listings" class="seller-own-listings">Loading your listings…</div>';
 var tools=$('seller-listing-tools');
 if(profile.status==='verified'){
  tools.innerHTML='<button class="market-action" id="new-listing-open" type="button">Create a listing</button><form id="new-listing-form" class="seller-listing-form" hidden><h3>New listing</h3><label>Title<input name="title" required minlength="4" maxlength="100"></label><label>Description<textarea name="description" required minlength="10" maxlength="3000" rows="4"></textarea></label><div class="seller-form-grid"><label>Category<select name="category_id" required></select></label><label>Listing type<select name="listing_type"><option value="product">Product</option><option value="service">Service</option><option value="rental">Rental</option><option value="free">Free</option></select></label><label>Price (₦)<input name="price_ngn" type="number" min="0" step="1" placeholder="Leave blank for price on request"></label><label>Condition<select name="item_condition"><option value="not_applicable">Not applicable</option><option value="new">New</option><option value="like_new">Like new</option><option value="good">Good</option><option value="fair">Fair</option></select></label><label>Campus / area<input name="campus" maxlength="120"></label><label>Institution<input name="institution" maxlength="120"></label><label>Image URL (optional)<input name="image_url" type="url" placeholder="https://…"></label></div><div class="seller-form-actions"><button class="market-action" type="submit">Save draft</button><button class="market-secondary" id="new-listing-cancel" type="button">Cancel</button></div><p id="listing-feedback" role="status"></p></form>';
  var select=tools.querySelector('[name="category_id"]');categories.forEach(function(c){var o=document.createElement('option');o.value=c.id;o.textContent=c.name;select.appendChild(o)});
  $('new-listing-open').addEventListener('click',function(){$('new-listing-form').hidden=false});
  $('new-listing-cancel').addEventListener('click',function(){$('new-listing-form').hidden=true});
  $('new-listing-form').addEventListener('submit',async function(e){
   e.preventDefault();var form=e.currentTarget,fd=new FormData(form),btn=form.querySelector('button[type=submit]'),msg=$('listing-feedback');
   var price=String(fd.get('price_ngn')||'').trim();var image=String(fd.get('image_url')||'').trim();
   var row={seller_id:profile.id,category_id:fd.get('category_id'),title:String(fd.get('title')).trim(),description:String(fd.get('description')).trim(),listing_type:fd.get('listing_type'),item_condition:fd.get('item_condition'),price_ngn:price===''?null:Number(price),institution:String(fd.get('institution')||'').trim()||null,campus:String(fd.get('campus')||'').trim()||null,image_urls:image?[image]:[]};
   btn.disabled=true;msg.textContent='Saving draft…';
   try{var saved=await sb.from('marketplace_listings').insert(row).select('id').single();if(saved.error)throw saved.error;msg.textContent='Draft saved. You can review it below and submit it when ready.';form.reset();await loadSellerListings(profile.id,current.user.id)}
   catch(err){msg.textContent=err.message||'Could not save listing.'}
   finally{btn.disabled=false}
  });
 }
 await loadSellerListings(profile.id,current.user.id);
}
async function loadSellerListings(sellerId,userId){
 var host=$('seller-own-listings');if(!host)return;
 var result=await sb.from('marketplace_listings').select('id,title,status,price_ngn,created_at,moderation_note').eq('seller_id',sellerId).order('created_at',{ascending:false}).limit(50);
 if(result.error){host.textContent='Could not load your listings: '+result.error.message;return}
 var rows=result.data||[];if(!rows.length){host.innerHTML='<div class="market-empty">You have not created any listings yet.</div>';return}
 host.innerHTML=rows.map(function(x){return '<article class="seller-own-row"><div><strong>'+escapeText(x.title)+'</strong><span>'+escapeText(x.status.replace('_',' '))+' · '+money(x.price_ngn)+'</span>'+(x.moderation_note?'<small>'+escapeText(x.moderation_note)+'</small>':'')+'</div>'+(x.status==='draft'||x.status==='rejected'?'<button type="button" class="market-secondary" data-submit-listing="'+escapeText(x.id)+'">Submit for review</button>':'')+'</article>'}).join('');
 host.querySelectorAll('[data-submit-listing]').forEach(function(button){button.addEventListener('click',async function(){button.disabled=true;try{var result=await sb.rpc('marketplace_submit_listing',{p_listing_id:button.getAttribute('data-submit-listing')});if(result.error)throw result.error;await loadSellerListings(sellerId,userId)}catch(e){button.disabled=false;alert(e.message||'Could not submit listing')}})});
}

function init(){
 $('seller-open')&&$('seller-open').addEventListener('click',openSeller);
 $('seller-close')&&$('seller-close').addEventListener('click',function(){$('seller-dialog').close()});
 $('seller-form')&&$('seller-form').addEventListener('submit',submitSeller);
 ['market-query','market-institution','market-category','market-kind'].forEach(function(id){var el=$(id);if(el)el.addEventListener('input',render);if(el)el.addEventListener('change',render)});
 $('market-search')&&$('market-search').addEventListener('submit',function(e){e.preventDefault();render();$('live-market').scrollIntoView({behavior:'smooth',block:'start'})});
 if(window.CV_SB){sb=window.CV_SB;loadCatalogue();loadSellerWorkspace();loadSellerWorkspace()}
 document.addEventListener('cv-ready',function(){sb=window.CV_SB;loadCatalogue()},{once:true});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();