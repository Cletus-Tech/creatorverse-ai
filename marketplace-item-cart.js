(function(){'use strict';
function add(){
 var root=document.getElementById('market-item-content');if(!root)return;
 var actions=root.querySelector('.market-detail-actions'),tag=root.querySelector('.market-listing-tag');
 if(!actions||!tag||actions.querySelector('#market-add-to-cart'))return;
 var type=tag.textContent.trim().toLowerCase();
 if(type==='service'||type==='rental')return;
 var stockNode=root.querySelector('#market-item-stock');
 var stock=stockNode?Number(stockNode.getAttribute('data-stock')):NaN;
 var b=document.createElement('button');b.type='button';b.id='market-add-to-cart';b.className='market-action';
 var msg=document.getElementById('market-item-feedback');
 if(!Number.isFinite(stock)){
  b.textContent='Stock unavailable';b.disabled=true;
  if(msg)msg.textContent='Stock information could not be loaded. Refresh this listing before adding it to your cart.';
 }else if(stock<1){
  b.textContent='Out of stock';b.disabled=true;
  if(msg)msg.textContent='This product is currently out of stock. Please check back later.';
 }else{
  b.textContent='Add to cart';
  if(msg)msg.textContent='Stock is checked again by the secure cart and checkout services.';
  b.onclick=async function(){
   b.disabled=true;
   try{
    var sb=window.CV_SB;if(!sb)throw new Error('Account services are loading. Try again shortly.');
    var a=await sb.auth.getSession(),u=a.data&&a.data.session&&a.data.session.user;
    if(!u){location.href='login.html?next='+encodeURIComponent('marketplace-item.html'+location.search);return}
    var id=new URLSearchParams(location.search).get('id');
    var r=await sb.rpc('marketplace_add_to_cart',{p_listing_id:id,p_quantity:1});
    if(r.error)throw r.error;
    b.textContent='Added to cart';b.disabled=true;
    if(msg)msg.textContent='Added to your cart. Your available stock is rechecked at checkout.';
   }catch(e){
    if(msg)msg.textContent=e.message||'Could not add this item to your cart.';
    b.disabled=false;
   }
  };
 }
 actions.insertBefore(b,actions.firstChild);
}
function init(){var root=document.getElementById('market-item-content');if(!root)return;var o=new MutationObserver(add);o.observe(root,{childList:true,subtree:true});add()}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();