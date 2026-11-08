(function(){
var root=document.getElementById('home');if(!root)return;
var C=window.CV_CONFIG||{},HD=window.CV_HOME,Q=new URLSearchParams(location.search);
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function ico(p){var s=document.createElementNS('http://www.w3.org/2000/svg','svg');s.setAttribute('viewBox','0 0 24 24');s.setAttribute('fill','none');s.setAttribute('stroke','currentColor');s.setAttribute('stroke-width','2');s.setAttribute('stroke-linecap','round');s.setAttribute('stroke-linejoin','round');s.innerHTML=p;s.setAttribute('aria-hidden','true');return s}
var I={arrow:'<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',play:'<polygon points="6 3 20 12 6 21 6 3"/>',layers:'<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',clock:'<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',book:'<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>',check:'<path d="M20 6 9 17l-5-5"/>'};
function rest(p){return fetch(C.supabaseUrl+'/rest/v1/'+p,{headers:{apikey:C.supabaseAnonKey,Authorization:'Bearer '+C.supabaseAnonKey}}).then(function(r){return r.json()})}
function accent(el,t){String(t).split('\n').forEach(function(line,i,a){line.split('*').forEach(function(p,j){if(!p)return;el.appendChild(j%2?h('span',{class:'acc',text:p}):document.createTextNode(p))});if(i<a.length-1)el.appendChild(h('br'))})}
function btn(label,url,cls){return h('a',{class:'btn '+cls,href:url||'#'},[h('span',{text:label}),cls.indexOf('primary')>-1?ico(I.arrow):null])}
function embed(u,poster){var m=u.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]{6,})/);
 if(m)return{iframe:'https://www.youtube-nocookie.com/embed/'+m[1]+'?autoplay=1'};if(/^https:\/\/player\.vimeo\.com\//.test(u))return{iframe:u+(u.indexOf('?')>-1?'&':'?')+'autoplay=1'};
 if(/\.(mp4|webm|mov|m4v)(\?|$)/i.test(u))return{video:u};return null}
function modal(v){var md=h('div',{class:'modal open'}),box=h('div',{class:'modal-box'}),x=h('button',{class:'modal-x',type:'button','aria-label':'Close',text:'×'});
 function close(){md.remove();document.removeEventListener('keydown',esc)}function esc(e){if(e.key==='Escape')close()}
 function load(){body.textContent='';var e=embed(v.url);body.appendChild(e.iframe?h('iframe',{src:e.iframe,allow:'autoplay; encrypted-media; fullscreen',allowfullscreen:''}):h('video',{src:e.video,controls:'',autoplay:'',playsinline:'',poster:v.thumbnail||''}))}
 var body=h('div');x.addEventListener('click',close);md.addEventListener('click',function(e){if(e.target===md)close()});document.addEventListener('keydown',esc);
 var e=embed(v.url);if(v.thumbnail&&e&&e.iframe){body.appendChild(h('button',{class:'cover',type:'button','aria-label':'Play video',on:load},[h('img',{src:v.thumbnail,alt:''}),h('span',{class:'playdot'},[ico(I.play)])]))}else load();
 box.appendChild(x);box.appendChild(body);md.appendChild(box);document.body.appendChild(md)}
