(function(){
var pg=document.body.dataset.page,main=document.getElementById('content'),Q=new URLSearchParams(location.search);
if(['courses','course','lesson','admin'].indexOf(pg)<0)return;
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else if(i==='value')e.value=a[i];else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function note(t){main.appendChild(h('div',{class:'note',text:t}))}
function head(t,p){main.textContent='';main.appendChild(h('h1',{text:t}));if(p)main.appendChild(h('p',{text:p}))}
function embed(u){if(!u)return null;var m=u.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]{6,})/);
 if(m)return h('iframe',{class:'academy-lesson-video',src:'https://www.youtube-nocookie.com/embed/'+m[1],allowfullscreen:'',allow:'encrypted-media; fullscreen'});
 if(/^https:\/\/player\.vimeo\.com\//.test(u))return h('iframe',{class:'lesson-video',src:u,allowfullscreen:''});
 if(/\.(mp4|webm)(\?|$)/i.test(u))return h('video',{class:'lesson-video',src:u,controls:''});return null}
function sorted(a){return (a||[]).slice().sort(function(x,y){return x.position-y.position})}
function boot(sb){
 sb.auth.getSession().then(function(r){var user=r.data.session&&r.data.session.user;
  if(user&&pg==='course'&&sb.channel){sb.channel('course-admission-sync-'+user.id).on('postgres_changes',{event:'*',schema:'public',table:'academy_applications',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'academy_admission_offers',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'enrolments',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'payment_orders',filter:'user_id=eq.'+user.id},function(){location.reload()}).subscribe()}if(pg==='courses')courses(sb);else if(pg==='course')course(sb,user);else if(pg==='lesson')lesson(sb,user);else admin(sb,user)})}
function ico(p){var s=document.createElementNS('http://www.w3.org/2000/svg','svg');s.setAttribute('viewBox','0 0 24 24');s.setAttribute('fill','none');s.setAttribute('stroke','currentColor');s.setAttribute('stroke-width','2');s.setAttribute('stroke-linecap','round');s.setAttribute('stroke-linejoin','round');s.innerHTML=p;return s}
var CK='<path d="M20 6 9 17l-5-5"/>',PL='<polygon points="6 3 20 12 6 21 6 3"/>';

