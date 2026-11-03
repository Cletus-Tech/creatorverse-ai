(function(){
var pg=document.body.dataset.page,main=document.getElementById('content'),Q=new URLSearchParams(location.search);
if(['courses','course','lesson','admin'].indexOf(pg)<0)return;
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else if(i==='value')e.value=a[i];else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function note(t){main.appendChild(h('div',{class:'note',text:t}))}
function head(t,p){main.textContent='';main.appendChild(h('h1',{text:t}));if(p)main.appendChild(h('p',{text:p}))}
function embed(u){if(!u)return null;var m=u.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]{6,})/);
 if(m)return h('iframe',{class:'lesson-video',src:'https://www.youtube-nocookie.com/embed/'+m[1],allowfullscreen:'',allow:'encrypted-media; fullscreen'});
 if(/^https:\/\/player\.vimeo\.com\//.test(u))return h('iframe',{class:'lesson-video',src:u,allowfullscreen:''});
 if(/\.(mp4|webm)(\?|$)/i.test(u))return h('video',{class:'lesson-video',src:u,controls:''});return null}
function sorted(a){return (a||[]).slice().sort(function(x,y){return x.position-y.position})}
function boot(sb){
 sb.auth.getSession().then(function(r){var user=r.data.session&&r.data.session.user;
  if(pg==='courses')courses(sb);else if(pg==='course')course(sb,user);else if(pg==='lesson')lesson(sb,user);else admin(sb,user)})}
function ico(p){var s=document.createElementNS('http://www.w3.org/2000/svg','svg');s.setAttribute('viewBox','0 0 24 24');s.setAttribute('fill','none');s.setAttribute('stroke','currentColor');s.setAttribute('stroke-width','2');s.setAttribute('stroke-linecap','round');s.setAttribute('stroke-linejoin','round');s.innerHTML=p;return s}
var CK='<path d="M20 6 9 17l-5-5"/>',PL='<polygon points="6 3 20 12 6 21 6 3"/>';
function nl(c){return(c.modules||[]).reduce(function(a,m){return a+(m.lessons||[]).length},0)}
function ccard(c){var n=nl(c),th=c.thumbnail_url?h('img',{src:c.thumbnail_url,alt:'',loading:'lazy'}):h('span',{class:'nothumb'},[ico(PL)]);
 return h('article',{class:'course-card'},[h('div',{class:'cthumb'},[th,h('span',{class:'badge',text:c.price_ngn?'₦'+c.price_ngn:'Free'})]),h('div',{class:'cbody'},[h('h3',{text:c.title}),h('p',{text:c.description||''}),
  h('div',{class:'meta'},[n?h('span',{text:n+(n===1?' lesson':' lessons')}):null,c.duration_text?h('span',{text:c.duration_text}):null,c.level?h('span',{text:c.level}):null]),
  h('a',{class:'btn btn-primary',href:'course.html?s='+encodeURIComponent(c.slug),text:c.price_ngn?'View Course':'Enroll Now'})])])}
function courses(sb){head('Explore Courses','Browse published courses and start learning.');var cat=Q.get('c')||'',term='',all=[],cats=[];
 var tools=h('div',{class:'tools'}),si=h('input',{type:'search',placeholder:'Search courses…','aria-label':'Search courses'}),chips=h('div',{class:'chips'}),g=h('div',{class:'grid'});
 tools.appendChild(si);main.appendChild(tools);main.appendChild(chips);main.appendChild(g);
 function draw(){chips.textContent='';[{slug:'',title:'All'}].concat(cats).forEach(function(c){chips.appendChild(h('button',{type:'button',class:'chipbtn'+(c.slug===cat?' on':''),text:c.title,on:function(){cat=c.slug;draw()}}))});
  g.textContent='';var l=all.filter(function(c){return(!cat||c.category_slug===cat)&&(!term||(c.title+' '+(c.description||'')).toLowerCase().indexOf(term)>-1)});
  if(!l.length)return g.appendChild(h('div',{class:'note',text:all.length?'No courses match your search.':'No courses are published yet.'}));l.forEach(function(c){g.appendChild(ccard(c))})}
 si.addEventListener('input',function(){term=si.value.trim().toLowerCase();draw()});
 Promise.all([sb.from('courses').select('*,modules(lessons(id))').eq('published',true).order('created_at',{ascending:false}),window.CV_CATS()]).then(function(r){if(r[0].error)return note(r[0].error.message);all=(r[0].data||[]).slice().sort(function(a,b){return (b.featured?1:0)-(a.featured?1:0)});cats=r[1];draw()})}