function hero(H){if(H.visible===false)return null;var P=H.portrait,F=H.founder,vid=H.video,e=vid.url?embed(vid.url):null;
 var copy=h('div',{class:'hero2-copy'},[h('span',{class:'chip2',text:'Your Digital Learning Partner'})]),t=h('h1');accent(t,H.title);copy.appendChild(t);copy.appendChild(h('p',{class:'lead',text:H.text}));
 var row=h('div',{class:'hero2-cta'});if(H.primary.visible!==false&&H.primary.label)row.appendChild(btn(H.primary.label,H.primary.url,'btn-primary'));
 if(H.secondary.visible!==false&&H.secondary.label&&vid.enabled&&e)row.appendChild(h('button',{class:'btn btn-outline',type:'button',id:'watch-intro',on:function(){modal(vid)}},[ico(I.play),h('span',{text:H.secondary.label})]));
 copy.appendChild(row);
 copy.appendChild(h('div',{class:'hero-proof'},[['Practical skills','Learn by doing'],['Creative tools','Build real projects'],['Community','Grow together']].map(function(x){return h('div',{class:'proof-item'},[h('strong',{text:x[0]}),h('span',{text:x[1]})])})));
 var art=null,cap=null;if(F.visible!==false&&(F.name||F.designation||F.description))cap=h('figcaption',{class:'cap'},[F.name?h('strong',{text:F.name}):null,F.designation?h('span',{text:F.designation}):null,F.description?h('small',{text:F.description}):null]);
 if(P.visible!==false&&P.url){var socials=[['facebook','Facebook','https://www.facebook.com/share/1CC9vnhnCP/'],['youtube','YouTube','https://youtube.com/@cletustech'],['tiktok','TikTok','https://www.tiktok.com/@cletustech'],['whatsapp','WhatsApp Channel','https://whatsapp.com/channel/0029VadSgOV96H4UzFlavl37'],['instagram','Instagram','https://www.instagram.com/cletus_tech/'],['threads','Threads','https://www.threads.com/@cletustech_ai'],['x','X','https://x.com/smartkiddelite']];var links=h('div',{class:'founder-social-links','aria-label':'CreatorVerse social channels'},socials.map(function(x){var url=F.socials&&F.socials[x[0]]||x[2];return h('a',{'data-social':x[0],href:url,target:'_blank',rel:'noopener noreferrer',title:x[1],'aria-label':x[1]},[h('img',{src:'https://cdn.jsdelivr.net/npm/simple-icons@v11/icons/'+x[0]+'.svg',alt:'',loading:'lazy'})])}));links.appendChild(h('a',{class:'founder-email-icon',href:'mailto:'+(F.email||'cletustech25@gmail.com'),title:'Email', 'aria-label':'Email CreatorVerse'},[ico('<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>')]));art=h('div',{class:'founder-visual'},[h('figure',{class:'portrait '+(P.style==='framed'?'framed':'cutout')},[h('img',{src:P.url,alt:F.name?'Portrait of '+F.name:'Founder portrait'}),cap]),links]);}
 else if(cap||P.visible!==false)art=h('figure',{class:'portrait fallback'},[h('div',{class:'fb-mark'},[ico(I.play)]),cap]);
 return h('section',{class:'hero2'+(P.position==='left'?' flip':'')},[h('div',{class:'hero2-in'+(art?'':' solo')},[copy,art])])}
