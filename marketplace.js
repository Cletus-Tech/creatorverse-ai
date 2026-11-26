(function(){
'use strict';
var sb=null, listings=[], categories=[], session=null;
var MARKET_BUCKET='marketplace-listing-images',MAX_IMAGE_BYTES=5*1024*1024,MAX_IMAGES=5;
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
 var sort=(($('market-sort')||{}).value||'newest');
 rows.sort(function(a,b){
  if(sort==='price-low')return (a.price_ngn==null?Number.MAX_SAFE_INTEGER:Number(a.price_ngn))-(b.price_ngn==null?Number.MAX_SAFE_INTEGER:Number(b.price_ngn));
  if(sort==='price-high')return (b.price_ngn==null?-1:Number(b.price_ngn))-(a.price_ngn==null?-1:Number(a.price_ngn));
  return new Date(b.created_at||0).getTime()-new Date(a.created_at||0).getTime();
 });
 $('market-count').textContent=rows.length+' approved listing'+(rows.length===1?'':'s');
 if(!rows.length){host.innerHTML='<div class="market-empty">No approved listings match these filters yet. Try another search or check back soon.</div>';return}
 host.innerHTML=rows.map(function(x){
  var photo=(x.image_urls&&x.image_urls.length)?x.image_urls[0]:'';
  var category=categories.find(function(c){return c.id===x.category_id});
  return '<article class="market-listing"><a class="market-listing-link" href="marketplace-item.html?id='+encodeURIComponent(x.id)+'" aria-label="View '+escapeText(x.title)+'">'+(photo?'<img class="market-listing-photo" src="'+escapeText(photo)+'" alt="" loading="lazy" referrerpolicy="no-referrer">':'<div class="market-listing-placeholder">CreatorVerse Marketplace</div>')+
  '<div class="market-listing-body"><span class="market-listing-tag">'+escapeText(category?category.name:x.listing_type)+'</span><h3>'+escapeText(x.title)+'</h3><p>'+escapeText(x.description)+'</p><strong class="market-price">'+money(x.price_ngn)+'</strong><small>'+escapeText([x.campus,x.institution].filter(Boolean).join(' · ')||x.location_label||'Campus listing')+'</small><span class="market-view-link">View listing →</span></div></a></article>';
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
  status(listings.length?'Showing approved listings. Add eligible products to your cart and follow purchases in My orders.':'Marketplace is connected. No approved listings have been published yet.');
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
 var payload={display_name:String(data.get('display_name')||'').trim(),seller_type:String(data.get('seller_type')||'student'),institution:String(data.get('institution')||'').trim()||null,campus:String(data.get('campus')||'').trim()||null,bio:String(data.get('bio')||'').trim()||null,bank_name:String(data.get('bank_name')||'').trim(),account_name:String(data.get('account_name')||'').trim(),account_number:String(data.get('account_number')||'').trim()};
 b.disabled=true;feedback('Submitting seller application and payout details…');
 try{
  var result=await sb.rpc('marketplace_submit_seller_application_v2',{p_display_name:payload.display_name,p_seller_type:payload.seller_type,p_institution:payload.institution,p_campus:payload.campus,p_bio:payload.bio,p_bank_name:payload.bank_name,p_account_name:payload.account_name,p_account_number:payload.account_number});
  if(result.error)throw result.error;
  feedback('Application submitted. Your seller profile and payout account are saved for administrator review.');
  f.reset();f.querySelectorAll('input,select,textarea,button[type=submit]').forEach(function(el){el.disabled=true});
 }catch(err){feedback(/duplicate|unique|already exists/i.test(err.message)?'You already have a seller application. Contact support if you need help.':err.message||'Could not submit application. Please try again.')}
 finally{b.disabled=false}
}

async function loadSellerWorkspace(){
 var host=$('seller-workspace-content');if(!host)return;
 if(!sb){host.textContent='Account services are loading…';return}
 var auth=await sb.auth.getSession(),current=auth.data&&auth.data.session;
 if(!current){host.innerHTML='<div class="market-empty">Sign in to manage your seller profile and listings. <a href="login.html?next=marketplace.html">Sign in</a></div>';return}
 var seller=await sb.from('marketplace_sellers').select('id,display_name,status,review_note').eq('user_id',current.user.id).maybeSingle();
 if(seller.error){host.textContent='Seller workspace will be available after the Marketplace database is enabled.';return}
 if(!seller.data){host.innerHTML='<div class="market-empty">You do not have a seller profile yet. Use “Become a seller” to apply.</div>';return}
 var profile=seller.data,editingListing=null;
 var badge=profile.status==='verified'?'Verified seller':profile.status==='pending'?'Application under review':profile.status==='rejected'?'Application needs attention':'Seller account suspended';
 host.innerHTML='<div class="seller-summary"><div><strong>'+escapeText(profile.display_name)+'</strong><span>'+escapeText(badge)+'</span>'+(profile.review_note?'<p>'+escapeText(profile.review_note)+'</p>':'')+'</div></div><div id="seller-listing-tools"></div><div id="seller-own-listings" class="seller-own-listings">Loading your listings…</div>';
 var tools=$('seller-listing-tools');
 if(profile.status==='verified'){
  tools.innerHTML='<div class="seller-management-links"><a class="market-secondary" href="marketplace-commerce.html?view=seller-orders">Manage customer orders</a><a class="market-secondary" href="marketplace-commerce.html?view=seller-payout">Manage payout account</a></div><button class="market-action" id="new-listing-open" type="button">Create a listing</button><form id="new-listing-form" class="seller-listing-form" hidden><h3>New listing</h3><input type="hidden" name="listing_id"><label>Title<input name="title" required minlength="4" maxlength="100"></label><label>Description<textarea name="description" required minlength="10" maxlength="3000" rows="4"></textarea></label><div class="seller-form-grid"><label>Category<select name="category_id" required></select></label><label>Listing type<select name="listing_type"><option value="product">Product</option><option value="service">Service</option><option value="rental">Rental</option><option value="free">Free</option></select></label><label>Price (₦)<input name="price_ngn" type="number" min="0" step="1" placeholder="Leave blank for price on request"></label><label>Quantity available<input name="quantity_available" type="number" min="1" max="9999" value="1" required></label><label>Condition<select name="item_condition"><option value="not_applicable">Not applicable</option><option value="new">New</option><option value="like_new">Like new</option><option value="good">Good</option><option value="fair">Fair</option></select></label><label>Campus / area<input name="campus" maxlength="120"></label><label>Institution<input name="institution" maxlength="120"></label><label>Pickup / location details<input name="location_label" maxlength="160"></label><label>SKU (optional)<input name="sku" maxlength="80"></label><label>Listing photos (up to 5)<input name="image_files" type="file" accept="image/jpeg,image/png,image/webp,image/avif" multiple></label><small class="seller-upload-help">Upload new photos to replace the current listing photos. JPG, PNG, WebP or AVIF · max 5 MB each.</small><div id="listing-existing-images" class="seller-image-preview"></div><label class="seller-check"><input name="negotiable" type="checkbox"> Price is negotiable</label><label class="seller-check"><input name="shipping_required" type="checkbox" checked> Requires delivery / shipping</label></div><div class="seller-form-actions"><button class="market-action" type="submit">Publish listing</button><button class="market-secondary" id="new-listing-cancel" type="button">Cancel</button></div><p id="listing-feedback" role="status"></p></form>';
  var form=$('new-listing-form'),select=form.querySelector('[name="category_id"]');categories.forEach(function(c){var o=document.createElement('option');o.value=c.id;o.textContent=c.name;select.appendChild(o)});
  function resetEditor(){editingListing=null;form.reset();form.hidden=true;form.querySelector('h3').textContent='New listing';form.querySelector('button[type=submit]').textContent='Publish listing';$('listing-existing-images').innerHTML=''}
  $('new-listing-open').addEventListener('click',function(){resetEditor();form.hidden=false});
  $('new-listing-cancel').addEventListener('click',resetEditor);
  window.CV_MARKETPLACE_EDIT_LISTING=function(row){
   editingListing=row;form.reset();form.hidden=false;form.querySelector('h3').textContent='Edit listing';form.querySelector('button[type=submit]').textContent='Save changes';
   form.elements.title.value=row.title||'';form.elements.description.value=row.description||'';form.elements.category_id.value=row.category_id||'';form.elements.listing_type.value=row.listing_type||'product';form.elements.price_ngn.value=row.price_ngn==null?'':row.price_ngn;form.elements.quantity_available.value=row.quantity_available||1;form.elements.item_condition.value=row.item_condition||'not_applicable';form.elements.campus.value=row.campus||'';form.elements.institution.value=row.institution||'';form.elements.location_label.value=row.location_label||'';form.elements.sku.value=row.sku||'';form.elements.negotiable.checked=!!row.negotiable;form.elements.shipping_required.checked=row.shipping_required!==false;
   $('listing-existing-images').innerHTML=(row.image_urls||[]).map(function(url){return '<img src="'+escapeText(url)+'" alt="Current listing photo">'}).join('');form.scrollIntoView({behavior:'smooth',block:'center'});
  };
  form.addEventListener('submit',async function(e){
   e.preventDefault();var fd=new FormData(form),btn=form.querySelector('button[type=submit]'),msg=$('listing-feedback'),price=String(fd.get('price_ngn')||'').trim(),files=Array.from(form.querySelector('[name="image_files"]').files||[]),uploaded=[];
   if(files.length>MAX_IMAGES){msg.textContent='Choose no more than '+MAX_IMAGES+' photos.';return}
   for(var i=0;i<files.length;i++){var file=files[i];if(!/^image\/(jpeg|png|webp|avif)$/.test(file.type)||file.size>MAX_IMAGE_BYTES){msg.textContent='Each photo must be JPG, PNG, WebP or AVIF and no larger than 5 MB.';return}}
   btn.disabled=true;msg.textContent=files.length?'Uploading photos…':'Saving listing…';
   try{
    for(var i=0;i<files.length;i++){var file=files[i],ext=({'image/jpeg':'jpg','image/png':'png','image/webp':'webp','image/avif':'avif'})[file.type],path=current.user.id+'/'+Date.now()+'-'+Math.random().toString(36).slice(2,10)+'-'+i+'.'+ext;var up=await sb.storage.from(MARK_BUCKET).upload(path,file,{cacheControl:'3600',contentType:file.type,upsert:false});if(up.error)throw up.error;uploaded.push(path)}
    var urls=uploaded.map(function(path){return sb.storage.from(MARK_BUCKET).getPublicUrl(path).data.publicUrl});
    var row={seller_id:profile.id,category_id:fd.get('category_id'),title:String(fd.get('title')).trim(),description:String(fd.get('description')).trim(),listing_type:fd.get('listing_type'),item_condition:fd.get('item_condition'),price_ngn:price===''?null:Number(price),quantity_available:Number(fd.get('quantity_available')||1),negotiable:fd.get('negotiable')==='on',location_label:String(fd.get('location_label')||'').trim()||null,institution:String(fd.get('institution')||'').trim()||null,campus:String(fd.get('campus')||'').trim()||null,sku:String(fd.get('sku')||'').trim()||null,shipping_required:fd.get('shipping_required')==='on',image_urls:urls.length?urls:(editingListing?(editingListing.image_urls||[]):[])};
    var wasEditing=!!editingListing,saved=wasEditing?await sb.from('marketplace_listings').update(row).eq('id',editingListing.id).eq('seller_id',profile.id).select('id').single():await sb.from('marketplace_listings').insert(row).select('id').single();
    if(saved.error)throw saved.error;
    msg.textContent=wasEditing?'Listing updated. Verified sellers do not need repeated listing approval.':'Listing published and live in the Marketplace.';
    resetEditor();await loadSellerListings(profile.id,current.user.id);
   }catch(err){if(uploaded.length)await sb.storage.from(MARK_BUCKET).remove(uploaded);msg.textContent=(/bucket not found|Bucket not found/i.test(err.message)?'Marketplace image storage is not enabled yet. ':'')+(err.message||'Could not save listing.')}
   finally{btn.disabled=false}
  });
 }
 await loadSellerListings(profile.id,current.user.id);
}
async function loadSellerListings(sellerId,userId){
 var host=$('seller-own-listings');if(!host)return;
 var result=await sb.from('marketplace_listings').select('id,title,description,category_id,listing_type,item_condition,price_ngn,quantity_available,negotiable,location_label,institution,campus,sku,shipping_required,image_urls,status,created_at,moderation_note').eq('seller_id',sellerId).order('created_at',{ascending:false}).limit(50);
 if(result.error){host.textContent='Could not load your listings: '+result.error.message;return}
 var rows=result.data||[];if(!rows.length){host.innerHTML='<div class="market-empty">You have not created any listings yet.</div>';return}
 host.innerHTML=rows.map(function(x){return '<article class="seller-own-row"><div><strong>'+escapeText(x.title)+'</strong><span>'+escapeText(x.status.replace('_',' '))+' · '+money(x.price_ngn)+'</span>'+(x.moderation_note?'<small>'+escapeText(x.moderation_note)+'</small>':'')+'</div><button type="button" class="market-secondary" data-edit-listing="'+escapeText(x.id)+'">Edit listing</button></article>'}).join('');
 host.querySelectorAll('[data-edit-listing]').forEach(function(button){button.addEventListener('click',function(){var row=rows.find(function(x){return x.id===button.getAttribute('data-edit-listing')});if(row&&window.CV_MARKETPLACE_EDIT_LISTING)window.CV_MARKETPLACE_EDIT_LISTING(row)})});
}

function init(){
 $('seller-open')&&$('seller-open').addEventListener('click',openSeller);
 $('seller-close')&&$('seller-close').addEventListener('click',function(){$('seller-dialog').close()});
 $('seller-form')&&$('seller-form').addEventListener('submit',submitSeller);
 ['market-query','market-institution','market-category','market-kind','market-sort'].forEach(function(id){var el=$(id);if(el)el.addEventListener('input',render);if(el)el.addEventListener('change',render)});
 $('market-search')&&$('market-search').addEventListener('submit',function(e){e.preventDefault();render();$('live-market').scrollIntoView({behavior:'smooth',block:'start'})});
 if(window.CV_SB){sb=window.CV_SB;loadCatalogue();loadSellerWorkspace()}
 document.addEventListener('cv-ready',function(){sb=window.CV_SB;loadCatalogue();loadSellerWorkspace()},{once:true});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();