function courseImage(c){
 if(c&&c.thumbnail_url)return c.thumbnail_url;
 var images={
  'youtube-automation-foundations':'photo-1492619375914-88005aa9e8fb',
  'ai-content-creation-practical':'photo-1677442136019-21780ecad995',
  'tiktok-growth-monetization':'photo-1611162616475-46b635cb6868',
  'prompt-engineering-mastery':'photo-1555949963-aa79dcee981c',
  'ai-graphic-design-studio':'photo-1626785774573-4b799315345d',
  'digital-business-launchpad':'photo-1556761175-b413da4baf72',
  'algorithm-niche-research-lab':'photo-1460925895917-afdab827c52f',
  '3d-animations-qnnp':'photo-1618005182384-a83a8bd57fbe'
 };
 var id=images[(c&&c.slug)||'']||'photo-1521737711867-e3b97375f902';
 return 'https://images.unsplash.com/'+id+'?auto=format&fit=crop&w=1400&q=88';
}
function nl(c){return(c.modules||[]).reduce(function(a,m){return a+(m.lessons||[]).length},0)}
function ccard(c){
 var n=nl(c),img=courseImage(c),cat=c.category_slug||'Featured learning';
 return h('article',{class:'academy-course-card'+(c.featured?' is-featured':'')},[
  h('a',{class:'academy-course-image',href:'course.html?s='+encodeURIComponent(c.slug),'aria-label':'View '+c.title},[
   h('img',{src:img,alt:c.title+' course cover',loading:'lazy'}),
   h('span',{class:'academy-image-shade'}),
   c.featured?h('span',{class:'academy-featured-tag',text:'FEATURED'}):null,
   h('span',{class:'academy-course-price',text:c.price_ngn?'₦'+Number(c.price_ngn).toLocaleString('en-NG'):'Free'})
  ]),
  h('div',{class:'academy-course-content'},[
   h('div',{class:'academy-course-overline'},[h('span',{class:'academy-category-dot'}),h('span',{text:cat.replace(/[-_]/g,' ')}),h('span',{class:'academy-course-level',text:c.level||'All levels'})]),
   h('h3',{text:c.title}),
   h('p',{text:c.description||'Build practical knowledge and develop skills you can put to work.'}),
   h('div',{class:'academy-course-meta'},[n?h('span',{text:n+(n===1?' lesson':' lessons')}):null,c.duration_text?h('span',{text:c.duration_text}):null]),
   h('a',{class:'academy-course-link',href:'course.html?s='+encodeURIComponent(c.slug),text:'Explore course', 'aria-label':'Explore '+c.title})
  ])
 ]);
}
function courses(sb){
 main.textContent='';main.className='page academy-catalogue';
 var all=[],cats=[],cat=Q.get('c')||'',term='',active='all';
 var hero=h('section',{class:'academy-catalogue-hero'},[
  h('div',{class:'academy-catalogue-copy'},[
   h('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY  /  COURSE LIBRARY'}),
   h('h1',{text:'Learn skills. Make things happen.'}),
   h('p',{text:'Explore practical courses built to help you create, grow your ideas and turn knowledge into real-world ability.'}),
   h('div',{class:'academy-catalogue-highlights'},[
    h('span',{text:'Expert-led learning'}),
    h('span',{text:'Learn at your pace'}),
    h('span',{text:'Practical skills'})
   ])
  ]),
  h('div',{class:'academy-catalogue-visual'},[
   h('img',{src:'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1400&q=88',alt:'Learners collaborating on a creative project',loading:'eager'}),
   h('span',{class:'academy-visual-caption',text:'YOUR NEXT CHAPTER STARTS HERE'})
  ])
 ]);
 main.appendChild(hero);
 var toolbar=h('section',{class:'academy-library-tools'},[
  h('div',{class:'academy-library-heading'},[h('span',{class:'academy-eyebrow',text:'FIND YOUR NEXT SKILL'}),h('h2',{text:'Explore all courses'}),h('p',{text:'Choose a course and start building something valuable.'})]),
  h('div',{class:'academy-search-wrap'},[h('span',{text:'⌕','aria-hidden':'true'}),h('input',{type:'search',placeholder:'Search courses or skills…','aria-label':'Search courses'})])
 ]);
 var search=toolbar.querySelector('input');main.appendChild(toolbar);
 var filters=h('div',{class:'academy-filter-row','aria-label':'Filter courses'});main.appendChild(filters);
 var summary=h('div',{class:'academy-results-summary','aria-live':'polite'});main.appendChild(summary);
 var grid=h('div',{class:'academy-course-grid','aria-live':'polite'});main.appendChild(grid);
 function draw(){
  filters.textContent='';
  [{slug:'',title:'All courses'}].concat(cats).forEach(function(c){var b=h('button',{type:'button',class:'academy-filter'+(c.slug===cat?' active':''),text:c.title,on:function(){cat=c.slug;draw()}});filters.appendChild(b)});
  var list=all.filter(function(c){var q=(c.title+' '+(c.description||'')+' '+(c.category_slug||'')).toLowerCase();return(!cat||c.category_slug===cat)&&(!term||q.indexOf(term)>-1)});
  summary.textContent=list.length+' '+(list.length===1?'course':'courses')+' available';
  grid.textContent='';
  if(!list.length){grid.appendChild(h('div',{class:'academy-empty'},[h('h3',{text:all.length?'No matching courses':'Courses are being prepared'}),h('p',{text:all.length?'Try another search term or choose a different category.':'New learning experiences will appear here as soon as they are published.'})]));return}
  list.forEach(function(c){grid.appendChild(ccard(c))});
 }
 search.addEventListener('input',function(){term=search.value.trim().toLowerCase();draw()});
 Promise.all([sb.from('courses').select('*,modules(lessons(id))').eq('published',true).order('created_at',{ascending:false}),window.CV_CATS()]).then(function(r){
  if(r[0].error){grid.appendChild(h('div',{class:'academy-empty',text:'Courses could not be loaded. Please refresh the page.'}));return}
  all=(r[0].data||[]).slice().sort(function(a,b){return (b.featured?1:0)-(a.featured?1:0)});cats=r[1]||[];
  if(cat&&!cats.some(function(x){return x.slug===cat}))cat='';
  draw();
 }).catch(function(){grid.appendChild(h('div',{class:'academy-empty',text:'Something went wrong while loading courses. Please try again.'}))});
}
function course(sb,user){var s=Q.get('s');
 sb.from('courses').select('*,modules(id,title,position,description,duration_text,stage_number,lessons(id,title,position,estimated_minutes,chapter_number,topic_outline))').eq('slug',s||'').maybeSingle().then(function(r){
  if(!r.data)return head('Course not found');var c=r.data,mods=sorted(c.modules),all=[];mods.forEach(function(m){sorted(m.lessons).forEach(function(l){all.push(l)})});main.textContent='';
  Promise.all([user?sb.from('enrolments').select('course_id').eq('course_id',c.id):{data:[]},user?sb.from('lesson_progress').select('lesson_id'):{data:[]},user?sb.from('academy_applications').select('id,status').eq('course_id',c.id).eq('user_id',user.id).order('created_at',{ascending:false}).limit(1).maybeSingle():{data:null}]).then(function(x){
   var enrolled=x[0].data&&x[0].data.length>0,application=x[2]&&x[2].data,done={};(x[1].data||[]).forEach(function(p){done[p.lesson_id]=1});var d=all.filter(function(l){return done[l.id]}).length,pct=all.length?Math.round(100*d/all.length):0;
   var act=h('div',{class:'hero2-cta'});
   if(!user)act.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to enroll'}));
   else if(enrolled){var nx=all.filter(function(l){return !done[l.id]})[0]||all[0];if(nx)act.appendChild(h('a',{class:'btn btn-primary',href:'lesson.html?l='+nx.id,text:d?'Continue learning':'Start learning'}))}
   else if(application&&application.status==='approved_pending_payment'){var payBtn=h('button',{class:'btn btn-primary',type:'button',text:'Complete payment to unlock course'}),payHost=h('div',{class:'academy-payment-checkout'});payBtn.addEventListener('click',function(){payBtn.disabled=true;payBtn.textContent='Opening secure payment options…';checkout(sb,user,c,payHost);setTimeout(function(){payBtn.remove()},0)});act.append(payBtn,payHost)}
   else if(application&&application.status==='approved'){act.appendChild(h('span',{class:'chip2',text:'Admission approved — activating your learning access'}))}
   else act.appendChild(h('a',{class:'btn btn-primary',href:'academy-apply.html?course='+encodeURIComponent(c.slug),text:application?'View application status':'Apply for admission'}));
   main.appendChild(h('div',{class:'academy-course-detail-hero'},[h('div',{class:'academy-course-detail-copy'},[h('span',{class:'academy-eyebrow',text:(c.category_slug||'CREATORVERSE ACADEMY').replace(/[-_]/g,' ')}),h('span',{class:'chip2',text:c.level||'Beginner'}),h('h1',{text:c.title}),h('p',{class:'lead',text:c.description||''}),
    h('div',{class:'meta'},[all.length?h('span',{text:all.length+(all.length===1?' lesson':' lessons')}):null,c.duration_text?h('span',{text:c.duration_text}):null,h('span',{text:c.price_ngn?'₦'+c.price_ngn:'Free'})]),
    enrolled?h('div',{},[bar2(pct),h('p',{class:'pmeta',text:d+' of '+all.length+' lessons completed ('+pct+'%)'})]):null,act]),
    h('img',{class:'academy-detail-cover',src:courseImage(c),alt:c.title+' course cover',loading:'eager'})]));
   var ol=(c.outcomes||'').split('\n').map(function(x){return x.trim()}).filter(Boolean),rq=(c.requirements||'').split('\n').map(function(x){return x.trim()}).filter(Boolean);
   if(ol.length){main.appendChild(h('h2',{class:'academy-section-title',text:'What you will learn'}));var u1=h('ul',{class:'academy-lesson-list'});ol.forEach(function(t){u1.appendChild(h('li',{},[h('span',{class:'outc'},[h('span',{class:'dot on'},[ico(CK)]),h('span',{text:t})])]))});main.appendChild(u1)}
   if(rq.length){main.appendChild(h('h2',{class:'academy-section-title',text:'What you need to get started'}));var u2=h('ul');rq.forEach(function(t){u2.appendChild(h('li',{text:t}))});main.appendChild(u2)}
   main.appendChild(h('h2',{class:'academy-section-title',text:'Course curriculum'}));if(!mods.length)note('No lessons have been added yet.');
   mods.forEach(function(m,i){var ul=h('ul',{class:'clist'});sorted(m.lessons).forEach(function(l){ul.appendChild(h('li',{},[h('a',{href:'lesson.html?l='+l.id},[h('span',{class:'dot'+(done[l.id]?' on':'')},[done[l.id]?ico(CK):null]),h('span',{text:l.title+(l.estimated_minutes?' · '+l.estimated_minutes+' min':'')})])]))});
    main.appendChild(h('details',{class:'academy-module',open:''},[h('summary',{text:(m.stage_number?'Stage '+m.stage_number+' · ':'')+m.title+' · '+(m.lessons||[]).length+' chapters'+(m.duration_text?' · '+m.duration_text:'')}),m.description?h('p',{class:'pmeta',text:m.description}):null,ul]))});window.CV_ASSESS&&main.appendChild(window.CV_ASSESS.courseBlock(sb,user,c,enrolled,all,done));})})}
