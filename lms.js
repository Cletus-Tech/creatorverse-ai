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
function courses(sb){head('Courses');var c=Q.get('c'),q=sb.from('courses').select('*').eq('published',true).order('created_at',{ascending:false});if(c)q=q.eq('category_slug',c);
 q.then(function(r){if(r.error)return note(r.error.message);if(!r.data.length)return note('No courses are published yet.');
  var g=h('div',{class:'panels'});r.data.forEach(function(x){g.appendChild(h('a',{class:'skill-card',href:'course.html?s='+encodeURIComponent(x.slug)},[x.thumbnail_url?h('img',{class:'thumb',src:x.thumbnail_url,alt:''}):null,h('h3',{class:'card-title',text:x.title}),h('p',{class:'card-desc',text:x.description||''}),h('p',{},[h('span',{class:'chip',text:x.level||'Beginner'}),h('span',{class:'chip',text:x.price_ngn?'₦'+x.price_ngn:'Free'})])]))});main.appendChild(g)})}
function course(sb,user){var s=Q.get('s');
 sb.from('courses').select('*,modules(id,title,position,lessons(id,title,position))').eq('slug',s||'').maybeSingle().then(function(r){
  if(!r.data)return head('Course not found');var c=r.data;head(c.title,c.description);if(c.thumbnail_url)main.appendChild(h('img',{class:'thumb big',src:c.thumbnail_url,alt:''}));
  main.appendChild(h('p',{},[h('span',{class:'chip',text:c.level||'Beginner'}),c.duration_text?h('span',{class:'chip',text:c.duration_text}):null,h('span',{class:'chip',text:c.price_ngn?'₦'+c.price_ngn:'Free'})]));
  var mods=sorted(c.modules),all=[];mods.forEach(function(m){sorted(m.lessons).forEach(function(l){all.push(l)})});
  Promise.all([user?sb.from('enrolments').select('course_id').eq('course_id',c.id):{data:[]},user?sb.from('lesson_progress').select('lesson_id'):{data:[]}]).then(function(x){
   var enrolled=x[0].data&&x[0].data.length>0,done={};(x[1].data||[]).forEach(function(p){done[p.lesson_id]=1});
   var act=h('div');main.appendChild(act);
   if(!user)act.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to enrol'}));
   else if(enrolled){var nx=all.filter(function(l){return !done[l.id]})[0]||all[0];if(nx)act.appendChild(h('a',{class:'btn btn-primary',href:'lesson.html?l='+nx.id,text:'Continue learning'}))}
   else if(c.price_ngn>0)act.appendChild(h('div',{class:'note',text:'Paid courses open when payments launch.'}));
   else act.appendChild(h('button',{class:'btn btn-primary',type:'button',text:'Enrol for free',on:function(){sb.from('enrolments').insert({user_id:user.id,course_id:c.id}).then(function(e){e.error?alert(e.error.message):location.reload()})}}));
   main.appendChild(h('h2',{text:'Curriculum'}));if(!mods.length)note('No lessons yet.');
   mods.forEach(function(m){main.appendChild(h('h3',{class:'mod',text:m.title}));var ul=h('ul');sorted(m.lessons).forEach(function(l){ul.appendChild(h('li',{},[h('a',{href:'lesson.html?l='+l.id,text:(done[l.id]?'✓ ':'')+l.title})]))});main.appendChild(ul)})})})}
function lesson(sb,user){
 sb.from('lessons').select('*,modules(course_id,title,courses(slug,title,price_ngn))').eq('id',Q.get('l')||'').maybeSingle().then(function(r){
  var l=r.data;if(!l)return head('Lesson not available','It may not exist, or you need to enrol in the course first.');
  var c=l.modules.courses,cid=l.modules.course_id;head(l.title,c.title+' · '+l.modules.title);var v=embed(l.video_url);if(v)main.appendChild(v);
  if(l.content)main.appendChild(h('div',{class:'lesson-text',text:l.content}));
  sb.from('modules').select('position,lessons(id,position)').eq('course_id',cid).then(function(mr){var all=[];sorted(mr.data).forEach(function(m){sorted(m.lessons).forEach(function(x){all.push(x.id)})});
   var i=all.indexOf(l.id);
   Promise.all([user?sb.from('lesson_progress').select('lesson_id'):{data:[]}]).then(function(pp){var done={};(pp[0].data||[]).forEach(function(p){done[p.lesson_id]=1});
    var n=all.filter(function(x){return done[x]}).length,bar=h('div',{class:'progress'},[h('span',{style:'width:'+(all.length?Math.round(100*n/all.length):0)+'%'})]);
    var row=h('div',{class:'row'}),pr=h('p',{class:'pmeta',text:n+' of '+all.length+' lessons completed'});
    main.appendChild(bar);main.appendChild(pr);main.appendChild(row);
    if(i>0)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+all[i-1],text:'← Previous'}));
    if(!user)row.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to track progress'}));
    else row.appendChild(h('button',{class:'btn btn-primary',type:'button',text:done[l.id]?'Completed ✓':'Mark as completed',on:function(){
     if(done[l.id])return;sb.from('enrolments').upsert({user_id:user.id,course_id:cid},{ignoreDuplicates:true}).then(function(){
      sb.from('lesson_progress').insert({user_id:user.id,lesson_id:l.id}).then(function(e){if(e.error)return alert(e.error.message);location.href=i<all.length-1?'lesson.html?l='+all[i+1]:'course.html?s='+encodeURIComponent(c.slug)})})}}));
    if(i<all.length-1)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+all[i+1],text:'Next →'}));
    row.appendChild(h('a',{class:'btn btn-outline',href:'course.html?s='+encodeURIComponent(c.slug),text:'Course page'}))})})})}
