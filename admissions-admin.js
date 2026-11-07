(function(){
function el(t,a,children){var n=document.createElement(t);Object.keys(a||{}).forEach(function(k){if(k==='text')n.textContent=a[k];else n.setAttribute(k,a[k])});(children||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
var levels=['Beginner','Foundation','Intermediate','Advanced','Professional'];
var statuses=['draft','submitted','under_review','more_information_requested','approved_pending_payment','approved','rejected','withdrawn'];
window.CV_ACADEMY_ADMIN={mount:function(host,sb,user,role){
 var root=el('div',{class:'academy-admissions-admin'});host.appendChild(root);
 var selected=null,rows=[],profiles={},courses={},statusFilter=el('select',{},[el('option',{value:'all',text:'All application statuses'})].concat(statuses.map(function(s){return el('option',{value:s,text:s.replace(/_/g,' ')})})));
 var search=el('input',{type:'search',placeholder:'Search application number, learner or course…'});
 var list=el('div',{class:'academy-app-list'}),detail=el('section',{class:'academy-app-detail'});
 root.appendChild(el('div',{class:'academy-admin-head'},[el('div',{},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY'}),el('h2',{text:'Admissions & Placement'}),el('p',{text:'Review applications, assess readiness, assign levels and manage interview stages.'})]),el('button',{class:'btn btn-outline',type:'button',text:'Refresh',onclick:'', 'data-refresh':'1'})]));
 root.appendChild(el('div',{class:'academy-admin-stats',id:'academy-admin-stats'}));
 var controls=el('div',{class:'academy-admin-controls'},[search,statusFilter]);root.appendChild(controls);
 root.appendChild(el('div',{class:'academy-admin-workspace'},[list,detail]));
 root.querySelector('[data-refresh]').addEventListener('click',load);search.addEventListener('input',draw);statusFilter.addEventListener('change',draw);
 function msg(text,bad){return el('p',{class:'academy-admin-message'+(bad?' is-error':''),text:text})}
 function load(){
  list.textContent='Loading applications…';detail.textContent='Select an application to review.';
  Promise.all([sb.from('academy_applications').select('*').order('created_at',{ascending:false}).limit(300),sb.from('profiles').select('id,full_name,email'),sb.from('courses').select('id,title,price_ngn')]).then(function(rs){
   var err=rs.filter(function(x){return x.error})[0];if(err){list.textContent='Admissions schema is not available yet. Apply the reviewed migration 202611070002_academy_admissions_foundation.sql before enabling this workspace. Details: '+err.error.message;return}
   rows=rs[0].data||[];profiles={};courses={};(rs[1].data||[]).forEach(function(x){profiles[x.id]=x});(rs[2].data||[]).forEach(function(x){courses[x.id]=x});
   var counts={};statuses.forEach(function(s){counts[s]=rows.filter(function(x){return x.status===s}).length});
   var stats=root.querySelector('#academy-admin-stats');stats.textContent='';
   [['Total applications',rows.length],['Awaiting review',counts.submitted+counts.under_review],['More information',counts.more_information_requested],['Approved',counts.approved+counts.approved_pending_payment]].forEach(function(x){stats.appendChild(el('div',{class:'academy-admin-stat'},[el('strong',{text:String(x[1])}),el('span',{text:x[0]})]))});
   draw();if(selected){var keep=rows.find(function(x){return x.id===selected.id});if(keep)open(keep)}
  })
 }
 function draw(){
  list.textContent='';var term=search.value.trim().toLowerCase(),filter=statusFilter.value;
  var filtered=rows.filter(function(x){var p=profiles[x.user_id]||{},c=courses[x.course_id]||{},hay=[x.application_no,p.full_name,p.email,c.title,x.first_name,x.last_name].join(' ').toLowerCase();return(filter==='all'||x.status===filter)&&(!term||hay.indexOf(term)>-1)});
  if(!filtered.length){list.appendChild(msg(rows.length?'No applications match this filter.':'No applications have been submitted yet.'));return}
  filtered.forEach(function(x){var p=profiles[x.user_id]||{},c=courses[x.course_id]||{},card=el('button',{type:'button',class:'academy-app-card'+(selected&&selected.id===x.id?' active':'')},[el('span',{class:'academy-app-card-top'},[el('strong',{text:x.application_no}),el('small',{text:new Date(x.created_at).toLocaleDateString()})]),el('strong',{text:p.full_name||[x.first_name,x.last_name].join(' ')}),el('span',{text:c.title||'Course unavailable'}),el('span',{class:'academy-status status-'+x.status,text:x.status.replace(/_/g,' ')}),el('small',{text:'Proposed: '+x.proposed_level})]);card.addEventListener('click',function(){open(x)});list.appendChild(card)})
 }
 function field(label,node){return el('label',{class:'academy-admin-field'},[el('span',{text:label}),node])}
 function open(x){
  selected=x;draw();detail.textContent='';
  var p=profiles[x.user_id]||{},c=courses[x.course_id]||{};
  detail.appendChild(el('div',{class:'academy-detail-top'},[el('span',{class:'academy-eyebrow',text:x.application_no}),el('h3',{text:p.full_name||[x.first_name,x.last_name].join(' ')}),el('p',{text:(p.email||'')+' · '+(c.title||'Course')}),el('span',{class:'academy-status status-'+x.status,text:x.status.replace(/_/g,' ')})]));
  var facts=el('div',{class:'academy-app-facts'});
  [['Phone',x.phone],['Location',[x.region,x.country].filter(Boolean).join(', ')],['Education',x.education_level],['Occupation',x.occupation],['Proposed level',x.proposed_level],['Portfolio',x.portfolio_url]].forEach(function(a){facts.appendChild(el('div',{},[el('small',{text:a[0]}),a[1]&&a[0]==='Portfolio'?el('a',{href:a[1],target:'_blank',rel:'noopener',text:a[1]}):el('strong',{text:a[1]||'Not provided'})]))});
  detail.appendChild(facts);
  [['Prior experience',x.prior_experience],['Motivation',x.motivation],['Learning goals',x.learning_goals],['Applicant note',x.decision_reason]].forEach(function(a){if(a[1])detail.appendChild(el('div',{class:'academy-app-copy'},[el('h4',{text:a[0]}),el('p',{text:a[1]})]))});
  var form=el('form',{class:'academy-review-form'}),st=el('select',{},statuses.map(function(s){return el('option',{value:s,text:s.replace(/_/g,' ')})}));st.value=x.status;
  var lv=el('select',{},levels.map(function(s){return el('option',{value:s,text:s})}));lv.value=x.proposed_level||'Beginner';
  var rationale=el('textarea',{rows:'3',placeholder:'Placement rationale — required when confirming a level'});
  var note=el('textarea',{rows:'3',placeholder:'Internal reviewer notes (visible to admins only)'});
  form.append(field('Application decision',st),field('Confirmed placement level',lv),field('Placement rationale',rationale),field('Internal reviewer note',note));
  var save=el('button',{class:'btn btn-primary',type:'submit',text:'Save review'}),feedback=el('div');form.append(save,feedback);detail.appendChild(el('h4',{text:'Review & placement'}));detail.appendChild(form);
  var offerPanel=el('section',{class:'academy-offer-panel'}),offerExpiry=el('input',{type:'datetime-local'}),offerText=el('textarea',{rows:'3',placeholder:'Welcome message, next steps, acceptance instructions…'}),offerFeedback=el('div');
  offerPanel.appendChild(el('h4',{text:'Admission offer & acceptance window'}));
  offerPanel.appendChild(el('p',{class:'academy-admin-footnote',text:'Set a firm deadline. The learner must accept before it expires. Expiry and acceptance enforcement will be completed by the secure server workflow; this panel records and publishes the offer only.'}));
  offerPanel.append(field('Acceptance deadline (local admin time)',offerExpiry),field('Offer message',offerText));
  var issueOffer=el('button',{class:'btn btn-primary',type:'button',text:'Issue admission offer'});offerPanel.append(issueOffer,offerFeedback);detail.appendChild(offerPanel);
  sb.from('academy_admission_offers').select('*').eq('application_id',x.id).order('created_at',{ascending:false}).limit(1).maybeSingle().then(function(o){
   if(o.error){offerFeedback.textContent='Offer records unavailable until lifecycle migration is applied.';return}
   if(o.data){offerExpiry.value=o.data.expires_at?new Date(new Date(o.data.expires_at).getTime()-new Date(o.data.expires_at).getTimezoneOffset()*60000).toISOString().slice(0,16):'';offerText.value=o.data.offer_message||'';offerFeedback.textContent='Current offer: '+o.data.status+' · deadline '+new Date(o.data.expires_at).toLocaleString()}
  });
  issueOffer.addEventListener('click',function(){
   if(!offerExpiry.value){offerFeedback.textContent='Choose an acceptance deadline.';return}
   var expiry=new Date(offerExpiry.value);if(!Number.isFinite(expiry.getTime())||expiry<=new Date()){offerFeedback.textContent='The acceptance deadline must be in the future.';return}
   issueOffer.disabled=true;offerFeedback.textContent='Issuing offer…';
   sb.from('academy_admission_offers').upsert({application_id:x.id,user_id:x.user_id,course_id:x.course_id,status:'offered',issued_at:new Date().toISOString(),expires_at:expiry.toISOString(),offer_message:offerText.value.trim()||null,issued_by:user.id,updated_at:new Date().toISOString()},{onConflict:'application_id'}).select('id').single()
    .then(function(z){if(z.error)throw z.error;return sb.from('academy_applications').update({status:'approved_pending_payment',offer_issued_at:new Date().toISOString(),offer_expires_at:expiry.toISOString(),updated_at:new Date().toISOString()}).eq('id',x.id)})
    .then(function(z){if(z.error)throw z.error;return sb.from('academy_application_events').insert({application_id:x.id,actor_id:user.id,event_type:'admission_offer_issued',from_status:x.status,to_status:'approved_pending_payment',message:'Admission offer issued. Acceptance deadline: '+expiry.toISOString()})})
    .then(function(z){if(z.error)throw z.error;return sb.from('academy_audit_log').insert({actor_id:user.id,application_id:x.id,action:'admission_offer_issued',details:{expires_at:expiry.toISOString()}})})
    .then(function(z){if(z.error)throw z.error;offerFeedback.textContent='Offer recorded. Learner acceptance and expiry enforcement require the secure lifecycle backend before this can grant access.';load()})
    .catch(function(err){offerFeedback.textContent=err.message||String(err)})
    .finally(function(){issueOffer.disabled=false})
  });
  form.addEventListener('submit',function(e){e.preventDefault();save.disabled=true;feedback.textContent='Saving review…';
   var patch={status:st.value,reviewed_by:user.id,reviewed_at:new Date().toISOString(),decision_reason:rationale.value.trim()||null,updated_at:new Date().toISOString()};
   sb.from('academy_applications').update(patch).eq('id',x.id).then(function(a){if(a.error)throw a.error;
    var tasks=[sb.from('academy_application_events').insert({application_id:x.id,actor_id:user.id,event_type:'admin_review',from_status:x.status,to_status:st.value,message:rationale.value.trim()||('Status changed to '+st.value)}),sb.from('academy_audit_log').insert({actor_id:user.id,application_id:x.id,action:'application_review_updated',details:{from_status:x.status,to_status:st.value,confirmed_level:lv.value}})];if(note.value.trim())tasks.push(sb.from('academy_application_private_notes').insert({application_id:x.id,author_id:user.id,note:note.value.trim()}));
    if(rationale.value.trim())tasks.push(sb.from('academy_placements').upsert({application_id:x.id,confirmed_level:lv.value,recommended_level:x.proposed_level, rationale:rationale.value.trim(),assigned_by:user.id,assigned_at:new Date().toISOString(),updated_at:new Date().toISOString()},{onConflict:'application_id'}));
    return Promise.all(tasks)
   }).then(function(rs){var bad=rs.filter(function(z){return z&&z.error})[0];if(bad)throw bad.error;feedback.textContent='Review saved. Access is not granted by this screen; payment/admission fulfilment is a separate controlled step.';feedback.className='academy-admin-message';load()}).catch(function(err){feedback.textContent=err.message||String(err);feedback.className='academy-admin-message is-error'}).finally(function(){save.disabled=false})
  });
  var interviewBox=el('section',{class:'academy-interview-admin'});
  detail.appendChild(el('h4',{text:'Interview & assessment'}));detail.appendChild(interviewBox);
  function interviewMessage(t,bad){interviewBox.appendChild(msg(t,bad))}
  function loadInterviews(){
   interviewBox.textContent='Loading interview records…';
   Promise.all([sb.from('academy_interviews').select('*').eq('application_id',x.id).order('created_at',{ascending:false}),sb.from('academy_interview_invitations').select('*').eq('application_id',x.id).order('starts_at',{ascending:false})]).then(function(pair){
    interviewBox.textContent='';
    var ir=pair[0],iv=pair[1];if(ir.error||iv.error){interviewMessage('Interview workspace unavailable: '+((ir.error||iv.error).message),true);return}
    var items=ir.data||[],invitations=iv.data||[];
    if(items.length)items.forEach(function(it){
     var title=(it.interview_type||'interview').replace(/_/g,' '),when=it.scheduled_start?new Date(it.scheduled_start).toLocaleString():'Not scheduled';
     var card=el('div',{class:'academy-interview-card'},[el('strong',{text:title+' · '+it.status}),el('p',{text:when+(it.timezone?' · '+it.timezone:'')}),el('p',{text:it.meeting_provider?(it.meeting_provider+' · '+(it.meeting_reference||'No meeting link/reference')):'No meeting details'}),el('p',{text:'Reviewer: '+(it.reviewer_id||'Unassigned')+' · Score: '+(it.score==null?'Not scored':it.score)})]);
     if(it.reviewer_notes)card.appendChild(el('p',{text:'Private reviewer notes: '+it.reviewer_notes}));
     var invite=invitations.find(function(v){return v.interview_id===it.id});
     if(invite){
      card.appendChild(el('p',{text:'Learner invitation: '+invite.status.replace(/_/g,' ')}));
      var attendance=el('select',{},['scheduled','confirmed','reschedule_requested','attended','missed','cancelled'].map(function(v){return el('option',{value:v,text:v.replace(/_/g,' ')})}));attendance.value=invite.status;
      var mark=el('button',{class:'btn btn-outline',type:'button',text:'Update attendance'}),attNote=el('small');
      mark.addEventListener('click',function(){mark.disabled=true;sb.from('academy_interview_invitations').update({status:attendance.value,updated_at:new Date().toISOString()}).eq('id',invite.id).then(function(z){if(z.error)throw z.error;return sb.from('academy_application_events').insert({application_id:x.id,actor_id:user.id,event_type:'interview_attendance_updated',message:'Interview attendance: '+attendance.value,metadata:{invitation_id:invite.id}})}).then(function(z){if(z.error)throw z.error;attNote.textContent='Attendance status saved.';invite.status=attendance.value}).catch(function(e){attNote.textContent=e.message||String(e)}).finally(function(){mark.disabled=false})});
      card.append(field('Attendance & appointment status',attendance),mark,attNote)
     }
     interviewBox.appendChild(card)
    });
    var form=el('form',{class:'academy-review-form'}),kind=el('select',{},[['live','Live interview'],['recorded_video','Recorded video response'],['recorded_audio','Recorded audio response'],['alternative','Alternative assessment']].map(function(v){return el('option',{value:v[0],text:v[1]})}));
    var state=el('select',{},['pending','scheduled','in_progress','submitted','completed','cancelled','declined'].map(function(v){return el('option',{value:v,text:v.replace(/_/g,' ')})}));
    var start=el('input',{type:'datetime-local'}),end=el('input',{type:'datetime-local'}),tz=el('input',{type:'text',placeholder:'e.g. Africa/Lagos'}),provider=el('input',{type:'text',placeholder:'Google Meet, Zoom, phone…'}),meeting=el('input',{type:'url',placeholder:'Private meeting link or reference URL'}),reviewer=el('select',{}),score=el('input',{type:'number',min:'0',step:'0.5',placeholder:'Score'}),notes=el('textarea',{rows:'3',placeholder:'Private interviewer evaluation and observations'}),feedback=el('div');
    reviewer.appendChild(el('option',{value:'',text:'Unassigned reviewer'}));
    (Object.keys(profiles).map(function(id){return profiles[id]})).forEach(function(p){reviewer.appendChild(el('option',{value:p.id,text:p.full_name||p.email||p.id}))});
    form.append(field('Interview type',kind),field('Workflow status',state),field('Start date & time',start),field('End date & time',end),field('Timezone (IANA)',tz),field('Meeting provider',provider),field('Meeting link / reference (restricted admin access)',meeting),field('Assigned reviewer',reviewer),field('Evaluation score',score),field('Private reviewer evaluation',notes));
    var saveInterview=el('button',{class:'btn btn-primary',type:'submit',text:'Save interview plan'});form.append(saveInterview,feedback);interviewBox.appendChild(form);
    form.addEventListener('submit',function(ev){ev.preventDefault();
     var a=start.value?new Date(start.value):null,b=end.value?new Date(end.value):null;
     if(a&&isNaN(a.getTime())||b&&isNaN(b.getTime())){feedback.textContent='Enter a valid date and time.';return}
     if(a&&b&&b<=a){feedback.textContent='Interview end must be after its start.';return}
     if(state.value==='scheduled'&&!a){feedback.textContent='A scheduled interview needs a start time.';return}
     if(score.value!==''&&(Number(score.value)<0||!Number.isFinite(Number(score.value)))){feedback.textContent='Enter a valid non-negative score.';return}
     saveInterview.disabled=true;feedback.textContent='Saving interview…';
     var payload={application_id:x.id,interview_type:kind.value,status:state.value,scheduled_start:a?a.toISOString():null,scheduled_end:b?b.toISOString():null,timezone:tz.value.trim()||null,meeting_provider:provider.value.trim()||null,meeting_reference:meeting.value.trim()||null,reviewer_id:reviewer.value||null,score:score.value===''?null:Number(score.value),reviewer_notes:notes.value.trim()||null,updated_at:new Date().toISOString()};
     sb.from('academy_interviews').insert(payload).select('id').single().then(function(w){
      if(w.error)throw w.error;
      if(!a||!b||!tz.value.trim())return w.data;
      return sb.from('academy_interview_invitations').upsert({interview_id:w.data.id,application_id:x.id,user_id:x.user_id,interview_type:kind.value,status:'scheduled',starts_at:a.toISOString(),ends_at:b.toISOString(),timezone:tz.value.trim(),attendance_deadline:b.toISOString(),learner_instructions:'Please attend at the scheduled time. If you cannot attend, contact Academy support before the session.' ,published_at:new Date().toISOString(),updated_at:new Date().toISOString()},{onConflict:'interview_id'}).then(function(inv){if(inv.error)throw inv.error;return w.data});
     }).then(function(w){
      return sb.from('academy_application_events').insert({application_id:x.id,actor_id:user.id,event_type:'interview_updated',message:'Interview plan '+state.value,metadata:{interview_type:kind.value,scheduled_start:payload.scheduled_start,timezone:payload.timezone}});
     }).then(function(ev2){if(ev2.error)throw ev2.error;return sb.from('academy_audit_log').insert({actor_id:user.id,application_id:x.id,action:'interview_plan_created',details:{interview_type:kind.value,status:state.value,scheduled_start:payload.scheduled_start,reviewer_id:payload.reviewer_id}})})
     .then(function(audit){if(audit.error)throw audit.error;feedback.textContent='Interview plan saved. No recording has been uploaded or shared.';loadInterviews()})
     .catch(function(err){feedback.textContent=err.message||String(err);feedback.className='academy-admin-message is-error'})
     .finally(function(){saveInterview.disabled=false})
    })
   })
  }
  loadInterviews();
  detail.appendChild(el('p',{class:'academy-admin-footnote',text:'Interview links, reviewer evaluations and scheduling details are restricted to authorised administrators. Recording capture and private media upload will be enabled only after consent, retention and signed-access controls are implemented.'}))
 }
 function diagnostics(){
  var box=el('section',{class:'academy-diagnostics-admin'});root.appendChild(box);
  box.appendChild(el('div',{class:'academy-admin-section-title'},[el('div',{},[el('span',{class:'academy-eyebrow',text:'QUESTION BANK'}),el('h3',{text:'Course diagnostics'}),el('p',{text:'Create and publish course-specific admission questions. Only published questions appear on the learner application.'})])]));
  var courseSelect=el('select',{}),questionList=el('div',{class:'academy-diagnostic-list'}),editor=el('form',{class:'academy-diagnostic-editor'});
  var prompt=el('textarea',{rows:'3',placeholder:'Write a clear diagnostic question or practical prompt…'}),type=el('select',{},[['long_text','Long written response'],['short_text','Short response'],['url','Portfolio / URL'],['single_choice','Single choice']].map(function(x){return el('option',{value:x[0],text:x[1]})})),level=el('select',{},[el('option',{value:'',text:'Any level'})].concat(levels.map(function(x){return el('option',{value:x,text:x})}))),options=el('textarea',{rows:'3',placeholder:'For single choice, enter one option per line'}),required=el('input',{type:'checkbox',checked:'checked'}),active=el('input',{type:'checkbox',checked:'checked'}),published=el('input',{type:'checkbox'}),save=el('button',{class:'btn btn-primary',type:'submit',text:'Add diagnostic question'}),feedback=el('div');
  editor.append(field('Course',courseSelect),field('Question prompt',prompt),field('Response format',type),field('Target level',level),field('Choice options (one per line)',options),field('Required',required),field('Active',active),field('Published',published),save,feedback);
  box.appendChild(el('div',{class:'academy-diagnostic-layout'},[editor,questionList]));
  var editing=null;
  function reset(){editing=null;prompt.value='';type.value='long_text';level.value='';options.value='';required.checked=true;active.checked=true;published.checked=false;save.textContent='Add diagnostic question';feedback.textContent=''}
  function refresh(){
   questionList.textContent='Loading questions…';if(!courseSelect.value){questionList.textContent='Select a course to manage its questions.';return}
   sb.from('academy_diagnostic_questions').select('*').eq('course_id',courseSelect.value).order('position').then(function(r){questionList.textContent='';if(r.error){questionList.appendChild(msg(r.error.message,true));return}var qs=r.data||[];if(!qs.length){questionList.appendChild(msg('No diagnostic questions for this course yet.'));return}
    qs.forEach(function(q){var card=el('div',{class:'academy-diagnostic-item'},[el('strong',{text:q.prompt}),el('small',{text:q.response_type.replace('_',' ')+' · '+(q.target_level||'Any level')+' · '+(q.required?'Required':'Optional')}),el('span',{class:'academy-status '+(q.published?'status-approved':'status-draft'),text:q.published?'Published':'Draft'})]);
     var actions=el('div',{class:'row'}),edit=el('button',{class:'btn btn-outline',type:'button',text:'Edit'}),toggle=el('button',{class:'btn btn-outline',type:'button',text:q.published?'Unpublish':'Publish'}),del=el('button',{class:'btn btn-outline',type:'button',text:'Delete'});
     edit.addEventListener('click',function(){editing=q.id;prompt.value=q.prompt;type.value=q.response_type;level.value=q.target_level||'';options.value=(q.options||[]).map(function(x){return typeof x==='string'?x:x.label||x.value}).join('\n');required.checked=q.required;active.checked=q.active;published.checked=q.published;save.textContent='Save question';feedback.textContent='Editing question';editor.scrollIntoView({behavior:'smooth',block:'center'})});
     toggle.addEventListener('click',function(){sb.from('academy_diagnostic_questions').update({published:!q.published}).eq('id',q.id).then(function(x){if(x.error)alert(x.error.message);refresh()})});
     del.addEventListener('click',function(){if(confirm('Delete this diagnostic question? Existing responses may prevent deletion.'))sb.from('academy_diagnostic_questions').delete().eq('id',q.id).then(function(x){if(x.error)alert(x.error.message);refresh()})});
     actions.append(edit,toggle,del);card.appendChild(actions);questionList.appendChild(card)
    })
   })
  }
  sb.from('courses').select('id,title').order('title').then(function(r){if(r.error){feedback.textContent=r.error.message;return}(r.data||[]).forEach(function(x){courseSelect.appendChild(el('option',{value:x.id,text:x.title}))});refresh()});
  courseSelect.addEventListener('change',refresh);
  editor.addEventListener('submit',function(e){e.preventDefault();if(!courseSelect.value||!prompt.value.trim())return;var opts=type.value==='single_choice'?options.value.split('\n').map(function(x){return x.trim()}).filter(Boolean):[];if(type.value==='single_choice'&&opts.length<2){feedback.textContent='Add at least two answer options.';return}
   var payload={course_id:courseSelect.value,prompt:prompt.value.trim(),response_type:type.value,target_level:level.value||null,options:opts,required:required.checked,active:active.checked,published:published.checked};
   if(editing)sb.from('academy_diagnostic_questions').update(payload).eq('id',editing).then(function(x){feedback.textContent=x.error?x.error.message:'Question saved.';if(!x.error){reset();refresh()}})
   else sb.from('academy_diagnostic_questions').insert(payload).then(function(x){feedback.textContent=x.error?x.error.message:'Question added.';if(!x.error){reset();refresh()}})
  })
 }
 diagnostics();
 load()
}}
})();