function checkout(sb,user,c,host){
 host.textContent='';host.appendChild(h('p',{class:'pmeta',text:'Loading available payment methods…'}));
 sb.from('payment_settings').select('*').eq('id',true).maybeSingle().then(function(r){
  host.textContent='';if(r.error){host.appendChild(h('div',{class:'note',text:'Unable to load payment options: '+r.error.message}));return}
  var cfg=r.data||{},methods=[];
  if(cfg.bank_transfer_enabled&&cfg.bank_name&&cfg.account_name&&cfg.account_number)methods.push(['bank_transfer','Bank transfer']);
  if(cfg.ussd_enabled&&cfg.ussd_instructions)methods.push(['ussd','USSD']);
  if(!methods.length){host.appendChild(h('div',{class:'note',text:'Checkout is being configured. Please check back later.'}));return}
  var select=h('select',{},methods.map(function(m){return h('option',{value:m[0],text:m[1]})})),start=h('button',{class:'btn btn-primary',type:'button',text:'Continue to payment'});host.append(select,start);
  start.addEventListener('click',function(){start.disabled=true;start.textContent='Creating payment…';
   sb.from('payment_orders').insert({user_id:user.id,course_id:c.id,method:select.value}).select('*').single().then(function(x){
    if(x.error){start.disabled=false;start.textContent='Continue to payment';host.appendChild(h('p',{class:'msg err',text:x.error.message}));return}
    var o=x.data;host.textContent='';var title=h('h3',{text:'Complete your payment'}),ref=h('p',{text:'Payment reference: '+o.reference}),amount=h('h2',{text:'₦'+Number(o.amount_ngn).toLocaleString('en-NG')}),timer=h('p',{class:'countdown'}),details=h('div',{class:'note'}),copy;
    if(o.method==='bank_transfer'){details.append(h('p',{text:'Bank: '+cfg.bank_name}),h('p',{text:'Account name: '+cfg.account_name}),h('p',{text:'Account number: '+cfg.account_number}));copy=h('button',{class:'btn btn-outline',type:'button',text:'Copy account number',on:function(){if(navigator.clipboard&&navigator.clipboard.writeText)navigator.clipboard.writeText(cfg.account_number).then(function(){copy.textContent='Copied ✓'}).catch(function(){alert('Copy failed. Please copy the number manually.')});else alert('Please copy: '+cfg.account_number)}});details.append(copy)}
    else details.append(h('p',{text:cfg.ussd_instructions}));
    var tr=h('input',{type:'text',placeholder:'Bank transfer reference / narration'}),submit=h('button',{class:'btn btn-primary',type:'button',text:'I have made the payment'}),state=h('p',{class:'pmeta',text:'After submitting, your payment will wait for admin verification.'});
    host.append(title,amount,ref,details,timer,tr,submit,state);
    var deadline=new Date(o.expires_at).getTime(),tick=setInterval(function(){var left=Math.max(0,deadline-Date.now()),m=Math.floor(left/60000),s=Math.floor(left%60000/1000);timer.textContent=left?'Time remaining: '+m+':'+String(s).padStart(2,'0'):'Payment window expired';if(!left){clearInterval(tick);submit.disabled=true}},1000);
    submit.addEventListener('click',function(){if(!tr.value.trim())return alert('Enter your bank transaction reference first.');submit.disabled=true;sb.from('payment_orders').update({status:'proof_submitted',transfer_reference:tr.value.trim()}).eq('id',o.id).then(function(z){if(z.error){submit.disabled=false;state.textContent=z.error.message}else{clearInterval(tick);timer.textContent='Submitted for verification';state.textContent='Your payment reference has been submitted. The course unlocks after an administrator confirms receipt.'}})});
   })
  })
 })
}
function bar2(p){return h('div',{class:'progress'},[h('span',{style:'width:'+p+'%'})])}
function lesson(sb,user){
 sb.from('lessons').select('*,modules(course_id,title,courses(slug,title,price_ngn))').eq('id',Q.get('l')||'').maybeSingle().then(function(r){
  var l=r.data;if(!l)return head('Lesson not available','It may not exist, or you need to enroll in the course first.');
  var c=l.modules.courses,cid=l.modules.course_id;main.textContent='';
  Promise.all([sb.from('modules').select('id,title,position,description,duration_text,stage_number,lessons(id,title,position,estimated_minutes,chapter_number,topic_outline)').eq('course_id',cid),user?sb.from('lesson_progress').select('lesson_id'):{data:[]},user?sb.from('enrolments').select('course_id').eq('course_id',cid).maybeSingle():{data:null}]).then(function(x){
   if(!user||!x[2].data){head('Course access required','Please enroll in this course before opening its lessons.');main.appendChild(h('a',{class:'btn btn-primary',href:'course.html?s='+encodeURIComponent(c.slug),text:'Return to course'}));return}
   Promise.resolve(sb.rpc('record_academy_lesson_view',{p_lesson_id:l.id})).catch(function(){});
   var mods=sorted(x[0].data),flat=[],done={};mods.forEach(function(m){sorted(m.lessons).forEach(function(q){flat.push(q.id)})});(x[1].data||[]).forEach(function(p){done[p.lesson_id]=1});
   var i=flat.indexOf(l.id),n=flat.filter(function(q){return done[q]}).length,pct=flat.length?Math.round(100*n/flat.length):0;
   var side=h('aside',{class:'academy-lesson-sidebar'},[h('h3',{text:'Course content'}),bar2(pct),h('p',{class:'pmeta',text:n+' of '+flat.length+' completed'})]);
   mods.forEach(function(m){side.appendChild(h('h4',{text:m.title}));var ul=h('ul',{class:'clist'});sorted(m.lessons).forEach(function(q){ul.appendChild(h('li',{class:q.id===l.id?'cur':''},[h('a',{href:'lesson.html?l='+q.id},[h('span',{class:'dot'+(done[q.id]?' on':'')},[done[q.id]?ico(CK):null]),h('span',{text:q.title+(q.estimated_minutes?' · '+q.estimated_minutes+' min':'')})])]))});side.appendChild(ul)});
   var col=h('div',{class:'academy-lesson-main'},[h('a',{class:'back',href:'course.html?s='+encodeURIComponent(c.slug),text:'← '+c.title}),h('div',{class:'pmeta',text:(l.chapter_number?'Chapter '+l.chapter_number+' · ':'')+(l.estimated_minutes||30)+' minute lesson'}),h('h1',{text:l.title}),l.topic_outline?h('p',{class:'lead',text:l.topic_outline}):null]);var v=embed(l.video_url);if(v)col.appendChild(v);
   if(l.content)col.appendChild(h('div',{class:'academy-lesson-text',text:l.content}));var rl=h('div');col.appendChild(rl);sb.from('lesson_resources').select('title,url,position').eq('lesson_id',l.id).then(function(rr){var d=sorted(rr.data||[]);if(!d.length)return;rl.appendChild(h('h3',{class:'mod',text:'Resources'}));var ul=h('ul',{class:'clist'});d.forEach(function(x){ul.appendChild(h('li',{},[h('a',{href:x.url,target:'_blank',rel:'noopener'},[h('span',{class:'dot'},[ico('<path d="M12 15V3"/><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/>')]),h('span',{text:x.title})])]))});rl.appendChild(ul)});
   var row=h('div',{class:'row'});col.appendChild(row);
   if(i>0)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+flat[i-1],text:'← Previous'}));
   if(!user)row.appendChild(h('a',{class:'btn btn-primary',href:'login.html',text:'Log in to track progress'}));
   else row.appendChild(h('button',{class:'btn btn-primary',type:'button',text:done[l.id]?'Completed ✓':'Mark as completed',on:function(){if(done[l.id])return;sb.from('lesson_progress').insert({user_id:user.id,lesson_id:l.id}).then(function(e){if(e.error)throw e.error;return sb.rpc('refresh_academy_learner_level',{p_course_id:cid})}).then(function(){location.href=i<flat.length-1?'lesson.html?l='+flat[i+1]:'course.html?s='+encodeURIComponent(c.slug)}).catch(function(e){alert('Your lesson was saved, but your level progress could not refresh yet: '+(e.message||String(e)))})}}));
   if(i<flat.length-1)row.appendChild(h('a',{class:'btn btn-outline',href:'lesson.html?l='+flat[i+1],text:'Next →'}));
   main.appendChild(h('div',{class:'academy-lesson-layout'},[col,side]))})})}
