(function(){
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(x){if(x)n.appendChild(x)});return n}
var host=document.getElementById('content');
function card(title,sub){return el('section',{class:'academy-status-card'},[el('div',{class:'academy-status-card-head'},[el('h2',{text:title}),sub?el('p',{text:sub}):null])])}
function boot(sb){sb.auth.getUser().then(function(r){var user=r.data&&r.data.user;if(!user){host.textContent='';host.appendChild(el('a',{href:'login.html',class:'btn btn-primary',text:'Sign in to view your Academy status'}));return}
 host.textContent='';host.className='page academy-status-page';host.appendChild(el('div',{class:'academy-status-hero'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY'}),el('h1',{text:'Your admission & learning timeline'}),el('p',{text:'Keep an eye on your admission deadline, interview schedule, course progress and next steps.'})]));
 var offers=card('Admission offers','An offer must be accepted before its deadline. Acceptance does not bypass required payment or onboarding.');var interviews=card('Interview schedule','Your interview appointment is time-bound. Confirm that you will attend, or request a reschedule before the session begins.');var progress=card('Learning progress','Your completed lessons and current learning level.');host.append(offers,interviews,progress);
 Promise.all([sb.from('academy_admission_offers').select('*').eq('user_id',user.id).order('created_at',{ascending:false}),sb.from('academy_interview_invitations').select('*').eq('user_id',user.id).not('published_at','is',null).order('starts_at',{ascending:true}),sb.from('enrolments').select('course_id,created_at,courses(id,title,modules(id,lessons(id)))'),sb.from('lesson_progress').select('lesson_id,completed_at'),sb.from('academy_learner_levels').select('course_id,current_level,highest_unlocked_level,progress_percent')]).then(function(rs){
 var bad=rs.find(function(x){return x.error});if(bad){host.appendChild(el('p',{class:'academy-status-alert',text:'Some Academy information is still being prepared. '+bad.error.message}));}
 var names={};(rs[2].data||[]).forEach(function(e){if(e.courses)names[e.course_id]=e.courses.title});
 (rs[0].data||[]).forEach(function(o){
  var expired=o.status==='offered'&&new Date(o.expires_at)<=new Date(),label=expired?'Offer deadline passed':o.status,box=el('article',{class:'academy-status-item'},[el('strong',{text:names[o.course_id]||'Academy admission'}),el('span',{class:'academy-status-pill',text:label}),el('p',{text:'Accept by: '+new Date(o.expires_at).toLocaleString()}),o.offer_message?el('p',{text:o.offer_message}):null]);
  if(o.status==='offered'&&!expired){var accept=el('button',{class:'btn btn-primary',type:'button',text:'Accept admission offer'}),feedback=el('small');box.append(accept,feedback);accept.addEventListener('click',function(){if(!confirm('Accept this admission offer? You must do so before the deadline.'))return;accept.disabled=true;feedback.textContent='Submitting acceptance…';sb.rpc('accept_academy_admission_offer',{p_offer_id:o.id}).then(function(z){if(z.error)throw z.error;feedback.textContent=z.data.message||z.data.status;setTimeout(function(){location.reload()},1200)}).catch(function(e){feedback.textContent=e.message||String(e);accept.disabled=false})})}
  offers.appendChild(box)
 });
 if(!(rs[0].data||[]).length)offers.appendChild(el('p',{class:'academy-status-muted',text:'No admission offer has been issued to your account yet.'}));
 (rs[1].data||[]).forEach(function(i){
  var box=el('article',{class:'academy-status-item'},[el('strong',{text:i.interview_type.replace(/_/g,' ')+' interview'}),el('span',{class:'academy-status-pill',text:i.status.replace(/_/g,' ')}),el('p',{text:new Date(i.starts_at).toLocaleString()+' · '+i.timezone}),el('p',{text:'Ends: '+new Date(i.ends_at).toLocaleString()}),i.learner_instructions?el('p',{text:i.learner_instructions}):null]);
  if(['scheduled','confirmed'].includes(i.status)&&new Date(i.starts_at)>new Date()){
   var confirmBtn=el('button',{class:'btn btn-primary',type:'button',text:'Confirm attendance'}),reschedule=el('button',{class:'btn btn-outline',type:'button',text:'Request reschedule'}),feedback=el('small');box.append(confirmBtn,reschedule,feedback);
   function respond(v){confirmBtn.disabled=true;reschedule.disabled=true;sb.rpc('respond_to_academy_interview_invitation',{p_invitation_id:i.id,p_response:v}).then(function(z){if(z.error)throw z.error;feedback.textContent=v==='confirmed'?'Attendance confirmed. Please arrive on time.':'Reschedule request sent to the Academy team.';setTimeout(function(){location.reload()},1000)}).catch(function(e){feedback.textContent=e.message||String(e);confirmBtn.disabled=false;reschedule.disabled=false})}
   confirmBtn.addEventListener('click',function(){respond('confirmed')});reschedule.addEventListener('click',function(){respond('reschedule_requested')})
  }
  interviews.appendChild(box)
 });
 if(!(rs[1].data||[]).length)interviews.appendChild(el('p',{class:'academy-status-muted',text:'No interview has been scheduled yet.'}));
 var completed={};(rs[3].data||[]).forEach(function(p){if(p.completed_at)completed[p.lesson_id]=true});
 var levels={};(rs[4].data||[]).forEach(function(l){levels[l.course_id]=l});
 (rs[2].data||[]).forEach(function(e){if(!e.courses)return;var lessons=[];(e.courses.modules||[]).forEach(function(m){(m.lessons||[]).forEach(function(l){lessons.push(l)})});var done=lessons.filter(function(l){return completed[l.id]}).length,lv=levels[e.course_id]||{},pct=lessons.length?Math.round(done/lessons.length*100):0;
  var box=el('article',{class:'academy-status-item'},[el('strong',{text:e.courses.title}),el('p',{text:done+' of '+lessons.length+' lessons completed · '+pct+'%'}),el('div',{class:'academy-status-meter'},[el('span',{style:'width:'+pct+'%'})]),el('p',{text:'Current level: '+(lv.current_level||'Beginner')+' · Highest unlocked: '+(lv.highest_unlocked_level||'Beginner')})]);progress.appendChild(box)
 });
 if(!(rs[2].data||[]).length)progress.appendChild(el('p',{class:'academy-status-muted',text:'Your learning progress will appear here after your course enrolment is activated.'}))
 }).catch(function(e){host.appendChild(el('p',{class:'academy-status-alert',text:e.message||String(e)}))})
 })}
if(window.CV_SB)boot(window.CV_SB);else document.addEventListener('cv-ready',function(){boot(window.CV_SB)});
})();