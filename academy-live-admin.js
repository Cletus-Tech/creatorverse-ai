(function(){
'use strict';
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
window.CV_ACADEMY_LIVE_ADMIN={mount:function(host,sb,user,role){
 var root=el('section',{class:'cv-live-admin'});host.appendChild(root);
 var items=[],status=el('p',{class:'cv-live-admin-status',text:'Loading live interviews…'}),list=el('div',{class:'cv-live-admin-list'}),refresh=el('button',{type:'button',class:'btn btn-outline',text:'Refresh'});
 root.append(el('div',{class:'cv-live-admin-hero'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · LIVE CONTROL ROOM'}),el('h1',{text:'Live interviews'}),el('p',{text:'Find every scheduled live interview, ring the applicant, and join the same private room from this dashboard.'}),refresh]),status,list);
 refresh.addEventListener('click',load);
 function card(r){
  var box=el('article',{class:'cv-live-admin-card'});
  var statusText=(r.interview_status||'pending').replace(/_/g,' ');
  box.append(el('div',{class:'cv-live-admin-card-top'},[el('div',{},[el('span',{class:'academy-eyebrow',text:r.application_no||'ACADEMY APPLICATION'}),el('h3',{text:r.applicant_name||'Applicant'}),el('p',{text:r.course_title||'CreatorVerse Academy'})]),el('span',{class:'academy-status-pill',text:statusText})]));
  box.append(el('p',{class:'cv-live-admin-topic',text:r.topic||'Interview topic not set'}));
  var when=r.scheduled_start?new Date(r.scheduled_start).toLocaleString():'Time not scheduled';
  box.append(el('div',{class:'cv-live-admin-meta'},[el('span',{text:'Scheduled: '+when}),el('span',{text:'Interviewer: '+(r.reviewer_name||'Not assigned')}),el('span',{text:'Applicant response: '+(r.invitation_status||'not confirmed').replace(/_/g,' ')})]));
  var actions=el('div',{class:'cv-live-admin-actions'}),join=el('a',{class:'btn btn-primary',href:'academy-live-room.html?interview='+encodeURIComponent(r.interview_id),text:'Join live room'}),workspace=el('a',{class:'btn btn-outline',href:'academy-interviewer.html?interview='+encodeURIComponent(r.interview_id),text:'Open review workspace'}),ring=el('button',{type:'button',class:'btn btn-call',text:'Ring applicant · Join now'}),feedback=el('small',{class:'cv-live-admin-feedback'});
  actions.append(join,ring,workspace);box.append(actions,feedback);
  ring.addEventListener('click',async function(){
   ring.disabled=true;feedback.textContent='Calling applicant…';
   try{var z=await sb.rpc('ring_academy_live_interview',{p_interview_id:r.interview_id});if(z.error)throw z.error;var already=z.data&&z.data.already_ringing;feedback.textContent=already?'The applicant is already being rung. The call remains active for up to 90 seconds.':'Call sent. The applicant will see an incoming-call alert and can join the room.';ring.textContent='Call sent · ring again';}
   catch(e){feedback.textContent=e.message||String(e)}
   finally{ring.disabled=false}
  });
  return box
 }
 async function load(){
  refresh.disabled=true;status.textContent='Loading live interviews…';list.textContent='';
  try{var z=await sb.rpc('get_my_academy_interview_assignments');if(z.error)throw z.error;
   items=(z.data||[]).filter(function(r){return r.interview_type==='live'});
   if(!items.length){status.textContent='No live interviews are currently assigned or scheduled.';return}
   items.sort(function(a,b){var x=new Date(a.scheduled_start||0).getTime(),y=new Date(b.scheduled_start||0).getTime();return x-y});
   status.textContent=items.length+' live interview'+(items.length===1?'':'s')+' found. Select Join live room to enter, or ring the applicant first.';
   items.forEach(function(r){list.appendChild(card(r))});
  }catch(e){status.textContent='Could not load the live interview queue: '+(e.message||String(e))}
  finally{refresh.disabled=false}
 }
 load();
}};
})();