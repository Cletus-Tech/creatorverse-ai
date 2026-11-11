(async function(){
function j(u){return fetch(u).then(function(r){return r.json()}).catch(function(){return null})}
var cfg=(await j('site.json'))||{},soc=cfg.socials||{};
var CC=window.CV_CONFIG||{},sc={};
if(CC.supabaseUrl&&CC.supabaseAnonKey){try{var rr=await fetch(CC.supabaseUrl+'/rest/v1/site_content?select=key,value',{headers:{apikey:CC.supabaseAnonKey,Authorization:'Bearer '+CC.supabaseAnonKey}});(await rr.json()).forEach(function(r){sc[r.key]=r.value})}catch(e){}}
// Centralised, admin-managed CreatorVerse brand configuration.
var brand={};try{brand=sc.creatorverse_brand?JSON.parse(sc.creatorverse_brand):{}}catch(e){brand={}}
(function(){
 var primary=brand.logo_url||'assets/creatorverse-mark.svg',dark=brand.logo_dark_url||primary,light=brand.logo_light_url||primary;
 document.querySelectorAll('.nav-left .logo-mark img,.footer-brand-lockup img,.adm-logo img,.cv-clean-mark,.cv-gate-brand img,#authLoader .cv-auth-brand img,.brand-row .logo-mark img').forEach(function(im){
  var lightSurface=im.closest('.footer')||im.closest('.footer-brand-lockup');im.src=lightSurface?light:dark;im.onerror=function(){im.onerror=null;im.src=primary};
  if(brand.logo_size&&im.matches('.cv-clean-mark,.cv-gate-brand img')){im.style.width=Math.max(28,Math.min(96,Number(brand.logo_size)))+'px';im.style.height=im.style.width}
  if(brand.glow===false)im.style.filter='none';
 });
 if(brand.show_header===false)document.querySelectorAll('.nav-left .logo-mark').forEach(function(n){n.style.display='none'});
 if(brand.show_footer===false)document.querySelectorAll('.footer-brand-lockup img').forEach(function(n){n.style.display='none'});
 if(brand.show_gate===false){var gate=document.getElementById('cv-page-loader');if(gate)gate.style.display='none';var shared=document.querySelector('.cv-universal-gate');if(shared)shared.style.display='none'}
 var title=brand.gate_title||brand.wordmark||'CREATORVERSE',caption=(!brand.gate_caption||brand.gate_caption==='PREPARING YOUR EXPERIENCE')?'A NEW CHAPTER BEGINS HERE':brand.gate_caption;
 document.querySelectorAll('.cv-clean-wordmark,.cv-gate-brand span,.cv-auth-brand span').forEach(function(n){n.textContent=title});
 document.querySelectorAll('.cv-clean-status,.cv-gate-caption,.cv-auth-caption').forEach(function(n){if(n.classList.contains('cv-auth-caption'))n.textContent='Verifying your secure session…';else n.textContent=caption});
 document.querySelectorAll('.brand-name').forEach(function(n){n.textContent=brand.wordmark||'CreatorVerse'});
 document.querySelectorAll('.brand-sub').forEach(function(n){n.textContent=brand.tagline||'LEARN · CREATE · EARN · GROW'});
 var favicon=brand.favicon_url||primary;document.querySelectorAll('link[rel~="icon"]').forEach(function(n){n.href=favicon});
 var style=document.createElement('style');style.textContent='.cv-universal-gate .cv-gate-brand img,.cv-page-loader .cv-clean-mark{animation:'+(brand.gate_animation==='none'?'none':brand.gate_animation==='pulse'?'cvBrandPulse 2.2s ease-in-out infinite':'cvBrandFloat 2.8s ease-in-out infinite')+'!important} @keyframes cvBrandPulse{0%,100%{filter:drop-shadow(0 0 5px #3989ff44)}50%{filter:drop-shadow(0 0 20px #3989ffaa)}}';document.head.appendChild(style);
})();
if(sc.founder_photo)cfg.founderPhoto=sc.founder_photo;if(sc.intro_video)cfg.introVideo=sc.intro_video;
if(sc.founder){try{var founderSettings=JSON.parse(sc.founder),founderSocials=founderSettings.socials||{};Object.keys(founderSocials).forEach(function(k){if(typeof founderSocials[k]==='string'&&founderSocials[k].trim())soc[k]=founderSocials[k].trim()})}catch(e){}}
var hl=document.querySelector('.headline'),hs=document.querySelector('.sub');
if(hl&&sc.hero_title){var ls=sc.hero_title.split(/\n/).filter(Boolean);hl.textContent='';ls.forEach(function(t,i){if(i===ls.length-1&&ls.length>1){var sp=document.createElement('span');sp.className='accent';sp.textContent=t;hl.appendChild(sp)}else{hl.appendChild(document.createTextNode(t));if(i<ls.length-1)hl.appendChild(document.createElement('br'))}})}
if(hs&&sc.hero_text)hs.textContent=sc.hero_text;
if(sc.banner_text){var bn=document.createElement(sc.banner_link&&/^https?:\/\//.test(sc.banner_link)?'a':'div');bn.className='announce';bn.textContent=sc.banner_text;if(bn.tagName==='A'){bn.href=sc.banner_link;bn.target='_blank';bn.rel='noopener'}
 var mm=document.getElementById('content'),ft2=document.querySelector('footer.footer');if(mm)mm.insertBefore(bn,mm.firstChild);else if(ft2)ft2.parentNode.insertBefore(bn,ft2)}
document.querySelectorAll('[data-social]').forEach(function(a){var u=soc[a.dataset.social];
 if(u){a.href=u;a.target='_blank';a.rel='noopener'}else{a.removeAttribute('href');a.setAttribute('aria-disabled','true');a.title='Link not set yet'}});
var fc=document.getElementById('footer-contact');
if(fc&&cfg.contactEmail)fc.innerHTML='<h4>Contact</h4><a href="mailto:'+cfg.contactEmail+'">'+cfg.contactEmail+'</a>';
var fo=document.querySelector('.founder-card');
if(fo&&cfg.founderPhoto){fo.classList.add('has-photo');fo.innerHTML='<img src="'+cfg.founderPhoto+'" alt="Founder">'}
var w=document.getElementById('watch-intro');
if(w){var md=document.createElement('div');md.className='modal';md.innerHTML='<div class="modal-box"><button class="modal-x" aria-label="Close">&times;</button><div id="modal-body"></div></div>';document.body.appendChild(md);
 var body=md.querySelector('#modal-body');
 function close(){md.classList.remove('open');body.innerHTML=''}
 w.addEventListener('click',function(e){e.preventDefault();var v=cfg.introVideo;
  body.innerHTML=!v?'<p style="padding:30px 10px;color:var(--soft-gray)">The introduction video is coming soon.</p>':/\.(mp4|webm)$/i.test(v)?'<video src="'+v+'" controls autoplay></video>':'<iframe src="'+v+'" allow="autoplay; encrypted-media; fullscreen" allowfullscreen></iframe>';
  md.classList.add('open')});
 md.addEventListener('click',function(e){if(e.target===md||e.target.className==='modal-x')close()});
 document.addEventListener('keydown',function(e){if(e.key==='Escape')close()})}
var pg=document.body.dataset.page,main=document.getElementById('content');
if(pg==='about'&&sc.about_text&&main){var story=main.querySelector('.about-story-copy');if(story){story.textContent='';sc.about_text.split(/\n\s*\n/).filter(Boolean).forEach(function(x){var pp=document.createElement('p');pp.textContent=x;story.appendChild(pp)})}}
if(!main)return;
var p=new URLSearchParams(location.search).get('p');
if(pg==='about'&&sc.founder){try{var F=JSON.parse(sc.founder);if(F.show_about!==false&&(F.name||F.bio||F.photo)){var fb=document.createElement('section');fb.className='founder-about';
 if(F.photo){var im=document.createElement('img');im.src=F.photo;im.alt=F.name?'Portrait of '+F.name:'Founder';fb.appendChild(im)}
 var bx=document.createElement('div'),t1=document.createElement('h2');t1.textContent=F.name||'Founder';bx.appendChild(t1);
 if(F.designation){var d1=document.createElement('p');d1.className='fdes';d1.textContent=F.designation;bx.appendChild(d1)}
 (F.bio||'').split(/\n\s*\n/).filter(Boolean).forEach(function(x){var pp=document.createElement('p');pp.textContent=x;bx.appendChild(pp)});
 var sl=document.createElement('div');sl.className='fsoc';Object.keys(F.socials||{}).forEach(function(k){var u=F.socials[k];if(u&&/^https?:\/\//.test(u)){var a=document.createElement('a');a.href=u;a.target='_blank';a.rel='noopener';a.textContent=k.charAt(0).toUpperCase()+k.slice(1);sl.appendChild(a)}});if(sl.children.length)bx.appendChild(sl);
 fb.appendChild(bx);main.appendChild(fb)}}catch(e){}}
if(pg==='learn'||pg==='category'){
 var cats=await window.CV_CATS();
 function node(tag,cls,txt){var e=document.createElement(tag);if(cls)e.className=cls;if(txt!==undefined)e.textContent=txt;return e}
 function link(label,url,cls){var a=node('a',cls,label);a.href=url;return a}
 if(pg==='learn'){
  main.textContent='';
  main.classList.add('learn-discovery');
  var hero=node('section','learn-hero');
  var heroCopy=node('div','learn-hero-copy');
  heroCopy.appendChild(node('span','learn-kicker','CREATORVERSE ACADEMY  /  LEARN SOMETHING NEW'));
  var title=node('h1','learn-hero-title');title.appendChild(document.createTextNode('Your next big idea '));var accent=node('span','', 'starts here.');title.appendChild(accent);heroCopy.appendChild(title);
  heroCopy.appendChild(node('p','learn-hero-description','Explore practical skills, discover new interests and find the knowledge to turn what you imagine into something real.'));
  var searchWrap=node('form','learn-search');searchWrap.setAttribute('role','search');searchWrap.addEventListener('submit',function(e){e.preventDefault()});
  var searchIcon=node('span','learn-search-icon','⌕');searchIcon.setAttribute('aria-hidden','true');searchWrap.appendChild(searchIcon);
  var search=node('input','learn-search-input');search.type='search';search.placeholder='What would you like to learn today?';search.setAttribute('aria-label','Search learning categories');searchWrap.appendChild(search);
  var searchHint=node('span','learn-search-hint','SEARCH SKILLS');searchWrap.appendChild(searchHint);heroCopy.appendChild(searchWrap);
  var quick=node('div','learn-quick-links');quick.appendChild(node('span','','TRENDING:'));
  ['Artificial Intelligence','Design','Content Creation','Business'].forEach(function(term){var a=node('button','learn-quick-chip',term);a.type='button';a.addEventListener('click',function(){search.value=term;search.dispatchEvent(new Event('input'))});quick.appendChild(a)});heroCopy.appendChild(quick);
  hero.appendChild(heroCopy);
  var visual=node('div','learn-hero-visual');
  var visualImg=node('img','learn-hero-photo');visualImg.src='https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1100&q=85';visualImg.alt='Learners collaborating around a table';visualImg.loading='eager';visual.appendChild(visualImg);
  var visualShade=node('div','learn-hero-visual-shade');visual.appendChild(visualShade);
  var visualTag=node('div','learn-visual-tag');visualTag.appendChild(node('span','learn-visual-tag-dot',''));visualTag.appendChild(node('span','','LEARN AT YOUR OWN PACE'));visual.appendChild(visualTag);
  var visualNote=node('div','learn-visual-note');visualNote.appendChild(node('strong','','Curiosity looks good on you.'));visualNote.appendChild(node('span','','Start with one skill. Go further than you imagined.'));visual.appendChild(visualNote);
  hero.appendChild(visual);main.appendChild(hero);
  var intro=node('section','learn-section-head');var introCopy=node('div','');introCopy.appendChild(node('span','learn-section-kicker','FIND YOUR DIRECTION'));introCopy.appendChild(node('h2','','Explore learning categories'));introCopy.appendChild(node('p','','Choose an area that excites you. Your next skill could open a whole new path.'));intro.appendChild(introCopy);
  var count=node('div','learn-category-count');count.appendChild(node('strong','',String(cats.length).padStart(2,'0')));count.appendChild(node('span','','SKILL AREAS'));intro.appendChild(count);main.appendChild(intro);
  var grid=node('div','category-grid learn-category-grid');grid.setAttribute('aria-live','polite');
  cats.forEach(function(cat,i){
   var card=link('', 'category.html?c='+encodeURIComponent(cat.slug),'category-tile category-tone-'+(i%8+1));
   card.dataset.search=(cat.title+' '+(cat.description||'')+' '+(cat.topics||[]).join(' ')).toLowerCase();
   if(cat.image_url){var img=node('img','category-tile-image');img.src=cat.image_url;img.alt='';img.loading='lazy';img.onerror=function(){img.remove()};card.appendChild(img)}
   card.appendChild(node('span','category-tile-index',String(i+1).padStart(2,'0')));
   card.appendChild(node('span','learn-card-label','LEARNING PATH'));
   card.appendChild(node('h3','',cat.title));
   card.appendChild(node('p','',cat.description||'Explore practical lessons, useful knowledge and projects in this category.'));
   var foot=node('span','category-tile-link','Explore this area');foot.appendChild(node('b','learn-card-arrow','↗'));card.appendChild(foot);
   grid.appendChild(card);
  });
  main.appendChild(grid);
  var empty=node('div','learn-empty','No learning areas match that search yet. Try another skill or browse all categories.');empty.hidden=true;main.appendChild(empty);
  search.addEventListener('input',function(){var q=search.value.trim().toLowerCase(),visible=0;Array.prototype.forEach.call(grid.children,function(card){var show=!q||card.dataset.search.indexOf(q)!==-1;card.hidden=!show;if(show)visible++});empty.hidden=visible!==0;intro.querySelector('.learn-category-count strong').textContent=String(visible).padStart(2,'0')});
  var bottom=node('section','learn-bottom-cta');bottom.appendChild(node('span','learn-section-kicker','YOUR JOURNEY STARTS WITH A CHOICE'));bottom.appendChild(node('h2','','Make room for your next breakthrough.'));bottom.appendChild(node('p','','Ready to find a course and turn curiosity into capability?'));bottom.appendChild(link('Browse all courses','courses.html','learn-cta-button'));main.appendChild(bottom);
 }else{
  main.classList.add('category-detail-page');
  var cat=cats.filter(function(x){return x.slug===new URLSearchParams(location.search).get('c')})[0];
  main.textContent='';
  if(!cat){main.appendChild(node('h1','','Category not found'));main.appendChild(link('All categories','learn.html','btn btn-outline'))}
  else{
   var hero=node('section','category-detail-hero');
   if(cat.image_url){var img=node('img','category-detail-image');img.src=cat.image_url;img.alt='';img.onerror=function(){img.remove()};hero.appendChild(img)}
   var shade=node('div','category-detail-shade');hero.appendChild(shade);
   var body=node('div','category-detail-copy');body.appendChild(node('span','category-eyebrow','LEARNING CATEGORY'));body.appendChild(node('h1','',cat.title));body.appendChild(node('p','',cat.description||''));body.appendChild(link('Explore courses','courses.html?c='+encodeURIComponent(cat.slug),'btn btn-primary'));hero.appendChild(body);main.appendChild(hero);
   if(cat.topics&&cat.topics.length){main.appendChild(node('h2','category-topics-title','What you can learn'));var ul=node('ul','category-topics');cat.topics.forEach(function(topic){ul.appendChild(node('li','',topic))});main.appendChild(ul)}
   main.appendChild(link('← All categories','learn.html','btn btn-outline'));
  }
 }
}
if(pg==='soon'){var S={community:['Community','The creator community is in development.'],resources:['Resources','The resource library is in development.'],login:['Login','Accounts are in development. Login will open when registration launches.'],'get-started':['Get Started','Registration is in development and will open soon.']},s=S[p]||['Coming soon','This page is in development.'];
 main.innerHTML='<h1>'+s[0]+'</h1><div class="note">'+s[1]+'</div><a class="btn btn-primary" href="index.html">Back to Home</a>'}
if(pg==='legal'){var T={privacy:['Privacy Policy','Explain what data CreatorVerse AI collects (account details, learning progress, uploads, payment references), why, how long it is kept, who it is shared with, and how users can access, correct or delete it.'],terms:['Terms of Service','Cover account rules, acceptable use, user content, course access and payments, refunds, termination and liability.']},t=T[p]||T.privacy;
 main.innerHTML='<h1>'+t[0]+'</h1><div class="note"><strong>Draft outline, not final.</strong> This page needs real text reviewed by a qualified professional before launch.</div><p style="margin-top:20px">'+t[1]+'</p>'}
})();