function admin(sb,user){
 head('Admin');
 if(!user){location.href='login.html';return}
 var loading=h('p',{class:'pmeta',text:'Checking administrator access…'});main.appendChild(loading);
 sb.from('profiles').select('role').eq('id',user.id).maybeSingle().then(function(p){
  if(p.error){head('Admin dashboard unavailable');note('Your administrator profile could not be loaded: '+p.error.message);return}
  var ro=p.data&&p.data.role;
  if(ro!=='admin'&&ro!=='super_admin'){head('Access restricted');note('Administrators only. Sign in with an administrator account.');return}
  var P1=h('div'),P2=h('div'),P3=h('div'),P4=h('div'),P5=h('div'),P6=h('div'),P7=h('div'),P8=h('div'),P9=h('div'),P10=h('div'),P11=h('div'),P12=h('div');
  var panes={courses:P1,media:P2,settings:P3,homepage:P4,founder:P5,video:P6,categories:P7,assess:P8,certs:P9,payments:P11,admissions:P12,homepageBackground:P10};
  if(!window.CV_SHELL||typeof window.CV_SHELL.mount!=='function'){head('Admin dashboard unavailable');note('The admin interface script did not load. Refresh the page or try again later.');return}
  window.CV_SHELL.mount(sb,user,ro,panes);
  function safe(label,host,fn){try{if(typeof fn!=='function')throw new Error(label+' module did not load.');fn(host)}catch(e){console.error('CreatorVerse admin module:',label,e);host.appendChild(h('div',{class:'note',text:label+' could not load: '+(e.message||String(e))}))}}
  safe('Admissions',P12,function(host){if(!window.CV_ACADEMY_ADMIN||typeof window.CV_ACADEMY_ADMIN.mount!=='function')throw new Error('Admissions module is unavailable.');window.CV_ACADEMY_ADMIN.mount(host,sb,user,ro)});
  safe('Assessments',P8,function(host){if(!window.CV_ASSESS_ADMIN)throw new Error('Assessment module is unavailable.');window.CV_ASSESS_ADMIN.assess(host)});
  safe('Certificates',P9,function(host){if(!window.CV_ASSESS_ADMIN)throw new Error('Certificate module is unavailable.');window.CV_ASSESS_ADMIN.certs(host)});
  safe('Courses',P1,window.CV_COURSES);
  safe('Media library',P2,function(host){window.CV_CMS.media(host)});
  safe('Site settings',P3,function(host){window.CV_CMS.site(host)});
  safe('Homepage manager',P4,function(host){window.CV_CMS.homepage(host)});
  safe('Founder profile',P5,function(host){window.CV_CMS.founder(host)});
  safe('Introduction video',P6,function(host){window.CV_CMS.video(host)});
  safe('Categories',P7,function(host){window.CV_CMS.categories(host)});
  safe('Homepage background',P10,function(host){window.CV_CMS.homepageBackground(host)});
  safe('Payments',P11,function(host){if(!window.CV_PAYMENTS_ADMIN)throw new Error('Payments module is unavailable.');window.CV_PAYMENTS_ADMIN.mount(host,sb,user,ro)});
 }).catch(function(e){console.error('CreatorVerse admin initialization failed:',e);head('Admin dashboard unavailable');note('The dashboard could not finish loading: '+(e.message||String(e)))})
}
if(window.CV_SB)boot(window.CV_SB);else document.addEventListener('cv-ready',function(){boot(window.CV_SB)});
})();
