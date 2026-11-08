(function(){
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(x){if(x)n.appendChild(x)});return n}
var host=document.getElementById('content');
function card(title,sub){return el('section',{class:'academy-status-card'},[el('div',{class:'academy-status-card-head'},[el('h2',{text:title}),sub?el('p',{text:sub}):null])])}
function boot(sb){sb.auth.getUser().then(function(r){var user=r.data&&r.data.user;if(!user){host.textContent='';host.appendChild(el('a',{href:'login.html',class:'btn btn-primary',text:'Sign in to view your Academy status'}));return}
 host.textContent='';host.className='page academy-status-page';host.appendChild(el('div',{class:'academy-status-hero'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY'}),el('h1',{text:'Your admission & learning timeline'}),el('p',{text:'Keep an eye on your admission deadline, interview schedule, course progress and next steps.'})]));
 var applications=card('My applications','Track each application reference, review decision and the latest admissions activity.');var notifications=card('Academy notifications','Important updates, deadlines, interview reminders and learning alerts.');var offers=card('Admission & course access','Your admission decision, payment state and course access are connected here.');var interviews=card('Interview schedule','Your interview appointment is time-bound. Confirm that you will attend, or request a reschedule before the session begins.');var progress=card('Learning progress','Your completed lessons and current learning level.');host.append(applications,notifications,offers,interviews,progress);
 Promise.all([sb.from('academy_admission_offers').select('*').eq('user_id',user.id).order('created_at',{ascending:false}),sb.from('academy_interview_invitations').select('*').eq('user_id',user.id).not('published_at','is',null).order('starts_at',{ascending:true}),sb.from('enrolments').select('course_id,created_at,courses(id,title,modules(id,lessons(id)))'),sb.from('lesson_progress').select('lesson_id,completed_at'),sb.from('academy_learner_levels').select('course_id,current_level,highest_unlocked_level,progress_percent'),sb.from('academy_notifications').select('id,notification_type,title,body,action_url,scheduled_for,read_at,created_at').lte('scheduled_for',new Date().toISOString()).order('created_at',{ascending:false}).limit(30),sb.from('academy_learning_activity').select('course_id,activity_type,occurred_at').order('occurred_at',{ascending:false}).limit(1000),sb.from('academy_level_rules').select('course_id,level_name,sequence_no,min_completed_percent,min_quiz_average,min_assignment_count,min_active_days,published').eq('published',true).order('sequence_no'),sb.from('academy_applications').select('id,application_no,course_id,status,submitted_at,reviewed_at,decision_reason,created_at,courses(title,slug,price_ngn)').eq('user_id',user.id).order('created_at',{ascending:false}),sb.from('academy_application_events').select('application_id,event_type,from_status,to_status,message,created_at').order('created_at',{ascending:false}).limit(150)]).then(function(rs){
 var bad=rs.find(function(x){return x.error});if(bad){host.appendChild(el('p',{class:'academy-status-alert',text:'Some Academy information is still being prepared. '+bad.error.message}));}
 var appRows=(rs[8]&&rs[8].data)||[],eventRows=(rs[9]&&rs[9].data)||[];
 if(rs[8]&&rs[8].error){applications.appendChild(el('p',{class:'academy-status-alert',text:'Application tracking is temporarily unavailable: '+rs[8].error.message}));}
 appRows.forEach(function(a){
  var timeline=eventRows.filter(function(v){return v.application_id===a.id;}).slice(0,8);
  var box=el('article',{class:'academy-status-item'},[
   el('strong',{text:(a.courses&&a.courses.title)||'Academy application'}),
   el('span',{class:'academy-status-pill',text:(a.status||'submitted').replace(/_/g,' ')}),
   el('p',{text:'Reference: '+a.application_no}),
   el('small',{text:'Submitted: '+(a.submitted_at?new Date(a.submitted_at).toLocaleString():'Not submitted')})
  ]);
  if(a.decision_reason)box.appendChild(el('p',{text:a.decision_reason}));
  if(timeline.length){
   var log=el('div',{class:'academy-status-timeline'});
   timeline.slice().reverse().forEach(function(v){log.appendChild(el('div',{class:'academy-status-timeline-event'},[
    el('strong',{text:(v.event_type||'update').replace(/_/g,' ')}),
    el('p',{text:v.message||((v.from_status||'')+' → '+(v.to_status||''))}),
    el('small',{text:new Date(v.created_at).toLocaleString()})
   ]));});
   box.appendChild(log);
  }else box.appendChild(el('p',{class:'academy-status-muted',text:'Your application has been received. Updates will appear here as the review progresses.'}));
  applications.appendChild(box);
 });
 if(!appRows.length)applications.appendChild(el('p',{class:'academy-status-muted',text:'You have not submitted an Academy application yet.'}));
 var noticeRows=(rs[5]&&rs[5].data)||[];
 if(rs[5]&&rs[5].error){notifications.appendChild(el('p',{class:'academy-status-muted',text:'Notifications will appear here when the Academy notification migration is enabled.'}));}
 noticeRows.forEach(function(n){
  var item=el('article',{class:'academy-status-item'+(n.read_at?' is-read':'')},[el('strong',{text:n.title}),el('span',{class:'academy-status-pill',text:n.notification_type.replace(/_/g,' ')}),el('p',{text:n.body}),el('small',{text:new Date(n.created_at).toLocaleString()})]);
  if(n.action_url)item.appendChild(el('a',{class:'btn btn-outline',href:n.action_url,text:'Open'}));
  if(!n.read_at){var read=el('button',{class:'btn btn-outline',type:'button',text:'Mark as read'});read.addEventListener('click',function(){read.disabled=true;sb.from('academy_notifications').update({read_at:new Date().toISOString()}).eq('id',n.id).then(function(z){if(z.error)throw z.error;item.classList.add('is-read');read.remove()}).catch(function(e){read.disabled=false;read.textContent=e.message||'Could not mark as read'})});item.appendChild(read)}
  notifications.appendChild(item)
 });
 if(!noticeRows.length)notifications.appendChild(el('p',{class:'academy-status-muted',text:'You are all caught up. New admission, interview and learning updates will appear here.'}));
 var names={};(rs[2].data||[]).forEach(function(e){if(e.courses){names[e.course_id]=e.courses.title;Promise.resolve(sb.rpc('refresh_academy_learner_level',{p_course_id:e.course_id})).catch(function(){})}});
 (rs[0].data||[]).forEach(function(o){
  var remaining=Math.max(0,new Date(o.expires_at).getTime()-Date.now()),hours=Math.floor(remaining/3600000),daysLeft=Math.floor(hours/24),timeLeft=daysLeft+'d '+(hours%24)+'h',expired=o.status==='offered'&&remaining===0,label=expired?'Offer deadline passed':o.status,box=el('article',{class:'academy-status-item'},[el('strong',{text:names[o.course_id]||'Academy admission'}),el('span',{class:'academy-status-pill',text:label}),el('p',{text:'Accept by: '+new Date(o.expires_at).toLocaleString()+(o.expires_timezone?' ('+o.expires_timezone+')':'')}),o.status==='offered'?el('p',{text:expired?'Acceptance window has closed.':'Time remaining: '+timeLeft}):null,o.offer_message?el('p',{text:o.offer_message}):null]);
  if(o.status==='offered'&&!expired){var accept=el('button',{class:'btn btn-primary',type:'button',text:'Accept admission offer'}),feedback=el('small');box.append(accept,feedback);accept.addEventListener('click',function(){if(!confirm('Accept this admission offer? You must do so before the deadline.'))return;accept.disabled=true;feedback.textContent='Submitting acceptance…';sb.rpc('accept_academy_admission_offer',{p_offer_id:o.id}).then(function(z){if(z.error)throw z.error;feedback.textContent=z.data.message||z.data.status;setTimeout(function(){if(z.data.status==='enrolled'){var a=appRows.find(function(x){return x.course_id===o.course_id;});location.href='course.html?s='+encodeURIComponent(a&&a.courses&&a.courses.slug||'')}else if(z.data.status==='approved_pending_payment'){var a=appRows.find(function(x){return x.course_id===o.course_id;});location.href='course.html?s='+encodeURIComponent(a&&a.courses&&a.courses.slug||'')}else location.reload()},900)}).catch(function(e){feedback.textContent=e.message||String(e);accept.disabled=false})})}
  if(o.status==='accepted'){
   var app=appRows.find(function(a){return a.id===o.application_id;});
   if(app&&app.status==='approved'){
    box.appendChild(el('p',{class:'academy-status-success',text:'Your admission is active. Interview assignments have been closed and course access is enabled.'}));
    box.appendChild(el('a',{class:'btn btn-primary',href:'course.html?s='+encodeURIComponent(app.courses&&app.courses.slug||''),text:'Continue learning'}));
   }else if(app&&app.status==='approved_pending_payment'){
    box.appendChild(el('p',{class:'academy-status-muted',text:'Your admission is accepted. Complete payment to activate your course.'}));
    box.appendChild(el('a',{class:'btn btn-primary',href:'course.html?s='+encodeURIComponent(app.courses&&app.courses.slug||''),text:'Go to payment portal'}));
   }
  }
  offers.appendChild(box)
 });
 if(!(rs[0].data||[]).length)offers.appendChild(el('p',{class:'academy-status-muted',text:'No admission offer has been issued to your account yet.'}));
 (rs[1].data||[]).filter(function(i){var a=appRows.find(function(x){return x.id===i.application_id;});return !a||!['approved','approved_pending_payment'].includes(a.status);}).forEach(function(i){
  var box=el('article',{class:'academy-status-item'},[el('strong',{text:(i.interview_type==='recorded_audio'?'Audio defence':i.interview_type==='recorded_video'?'Audiovisual defence':'Live interview')}),el('span',{class:'academy-status-pill',text:i.status.replace(/_/g,' ')}),el('p',{text:new Date(i.starts_at).toLocaleString()+' · '+i.timezone}),el('p',{text:'Ends / deadline: '+new Date(i.ends_at).toLocaleString()}),i.learner_instructions?el('p',{text:i.learner_instructions}):null]);
  var interviewHref=i.interview_type==='live'?'academy-live-room.html?interview='+encodeURIComponent(i.interview_id):'academy-interview.html?id='+encodeURIComponent(i.interview_id);box.appendChild(el('a',{class:'btn btn-primary',href:interviewHref,text:i.interview_type==='live'?'Open live interview room':'Open defence assignment'}));
  if(i.interview_type==='live'&&['scheduled','confirmed'].includes(i.status)&&new Date(i.starts_at)>new Date()){
   var confirmBtn=el('button',{class:'btn btn-primary',type:'button',text:'Confirm attendance'}),reschedule=el('button',{class:'btn btn-outline',type:'button',text:'Request reschedule'}),feedback=el('small');box.append(confirmBtn,reschedule,feedback);
   function respond(v){confirmBtn.disabled=true;reschedule.disabled=true;sb.rpc('respond_to_academy_interview_invitation',{p_invitation_id:i.id,p_response:v}).then(function(z){if(z.error)throw z.error;feedback.textContent=v==='confirmed'?'Attendance confirmed. Please arrive on time.':'Reschedule request sent to the Academy team.';setTimeout(function(){location.reload()},1000)}).catch(function(e){feedback.textContent=e.message||String(e);confirmBtn.disabled=false;reschedule.disabled=false})}
   confirmBtn.addEventListener('click',function(){respond('confirmed')});reschedule.addEventListener('click',function(){respond('reschedule_requested')})
  }
  interviews.appendChild(box)
 });
 if(!(rs[1].data||[]).length)interviews.appendChild(el('p',{class:'academy-status-muted',text:'No interview has been scheduled yet.'}));
 var completed={};(rs[3].data||[]).forEach(function(p){if(p.completed_at)completed[p.lesson_id]=true});
 var levels={};(rs[4].data||[]).forEach(function(l){levels[l.course_id]=l});var activity=rs[6]&&rs[6].data||[],rules=rs[7]&&rs[7].data||[];
 (rs[2].data||[]).forEach(function(e){if(!e.courses)return;var lessons=[];(e.courses.modules||[]).forEach(function(m){(m.lessons||[]).forEach(function(l){lessons.push(l)})});var done=lessons.filter(function(l){return completed[l.id]}).length,lv=levels[e.course_id]||{},pct=lessons.length?Math.round(done/lessons.length*100):0,acts=activity.filter(function(a){return a.course_id===e.course_id}),now=Date.now(),activeDays={};acts.forEach(function(a){var t=new Date(a.occurred_at).getTime();if(Number.isFinite(t)&&now-t<=30*86400000)activeDays[new Date(t).toISOString().slice(0,10)]=true});var days=Object.keys(activeDays).length,weekly=acts.filter(function(a){return a.activity_type==='lesson_completed'&&now-new Date(a.occurred_at).getTime()<=7*86400000}).length,highest=lv.highest_unlocked_level||lv.current_level||'Beginner',order=['Beginner','Foundation','Intermediate','Advanced','Professional'],idx=order.indexOf(highest),next=rules.filter(function(r){return r.course_id===e.course_id&&r.sequence_no>idx+1}).sort(function(a,b){return a.sequence_no-b.sequence_no})[0],milestone=next?'Next level: '+next.level_name+' · '+next.min_completed_percent+'% lesson completion'+(next.min_active_days?' · '+next.min_active_days+' active study days':'')+(next.min_quiz_average!==null?' · quiz average '+next.min_quiz_average+'%':'')+(next.min_assignment_count?' · '+next.min_assignment_count+' assignment(s)':''):'You have reached the highest published level in this course.';
  var box=el('article',{class:'academy-status-item'},[el('strong',{text:e.courses.title}),el('p',{text:done+' of '+lessons.length+' lessons completed · '+pct+'%'}),el('div',{class:'academy-status-meter'},[el('span',{style:'width:'+pct+'%'})]),el('p',{text:'Current level: '+(lv.current_level||'Beginner')+' · Highest unlocked: '+highest}),el('p',{text:'Learning pace: '+weekly+' lesson(s) completed in the last 7 days · '+days+' active study day(s) in the last 30 days'}),el('p',{class:'academy-status-muted',text:milestone})]);progress.appendChild(box)
 });
 if(!(rs[2].data||[]).length)progress.appendChild(el('p',{class:'academy-status-muted',text:'Your learning progress will appear here after your course enrolment is activated.'}))
 }).catch(function(e){host.appendChild(el('p',{class:'academy-status-alert',text:e.message||String(e)}))})
 })}
if(window.CV_SB)boot(window.CV_SB);else document.addEventListener('cv-ready',function(){boot(window.CV_SB)});
})();