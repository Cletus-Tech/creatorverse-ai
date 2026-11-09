(function(){
function el(tag,attrs,children){var n=document.createElement(tag);Object.keys(attrs||{}).forEach(function(k){if(k==='text')n.textContent=attrs[k];else if(k==='html')n.innerHTML=attrs[k];else n.setAttribute(k,attrs[k])});(children||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function sorted(a){return(a||[]).slice().sort(function(x,y){return(x.position||0)-(y.position||0)})}

function courseImage(c){
 if(c&&c.thumbnail_url)return c.thumbnail_url;
 var s=((c&&c.title)||'').toLowerCase()+' '+((c&&c.category_slug)||'').toLowerCase();
 var map=[
  [/artificial intelligence|\bai\b|machine learning|prompt/,'photo-1677442136019-21780ecad995'],
  [/graphic|design|illustrat|photoshop|canva/,'photo-1626785774573-4b799315345d'],
  [/web|coding|program|developer|javascript|software/,'photo-1498050108023-c5249f4df085'],
  [/video|film|editing|motion|animation/,'photo-1574717024653-61fd2cf4d44d'],
  [/market|social media|marketing|seo|brand/,'photo-1557838923-2985c318be48'],
  [/business|entrepreneur|startup|finance/,'photo-1556761175-b413da4baf72'],
  [/photo|photography|camera/,'photo-1516035069371-29a1b244cc32'],
  [/content|creator|youtube|writing/,'photo-1492619375914-88005aa9e8fb']
 ];
 var id='photo-1516321318423-f06f85e504b3';
 for(var i=0;i<map.length;i++){if(map[i][0].test(s)){id=map[i][1];break}}
 return 'https://images.unsplash.com/'+id+'?auto=format&fit=crop&w=1100&q=85';
}

function initials(n){return(n||'S').trim().split(/\s+/).slice(0,2).map(function(x){return x[0]||''}).join('').toUpperCase()}
function progress(p){var w=el('div',{class:'cv-progress'});w.appendChild(el('span',{style:'width:'+Math.max(0,Math.min(100,p))+'%'}));return w}
function note(target,msg,type){target.textContent=msg;target.className='cv-feedback '+(type||'')}
window.CV_DASH=function(sb,session,X){
 var user=session.user,meta=user.user_metadata||{},display=meta.full_name||'',avatar=meta.avatar_url||'',main=document.getElementById('content');if(sb.channel){var academySync=sb.channel('student-academy-sync-'+user.id).on('postgres_changes',{event:'*',schema:'public',table:'enrolments',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'academy_applications',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'academy_learning_activity',filter:'user_id=eq.'+user.id},function(){location.reload()}).on('postgres_changes',{event:'*',schema:'public',table:'lesson_progress',filter:'user_id=eq.'+user.id},function(){location.reload()}).subscribe();}
 main.className='page cv-student';main.innerHTML='';
 var shell=el('div',{class:'cv-dash-shell'});
 var side=el('aside',{class:'cv-dash-side'});
 side.appendChild(el('a',{class:'cv-side-brand',href:'index.html',text:'CreatorVerse AI'}));
 side.appendChild(el('div',{class:'cv-side-label',text:'LEARNING SPACE'}));
 [['Overview','#overview'],['Engagement','#engagement'],['My learning','#learning'],['Achievements','#achievements'],['Profile settings','#profile']].forEach(function(x,i){side.appendChild(el('a',{class:'cv-side-link'+(!i?' active':''),href:x[1],text:x[0]}))});
 side.appendChild(el('a',{class:'cv-side-link',href:'academy-status.html',text:'Academy status & interviews'}));side.appendChild(el('a',{class:'cv-side-link cv-side-explore',href:'courses.html',text:'Explore courses'}));
 side.appendChild(el('div',{class:'cv-side-bottom'},[el('div',{class:'cv-side-mini',text:'Your learning journey, one lesson at a time.'}),el('button',{class:'cv-logout',type:'button',text:'Sign out'})]));
 var area=el('div',{class:'cv-dash-area'});
 var topName=el('span',{class:'cv-top-name',text:display||'Student'}),topAvatar=avatar?el('img',{src:avatar,alt:'Profile photo'}):el('span',{class:'cv-avatar-sm',text:initials(display)});sb.from('profiles').select('id,full_name,avatar_url,verified_badge,role').eq('id',user.id).maybeSingle().then(function(r){if(!r.error&&r.data){var p=r.data;display=p.full_name||display||'Student';topName.textContent=display;var tick=window.CV_BADGE_ICON&&window.CV_BADGE_ICON(p);if(tick)topName.appendChild(tick);var photo=p.avatar_url||avatar;if(photo){var im=el('img',{src:photo,alt:'Profile photo'});topAvatar.replaceWith(im);topAvatar=im}else if(topAvatar.tagName==='IMG'){var fallback=el('span',{class:'cv-avatar-sm',text:initials(display)});topAvatar.replaceWith(fallback);topAvatar=fallback}else topAvatar.textContent=initials(display);}});var top=el('header',{class:'cv-dash-top'},[el('div',{class:'cv-breadcrumb',text:'Student portal  /  Overview'}),el('div',{class:'cv-top-user'},[topName,topAvatar])]);
 var body=el('div',{class:'cv-dash-content',id:'overview'});
 var hero=el('section',{class:'cv-welcome'},[el('div',{class:'cv-welcome-copy'},[el('span',{class:'cv-kicker',text:'YOUR LEARNING SPACE'}),el('h1',{text:'Welcome back, '+(display.trim().split(/\s+/)[0]||'Creator')+'.'}),el('p',{text:'Keep building your skills. Your next breakthrough starts with the next lesson.'}),el('a',{class:'cv-hero-btn',href:'courses.html',text:'Explore learning paths'})]),el('div',{class:'cv-welcome-art'},[el('span',{class:'cv-orbit o1'}),el('span',{class:'cv-orbit o2'}),el('span',{class:'cv-art-mark',text:'CV'})])]);
 body.appendChild(hero);
 var stats=el('section',{class:'cv-stat-grid'});
 var learning=el('section',{id:'learning',class:'cv-section'});
 var ach=el('section',{id:'achievements',class:'cv-section'});
 var profile=el('section',{id:'profile',class:'cv-section cv-profile-section'});
 var footer=el('div',{class:'cv-dash-footer',text:'CreatorVerse AI · Learn. Create. Grow.'});
 area.appendChild(top);area.appendChild(body);shell.appendChild(side);shell.appendChild(area);main.appendChild(shell);
 side.querySelector('.cv-logout').addEventListener('click',function(){sb.auth.signOut().then(function(){location.href='index.html'})});
 function stat(label,value,detail){return el('article',{class:'cv-stat'},[el('span',{class:'cv-stat-label',text:label}),el('strong',{class:'cv-stat-value',text:String(value)}),el('small',{text:detail})])}
 Promise.all([
 sb.from('enrolments').select('created_at,courses(id,slug,title,description,thumbnail_url,modules(id,position,lessons(id,title,position)))').order('created_at',{ascending:false}),
 sb.from('lesson_progress').select('lesson_id,completed_at').order('completed_at',{ascending:false}),
 sb.from('certificates').select('certificate_no,course_title,issued_at,revoked').order('issued_at',{ascending:false}),
 sb.from('quiz_attempts').select('score,passed,created_at,quizzes(title)').order('created_at',{ascending:false}).limit(5)
 ]).then(function(res){
 var enrol=(res[0].data||[]).filter(function(x){return x.courses}),pr=res[1].data||[],certs=res[2].data||[],quizzes=res[3].data||[],done={};pr.forEach(function(x){done[x.lesson_id]=true});
 var courses=enrol.map(function(e){var c=e.courses,lessons=[];sorted(c.modules).forEach(function(m){sorted(m.lessons).forEach(function(l){lessons.push(l)})});var completed=lessons.filter(function(l){return done[l.id]}).length;return{course:c,total:lessons.length,completed:completed,pct:lessons.length?Math.round(completed/lessons.length*100):0,next:lessons.filter(function(l){return !done[l.id]})[0]||lessons[0]||null}});
 var total=courses.reduce(function(a,c){return a+c.total},0),complete=courses.reduce(function(a,c){return a+c.completed},0),pct=total?Math.round(complete/total*100):0;
 stats.appendChild(stat('Enrolled courses',courses.length,'Your active learning paths'));stats.appendChild(stat('Lessons completed',complete,'Keep your momentum'));stats.appendChild(stat('Overall progress',pct+'%','Across your enrolled courses'));body.appendChild(stats);
  var engagement=el('section',{id:'engagement',class:'cv-section cv-engagement-section'});
  engagement.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'YOUR LEARNING RHYTHM'}),el('h2',{text:'Engagement & weekly goals'}),el('p',{text:'See your learning activity and the expectations set by your Academy administrators.'})])]));
  var engagementState=el('div',{class:'cv-engagement-loading',text:'Loading your engagement report…'});
  engagement.appendChild(engagementState);body.appendChild(engagement);
  function engagementMessage(state){
    return ({on_track:'You are meeting your current learning target. Keep your momentum going.',
      below_target:'You are below your weekly learning target. Set aside some time to continue a lesson this week.',
      inactive:'Your learning has been quiet for a while. Return to your course and pick up where you stopped.',
      not_started:'You have not started a lesson in this course yet. Begin your first lesson to start building your learning record.'})[state]||'Keep making progress in your course.';
  }
  function engagementLabel(state){return ({on_track:'On track',below_target:'Below weekly target',inactive:'Needs attention',not_started:'Not started'})[state]||state}
  sb.rpc('student_get_my_engagement').then(function(r){
    if(r.error){engagementState.className='cv-engagement-empty';engagementState.textContent='Your engagement report is temporarily unavailable. Please refresh the page later.';return}
    var report=r.data||{},items=report.courses||[];
    engagementState.textContent='';
    if(!items.length){engagementState.className='cv-engagement-empty';engagementState.textContent='Your course engagement report will appear here when you have an active enrolment.';return}
    engagementState.className='cv-engagement-grid';
    items.forEach(function(item){
      var card=el('article',{class:'cv-engagement-card'});
      var head=el('div',{class:'cv-engagement-card-head'});
      head.appendChild(el('div',{},[el('span',{class:'cv-engagement-overline',text:'COURSE ENGAGEMENT'}),el('h3',{text:item.course_title||'Your course'})]));
      head.appendChild(el('span',{class:'cv-engagement-status '+(item.status||''),text:engagementLabel(item.status)}));
      card.appendChild(head);
      card.appendChild(el('p',{class:'cv-engagement-message',text:engagementMessage(item.status)}));
      var target=Number(item.min_events_per_week)||0,events=Number(item.events_7d)||0,weekly=target?Math.min(100,Math.round(events/target*100)):100;
      var goal=el('div',{class:'cv-engagement-goal'});
      goal.appendChild(el('div',{class:'cv-engagement-goal-copy'},[el('strong',{text:'Weekly learning activity'}),el('span',{text:events+' / '+target+' activities'})]));
      var track=el('div',{class:'cv-engagement-track'});track.appendChild(el('span',{style:'width:'+weekly+'%'}));goal.appendChild(track);
      goal.appendChild(el('small',{text:'Your Academy-set target is '+target+' learning activities every 7 days.'}));card.appendChild(goal);
      var details=el('div',{class:'cv-engagement-details'});
      details.appendChild(el('div',{},[el('strong',{text:String(item.lessons_completed||0)+' / '+String(item.total_lessons||0)}),el('small',{text:'Lessons completed'})]));
      details.appendChild(el('div',{},[el('strong',{text:String(item.lesson_views_7d||0)}),el('small',{text:'Lesson views this week'})]));
      var last=item.last_activity?new Date(item.last_activity).toLocaleDateString(undefined,{day:'numeric',month:'short',year:'numeric'}):'No activity yet';
      details.appendChild(el('div',{},[el('strong',{text:last}),el('small',{text:'Last learning activity'})]));
      card.appendChild(details);
      var action=el('a',{class:'cv-engagement-link',href:item.course_slug?'course.html?s='+encodeURIComponent(item.course_slug):'courses.html',text:item.status==='on_track'?'Continue learning':'Open my course'});
      card.appendChild(action);engagementState.appendChild(card);
    });
  }).catch(function(){engagementState.className='cv-engagement-empty';engagementState.textContent='Your engagement report is temporarily unavailable. Please refresh the page later.'});


 var sessionsSection=el('section',{class:'cv-section cv-session-section'});
 sessionsSection.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'ACADEMY SCHEDULE'}),el('h2',{text:'Scheduled learning sessions'}),el('p',{text:'Check in during a scheduled session to record your attendance. A missed session is recorded only when its time window has ended without a check-in.'})])]));
 var sessionsList=el('div',{class:'cv-engagement-loading',text:'Loading your schedule…'});sessionsSection.appendChild(sessionsList);body.appendChild(sessionsSection);
 sb.rpc('student_get_my_learning_sessions').then(function(r){
  sessionsList.textContent='';var rows=r.data||[];
  if(r.error){sessionsList.className='cv-engagement-empty';sessionsList.textContent='Your schedule is temporarily unavailable.';return}
  if(!rows.length){sessionsList.className='cv-engagement-empty';sessionsList.textContent='There are no scheduled learning sessions for your enrolled courses yet.';return}
  sessionsList.className='cv-engagement-grid';
  rows.forEach(function(x){var card=el('article',{class:'cv-engagement-card'}),state={upcoming:'Upcoming',open:'Open for check-in',checked_in:'Checked in',missed:'Missed'}[x.status]||x.status;
   card.appendChild(el('div',{class:'cv-engagement-card-head'},[el('div',{},[el('span',{class:'cv-engagement-overline',text:x.course_title||'Course'}),el('h3',{text:x.title})]),el('span',{class:'cv-engagement-status '+x.status,text:state})]));
   if(x.description)card.appendChild(el('p',{class:'cv-engagement-message',text:x.description}));
   card.appendChild(el('p',{class:'cv-muted',text:new Date(x.starts_at).toLocaleString()+' – '+new Date(x.ends_at).toLocaleString()}));
   if(x.status==='open'){var btn=el('button',{class:'cv-hero-btn',type:'button',text:'Check in now'}),msg=el('small',{class:'cv-muted'});btn.addEventListener('click',function(){btn.disabled=true;msg.textContent='Recording check-in…';sb.rpc('student_check_in_learning_session',{p_session_id:x.id}).then(function(z){if(z.error){btn.disabled=false;msg.textContent=z.error.message;return}msg.textContent='Your check-in has been recorded.';btn.textContent='Checked in';btn.disabled=true;location.reload()})});card.append(btn,msg)}
   if(x.status==='checked_in')card.appendChild(el('small',{class:'cv-muted',text:'Checked in '+new Date(x.checked_in_at).toLocaleString()}));
   if(x.status==='missed')card.appendChild(el('small',{class:'cv-muted',text:'This session ended without a recorded check-in. Contact your Academy administrator if you believe this is incorrect.'}));
   sessionsList.appendChild(card);
  });
 }).catch(function(){sessionsList.className='cv-engagement-empty';sessionsList.textContent='Your schedule is temporarily unavailable.'});

 var interventionSection=el('section',{class:'cv-section cv-intervention-section'});
 interventionSection.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'ACADEMY SUPPORT'}),el('h2',{text:'Interventions & follow-up'}),el('p',{text:'Messages from your Academy administrators that need your attention.'})])]));
 var interventionList=el('div',{class:'cv-engagement-loading',text:'Loading follow-up items…'});interventionSection.appendChild(interventionList);body.appendChild(interventionSection);
 sb.rpc('student_get_my_interventions').then(function(r){interventionList.textContent='';if(r.error){interventionList.className='cv-engagement-empty';interventionList.textContent='Your follow-up messages are temporarily unavailable.';return}var items=r.data||[];if(!items.length){interventionList.className='cv-engagement-empty';interventionList.textContent='You have no open interventions. Keep up your learning progress.';return}interventionList.className='cv-engagement-grid';items.forEach(function(it){var box=el('article',{class:'cv-engagement-card'}),label=it.status==='resolved'?'Resolved':it.status==='responded'?'Response submitted':'Action required';box.append(el('div',{class:'cv-engagement-card-head'},[el('div',{},[el('span',{class:'cv-engagement-overline',text:it.course_title||'General Academy notice'}),el('h3',{text:it.title})]),el('span',{class:'cv-engagement-status '+it.status,text:label})]),el('p',{class:'cv-engagement-message',text:it.message}));if(it.action_required)box.append(el('p',{class:'cv-muted',text:'Next step: '+it.action_required}));if(it.due_at)box.append(el('p',{class:'cv-muted',text:'Follow-up deadline: '+new Date(it.due_at).toLocaleString()}));if(it.student_response)box.append(el('p',{class:'cv-muted',text:'Your response: '+it.student_response}));if(it.status!=='resolved'&&it.status!=='responded'){var reply=el('textarea',{rows:'3',placeholder:'Write your response to the Academy…'}),send=el('button',{type:'button',class:'cv-hero-btn',text:'Submit response'}),msg=el('small',{class:'cv-muted'});send.addEventListener('click',function(){if(reply.value.trim().length<3){msg.textContent='Please write a short response first.';return}send.disabled=true;sb.rpc('student_respond_to_intervention',{p_intervention_id:it.id,p_response:reply.value.trim()}).then(function(z){if(z.error){send.disabled=false;msg.textContent=z.error.message;return}msg.textContent='Your response has been submitted to the Academy.';send.textContent='Response submitted';location.reload()})});box.append(reply,send,msg)}else if(it.status==='responded')box.append(el('small',{class:'cv-muted',text:'Your response has been sent. The Academy team will review it.'}));interventionList.appendChild(box)})}).catch(function(){interventionList.className='cv-engagement-empty';interventionList.textContent='Your follow-up messages are temporarily unavailable.'});

 body.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'PICK UP WHERE YOU LEFT OFF'}),el('h2',{text:'Continue learning'})]),el('a',{href:'courses.html',class:'cv-text-link',text:'Browse courses →'})]));
 if(!courses.length){body.appendChild(el('div',{class:'cv-empty'},[el('div',{class:'cv-empty-icon',text:'＋'}),el('h3',{text:'Your learning journey starts here'}),el('p',{text:'Explore the course library and enrol in a learning path to see your progress here.'}),el('a',{class:'cv-hero-btn',href:'courses.html',text:'Explore courses'})]))}
 else{var next=courses.filter(function(c){return c.next&&c.pct<100})[0]||courses[0];var card=el('article',{class:'cv-continue-card'},[next.course.thumbnail_url?el('img',{class:'cv-course-cover',src:next.course.thumbnail_url,alt:''}):el('div',{class:'cv-course-cover cv-course-placeholder',text:'CV'}),el('div',{class:'cv-continue-info'},[el('span',{class:'cv-course-tag',text:'YOUR CURRENT COURSE'}),el('h3',{text:next.course.title}),el('p',{text:next.next?(next.pct===100?'You have completed this course. Revisit a lesson anytime.':'Next lesson: '+next.next.title):'Course lessons are being prepared.'}),progress(next.pct),el('div',{class:'cv-course-meta'},[el('span',{text:next.completed+' of '+next.total+' lessons completed'}),el('strong',{text:next.pct+'%'})]),next.next?el('a',{class:'cv-hero-btn',href:'lesson.html?l='+encodeURIComponent(next.next.id),text:next.pct===100?'Review course':'Continue lesson'}):null])]);body.appendChild(card);
 body.appendChild(el('div',{class:'cv-section-heading cv-my-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'YOUR LIBRARY'}),el('h2',{text:'My courses'})]),el('span',{class:'cv-muted',text:courses.length+' enrolled'})]));
 var grid=el('div',{class:'cv-course-grid'});courses.forEach(function(c){grid.appendChild(el('article',{class:'cv-course-card'},[el('img',{src:courseImage(c.course),alt:c.course.title+' course cover',class:'cv-course-thumb',loading:'lazy'}),el('div',{class:'cv-course-card-body'},[el('h3',{text:c.course.title}),el('p',{text:c.course.description||'Continue developing practical digital skills.'}),progress(c.pct),el('div',{class:'cv-course-meta'},[el('span',{text:c.completed+'/'+c.total+' lessons'}),el('strong',{text:c.pct+'%'})]),el('a',{href:c.next?'lesson.html?l='+encodeURIComponent(c.next.id):'course.html?s='+encodeURIComponent(c.course.slug),class:'cv-text-link',text:c.next?'Resume learning →':'View course →'})])]))});body.appendChild(grid)}
 var act=el('section',{class:'cv-section'});act.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'YOUR MOMENTUM'}),el('h2',{text:'Recent learning activity'})])]));
 if(pr.length){var list=el('div',{class:'cv-activity-list'});pr.slice(0,5).forEach(function(p){list.appendChild(el('div',{class:'cv-activity-row'},[el('span',{class:'cv-activity-check',text:'✓'}),el('div',{},[el('strong',{text:'Lesson completed'}),el('small',{text:new Date(p.completed_at).toLocaleString()})])]))});act.appendChild(list)}else act.appendChild(el('div',{class:'cv-empty compact',text:'Your completed lessons will appear here.'}));body.appendChild(act);
 ach.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'MILESTONES'}),el('h2',{text:'Achievements & results'})])]));
 var achgrid=el('div',{class:'cv-achievement-grid'});achgrid.appendChild(el('article',{class:'cv-achievement-card'},[el('span',{class:'cv-ach-icon',text:'✦'}),el('strong',{text:certs.length}),el('small',{text:'Certificates earned'})]));achgrid.appendChild(el('article',{class:'cv-achievement-card'},[el('span',{class:'cv-ach-icon',text:'✓'}),el('strong',{text:quizzes.length}),el('small',{text:'Recent quiz attempts'})]));ach.appendChild(achgrid);
 if(certs.length){certs.forEach(function(c){ach.appendChild(el('div',{class:'cv-certificate-row'},[el('div',{},[el('strong',{text:c.course_title}),el('small',{text:new Date(c.issued_at).toLocaleDateString()+(c.revoked?' · Revoked':'')})]),el('a',{class:'cv-text-link',href:'certificate.html?n='+encodeURIComponent(c.certificate_no),text:'View certificate →'})]))})}
 if(quizzes.length){quizzes.forEach(function(q){ach.appendChild(el('div',{class:'cv-certificate-row'},[el('div',{},[el('strong',{text:q.quizzes&&q.quizzes.title||'Quiz attempt'}),el('small',{text:new Date(q.created_at).toLocaleDateString()})]),el('span',{class:'cv-result-pill',text:q.score+'% · '+(q.passed?'Passed':'Try again')})]))})}
 body.appendChild(learning);body.appendChild(ach);
 }).catch(function(err){console.error(err);note(body,'Some learning information could not be loaded. Refresh the page to try again.','error')});
 profile.appendChild(el('div',{class:'cv-section-heading'},[el('div',{},[el('span',{class:'cv-kicker',text:'MAKE IT YOURS'}),el('h2',{text:'Profile & account settings'}),el('p',{text:'Manage how your profile appears and keep your account details up to date.'})])]));
 var form=el('form',{class:'cv-settings-card',id:'cvProfileForm'});
 var preview=avatar?el('img',{src:avatar,alt:'Your profile photo',class:'cv-avatar-preview'}):el('div',{class:'cv-avatar-preview cv-avatar-fallback',text:initials(display)});
 var file=el('input',{type:'file',id:'cvAvatarFile',accept:'image/png,image/jpeg,image/webp',class:'cv-file-input'});
 var upload=el('label',{class:'cv-upload-btn',for:'cvAvatarFile',text:'Choose photo'});
 var photo=el('div',{class:'cv-photo-row'},[preview,el('div',{},[el('strong',{text:'Profile photo'}),el('p',{text:'JPG, PNG or WebP · up to 5 MB'}),upload,file])]);
 var nameInput=el('input',{type:'text',id:'cvFullName',maxlength:'80',required:'',value:display,placeholder:'Your name'});
 var emailInput=el('input',{type:'email',id:'cvEmail',value:user.email||'',required:'',autocomplete:'email'});
 var save=el('button',{class:'cv-hero-btn',type:'submit',text:'Save profile'});
 var feedback=el('div',{class:'cv-feedback',id:'cvProfileFeedback','aria-live':'polite'});
 form.appendChild(photo);form.appendChild(el('div',{class:'cv-form-grid'},[el('label',{class:'cv-field'},[el('span',{text:'Display name'}),nameInput]),el('label',{class:'cv-field'},[el('span',{text:'Email address'}),emailInput]) ]));
 form.appendChild(el('p',{class:'cv-field-help',text:'Changing your email address may require confirmation through your inbox.'}));form.appendChild(el('div',{class:'cv-form-actions'},[save,feedback]));profile.appendChild(form);
 var security=el('form',{class:'cv-settings-card cv-security-form',id:'cvPasswordForm'},[el('div',{class:'cv-settings-title'},[el('h3',{text:'Password & security'}),el('p',{text:'Choose a strong password that you do not use elsewhere.'})]),el('label',{class:'cv-field'},[el('span',{text:'New password'}),el('input',{type:'password',id:'cvNewPassword',minlength:'8',autocomplete:'new-password',placeholder:'At least 8 characters',required:''})]),el('button',{class:'cv-secondary-btn',type:'submit',text:'Update password'}),el('div',{class:'cv-feedback','aria-live':'polite'})]);profile.appendChild(security);body.appendChild(profile);body.appendChild(footer);
 file.addEventListener('change',function(){var f=file.files&&file.files[0];if(!f)return;if(f.size>5*1024*1024){note(feedback,'Choose an image smaller than 5 MB.','error');file.value='';return}var reader=new FileReader();reader.onload=function(){if(preview.tagName==='IMG')preview.src=reader.result;else{var im=el('img',{src:reader.result,alt:'Your profile photo',class:'cv-avatar-preview'});preview.replaceWith(im);preview=im}};reader.readAsDataURL(f)});
 form.addEventListener('submit',function(e){e.preventDefault();save.disabled=true;note(feedback,'Saving your profile…','');var f=file.files&&file.files[0],newName=nameInput.value.trim(),newEmail=emailInput.value.trim(),tasks=[];
 if(!newName){note(feedback,'Please enter your display name.','error');save.disabled=false;return}
 tasks.push(sb.auth.updateUser({data:{full_name:newName}}));
 tasks.push(sb.from('profiles').update({full_name:newName,email:newEmail}).eq('id',user.id));
 if(newEmail!==user.email)tasks.push(sb.auth.updateUser({email:newEmail}));
 Promise.all(tasks).then(function(rs){var er=rs.find(function(x){return x.error});if(er)throw er;var dbErr=rs.find(function(x){return x&&x.error&&x.error.code});if(dbErr)throw dbErr.error;if(f){var path=user.id+'/'+Date.now()+'.'+(f.type==='image/png'?'png':f.type==='image/webp'?'webp':'jpg');return sb.storage.from('profile-avatars').upload(path,f,{upsert:true,contentType:f.type}).then(function(up){if(up.error)throw up.error;var pub=sb.storage.from('profile-avatars').getPublicUrl(path).data.publicUrl;return Promise.all([sb.auth.updateUser({data:{full_name:newName,avatar_url:pub}}),sb.from('profiles').update({avatar_url:pub}).eq('id',user.id)]).then(function(rr){if(rr[0].error)throw rr[0].error;if(rr[1].error)throw rr[1].error;return pub})})}else if(avatar){return sb.from('profiles').update({avatar_url:avatar}).eq('id',user.id).then(function(r){if(r.error)throw r.error;return avatar})}return avatar}).then(function(url){display=newName;avatar=url||avatar;user.email=newEmail;top.querySelector('.cv-top-name').textContent=newName;top.querySelector('img, .cv-avatar-sm').replaceWith(url?el('img',{src:url,alt:'Profile photo'}):el('span',{class:'cv-avatar-sm',text:initials(newName)}));note(feedback,newEmail!==(session.user.email||'')?'Profile saved. Check your new email inbox to confirm the address.':'Profile saved successfully.','success');save.disabled=false}).catch(function(err){note(feedback,err.message||'Could not save changes. Please try again.','error');save.disabled=false})});
 security.addEventListener('submit',function(e){e.preventDefault();var pass=document.getElementById('cvNewPassword').value,btn=security.querySelector('button'),msg=security.querySelector('.cv-feedback');if(pass.length<8){note(msg,'Use at least 8 characters.','error');return}btn.disabled=true;sb.auth.updateUser({password:pass}).then(function(r){if(r.error)throw r.error;security.reset();note(msg,'Password updated successfully.','success')}).catch(function(err){note(msg,err.message||'Password could not be updated.','error')}).finally(function(){btn.disabled=false})});
 };
})();
