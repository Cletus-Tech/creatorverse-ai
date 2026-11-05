(async function(){
function j(u){return fetch(u).then(function(r){return r.json()}).catch(function(){return null})}
var cfg=(await j('site.json'))||{},soc=cfg.socials||{};
var CC=window.CV_CONFIG||{},sc={};
if(CC.supabaseUrl&&CC.supabaseAnonKey){try{var rr=await fetch(CC.supabaseUrl+'/rest/v1/site_content?select=key,value',{headers:{apikey:CC.supabaseAnonKey,Authorization:'Bearer '+CC.supabaseAnonKey}});(await rr.json()).forEach(function(r){sc[r.key]=r.value})}catch(e){}}
if(sc.founder_photo)cfg.founderPhoto=sc.founder_photo;if(sc.intro_video)cfg.introVideo=sc.intro_video;
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
  main.textContent='';main.appendChild(node('h1','page-title','Learning Categories'));
  var intro=node('p','page-intro','Choose a skill area and explore the topics covered.');main.appendChild(intro);
  main.appendChild(link('Browse all courses','courses.html','btn btn-outline'));
  var grid=node('div','category-grid');
  cats.forEach(function(cat,i){
   var card=link('','category.html?c='+encodeURIComponent(cat.slug),'category-tile category-tone-'+(i%7+1));
   if(cat.image_url){var img=node('img','category-tile-image');img.src=cat.image_url;img.alt='';img.loading='lazy';img.onerror=function(){img.remove()};card.appendChild(img)}
   card.appendChild(node('span','category-tile-index',String(i+1).padStart(2,'0')));
   card.appendChild(node('h2','',cat.title));
   card.appendChild(node('p','',cat.description||'Explore practical lessons and projects in this category.'));
   card.appendChild(node('span','category-tile-link','Explore category →'));
   grid.appendChild(card);
  });
  main.appendChild(grid);
 }else{
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
