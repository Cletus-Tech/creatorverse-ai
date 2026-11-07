(function(){
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(x){if(x)n.appendChild(x)});return n}
var levels=['Beginner','Foundation','Intermediate','Advanced','Professional'];
window.CV_ACADEMY_PROGRESS={mount:function(host,sb,user){
 var root=el('section',{class:'academy-progress-admin'});host.appendChild(root);
 var head=el('div',{class:'academy-admin-head'},[el('div',{},[el('span',{class:'academy-eyebrow',text:'LEARNER SUCCESS & RETENTION'}),el('h2',{text:'Learning Progress & Activity'}),el('p',{text:'Monitor course completion, lesson activity, inactivity and level progression.'})]),el('button',{class:'btn btn-outline',type:'button',text:'Refresh'})]);root.appendChild(head);
 var stats=el('div',{class:'academy-admin-stats'}),filters=el('div',{class:'academy-admin-controls'}),term=el('input',{type:'search',placeholder:'Search learner or course…'}),filter=el('select',{},[['all','All activity'],['active','Active in last 7 days'],['warning','Inactive 8–14 days'],['overdue','Inactive 15+ days']].map(function(x){return el('option',{value:x[0],text:x[1]})})),list=el('div',{class:'academy-progress-list'});
 filters.append(term,filter);root.append(stats,filters,list);head.querySelector('button').addEventListener('click',load);term.addEventListener('input',draw);filter.addEventListener('change',draw);
 var records=[],profiles={},courses={},levelsByKey={};
 function message(t,bad){list.appendChild(el('p',{class:'academy-admin-message'+(bad?' is-error':''),text:t}))}
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
   sb.from('academy_learner_levels').select('*')
  ]).then(function(rs){
   var bad=rs.find(function(x){return x.error});if(bad){list.textContent='Learning monitor needs the Academy lifecycle migration and admin read permissions. '+bad.error.message;return}
   var enrol=rs[0].data||[],mods=rs[3].data||[],lessons=rs[4].data||[],progress=rs[5].data||[],activity=rs[6].data||[];
   profiles={};courses={};levelsByKey={};(rs[1].data||[]).forEach(function(x){profiles[x.id]=x});(rs[2].data||[]).forEach(function(x){courses[x.id]=x});(rs[7].data||[]).forEach(function(x){levelsByKey[x.user_id+':'+x.course_id]=x});
   var lessonCourse={};mods.forEach(function(m){lessons.forEach(function(l){if(l.module_id===m.id)lessonCourse[l.id]=m.course_id})});
   records=enrol.map(function(e){
    var ls=lessons.filter(function(l){return lessonCourse[l.id]===e.course_id}),done=progress.filter(function(p){return p.user_id===e.user_id&&p.completed_at&&ls.some(function(l){return l.id===p.lesson_id})}),acts=activity.filter(function(a){return a.user_id===e.user_id&&a.course_id===e.course_id});
    var dates=acts.map(function(a){return new Date(a.occurred_at).getTime()}).concat(done.map(function(p){return new Date(p.completed_at).getTime()})).filter(Number.isFinite);
    var last=dates.length?new Date(Math.max.apply(null,dates)):null,days=last?Math.floor((Date.now()-last.getTime())/86400000):null,pr=levelsByKey[e.user_id+':'+e.course_id]||{};
    return{user_id:e.user_id,course_id:e.course_id,enrolled_at:e.created_at,completed:done.length,total:ls.length,pct:ls.length?Math.round(done.length/ls.length*100):0,last:last,days:days,level:pr.current_level||'Beginner',highest:pr.highest_unlocked_level||pr.current_level||'Beginner',override:!!pr.admin_override,progress:pr}
   });
   var total=records.length,active=records.filter(function(r){return r.days!==null&&r.days<=7}).length,late=records.filter(function(r){return r.days===null||r.days>14}).length,avg=total?Math.round(records.reduce(function(a,r){return a+r.pct},0)/total):0;
   stats.textContent='';[['Enrolled learners',total],['Active this week',active],['Inactive 15+ days / no activity',late],['Average completion',avg+'%']].forEach(function(x){stats.appendChild(el('div',{class:'academy-admin-stat'},[el('strong',{text:String(x[1])}),el('span',{text:x[0]})]))});draw()
  }).catch(function(e){list.textContent=e.message||String(e)})
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
   card.appendChild(el('div',{class:'academy-progress-meta'},[el('span',{text:r.completed+' / '+r.total+' lessons · '+r.pct+'% complete'}),el('span',{text:'Last activity: '+(r.last?r.last.toLocaleString():'Not recorded')})]));
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