function admin(sb,user){var main;head('Admin');if(!user){location.href='login.html';return}
 sb.from('profiles').select('role').eq('id',user.id).maybeSingle().then(function(p){var ro=p.data&&p.data.role;
  if(ro!=='admin'&&ro!=='super_admin')return note('Administrators only.');var root=document.getElementById('content'),tb=h('div',{class:'row'}),P1=h('div'),P2=h('div',{style:'display:none'}),P3=h('div',{style:'display:none'}),P4=h('div',{style:'display:none'}),T=[['Courses',P1],['Homepage',P4],['Media library',P2],['Website content',P3]];T.forEach(function(t,i){tb.appendChild(h('button',{class:'btn '+(i?'btn-outline':'btn-primary'),type:'button',text:t[0],on:function(){T.forEach(function(x,j){x[1].style.display=j===i?'':'none';tb.children[j].className='btn '+(j===i?'btn-primary':'btn-outline')})}}))});root.appendChild(tb);root.appendChild(P1);root.appendChild(P2);root.appendChild(P3);root.appendChild(P4);main=P1;window.CV_CMS.media(P2);window.CV_CMS.site(P3);window.CV_CMS.homepage(P4);
  fetch('categories.json').then(function(r){return r.json()}).catch(function(){return[]}).then(function(cats){
   var f=h('form',{id:'nc'});function fld(l,n,t,x){var i=t==='ta'?h('textarea',{id:n,name:n,rows:'3'}):h('input',{id:n,name:n,type:t||'text'});return[h('label',{class:'field',for:n,text:l}),i]}
   var sel=h('select',{name:'category',id:'category'},cats.map(function(c){return h('option',{value:c.slug,text:c.title})}));
   [].concat(fld('Title','title'),fld('Short description','description','ta'),[h('label',{class:'field',for:'category',text:'Category'}),sel],fld('Level (Beginner, Intermediate, Advanced)','level'),fld('Duration (e.g. 4 hours)','duration'),fld('Price in naira (0 = free)','price','number')).forEach(function(e){f.appendChild(e)});
   f.title.required=true;f.price.value=0;f.level.value='Beginner';f.appendChild(h('button',{class:'btn btn-primary',type:'submit',text:'Create course (draft)'}));
   main.appendChild(h('h2',{text:'New course'}));main.appendChild(f);var out=h('div',{id:'list'});main.appendChild(h('h2',{text:'All courses'}));main.appendChild(out);
   function slug(t){return t.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')+'-'+Math.random().toString(36).slice(2,6)}
   f.addEventListener('submit',function(e){e.preventDefault();sb.from('courses').insert({title:f.title.value,slug:slug(f.title.value),description:f.description.value,category_slug:sel.value,level:f.level.value,duration_text:f.duration.value,price_ngn:parseInt(f.price.value,10)||0}).then(function(r){r.error?alert(r.error.message):(f.reset(),f.price.value=0,f.level.value='Beginner',load())})});
   function load(){sb.from('courses').select('*,modules(id,title,position,lessons(id,title,position))').order('created_at',{ascending:false}).then(function(r){out.textContent='';(r.data||[]).forEach(function(c){
    var thumb=c.thumbnail_url||'',box=h('div',{class:'panel'},[thumb?h('img',{class:'thumb',src:thumb,alt:''}):null,h('h3',{text:c.title+(c.published?'':' (draft)')}),h('p',{text:(c.category_slug||'')+' · '+(c.price_ngn?'₦'+c.price_ngn:'Free')})]);
    var ef=h('form',{class:'mini',style:'display:none'}),eT=h('input',{value:c.title,required:''}),eD=h('textarea',{rows:'3',value:c.description||''}),eC=h('select',{},cats.map(function(x){return h('option',{value:x.slug,text:x.title})})),eL=h('input',{value:c.level||''}),eU=h('input',{value:c.duration_text||''}),eP=h('input',{type:'number',value:c.price_ngn||0}),eV=h('img',{class:'thumb',alt:'',style:thumb?'':'display:none',src:thumb}),eF=h('input',{type:'file',accept:'image/*'}),em=h('div',{class:'msg'});eC.value=c.category_slug||'';
    eF.addEventListener('change',function(){if(eF.files[0]){em.textContent='Uploading…';em.className='msg';window.CV_MEDIA.upload(eF.files[0],'course-thumbnails').then(function(u){thumb=u;eV.src=u;eV.style.display='';em.textContent='Preview ready. Press Save to apply.';em.className='msg ok'}).catch(function(e){em.textContent=e.message;em.className='msg err'})}});
    [h('label',{class:'field',text:'Title'}),eT,h('label',{class:'field',text:'Description'}),eD,h('label',{class:'field',text:'Category'}),eC,h('label',{class:'field',text:'Level'}),eL,h('label',{class:'field',text:'Duration'}),eU,h('label',{class:'field',text:'Price in naira (0 = free)'}),eP,h('label',{class:'field',text:'Course flyer / thumbnail'}),eV,eF,window.CV_CMS.pick('image',{set value(v){thumb=v;eV.src=v;eV.style.display=''}}),h('button',{class:'btn btn-outline',type:'button',text:'Remove image',on:function(){thumb='';eV.style.display='none'}}),h('button',{class:'btn btn-primary',type:'submit',text:'Save changes'}),em].forEach(function(e){ef.appendChild(e)});
    ef.addEventListener('submit',function(e){e.preventDefault();sb.from('courses').update({title:eT.value,description:eD.value,category_slug:eC.value,level:eL.value,duration_text:eU.value,price_ngn:parseInt(eP.value,10)||0,thumbnail_url:thumb||null}).eq('id',c.id).then(function(r){r.error?(em.textContent=r.error.message,em.className='msg err'):load()})});
    var row=h('div',{class:'row'},[h('button',{class:'btn btn-outline',type:'button',text:'Edit',on:function(){ef.style.display=ef.style.display==='none'?'grid':'none'}}),h('button',{class:'btn btn-outline',type:'button',text:c.published?'Unpublish':'Publish',on:function(){sb.from('courses').update({published:!c.published}).eq('id',c.id).then(load)}}),
     h('a',{class:'btn btn-outline',href:'course.html?s='+encodeURIComponent(c.slug),text:'View'}),
     h('button',{class:'btn btn-outline',type:'button',text:'Delete',on:function(){if(confirm('Delete "'+c.title+'" and all its lessons?'))sb.from('courses').delete().eq('id',c.id).then(load)}})]);box.appendChild(row);box.appendChild(ef);
    sorted(c.modules).forEach(function(m){var ls=h('ul');sorted(m.lessons).forEach(function(l){ls.appendChild(h('li',{},[h('span',{text:l.title+' '}),h('a',{href:'#',text:'remove',on:function(e){e.preventDefault();if(confirm('Remove lesson?'))sb.from('lessons').delete().eq('id',l.id).then(load)}})]))});
     var lf=h('form',{class:'mini'},[h('input',{name:'t',placeholder:'Lesson title',required:''}),h('input',{name:'v',placeholder:'YouTube / Vimeo / .mp4 link (optional)'}),h('textarea',{name:'c',rows:'3',placeholder:'Lesson text (optional)'}),h('button',{class:'btn btn-primary',type:'submit',text:'Add lesson'})]);
     lf.addEventListener('submit',function(e){e.preventDefault();sb.from('lessons').insert({module_id:m.id,title:lf.t.value,video_url:lf.v.value||null,content:lf.c.value||null,position:(m.lessons||[]).length+1}).then(function(x){x.error?alert(x.error.message):load()})});
     box.appendChild(h('h3',{class:'mod',text:m.title}));box.appendChild(ls);box.appendChild(lf)});
    var mf=h('form',{class:'mini'},[h('input',{name:'t',placeholder:'New module title',required:''}),h('button',{class:'btn btn-outline',type:'submit',text:'Add module'})]);
    mf.addEventListener('submit',function(e){e.preventDefault();sb.from('modules').insert({course_id:c.id,title:mf.t.value,position:(c.modules||[]).length+1}).then(function(x){x.error?alert(x.error.message):load()})});box.appendChild(mf);out.appendChild(box)})})}
   load()})})}
if(window.CV_SB)boot(window.CV_SB);else document.addEventListener('cv-ready',function(){boot(window.CV_SB)});
})();
