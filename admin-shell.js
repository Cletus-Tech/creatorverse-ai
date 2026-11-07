(function(){
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function ico(p,c){var s=document.createElementNS('http://www.w3.org/2000/svg','svg');s.setAttribute('viewBox','0 0 24 24');s.setAttribute('fill','none');s.setAttribute('stroke','currentColor');s.setAttribute('stroke-width','2');s.setAttribute('stroke-linecap','round');s.setAttribute('stroke-linejoin','round');s.innerHTML=p;if(c)s.setAttribute('class',c);return s}
var IC={dashboard:'<rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/>',
 background:'<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18"/>',homepage:'<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',
 founder:'<circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/>',video:'<path d="m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5"/><rect x="2" y="6" width="14" height="12" rx="2"/>',
 media:'<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
 courses:'<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>',
 categories:'<path d="M4 4h6v6H4z"/><path d="M14 4h6v6h-6z"/><path d="M4 14h6v6H4z"/><path d="M14 14h6v6h-6z"/>',modules:'<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',
 lessons:'<circle cx="12" cy="12" r="10"/><polygon points="10 8 16 12 10 16 10 8"/>',
 students:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
 quizzes:'<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/>',
 certificates:'<path d="m15.477 12.89 1.515 8.526a.5.5 0 0 1-.81.47l-3.58-2.687a1 1 0 0 0-1.197 0l-3.586 2.686a.5.5 0 0 1-.81-.469l1.514-8.526"/><circle cx="12" cy="8" r="6"/>',
 payments:'<rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/>',analytics:'<path d="M3 3v16a2 2 0 0 0 2 2h16"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
 notifications:'<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>',
 settings:'<circle cx="12" cy="12" r="3"/><path d="M12 1v3M12 20v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M1 12h3M20 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
 educator:'<path d="M4 5h16v12H4z"/><path d="M8 21h8M12 17v4M7 9h10M7 13h6"/>',help:'<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',menu:'<path d="M4 7h16M4 12h16M4 17h16"/>',out:'<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',arrow:'<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'};
var NAV=[[['dashboard','Dashboard'],['homepage','Homepage Manager'],['background','3D Background'],['founder','Founder Profile'],['video','Introduction Video'],['media','Media Library']],
 [['courses','Courses'],['educator','Educator Curriculum'],['categories','Categories'],['modules','Modules'],['lessons','Lessons'],['students','Students'],['quizzes','Quizzes & Assignments'],['certificates','Certificates']],
 [['payments','Payments'],['analytics','Analytics'],['notifications','Notifications','Soon'],['settings','Settings'],['help','Help & Support']]];
var SOON={notifications:'Notifications and announcements (a later stage)'};
function day(d){return d.toISOString().slice(0,10)}
function chart(title,rows,total){var days=[],i,m={};for(i=29;i>=0;i--){var d=new Date();d.setDate(d.getDate()-i);days.push(day(d))}days.forEach(function(d){m[d]=0});rows.forEach(function(r){var k=day(new Date(r.created_at));if(k in m)m[k]++});
 var vals=days.map(function(d){return m[d]}),mx=Math.max.apply(null,vals.concat([1])),NS='http://www.w3.org/2000/svg',s=document.createElementNS(NS,'svg');s.setAttribute('viewBox','0 0 300 100');s.setAttribute('class','bars');
 vals.forEach(function(v,j){var r=document.createElementNS(NS,'rect');r.setAttribute('x',j*10+1);r.setAttribute('width',8);var hh=Math.max(v?4:1,v/mx*92);r.setAttribute('y',98-hh);r.setAttribute('height',hh);r.setAttribute('rx',2);r.setAttribute('fill',v?'#2f7bff':'#1b2a52');var t=document.createElementNS(NS,'title');t.textContent=days[j]+': '+v;r.appendChild(t);s.appendChild(r)});
 return h('div',{class:'panel'},[h('h3',{text:title}),h('p',{class:'big',text:String(total)+' in total'}),s,h('p',{class:'pmeta',text:'Last 30 days'})])}
function ago(t){var s=(Date.now()-new Date(t))/1000;return s<60?'just now':s<3600?Math.floor(s/60)+'m ago':s<86400?Math.floor(s/3600)+'h ago':Math.floor(s/86400)+'d ago'}
window.CV_SHELL={mount:function(sb,user,role,P){
 var root=document.getElementById('content');root.textContent='';var me={name:'',role:role},cur='',view=h('div',{class:'adm-view'}),side=h('aside',{class:'adm-side'}),back=h('div',{class:'adm-back'});
 function open(o){side.classList.toggle('open',o);back.classList.toggle('on',o)}back.addEventListener('click',function(){open(false)});
 side.appendChild(h('a',{class:'adm-brand',href:'index.html'},[h('span',{class:'adm-logo'},[h('img',{src:'assets/creatorverse-mark.svg',alt:'',width:'38',height:'38'})]),h('span',{},[h('strong',{text:'CreatorVerse'}),h('small',{text:'Learn. Create. Grow.'})])]));
 var links={};NAV.forEach(function(g,gi){if(gi)side.appendChild(h('hr'));g.forEach(function(n){var a=h('a',{href:'#'+n[0],class:'adm-link'},[ico(IC[n[0]]),h('span',{text:n[1]}),n[2]?h('em',{text:n[2]}):null]);a.addEventListener('click',function(){open(false)});links[n[0]]=a;side.appendChild(a)})});
 side.appendChild(h('a',{href:'connect-admin.html',class:'adm-link'},[h('span',{text:'◈'}),h('span',{text:'Connect Moderation'})]));
 var who=h('span',{class:'adm-who'}),top=h('header',{class:'adm-top'},[h('button',{class:'adm-burger',type:'button','aria-label':'Menu',on:function(){open(true)}},[ico(IC.menu)]),h('strong',{id:'adm-title',text:'Dashboard'}),h('span',{class:'sp'}),h('a',{class:'btn btn-outline',href:'index.html',text:'View website'}),who,
  h('button',{class:'btn btn-outline',type:'button',on:function(){sb.auth.signOut().then(function(){location.href='index.html'})}},[ico(IC.out),h('span',{text:'Log out'})])]);
 root.appendChild(h('div',{class:'adm'},[side,back,h('div',{class:'adm-main'},[top,view])]));
 sb.from('profiles').select('id,full_name,verified_badge,avatar_url').eq('id',user.id).maybeSingle().then(function(r){me.name=(r.data&&r.data.full_name)||user.email;var isOwner=r.data&&r.data.id===window.CV_OWNER_ID;who.textContent=me.name+' · '+(isOwner?'Owner':role.replace('_',' '));if(isOwner)who.classList.add('cv-owner-name');var tick=window.CV_BADGE_ICON&&window.CV_BADGE_ICON(r.data||{});if(tick)who.appendChild(tick)});
 function pane(p,note){view.textContent='';if(note)view.appendChild(h('div',{class:'note',text:note}));view.appendChild(p)}
 function route(){var id=(location.hash||'#dashboard').slice(1);if(!links[id])id='dashboard';if(id===cur)return;cur=id;Object.keys(links).forEach(function(k){links[k].classList.toggle('on',k===id)});
  var label=links[id].querySelector('span').textContent;document.getElementById('adm-title').textContent=label;view.textContent='';
  if(id==='dashboard')dash();else if(id==='analytics')analytics();else if(id==='students')students();else if(id==='help')help();
  else if(id==='homepage')pane(P.homepage);else if(id==='background')pane(P.homepageBackground);else if(id==='founder')pane(P.founder);else if(id==='video')pane(P.video);else if(id==='educator')pane(P.educator,'Draft curriculum workspace. Changes here are private to administrators until reviewed and transferred into the live course curriculum.');else if(id==='categories')pane(P.categories);else if(id==='quizzes')pane(P.assess);else if(id==='certificates')pane(P.certs);
  else if(id==='payments'){if(P.payments)pane(P.payments);else view.appendChild(h('div',{class:'note',text:'Payment administration is loading. Refresh this page if it does not appear.'}));}else if(id==='media')pane(P.media);else if(id==='settings')pane(P.settings,'Announcement banner and About page text.');
  else if(id==='courses')pane(P.courses);else if(id==='modules'||id==='lessons')pane(P.courses,'Modules and lessons are managed inside each course. Open a course below to add or remove them. Use Up and Down to reorder.');
  else view.appendChild(h('div',{class:'panel'},[h('h3',{text:label}),h('p',{text:'This feature is not built yet. Planned: '+SOON[id]+'.'}),h('p',{class:'pmeta',text:'Nothing on this page is placeholder data.'})]))}
 function cnt(t,f){var q=sb.from(t).select('id',{count:'exact',head:true});return(f?f(q):q).then(function(r){return r.count||0})}
 function dash(){var g=h('div',{class:'stats4'}),qa=h('div',{class:'qa'}),cm=h('div',{class:'panel'}),ru=h('div',{class:'panel'}),ra=h('div',{class:'panel'}),cg=h('div',{class:'two'});
  view.appendChild(h('div',{class:'dash-hero'},[h('div',{},[h('h1',{text:'Welcome back'+(me.name?', '+me.name:'')}),h('p',{text:'Everything below is counted from your live database.'})])]));view.appendChild(g);
  view.appendChild(h('div',{class:'panel'},[h('h3',{text:'Quick management'}),qa]));[['courses','Manage Courses','Create and edit courses'],['media','Manage Media','Upload and organise files'],['homepage','Edit Homepage','Headline, portrait and video'],['students','Manage Students','View learners']].forEach(function(x){qa.appendChild(h('a',{class:'qcard',href:'#'+x[0]},[ico(IC[x[0]]),h('strong',{text:x[1]}),h('small',{text:x[2]}),ico(IC.arrow,'qa-go')]))});
  view.appendChild(cg);view.appendChild(h('div',{class:'two'},[cm,ru]));view.appendChild(ra);
  Promise.all([cnt('profiles'),cnt('courses'),cnt('courses',function(q){return q.eq('published',true)}),cnt('lessons'),cnt('enrolments'),cnt('lesson_progress'),cnt('media_files')]).then(function(v){
   [['Registered users',v[0]],['Courses ('+v[2]+' published)',v[1]],['Lessons',v[3]],['Enrolments',v[4]],['Lessons completed',v[5]],['Media files',v[6]]].forEach(function(s){g.appendChild(h('div',{class:'stat'},[h('strong',{text:String(s[1])}),h('span',{text:s[0]})]))})});
  var since=new Date(Date.now()-30*864e5).toISOString();
  Promise.all([sb.from('profiles').select('created_at').gte('created_at',since),sb.from('enrolments').select('created_at').gte('created_at',since)]).then(function(r){cg.appendChild(chart('New registrations',r[0].data||[],(r[0].data||[]).length));cg.appendChild(chart('New enrolments',r[1].data||[],(r[1].data||[]).length))});
  cm.appendChild(h('h3',{text:'Course management'}));sb.from('courses').select('id,title,published,thumbnail_url,modules(lessons(id))').order('created_at',{ascending:false}).limit(4).then(function(r){var d=r.data||[];if(!d.length)return cm.appendChild(h('p',{text:'No courses yet.'}));
   d.forEach(function(c){var n=(c.modules||[]).reduce(function(a,m){return a+(m.lessons||[]).length},0);cm.appendChild(h('a',{class:'crow',href:'#courses'},[c.thumbnail_url?h('img',{src:c.thumbnail_url,alt:''}):h('span',{class:'sq'}),h('span',{},[h('strong',{text:c.title}),h('small',{text:n+' lessons'})]),h('span',{class:'chip',text:c.published?'Published':'Draft'})]))})});
  ru.appendChild(h('h3',{text:'Recent uploads'}));sb.from('media_files').select('url,name,kind').order('created_at',{ascending:false}).limit(8).then(function(r){var d=r.data||[];if(!d.length)return ru.appendChild(h('p',{text:'Nothing uploaded yet.'}));var gg=h('div',{class:'mgrid'});d.forEach(function(m){gg.appendChild(h('a',{href:'#media',title:m.name},[m.kind==='image'?h('img',{src:m.url,alt:''}):h('span',{class:'sq',text:m.kind})]))});ru.appendChild(gg)});
  ra.appendChild(h('h3',{text:'Recent activity'}));
  platformActivity();
  var L=function(t,s){return sb.from(t).select(s).order('created_at',{ascending:false}).limit(6)};
  Promise.all([L('profiles','id,full_name,email,created_at'),L('enrolments','user_id,course_id,created_at'),sb.from('lesson_progress').select('user_id,lesson_id,completed_at').order('completed_at',{ascending:false}).limit(6),L('media_files','name,created_at'),L('courses','id,title,created_at'),sb.from('profiles').select('id,full_name,email'),sb.from('courses').select('id,title')]).then(function(r){
   var pn={},cn={};(r[5].data||[]).forEach(function(p){pn[p.id]=p.full_name||p.email||'A student'});(r[6].data||[]).forEach(function(c){cn[c.id]=c.title});var ev=[];
   (r[0].data||[]).forEach(function(p){ev.push([p.created_at,(p.full_name||p.email||'A student')+' registered'])});(r[1].data||[]).forEach(function(e){ev.push([e.created_at,(pn[e.user_id]||'A student')+' enrolled in '+(cn[e.course_id]||'a course')])});
   (r[2].data||[]).forEach(function(p){ev.push([p.completed_at,(pn[p.user_id]||'A student')+' completed a lesson'])});(r[3].data||[]).forEach(function(m){ev.push([m.created_at,'Uploaded '+m.name])});(r[4].data||[]).forEach(function(c){ev.push([c.created_at,'Course created: '+c.title])});
   ev.sort(function(a,b){return new Date(b[0])-new Date(a[0])});if(!ev.length)return ra.appendChild(h('p',{text:'No activity yet.'}));var ul=h('ul',{class:'act'});ev.slice(0,8).forEach(function(e){ul.appendChild(h('li',{},[h('span',{text:e[1]}),h('small',{text:ago(e[0])})]))});ra.appendChild(ul)})}
 function platformActivity(){
  var box=h('div',{class:'panel'});box.appendChild(h('h3',{text:'Platform activity log'}));
  var filter=h('select',{},[['all','All activity'],['signup','New accounts'],['enrolment','Course enrolments'],['community_post','Community posts'],['report','Reports']].map(function(x){return h('option',{value:x[0],text:x[1]})}));
  var list=h('div',{class:'act'}),status=h('p',{class:'pmeta',text:'Loading recorded platform events…'});
  box.append(filter,status,list);view.appendChild(box);
  function load(){list.textContent='';status.textContent='Loading…';var q=sb.from('admin_activity').select('id,event_type,actor_id,summary,metadata,created_at').order('created_at',{ascending:false}).limit(100);if(filter.value!=='all')q=q.eq('event_type',filter.value);
   q.then(async function(r){if(r.error){status.textContent='Could not load activity: '+r.error.message;return}var rows=r.data||[],ids=Array.from(new Set(rows.map(function(x){return x.actor_id}).filter(Boolean))),profiles={};
    if(ids.length){var p=await sb.from('profiles').select('id,full_name,email').in('id',ids);(p.data||[]).forEach(function(x){profiles[x.id]=x})}
    status.textContent=rows.length?rows.length+' recorded events':'No events recorded yet.';
    rows.forEach(function(x){var p=profiles[x.actor_id]||{},label=p.full_name||p.email||'Platform event';list.appendChild(h('li',{},[h('span',{text:x.summary}),h('small',{text:label+' · '+ago(x.created_at)})]))})
   })
  }
  filter.addEventListener('change',load);load()
 }
 function analytics(){var since=new Date(Date.now()-30*864e5).toISOString(),g=h('div',{class:'two'});view.appendChild(g);
  Promise.all([sb.from('profiles').select('created_at').gte('created_at',since),sb.from('enrolments').select('created_at').gte('created_at',since),sb.from('lesson_progress').select('completed_at').gte('completed_at',since)]).then(function(r){
   g.appendChild(chart('New registrations',r[0].data||[],(r[0].data||[]).length));g.appendChild(chart('New enrolments',r[1].data||[],(r[1].data||[]).length));
   g.appendChild(chart('Lessons completed',(r[2].data||[]).map(function(x){return{created_at:x.completed_at}}),(r[2].data||[]).length))});
  view.appendChild(h('p',{class:'pmeta',text:'Revenue, completion rates and content performance arrive with later stages. Only real recorded data is shown.'}))}
 function students(){var q=h('input',{type:'search',placeholder:'Search name or email…'}),tb=h('div',{class:'tbl'}),rows=[];view.appendChild(q);view.appendChild(tb);
  Promise.all([sb.from('profiles').select('id,full_name,email,role,verified_badge,created_at').order('created_at',{ascending:false}).limit(300),sb.from('enrolments').select('user_id')]).then(function(r){var ec={};(r[1].data||[]).forEach(function(e){ec[e.user_id]=(ec[e.user_id]||0)+1});rows=r[0].data||[];draw()
   function draw(){tb.textContent='';var t=q.value.trim().toLowerCase(),l=rows.filter(function(p){return!t||((p.full_name||'')+' '+(p.email||'')).toLowerCase().indexOf(t)>-1});if(!l.length)return tb.appendChild(h('p',{text:rows.length?'No matches.':'No users yet.'}));
    l.forEach(function(p){var sel=h('select',{'aria-label':'Role'},['student','creator','instructor','moderator','admin','super_admin'].map(function(x){return h('option',{value:x,text:x.replace('_',' ')})}));sel.value=p.role;if(role!=='super_admin'||p.id===user.id)sel.disabled=true;
     var badge=h('select',{'aria-label':'Verification tick'});[['none','No tick'],['blue','Blue tick']].forEach(function(x){badge.appendChild(h('option',{value:x[0],text:x[1]}))});badge.value=p.verified_badge&&p.verified_badge!=='none'?'blue':'none';if(role!=='super_admin'||p.id===user.id)badge.disabled=true;
     badge.addEventListener('change',function(){sb.from('profiles').update({verified_badge:badge.value}).eq('id',p.id).then(function(u){if(u.error){alert(u.error.message);badge.value=p.verified_badge||'none'}else p.verified_badge=badge.value})});
     sel.addEventListener('change',function(){sb.from('profiles').update({role:sel.value}).eq('id',p.id).then(function(u){if(u.error){alert(u.error.message);sel.value=p.role}else p.role=sel.value})});
     tb.appendChild(h('div',{class:'trow'},[h('span',{},[h('strong',{text:p.full_name||'(no name)'},window.CV_BADGE_ICON&&window.CV_BADGE_ICON(p)?[window.CV_BADGE_ICON(p)]:[]),h('small',{text:p.email||''})]),h('small',{text:(ec[p.id]||0)+' enrolled'}),h('small',{text:new Date(p.created_at).toLocaleDateString()}),sel,badge]))})}
   q.addEventListener('input',draw)});
  if(role!=='super_admin')view.insertBefore(h('div',{class:'note',text:'Only a super admin can change roles and assign or remove the blue verification tick.'}),q)}
 function help(){view.appendChild(h('div',{class:'panel'},[h('h3',{text:'Quick guide'}),h('ul',{class:'guide'},['Homepage Manager: edit the hero, sections and videos. Save draft, Preview, then Publish.','Media Library: upload images and videos once, then pick them anywhere.','Courses: create a course, add modules and lessons, upload a flyer, then Publish.','Students: search learners. Only a super admin can change roles.','Settings: announcement banner and About page text.','If something saves with an error, make sure the SQL files were run in order (phase2, phase3, phase4, stage3, stage5).'].map(function(t){return h('li',{text:t})}))]))}
 window.addEventListener('hashchange',route);route()}};
})();