function course(sb,user){var s=Q.get('s');
 sb.from('courses').select('*,modules(id,title,position,lessons(id,title,position))').eq('slug',s||'').maybeSingle().then(function(r){
  if(!r.data)return head('Course not found');var c=r.data,mods=sorted(c.modules),all=[];mods.forEach(function(m){sorted(m.lessons).forEach(function(l){all.push(l)})});main.textContent='';
  Promise.all([user?sb.from('enrolments').select('course_id').eq('course_id',c.id):{data:[]},user?sb.from('lesson_progress').select('lesson_id'):{data:[]}]).then(function(x){
   var enrolled=x[0].data&&x[0].data.length>0,done={};(x[1].data||[]).forEach(function(p){done[p.lesson_id]=1});var d=all.filter(function(l){return done[l.id]}).length,pct=all.length?Math.round(100*d/all.length):0;
   var act=h('div',{class:'hero2-cta'});
   if(!user)act.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to enroll'}));
   else if(enrolled){var nx=all.filter(function(l){return !done[l.id]})[0]||all[0];if(nx)act.appendChild(h('a',{class:'btn btn-primary',href:'lesson.html?l='+nx.id,text:d?'Continue learning':'Start learning'}))}
   else if(c.price_ngn>0)act.appendChild(h('div',{class:'note',text:'Paid courses open when payments launch.'}));
   else act.appendChild(h('button',{class:'btn btn-primary',type:'button',text:'Enroll for free',on:function(){sb.from('enrolments').insert({user_id:user.id,course_id:c.id}).then(function(e){e.error?alert(e.error.message):location.reload()})}}));
   main.appendChild(h('div',{class:'chero'},[h('div',{},[h('span',{class:'chip2',text:c.level||'Beginner'}),h('h1',{text:c.title}),h('p',{class:'lead',text:c.description||''}),
    h('div',{class:'meta'},[all.length?h('span',{text:all.length+(all.length===1?' lesson':' lessons')}):null,c.duration_text?h('span',{text:c.duration_text}):null,h('span',{text:c.price_ngn?'₦'+c.price_ngn:'Free'})]),
    enrolled?h('div',{},[bar2(pct),h('p',{class:'pmeta',text:d+' of '+all.length+' lessons completed ('+pct+'%)'})]):null,act]),
    c.thumbnail_url?h('img',{class:'cimg',src:c.thumbnail_url,alt:''}):null]));
   var ol=(c.outcomes||'').split('\n').map(function(x){return x.trim()}).filter(Boolean),rq=(c.requirements||'').split('\n').map(function(x){return x.trim()}).filter(Boolean);
   if(ol.length){main.appendChild(h('h2',{text:'What you will learn'}));var u1=h('ul',{class:'clist'});ol.forEach(function(t){u1.appendChild(h('li',{},[h('span',{class:'outc'},[h('span',{class:'dot on'},[ico(CK)]),h('span',{text:t})])]))});main.appendChild(u1)}
   if(rq.length){main.appendChild(h('h2',{text:'Requirements'}));var u2=h('ul');rq.forEach(function(t){u2.appendChild(h('li',{text:t}))});main.appendChild(u2)}
   main.appendChild(h('h2',{text:'Curriculum'}));if(!mods.length)note('No lessons have been added yet.');
   mods.forEach(function(m,i){var ul=h('ul',{class:'clist'});sorted(m.lessons).forEach(function(l){ul.appendChild(h('li',{},[h('a',{href:'lesson.html?l='+l.id},[h('span',{class:'dot'+(done[l.id]?' on':'')},[done[l.id]?ico(CK):null]),h('span',{text:l.title})])]))});
    main.appendChild(h('details',{class:'mod2',open:''},[h('summary',{text:m.title+' · '+(m.lessons||[]).length+' lessons'}),ul]))})})})}
