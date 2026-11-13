(function(){
'use strict';
function el(tag,attrs,children){var n=document.createElement(tag);Object.keys(attrs||{}).forEach(function(k){if(k==='text')n.textContent=attrs[k];else n.setAttribute(k,attrs[k])});(children||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function msg(parent,text){parent.textContent=text}
function card(title,subtitle){return el('section',{class:'panel cv-market-admin-card'},[el('div',{class:'cv-market-admin-head'},[el('h3',{text:title}),el('p',{text:subtitle})])])}
function mount(root,sb,user,role){
 root.textContent='';
 if(role!=='admin'&&role!=='super_admin'){root.appendChild(el('div',{class:'note',text:'Marketplace administration requires an authorized administrator account.'}));return}
 var wrap=el('div',{class:'cv-market-admin'});
 wrap.appendChild(el('div',{class:'dash-hero'},[el('div',{},[el('h1',{text:'Marketplace control centre'}),el('p',{text:'Review seller applications, moderate listings and maintain marketplace trust. All actions use the existing CreatorVerse administrator access controls.'})])]));
 var stats=el('div',{class:'cv-market-admin-stats'});wrap.appendChild(stats);
 var tabs=el('div',{class:'cv-market-admin-tabs'}),sellerTab=el('button',{type:'button',class:'active',text:'Seller applications'}),listingTab=el('button',{type:'button',text:'Listing moderation'}),categoryTab=el('button',{type:'button',text:'Categories'});tabs.append(sellerTab,listingTab,categoryTab);wrap.appendChild(tabs);
 var content=el('div',{class:'cv-market-admin-content'});wrap.appendChild(content);root.appendChild(wrap);
 var sellers=[],listings=[],categories=[];
 function stat(label,value){return el('div',{class:'cv-market-admin-stat'},[el('strong',{text:String(value)}),el('span',{text:label})])}
 function loadStats(){Promise.all([sb.from('marketplace_sellers').select('id,status'),sb.from('marketplace_listings').select('id,status')]).then(function(r){stats.textContent='';if(r[0].error||r[1].error){stats.appendChild(stat('Marketplace database','Not enabled'));return}
 var ss=r[0].data||[],ll=r[1].data||[];stats.append(stat('Pending sellers',ss.filter(x=>x.status==='pending').length));stats.append(stat('Verified sellers',ss.filter(x=>x.status==='verified').length));stats.append(stat('Listings awaiting review',ll.filter(x=>x.status==='pending_review').length));stats.append(stat('Published listings',ll.filter(x=>x.status==='published').length));})}
 function setTab(active){[sellerTab,listingTab,categoryTab].forEach(b=>b.classList.toggle('active',b===active))}
 function sellersView(){
  content.textContent='Loading seller applications…';
  sb.from('marketplace_sellers').select('id,user_id,display_name,seller_type,institution,campus,bio,status,review_note,created_at').order('created_at',{ascending:false}).limit(250).then(function(r){
   content.textContent='';if(r.error){content.appendChild(el('div',{class:'note',text:'Could not load seller applications: '+r.error.message}));return}
   sellers=r.data||[];var box=card('Seller applications','Review applicants and control who is allowed to list products and services.');
   var filter=el('select',{},['all','pending','verified','rejected','suspended'].map(v=>el('option',{value:v,text:v==='all'?'All statuses':v.replace('_',' ')})));
   var search=el('input',{type:'search',placeholder:'Search seller, institution or campus'});var list=el('div',{class:'cv-market-admin-list'});
   box.append(filter,search,list);content.appendChild(box);
   function draw(){list.textContent='';var term=search.value.toLowerCase(),rows=sellers.filter(s=>(filter.value==='all'||s.status===filter.value)&&[s.display_name,s.institution,s.campus,s.seller_type].join(' ').toLowerCase().includes(term));
    if(!rows.length){list.appendChild(el('div',{class:'note',text:'No seller applications match this filter.'}));return}
    rows.forEach(function(s){var row=el('article',{class:'cv-market-admin-row'}),info=el('div',{},[el('strong',{text:s.display_name}),el('span',{text:[s.seller_type,s.institution,s.campus].filter(Boolean).join(' · ')}),el('p',{text:s.bio||'No description provided.'}),el('small',{text:'Applied '+new Date(s.created_at).toLocaleString()})]);
     var actions=el('div',{class:'cv-market-admin-actions'}),note=el('input',{type:'text',maxlength:'500',placeholder:'Review note (optional)'}),status=el('select',{},['pending','verified','rejected','suspended'].map(v=>el('option',{value:v,text:v.replace('_',' ')})));status.value=s.status;
     var save=el('button',{type:'button',class:'btn btn-primary',text:'Save decision'});save.addEventListener('click',function(){save.disabled=true;sb.from('marketplace_sellers').update({status:status.value,review_note:note.value.trim()||null}).eq('id',s.id).then(function(u){save.disabled=false;if(u.error){alert(u.error.message);return}s.status=status.value;s.review_note=note.value.trim()||null;draw();loadStats()})});
     actions.append(note,status,save);row.append(info,actions);list.appendChild(row)
    })
   }
   filter.addEventListener('change',draw);search.addEventListener('input',draw);draw();
  })
 }
 function listingsView(){
  content.textContent='Loading listing submissions…';
  sb.from('marketplace_listings').select('id,seller_id,category_id,title,description,listing_type,price_ngn,institution,campus,image_urls,status,moderation_note,created_at,marketplace_sellers(display_name)').order('created_at',{ascending:false}).limit(300).then(function(r){
   content.textContent='';if(r.error){content.appendChild(el('div',{class:'note',text:'Could not load listings: '+r.error.message}));return}
   listings=r.data||[];var box=card('Listing moderation','Approve safe listings for public discovery or reject listings that breach marketplace rules.');
   var filter=el('select',{},['all','pending_review','published','rejected','draft','archived','sold'].map(v=>el('option',{value:v,text:v==='all'?'All statuses':v.replace('_',' ')})));
   var search=el('input',{type:'search',placeholder:'Search title, seller or campus'}),list=el('div',{class:'cv-market-admin-list'});box.append(filter,search,list);content.appendChild(box);
   function draw(){list.textContent='';var term=search.value.toLowerCase(),rows=listings.filter(x=>(filter.value==='all'||x.status===filter.value)&&[x.title,x.description,x.institution,x.campus,x.marketplace_sellers&&x.marketplace_sellers.display_name].join(' ').toLowerCase().includes(term));
    if(!rows.length){list.appendChild(el('div',{class:'note',text:'No listings match this filter.'}));return}
    rows.forEach(function(x){var row=el('article',{class:'cv-market-admin-row'}),info=el('div',{},[el('strong',{text:x.title}),el('span',{text:(x.marketplace_sellers&&x.marketplace_sellers.display_name||'Seller')+' · '+x.listing_type+' · ₦'+(x.price_ngn==null?'—':Number(x.price_ngn).toLocaleString('en-NG'))}),el('p',{text:x.description}),el('small',{text:[x.institution,x.campus,x.status].filter(Boolean).join(' · ')})]);
     if(x.image_urls&&x.image_urls[0])info.appendChild(el('a',{href:x.image_urls[0],target:'_blank',rel:'noopener',text:'View listing image'}));
     var actions=el('div',{class:'cv-market-admin-actions'}),note=el('input',{type:'text',maxlength:'1000',placeholder:'Moderation note'});note.value=x.moderation_note||'';
     var status=el('select',{},['pending_review','published','rejected','archived','sold'].map(v=>el('option',{value:v,text:v.replace('_',' ')})));status.value=x.status==='draft'?'pending_review':x.status;
     var save=el('button',{type:'button',class:'btn btn-primary',text:'Save moderation'});save.addEventListener('click',function(){save.disabled=true;sb.from('marketplace_listings').update({status:status.value,moderation_note:note.value.trim()||null}).eq('id',x.id).then(function(u){save.disabled=false;if(u.error){alert(u.error.message);return}x.status=status.value;x.moderation_note=note.value.trim()||null;draw();loadStats()})});
     actions.append(note,status,save);row.append(info,actions);list.appendChild(row)
    })
   }
   filter.addEventListener('change',draw);search.addEventListener('input',draw);draw();
  })
 }
 function categoriesView(){
  content.textContent='Loading Marketplace categories…';
  sb.from('marketplace_categories').select('id,name,slug,description,active,position').order('position').then(function(r){
   content.textContent='';if(r.error){content.appendChild(el('div',{class:'note',text:r.error.message}));return}
   categories=r.data||[];var box=card('Marketplace categories','Organise discovery categories. Deactivation hides a category from public browsing while preserving existing listings.');
   var rows=el('div',{class:'cv-market-admin-list'});categories.forEach(function(c){var row=el('div',{class:'cv-market-category-row'}),name=el('strong',{text:c.name}),desc=el('span',{text:c.description||c.slug}),active=el('input',{type:'checkbox'});active.checked=c.active;var save=el('button',{type:'button',class:'btn btn-outline',text:'Save'});save.addEventListener('click',function(){save.disabled=true;sb.from('marketplace_categories').update({active:active.checked}).eq('id',c.id).then(function(u){save.disabled=false;if(u.error)alert(u.error.message);else c.active=active.checked})});row.append(name,desc,active,save);rows.appendChild(row)});
   box.appendChild(rows);content.appendChild(box);
  })
 }
 sellerTab.addEventListener('click',function(){setTab(sellerTab);sellersView()});listingTab.addEventListener('click',function(){setTab(listingTab);listingsView()});categoryTab.addEventListener('click',function(){setTab(categoryTab);categoriesView()});
 loadStats();sellersView();
}
window.CV_MARKETPLACE_ADMIN={mount:mount};
})();