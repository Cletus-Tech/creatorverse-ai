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
if(pg==='about'&&sc.about_text&&main){main.textContent='';var t1=document.createElement('h1');t1.textContent='About CreatorVerse AI';main.appendChild(t1);sc.about_text.split(/\n\s*\n/).forEach(function(x){var pp=document.createElement('p');pp.textContent=x;main.appendChild(pp)});var ab=document.createElement('a');ab.className='btn btn-primary';ab.href='learn.html';ab.textContent='Explore Learning Categories';main.appendChild(ab)}
if(!main)return;
var p=new URLSearchParams(location.search).get('p');
if(pg==='learn'||pg==='category'){var cats=(await j('categories.json'))||[];
 if(pg==='learn')main.innerHTML='<h1>Learning Categories</h1><p>Pick a category, or <a href="courses.html" style="color:#bfe6ff">browse all courses</a>.</p><div class="panels" style="margin-top:20px">'+cats.map(function(c){return '<a class="skill-card" href="category.html?c='+c.slug+'"><h3 class="card-title">'+c.title+'</h3><p class="card-desc">'+c.description+'</p></a>'}).join('')+'</div>';
 else{var c=cats.filter(function(x){return x.slug===new URLSearchParams(location.search).get('c')})[0];
  main.innerHTML=c?'<h1>'+c.title+'</h1><p>'+c.description+'</p>'+(c.topics.length?'<h2>What this covers</h2><ul class="topics">'+c.topics.map(function(t){return '<li>'+t+'</li>'}).join('')+'</ul>':'')+'<a class="btn btn-primary" href="courses.html?c='+c.slug+'">View courses</a><a class="btn btn-outline" href="learn.html">All categories</a>':'<h1>Category not found</h1><a class="btn btn-outline" href="learn.html">All categories</a>'}}
if(pg==='soon'){var S={community:['Community','The creator community is in development.'],resources:['Resources','The resource library is in development.'],login:['Login','Accounts are in development. Login will open when registration launches.'],'get-started':['Get Started','Registration is in development and will open soon.']},s=S[p]||['Coming soon','This page is in development.'];
 main.innerHTML='<h1>'+s[0]+'</h1><div class="note">'+s[1]+'</div><a class="btn btn-primary" href="index.html">Back to Home</a>'}
if(pg==='legal'){var T={privacy:['Privacy Policy','Explain what data CreatorVerse AI collects (account details, learning progress, uploads, payment references), why, how long it is kept, who it is shared with, and how users can access, correct or delete it.'],terms:['Terms of Service','Cover account rules, acceptable use, user content, course access and payments, refunds, termination and liability.']},t=T[p]||T.privacy;
 main.innerHTML='<h1>'+t[0]+'</h1><div class="note"><strong>Draft outline, not final.</strong> This page needs real text reviewed by a qualified professional before launch.</div><p style="margin-top:20px">'+t[1]+'</p>'}
})();