function head(S){return h('div',{class:'sec-head'},[h('h2',{text:S.title}),S.subtitle?h('p',{text:S.subtitle}):null])}
function sec(S,courses,cats){var items=S.items||[],g,s=h('section',{class:'sec',id:S.id});
 if(S.type==='categories'){if(!cats.length)return null;s.appendChild(head(S));g=h('div',{class:'grid'});cats.forEach(function(c){g.appendChild(h('a',{class:'cat-card'+(c.image_url?' has-art':''),href:'category.html?c='+c.slug},[c.image_url?h('img',{class:'cat-img',src:c.image_url,alt:c.title+' course category artwork',loading:'lazy'}):h('span',{class:'cat-art-mark'},[ico(I.layers)]),h('div',{class:'cat-copy'},[h('h3',{text:c.title}),h('p',{text:c.description})]),h('span',{class:'go'},[ico(I.arrow)])]))});s.appendChild(g)}
 else if(S.type==='courses'){var list=courses;if(S.ids&&S.ids.length)list=S.ids.map(function(i){return courses.filter(function(c){return c.id===i})[0]}).filter(Boolean);else list=courses.slice(0,4);if(!list.length)return null;
  s.appendChild(head(S));g=h('div',{class:'grid'});list.forEach(function(c){var n=(c.modules||[]).reduce(function(a,m){return a+(m.lessons||[]).length},0),th=c.thumbnail_url?h('img',{src:c.thumbnail_url,alt:'',loading:'lazy'}):h('span',{class:'nothumb'},[ico(I.play)]);
   g.appendChild(h('article',{class:'course-card'},[h('div',{class:'cthumb'},[th,h('span',{class:'badge',text:c.price_ngn?'₦'+c.price_ngn:'Free'})]),h('div',{class:'cbody'},[h('h3',{text:c.title}),h('p',{text:c.description||''}),
    h('div',{class:'meta'},[n?h('span',{},[ico(I.book),document.createTextNode(n+(n===1?' lesson':' lessons'))]):null,c.duration_text?h('span',{},[ico(I.clock),document.createTextNode(c.duration_text)]):null]),
    h('a',{class:'btn btn-primary',href:'course.html?s='+encodeURIComponent(c.slug)},[h('span',{text:c.price_ngn?'View Course':'Enroll Now'})])])]))});s.appendChild(g)}
 else if(S.type==='cards'||S.type==='testimonials'){if(!items.length)return null;s.appendChild(head(S));g=h('div',{class:'grid'});items.forEach(function(x){g.appendChild(h('div',{class:S.type==='cards'?'info-card':'quote-card'},S.type==='cards'?[h('span',{class:'ico'},[ico(I.check)]),h('h3',{text:x.title}),h('p',{text:x.text})]:[h('p',{text:'“'+x.text+'”'}),h('strong',{text:x.title})]))});s.appendChild(g)}
 else if(S.type==='faq'){if(!items.length)return null;s.appendChild(head(S));g=h('div',{class:'faq'});items.forEach(function(x){g.appendChild(h('details',{},[h('summary',{text:x.title}),h('p',{text:x.text})]))});s.appendChild(g)}
 else if(S.type==='cta'){s.appendChild(h('div',{class:'cta2'},[h('h2',{text:S.title}),S.text?h('p',{text:S.text}):null,S.label?btn(S.label,S.url,'btn-primary'):null]))}
 return s}
function cms(){if(!C.supabaseUrl)return Promise.resolve({});return rest('site_content?key=in.(founder,intro_video_cfg,homepage_bg_cfg)&select=key,value').then(function(r){var o={};(Array.isArray(r)?r:[]).forEach(function(x){try{o[x.key]=JSON.parse(x.value)}catch(e){}});return o}).catch(function(){return{}})}
function draw(content){var X=HD.merge(HD.D,content||{});cms().then(function(sc){var f=sc.founder,v=sc.intro_video_cfg;
 if(f){X.hero.portrait.url=f.photo||'';X.hero.founder=Object.assign({},X.hero.founder,{name:f.name||'',designation:f.designation||'',description:'',socials:f.socials||{},email:f.email||'cletustech25@gmail.com',visible:X.hero.founder.visible!==false&&f.show_home!==false})}
 if(v)X.hero.video={enabled:!!v.enabled,url:v.url||'',thumbnail:v.thumbnail||''};
 if(sc.homepage_bg_cfg){try{X.homepageBackground=(typeof sc.homepage_bg_cfg==='string'?JSON.parse(sc.homepage_bg_cfg):sc.homepage_bg_cfg)}catch(e){console.warn('CreatorVerse homepage background config could not be read:',e)}}
 if(content||f)return render(X);
 fetch('site.json').then(function(r){return r.json()}).catch(function(){return{}}).then(function(c){if(c&&c.founderPhoto)X.hero.portrait.url=c.founderPhoto;render(X)})})}

