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
  form.addEventListener('submit',function(e){e.preventDefault();save.disabled=true;feedback.textContent='Saving review…';
   var patch={status:st.value,reviewed_by:user.id,reviewed_at:new Date().toISOString(),decision_reason:rationale.value.trim()||null,updated_at:new Date().toISOString()};
   sb.from('academy_applications').update(patch).eq('id',x.id).then(function(a){if(a.error)throw a.error;
    var tasks=[sb.from('academy_application_events').insert({application_id:x.id,actor_id:user.id,event_type:'admin_review',from_status:x.status,to_status:st.value,message:rationale.value.trim()||('Status changed to '+st.value)}),sb.from('academy_audit_log').insert({actor_id:user.id,application_id:x.id,action:'application_review_updated',details:{from_status:x.status,to_status:st.value,confirmed_level:lv.value}})];if(note.value.trim())tasks.push(sb.from('academy_application_private_notes').insert({application_id:x.id,author_id:user.id,note:note.value.trim()}));
    if(rationale.value.trim())tasks.push(sb.from('academy_placements').upsert({application_id:x.id,confirmed_level:lv.value,recommended_level:x.proposed_level, rationale:rationale.value.trim(),assigned_by:user.id,assigned_at:new Date().toISOString(),updated_at:new Date().toISOString()},{onConflict:'application_id'}));
    return Promise.all(tasks)
   }).then(function(rs){var bad=rs.filter(function(z){return z&&z.error})[0];if(bad)throw bad.error;feedback.textContent='Review saved. Access is not granted by this screen; payment/admission fulfilment is a separate controlled step.';feedback.className='academy-admin-message';load()}).catch(function(err){feedback.textContent=err.message||String(err);feedback.className='academy-admin-message is-error'}).finally(function(){save.disabled=false})
  });
  detail.appendChild(el('p',{class:'academy-admin-footnote',text:'Recorded interviews, diagnostic scoring, scheduling and admission fulfilment will appear here as their secure workflows are completed. Do not share interview recordings through public media links.'}))
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