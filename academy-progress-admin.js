(function(){
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(x){if(x)n.appendChild(x)});return n}
var levels=['Beginner','Foundation','Intermediate','Advanced','Professional'];
window.CV_ACADEMY_PROGRESS={mount:function(host,sb,user){
 var root=el('section',{class:'academy-progress-admin'});host.appendChild(root);
 var head=el('div',{class:'academy-admin-head'},[el('div',{},[el('span',{class:'academy-eyebrow',text:'LEARNER SUCCESS & RETENTION'}),el('h2',{text:'Learning Progress & Activity'}),el('p',{text:'Monitor course completion, lesson activity, inactivity and level progression.'})]),el('button',{class:'btn btn-outline',type:'button',text:'Refresh'})]);root.appendChild(head);
 var stats=el('div',{class:'academy-admin-stats'}),rulesPanel=el('section',{class:'academy-progress-rules'}),unlockPanel=el('section',{class:'academy-progress-unlocks'}),filters=el('div',{class:'academy-admin-controls'}),term=el('input',{type:'search',placeholder:'Search learner or course…'}),filter=el('select',{},[['all','All activity'],['active','Active in last 7 days'],['warning','Inactive 8–14 days'],['overdue','Inactive 15+ days']].map(function(x){return el('option',{value:x[0],text:x[1]})})),list=el('div',{class:'academy-progress-list'});
 filters.append(term,filter);root.append(stats,rulesPanel,unlockPanel,filters,list);head.querySelector('button').addEventListener('click',load);term.addEventListener('input',draw);filter.addEventListener('change',draw);
 var records=[],profiles={},courses={},levelsByKey={};
 function message(t,bad){list.appendChild(el('p',{class:'academy-admin-message'+(bad?' is-error':''),text:t}))}
 function field(label,node){return el('label',{class:'academy-admin-field'},[el('span',{text:label}),node])}
 function load(){
  list.textContent='Loading learner activity…';
  Promise.all([
   sb.from('enrolments').select('user_id,course_id,created_at'),
   sb.from('profiles').select('id,full_name,email,avatar_url'),
   sb.from('courses').select('id,title'),
   sb.from('modules').select('id,course_id'),
   sb.from('lessons').select('id,module_id'),
   sb.from('lesson_progress').select('user_id,lesson_id,completed_at'),
   sb.from('academy_learning_activity').select('user_id,course_id,activity_type,occurred_at,lesson_id').order('occurred_at',{ascending:false}).limit(5000),
   sb.from('academy_learner_levels').select('*'),
   sb.from('academy_level_rules').select('*').order('sequence_no'),
   sb.from('academy_level_unlock_requests').select('*').eq('status','pending').order('requested_at',{ascending:true})
  ]).then(function(rs){
   var bad=rs.find(function(x){return x.error});if(bad){list.textContent='Learning monitor needs the Academy lifecycle migration and admin read permissions. '+bad.error.message;return}
   var enrol=rs[0].data||[],mods=rs[3].data||[],lessons=rs[4].data||[],progress=rs[5].data||[],activity=rs[6].data||[];
   profiles={};courses={};levelsByKey={};(rs[1].data||[]).forEach(function(x){profiles[x.id]=x});(rs[2].data||[]).forEach(function(x){courses[x.id]=x});(rs[7].data||[]).forEach(function(x){levelsByKey[x.user_id+':'+x.course_id]=x});
   renderRules(rs[2].data||[],rs[8].data||[]);
   renderUnlockRequests(rs[9].data||[]);
   var lessonCourse={};mods.forEach(function(m){lessons.forEach(function(l){if(l.module_id===m.id)lessonCourse[l.id]=m.course_id})});
   records=enrol.map(function(e){
    var ls=lessons.filter(function(l){return lessonCourse[l.id]===e.course_id}),done=progress.filter(function(p){return p.user_id===e.user_id&&p.completed_at&&ls.some(function(l){return l.id===p.lesson_id})}),acts=activity.filter(function(a){return a.user_id===e.user_id&&a.course_id===e.course_id});
    var dates=acts.map(function(a){return new Date(a.occurred_at).getTime()}).concat(done.map(function(p){return new Date(p.completed_at).getTime()})).filter(Number.isFinite);
    var last=dates.length?new Date(Math.max.apply(null,dates)):null,days=last?Math.floor((Date.now()-last.getTime())/86400000):null,pr=levelsByKey[e.user_id+':'+e.course_id]||{};
    var recent=acts.filter(function(a){return(Date.now()-new Date(a.occurred_at).getTime())<=7*86400000}),week=recent.filter(function(a){return a.activity_type==='lesson_completed'}).length,views=recent.filter(function(a){return a.activity_type==='lesson_viewed'}).length,assess=recent.filter(function(a){return a.activity_type==='quiz_submitted'||a.activity_type==='assignment_submitted'}).length;return{user_id:e.user_id,course_id:e.course_id,enrolled_at:e.created_at,completed:done.length,total:ls.length,pct:ls.length?Math.round(done.length/ls.length*100):0,last:last,days:days,weekly:week,views:views,assess:assess,level:pr.current_level||'Beginner',highest:pr.highest_unlocked_level||pr.current_level||'Beginner',override:!!pr.admin_override,progress:pr}
   });
   var total=records.length,active=records.filter(function(r){return r.days!==null&&r.days<=7}).length,late=records.filter(function(r){return r.days===null||r.days>14}).length,avg=total?Math.round(records.reduce(function(a,r){return a+r.pct},0)/total):0;
   stats.textContent='';[['Enrolled learners',total],['Active this week',active],['Inactive 15+ days / no activity',late],['Average completion',avg+'%']].forEach(function(x){stats.appendChild(el('div',{class:'academy-admin-stat'},[el('strong',{text:String(x[1])}),el('span',{text:x[0]})]))});draw()
  }).catch(function(e){list.textContent=e.message||String(e)})
 }
function renderRules(courseRows,ruleRows){
  rulesPanel.textContent='';rulesPanel.appendChild(el('h3',{text:'Level progression rules'}));rulesPanel.appendChild(el('p',{class:'academy-admin-footnote',text:'Set the completion, quiz, assignment and active-day thresholds for each level. Publish a rule to activate it. Choose automatic unlock or require an administrator approval.'}));
  var course=el('select',{});courseRows.forEach(function(c){course.appendChild(el('option',{value:c.id,text:c.title}))});
  var level=el('select',{},levels.map(function(l){return el('option',{value:l,text:l})})),completion=el('input',{type:'number',min:'0',max:'100',step:'1',value:'20'}),quiz=el('input',{type:'number',min:'0',max:'100',step:'1',placeholder:'Optional'}),assign=el('input',{type:'number',min:'0',step:'1',value:'0'}),days=el('input',{type:'number',min:'0',step:'1',value:'0'}),approval=el('input',{type:'checkbox'});approval.checked=true;var published=el('input',{type:'checkbox'}),form=el('form',{class:'academy-review-form'}),feedback=el('small'),save=el('button',{class:'btn btn-primary',type:'submit',text:'Save level rule'}),list=el('div',{class:'academy-rule-list'});
  form.append(field('Course',course),field('Level',level),field('Minimum lesson completion (%)',completion),field('Minimum quiz average (%) — optional',quiz),field('Minimum submitted assignments',assign),field('Minimum active study days',days),field('Require admin approval',approval),field('Published / active',published),save,feedback);rulesPanel.append(form,list);
  function drawRules(){list.textContent='';ruleRows.filter(function(r){return r.course_id===course.value}).forEach(function(r){var row=el('button',{type:'button',class:'academy-rule-chip',text:r.level_name+' · '+r.min_completed_percent+'% · '+(r.published?'Published':'Draft')});row.addEventListener('click',function(){level.value=r.level_name;completion.value=r.min_completed_percent;quiz.value=r.min_quiz_average==null?'':r.min_quiz_average;assign.value=r.min_assignment_count;days.value=r.min_active_days;approval.checked=r.requires_admin_approval;published.checked=r.published});list.appendChild(row)})}
  course.addEventListener('change',drawRules);drawRules();
  form.addEventListener('submit',function(e){e.preventDefault();var pc=Number(completion.value),qa=quiz.value===''?null:Number(quiz.value),ac=Number(assign.value),ad=Number(days.value);if(!Number.isFinite(pc)||pc<0||pc>100||qa!==null&&(!Number.isFinite(qa)||qa<0||qa>100)||ac<0||ad<0){feedback.textContent='Check the threshold values.';return}
   save.disabled=true;feedback.textContent='Saving rule…';var payload={course_id:course.value,level_name:level.value,sequence_no:levels.indexOf(level.value)+1,min_completed_percent:pc,min_quiz_average:qa,min_assignment_count:ac,min_active_days:ad,requires_admin_approval:approval.checked,published:published.checked,updated_by:user.id,updated_at:new Date().toISOString()};
   sb.from('academy_level_rules').upsert(payload,{onConflict:'course_id,level_name'}).select('*').single().then(function(z){if(z.error)throw z.error;var ix=ruleRows.findIndex(function(r){return r.course_id===z.data.course_id&&r.level_name===z.data.level_name});if(ix<0)ruleRows.push(z.data);else ruleRows[ix]=z.data;drawRules();feedback.textContent='Rule saved.';return sb.from('academy_audit_log').insert({actor_id:user.id,action:'academy_level_rule_updated',details:payload})}).then(function(z){if(z&&z.error)throw z.error}).catch(function(e){feedback.textContent=e.message||String(e)}).finally(function(){save.disabled=false})
  })
 }
 function renderUnlockRequests(requests){
  unlockPanel.textContent='';unlockPanel.appendChild(el('h3',{text:'Level unlock approvals'}));if(!requests.length){unlockPanel.appendChild(el('p',{class:'academy-admin-footnote',text:'No learners are waiting for level approval.'}));return}
  requests.forEach(function(r){var p=profiles[r.user_id]||{},c=courses[r.course_id]||{},row=el('div',{class:'academy-unlock-request'},[el('strong',{text:(p.full_name||p.email||'Learner')+' · '+(c.title||'Course')}),el('span',{text:'Requested '+r.level_name+' at '+r.progress_percent+'% completion'}),el('input',{type:'text',placeholder:'Optional reviewer note'})]),note=row.querySelector('input');
   ['Approve','Reject'].forEach(function(action){var b=el('button',{class:'btn btn-outline',type:'button',text:action});b.addEventListener('click',function(){b.disabled=true;var status=action==='Approve'?'approved':'rejected';sb.from('academy_level_unlock_requests').update({status:status,reviewed_at:new Date().toISOString(),reviewed_by:user.id,reviewer_note:note.value.trim()||null}).eq('id',r.id).then(function(z){if(z.error)throw z.error;if(status==='approved')return sb.from('academy_learner_levels').upsert({user_id:r.user_id,course_id:r.course_id,current_level:r.level_name,highest_unlocked_level:r.level_name,progress_percent:r.progress_percent,updated_by:user.id,last_evaluated_at:new Date().toISOString(),updated_at:new Date().toISOString()},{onConflict:'user_id,course_id'});}).then(function(z){if(z&&z.error)throw z.error;return sb.from('academy_audit_log').insert({actor_id:user.id,action:'academy_level_unlock_reviewed',details:{request_id:r.id,status:status,level:r.level_name,reviewer_note:note.value.trim()}})}).then(function(z){if(z.error)throw z.error;row.remove()}).catch(function(e){b.disabled=false;note.value=e.message||String(e)})});row.appendChild(b)});
   unlockPanel.appendChild(row)
  })
 }
  function draw(){
  list.textContent='';var q=term.value.toLowerCase(),f=filter.value;
  var rows=records.filter(function(r){var p=profiles[r.user_id]||{},c=courses[r.course_id]||{},d=r.days;return(!q||[p.full_name,p.email,c.title].join(' ').toLowerCase().indexOf(q)>-1)&&(f==='all'||(f==='active'&&d!==null&&d<=7)||(f==='warning'&&d!==null&&d>=8&&d<=14)||(f==='overdue'&&(d===null||d>=15)))});
  if(!rows.length){message(records.length?'No learners match these filters.':'No active course enrolments found.');return}
  rows.sort(function(a,b){return(a.days===null?9999:a.days)-(b.days===null?9999:b.days)});
  rows.forEach(function(r){
   var p=profiles[r.user_id]||{},c=courses[r.course_id]||{},key=r.user_id+':'+r.course_id,card=el('article',{class:'academy-progress-card'});
   var label=r.days===null?'No recorded activity':r.days===0?'Active today':r.days+' days inactive';
   card.appendChild(el('div',{class:'academy-progress-card-head'},[el('div',{},[el('strong',{text:p.full_name||p.email||r.user_id}),el('small',{text:c.title||'Course'})]),el('span',{class:'academy-progress-inactivity'+(r.days===null||r.days>=15?' is-overdue':r.days>=8?' is-warning':' is-active'),text:label})]));
   card.appendChild(el('div',{class:'academy-progress-meter'},[el('span',{style:'width:'+r.pct+'%'})]));
   card.appendChild(el('div',{class:'academy-progress-meta'},[el('span',{text:r.completed+' / '+r.total+' lessons · '+r.pct+'% complete'}),el('span',{text:r.weekly+' lessons completed · '+r.views+' lesson visits · '+r.assess+' assessments (7 days)'}),el('span',{text:'Last activity: '+(r.last?r.last.toLocaleString():'Not recorded')})]));
   var badge=el('div',{class:'academy-level-badge'},[el('span',{text:'Current level: '+r.level}),el('span',{text:'Highest unlocked: '+r.highest})]);card.appendChild(badge);
   var controls=el('div',{class:'academy-level-controls'}),select=el('select',{},levels.map(function(l){return el('option',{value:l,text:l})}));select.value=r.level;
   var override=el('input',{type:'checkbox'});override.checked=r.override;
   var note=el('input',{type:'text',placeholder:'Reason for manual level decision'});note.value=r.progress.admin_note||'';
   var save=el('button',{class:'btn btn-outline',type:'button',text:'Save level'}),feedback=el('small');
   controls.append(el('label',{},[el('span',{text:'Set current level'}),select]),el('label',{},[override,el('span',{text:'Admin override'})]),note,save,feedback);card.appendChild(controls);
   save.addEventListener('click',function(){
    if(override.checked&&!note.value.trim()){feedback.textContent='Add a reason for a manual override.';return}
    save.disabled=true;feedback.textContent='Saving…';
    var payload={user_id:r.user_id,course_id:r.course_id,current_level:select.value,highest_unlocked_level:levels[Math.max(levels.indexOf(r.highest),levels.indexOf(select.value))],progress_percent:r.pct,completed_lessons:r.completed,total_lessons:r.total,last_activity_at:r.last?r.last.toISOString():null,admin_override:override.checked,admin_note:note.value.trim()||null,updated_by:user.id,last_evaluated_at:new Date().toISOString(),updated_at:new Date().toISOString()};
    sb.from('academy_learner_levels').upsert(payload,{onConflict:'user_id,course_id'}).then(function(z){if(z.error)throw z.error;return sb.from('academy_audit_log').insert({actor_id:user.id,action:'learner_level_admin_update',details:{user_id:r.user_id,course_id:r.course_id,level:select.value,override:override.checked,reason:note.value.trim()}})}).then(function(z){if(z.error)throw z.error;feedback.textContent='Saved.';r.level=select.value;r.highest=payload.highest_unlocked_level;r.override=override.checked;r.progress=payload}).catch(function(e){feedback.textContent=e.message||String(e)}).finally(function(){save.disabled=false})
   });
   list.appendChild(card)
  })
 }
 load()
}}
})();