function bar2(p){return h('div',{class:'progress'},[h('span',{style:'width:'+p+'%'})])}
function lesson(sb,user){
 sb.from('lessons').select('*,modules(course_id,title,courses(slug,title,price_ngn))').eq('id',Q.get('l')||'').maybeSingle().then(function(r){
  var l=r.data;if(!l)return head('Lesson not available','It may not exist, or you need to enroll in the course first.');
  var c=l.modules.courses,cid=l.modules.course_id;main.textContent='';
  Promise.all([sb.from('modules').select('id,title,position,lessons(id,title,position)').eq('course_id',cid),user?sb.from('lesson_progress').select('lesson_id'):{data:[]}]).then(function(x){
   var mods=sorted(x[0].data),flat=[],done={};mods.forEach(function(m){sorted(m.lessons).forEach(function(q){flat.push(q.id)})});(x[1].data||[]).forEach(function(p){done[p.lesson_id]=1});
   var i=flat.indexOf(l.id),n=flat.filter(function(q){return done[q]}).length,pct=flat.length?Math.round(100*n/flat.length):0;
   var side=h('aside',{class:'lside'},[h('h3',{text:'Course content'}),bar2(pct),h('p',{class:'pmeta',text:n+' of '+flat.length+' completed'})]);
   mods.forEach(function(m){side.appendChild(h('h4',{text:m.title}));var ul=h('ul',{class:'clist'});sorted(m.lessons).forEach(function(q){ul.appendChild(h('li',{class:q.id===l.id?'cur':''},[h('a',{href:'lesson.html?l='+q.id},[h('span',{class:'dot'+(done[q.id]?' on':'')},[done[q.id]?ico(CK):null]),h('span',{text:q.title})])]))});side.appendChild(ul)});
   var col=h('div',{class:'lmain'},[h('a',{class:'back',href:'course.html?s='+encodeURIComponent(c.slug),text:'← '+c.title}),h('h1',{text:l.title})]);var v=embed(l.video_url);if(v)col.appendChild(v);
   if(l.content)col.appendChild(h('div',{class:'lesson-text',text:l.content}));var rl=h('div');col.appendChild(rl);sb.from('lesson_resources').select('title,url,position').eq('lesson_id',l.id).then(function(rr){var d=sorted(rr.data||[]);if(!d.length)return;rl.appendChild(h('h3',{class:'mod',text:'Resources'}));var ul=h('ul',{class:'clist'});d.forEach(function(x){ul.appendChild(h('li',{},[h('a',{href:x.url,target:'_blank',rel:'noopener'},[h('span',{class:'dot'},[ico('<path d="M12 15V3"/><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/>')]),h('span',{text:x.title})])]))});rl.appendChild(ul)});
   var row=h('div',{class:'row'});col.appendChild(row);
   if(i>0)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+flat[i-1],text:'← Previous'}));
   if(!user)row.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to track progress'}));
   else row.appendChild(h('button',{class:'btn btn-primary',type:'button',text:done[l.id]?'Completed ✓':'Mark as completed',on:function(){if(done[l.id])return;sb.from('enrolments').upsert({user_id:user.id,course_id:cid},{ignoreDuplicates:true}).then(function(){
    sb.from('lesson_progress').insert({user_id:user.id,lesson_id:l.id}).then(function(e){if(e.error)return alert(e.error.message);location.href=i<flat.length-1?'lesson.html?l='+flat[i+1]:'course.html?s='+encodeURIComponent(c.slug)})})}}));
   if(i<flat.length-1)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+flat[i+1],text:'Next →'}));
   main.appendChild(h('div',{class:'lgrid'},[col,side]))})})}
function admin(sb,user){var main;head('Admin');if(!user){location.href='login.html';return}
 sb.from('profiles').select('role').eq('id',user.id).maybeSingle().then(function(p){var ro=p.data&&p.data.role;
  if(ro!=='admin'&&ro!=='super_admin')return note('Administrators only.');
  var P1=h('div'),P2=h('div'),P3=h('div'),P4=h('div'),P5=h('div'),P6=h('div'),P7=h('div');window.CV_COURSES(P1);window.CV_CMS.media(P2);window.CV_CMS.site(P3);window.CV_CMS.homepage(P4);window.CV_CMS.founder(P5);window.CV_CMS.video(P6);window.CV_CMS.categories(P7);
  window.CV_SHELL.mount(sb,user,ro,{courses:P1,media:P2,settings:P3,homepage:P4,founder:P5,video:P6,categories:P7})})}
if(window.CV_SB)boot(window.CV_SB);else document.addEventListener('cv-ready',function(){boot(window.CV_SB)});
})();