function landingSections(){
 var wrap=h('div',{class:'cv-home-experience'});
 var intro=h('section',{class:'cv-home-intro'},[
  h('span',{class:'cv-kicker',text:'THE CREATORVERSE ECOSYSTEM'}),
  h('h2',{text:'One connected platform. More ways to grow.'}),
  h('p',{text:'Learn new skills, connect with creators, grow a business and discover new opportunities across one connected digital ecosystem.'})
 ]);
 var divisions=[
  {n:'01',name:'CreatorVerse Academy',desc:'Build practical skills through guided courses, learning paths and hands-on projects.',status:'Available now',live:true,href:'courses.html',action:'Explore Academy',kind:'academy'},
  {n:'02',name:'CreatorVerse Community',desc:'Meet other creators, share your work, exchange ideas and grow together.',status:'Available now',live:true,href:'community.html',action:'Visit Community',kind:'community'},
  {n:'03',name:'CreatorVerse Marketplace',desc:'A future home for creator services, digital products, orders and client work.',status:'In development',kind:'market'},
  {n:'04',name:'CreatorVerse Affiliate',desc:'A planned network for referral campaigns, transparent tracking and commissions.',status:'In development',kind:'affiliate'},
  {n:'05',name:'CreatorVerse Realty',desc:'Discover property opportunities, verified agents and viewing enquiries.',status:'In development',kind:'realty'},
  {n:'06',name:'CreatorVerse Business',desc:'Help businesses build visibility, reach customers and generate new leads.',status:'In development',kind:'business'}
 ];
 var grid=h('div',{class:'cv-division-grid'});
 var artImages={academy:'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=900&q=82',community:'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=900&q=82',market:'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=900&q=82',affiliate:'https://images.unsplash.com/photo-1553877522-43269d4ea984?auto=format&fit=crop&w=900&q=82',realty:'https://images.unsplash.com/photo-160059_info?auto=format&fit=crop&w=900&q=82',business:'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=82'};
 artImages.realty='https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=900&q=82';
 divisions.forEach(function(d){
  var card=h('article',{class:'cv-division-card cv-'+d.kind},[
   h('div',{class:'cv-division-art'},[h('img',{src:artImages[d.kind],alt:'',loading:'lazy'})]),
   h('div',{class:'cv-division-top'},[
    h('span',{class:'cv-division-number',text:d.n}),
    h('span',{class:'cv-division-status'+(d.live?' is-live':''),text:d.status})
   ]),
   h('div',{class:'cv-division-symbol','aria-hidden':'true',text:d.n}),
   h('h3',{text:d.name}),
   h('p',{text:d.desc}),
   d.live?h('a',{class:'cv-division-action',href:d.href},[h('span',{text:d.action}),ico(I.arrow)]):h('span',{class:'cv-division-action is-disabled',text:'Coming soon'})
  ]);
  grid.appendChild(card);
 });
 var path=h('section',{class:'cv-pathway cv-reveal'},[
  h('div',{class:'cv-pathway-copy'},[
   h('span',{class:'cv-kicker',text:'START WITH WHAT IS AVAILABLE TODAY'}),
   h('h2',{text:'Your next skill could change what comes next.'}),
   h('p',{text:'Explore practical courses, learn by doing and turn what you know into something real.'}),
   h('div',{class:'cv-pathway-actions'},[
    btn('Browse all courses','courses.html','btn-primary'),
    btn('Explore all divisions','divisions.html','btn-outline')
   ])
  ]),
  h('div',{class:'cv-pathway-visual'},[
   h('img',{src:'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1100&q=85',alt:'A collaborative team sharing ideas around a table',loading:'lazy'}),
   h('div',{class:'cv-visual-shade'}),
   h('div',{class:'cv-visual-label'},[h('span',{text:'THE CREATORVERSE WAY'}),h('strong',{text:'Learn. Build. Grow.'})]),
   h('div',{class:'cv-visual-stamp'},[h('span',{text:'01 — 06'}),h('b',{text:'ONE ECOSYSTEM'})])
  ])
 ]);
 intro.classList.add('cv-reveal');
 grid.classList.add('cv-reveal');
 var admissions=h('section',{class:'cv-admissions-entry cv-reveal'},[
  h('div',{class:'cv-admissions-entry-copy'},[
   h('span',{class:'cv-kicker',text:'CREATORVERSE ACADEMY · ADMISSIONS'}),
   h('h2',{text:'Ready to turn your interest into real skills?'}),
   h('p',{text:'Apply to join a guided learning pathway. Your application, placement review, admission offer and interview updates stay connected to your learner account.'}),
   h('div',{class:'cv-admissions-entry-actions'},[
    btn('Choose a course & apply','academy-apply.html','btn-primary'),
    btn('Check application status','academy-status.html','btn-outline')
   ])
  ]),
  h('div',{class:'cv-admissions-entry-art'},[
   h('span',{class:'cv-admissions-orbit cv-orbit-a'}),
   h('span',{class:'cv-admissions-orbit cv-orbit-b'}),
   h('div',{class:'cv-admissions-entry-mark'},[ico(I.book)]),
   h('strong',{text:'LEARN WITH DIRECTION'}),
   h('small',{text:'Apply · Get placed · Progress'})
  ])
 ]);
 admissions.classList.add('is-visible');
 wrap.appendChild(intro);wrap.appendChild(grid);wrap.appendChild(admissions);wrap.appendChild(path);root.appendChild(wrap);
 var revealItems=wrap.querySelectorAll('.cv-reveal,.cv-division-card');
 if('IntersectionObserver' in window){
  var revealObserver=new IntersectionObserver(function(entries){entries.forEach(function(entry){if(entry.isIntersecting){entry.target.classList.add('is-visible');revealObserver.unobserve(entry.target)}})},{threshold:.12,rootMargin:'0px 0px -35px 0px'});
  revealItems.forEach(function(el,i){el.style.setProperty('--reveal-delay',Math.min(i%6,5)*85+'ms');revealObserver.observe(el)});
 }else{revealItems.forEach(function(el){el.classList.add('is-visible')})}
}
function render(X){root.textContent='';var hr=hero(X.hero);if(hr){if(X.homepageBackground&&X.homepageBackground.enabled&&X.homepageBackground.url){var bg=h('div',{class:'home-watermark','aria-hidden':'true'});bg.style.backgroundImage='url("'+X.homepageBackground.url.replace(/"/g,'%22')+'")';bg.style.backgroundPosition=X.homepageBackground.position||'center center';bg.style.setProperty('--watermark-opacity',String(Math.max(5,Math.min(45,Number(X.homepageBackground.opacity)||18))/100));hr.insertBefore(bg,hr.firstChild);hr.classList.add('has-watermark')}root.appendChild(hr)}
 landingSections();
 var need=X.sections.some(function(s){return s.visible!==false&&s.type==='courses'});
 Promise.all([need&&C.supabaseUrl?rest('courses?published=eq.true&select=*,modules(lessons(id))&order=created_at.desc&limit=40').then(function(d){return Array.isArray(d)?d.sort(function(x,y){return(y.featured?1:0)-(x.featured?1:0)}):[]}).catch(function(){return[]}):[],window.CV_CATS()]).then(function(r){
  var courses=Array.isArray(r[0])?r[0]:[];X.sections.forEach(function(S){if(S.visible===false||S.type==='courses'||S.type==='categories')return;var e=sec(S,courses,r[1]);if(e)root.appendChild(e);});requestAnimationFrame(function(){requestAnimationFrame(function(){if(window.cvFinishLoading)window.cvFinishLoading()})})})}
function go(){var ok=C.supabaseUrl&&C.supabaseAnonKey;
 if(Q.get('preview')==='1'){document.body.insertBefore(h('div',{class:'preview-bar',text:'Preview of the unpublished draft. Visitors do not see this.'}),document.body.firstChild);
  var f=function(){window.CV_SB.from('homepage_versions').select('content').eq('status','draft').maybeSingle().then(function(r){draw(r.data&&r.data.content)})};
  if(window.CV_SB)f();else document.addEventListener('cv-ready',f);return}
 if(!ok)return draw();rest('homepage_versions?status=eq.published&select=content&order=created_at.desc&limit=1').then(function(r){draw(r[0]&&r[0].content)}).catch(function(){draw()})}
go();
})();
