(function(){
'use strict';
var host=document.getElementById('content'),id=new URLSearchParams(location.search).get('interview'),sb=window.CV_SB,user,interview,interviewer=false,room=null,localTrack=null,remoteTracks=[];
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function status(t,bad){var n=document.getElementById('cv-live-status');if(n){n.textContent=t;n.className='cv-live-status'+(bad?' error':'')}}
function render(){
 host.textContent='';
 host.appendChild(el('div',{class:'cv-live-head'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · PRIVATE SESSION'}),el('h1',{text:'Live interview room'}),el('p',{text:interview.topic||'Academy interview'})]));
 var grid=el('div',{class:'cv-live-grid'}),remote=el('video',{id:'cv-live-remote',autoplay:'autoplay',playsinline:'playsinline'}),local=el('video',{id:'cv-live-local',autoplay:'autoplay',playsinline:'playsinline',muted:'muted'});
 grid.append(el('div',{class:'cv-live-tile'},[el('span',{text:'Other participant'}),remote]),el('div',{class:'cv-live-tile cv-live-self'},[el('span',{text:'You'}),local]));host.appendChild(grid);
 var controls=el('div',{class:'cv-live-controls'}),join=el('button',{class:'btn btn-primary',type:'button',text:'Join with camera & microphone'}),mute=el('button',{class:'btn btn-outline',type:'button',text:'Mute microphone',disabled:'disabled'}),camera=el('button',{class:'btn btn-outline',type:'button',text:'Turn camera off',disabled:'disabled'}),leave=el('button',{class:'btn btn-outline',type:'button',text:'Leave room',disabled:'disabled'});
 controls.append(join,mute,camera,leave);host.append(controls,el('p',{id:'cv-live-status',class:'cv-live-status',text:'Join when you are ready. The other participant must also enter this room.'}),el('p',{class:'cv-live-footnote',text:'This is a private CreatorVerse Academy live session. Media is transmitted through the secure room and is not recorded by CreatorVerse.'}));
 var connected=false,muted=false,cameraOn=false;
 join.addEventListener('click',async function(){
  join.disabled=true;status('Requesting secure room access…');
  try{
   const sdk=await import('https://cdn.jsdelivr.net/npm/livekit-client@2.15.6/dist/livekit-client.esm.mjs');
   const tokenResult=await sb.functions.invoke('livekit-token',{body:{interview_id:id}});
   if(tokenResult.error)throw tokenResult.error;
   const credentials=tokenResult.data||{};
   if(!credentials.url||!credentials.token)throw new Error('The secure room service did not return connection credentials.');
   if(interviewer){const started=await sb.rpc('mark_academy_live_interview_started',{p_interview_id:id});if(started.error)throw started.error;}
   room=new sdk.Room({adaptiveStream:true,dynacast:true});
   room.on(sdk.RoomEvent.TrackSubscribed,function(track){if(track.kind==='video'){track.attach(remote);remote.play().catch(function(){})}else{track.attach()}});
   room.on(sdk.RoomEvent.TrackUnsubscribed,function(track){track.detach()});
   room.on(sdk.RoomEvent.Disconnected,function(){connected=false;status('The room connection ended.')});
   await room.connect(credentials.url,credentials.token);
   await room.localParticipant.setMicrophoneEnabled(true);
   await room.localParticipant.setCameraEnabled(true);
   room.localParticipant.videoTrackPublications.forEach(function(pub){if(pub.track){pub.track.attach(local);local.play().catch(function(){})}});
   connected=true;cameraOn=true;mute.disabled=false;camera.disabled=false;leave.disabled=false;
   status('Connected. You can begin your interview.');
  }catch(e){join.disabled=false;status('Could not join: '+(e.message||String(e)),true);if(room){await room.disconnect();room=null}}
 });
 mute.addEventListener('click',async function(){if(!room)return;try{muted=!muted;await room.localParticipant.setMicrophoneEnabled(!muted);mute.textContent=muted?'Unmute microphone':'Mute microphone'}catch(e){status('Microphone control failed: '+e.message,true)}});
 camera.addEventListener('click',async function(){if(!room)return;try{cameraOn=!cameraOn;await room.localParticipant.setCameraEnabled(cameraOn);camera.textContent=cameraOn?'Turn camera off':'Turn camera on';if(!cameraOn)local.srcObject=null;else room.localParticipant.videoTrackPublications.forEach(function(pub){if(pub.track)pub.track.attach(local)})}catch(e){status('Camera control failed: '+e.message,true)}});
 leave.addEventListener('click',async function(){if(room){await room.disconnect();room=null}connected=false;join.disabled=false;mute.disabled=true;camera.disabled=true;leave.disabled=true;status('You have left the interview room.')});
 window.addEventListener('beforeunload',function(){if(room)room.disconnect()});
}
async function boot(){
 if(!sb){host.textContent='CreatorVerse is still loading.';return}
 var a=await sb.auth.getUser();user=a.data&&a.data.user;
 if(!user){host.textContent='';host.appendChild(el('a',{href:'login.html',class:'btn btn-primary',text:'Sign in to continue'}));return}
 if(!id){host.textContent='This room link is incomplete.';return}
 var access=await sb.rpc('can_access_academy_interview',{p_interview_id:id});
 if(access.error||!access.data){host.textContent='You do not have permission to enter this interview room.';return}
 var r=await sb.from('academy_interviews').select('id,interview_type,reviewer_id,topic').eq('id',id).maybeSingle();
 var data=r.data;
 if(!data){var brief=await sb.rpc('get_my_academy_interview_details',{p_interview_id:id});if(brief.error||!brief.data){host.textContent='This live interview is unavailable.';return}data=brief.data.interview}
 if(r.error||!data||data.interview_type!=='live'){host.textContent='This live interview is unavailable.';return}
 interview=data;
 var profile=await sb.from('profiles').select('role').eq('id',user.id).maybeSingle();
 interviewer=interview.reviewer_id===user.id||!!(profile.data&&['admin','super_admin'].includes(profile.data.role));
 render();
}
if(window.CV_SB)boot().catch(function(e){host.textContent=e.message||String(e)});
else document.addEventListener('cv-ready',function(){sb=window.CV_SB;boot().catch(function(e){host.textContent=e.message||String(e)})},{once:true});
})();