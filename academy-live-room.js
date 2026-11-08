(function(){
'use strict';var host=document.getElementById('content'),id=new URLSearchParams(location.search).get('interview'),sb=window.CV_SB,user,channel,pc,localStream,remoteStream,interviewer=false,offered=false,pendingCandidates=[];
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function status(t,bad){var n=document.getElementById('cv-live-status');if(n){n.textContent=t;n.className='cv-live-status'+(bad?' error':'')}}
function send(payload){if(channel)channel.send({type:'broadcast',event:'signal',payload:Object.assign({from:user.id},payload)})}
async function drain(){for(var c of pendingCandidates){try{await pc.addIceCandidate(c)}catch(e){console.warn(e)}}pendingCandidates=[]}
async function makeOffer(){if(offered||!interviewer)return;offered=true;var offer=await pc.createOffer();await pc.setLocalDescription(offer);send({kind:'offer',sdp:pc.localDescription})}
async function signal(p){if(!p||p.from===user.id)return;try{
 if(p.kind==='ready'){if(interviewer)await makeOffer();else send({kind:'ready'})}
 else if(p.kind==='offer'){await pc.setRemoteDescription(new RTCSessionDescription(p.sdp));await drain();var answer=await pc.createAnswer();await pc.setLocalDescription(answer);send({kind:'answer',sdp:pc.localDescription});status('Connecting your camera and microphone…')}
 else if(p.kind==='answer'){await pc.setRemoteDescription(new RTCSessionDescription(p.sdp));await drain()}
 else if(p.kind==='candidate'){var c=new RTCIceCandidate(p.candidate);if(pc.remoteDescription)await pc.addIceCandidate(c);else pendingCandidates.push(c)}
 else if(p.kind==='leave'){status('The other participant has left the room.')}
 }catch(e){status('Connection setup error: '+(e.message||String(e)),true)}
}
function render(interview){
 host.textContent='';host.appendChild(el('div',{class:'cv-live-head'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · PRIVATE SESSION'}),el('h1',{text:'Live interview room'}),el('p',{text:interview.topic||'Academy interview'})]));
 var grid=el('div',{class:'cv-live-grid'}),remote=el('video',{id:'cv-live-remote',autoplay:'autoplay',playsinline:'playsinline'}),local=el('video',{id:'cv-live-local',autoplay:'autoplay',playsinline:'playsinline',muted:'muted'});grid.append(el('div',{class:'cv-live-tile'},[el('span',{text:'Other participant'}),remote]),el('div',{class:'cv-live-tile cv-live-self'},[el('span',{text:'You'}),local]));host.appendChild(grid);
 var controls=el('div',{class:'cv-live-controls'}),join=el('button',{class:'btn btn-primary',type:'button',text:'Join with camera & microphone'}),mute=el('button',{class:'btn btn-outline',type:'button',text:'Mute microphone',disabled:'disabled'}),camera=el('button',{class:'btn btn-outline',type:'button',text:'Turn camera off',disabled:'disabled'}),leave=el('button',{class:'btn btn-outline',type:'button',text:'Leave room',disabled:'disabled'});controls.append(join,mute,camera,leave);host.append(controls,el('p',{id:'cv-live-status',class:'cv-live-status',text:'Join when you are ready. The other participant must also enter this room.'}),el('p',{class:'cv-live-footnote',text:'This is a private, in-app, peer-to-peer session. Do not close this tab during the interview. The session is not recorded by CreatorVerse.'}));
 join.addEventListener('click',async function(){join.disabled=true;status('Requesting camera and microphone permission…');try{
  localStream=await navigator.mediaDevices.getUserMedia({audio:true,video:true});local.srcObject=localStream;
  pc=new RTCPeerConnection({iceServers:[{urls:'stun:stun.l.google.com:19302'},{urls:'stun:stun1.l.google.com:19302'}]});
  localStream.getTracks().forEach(function(t){pc.addTrack(t,localStream)});
  pc.ontrack=function(e){remoteStream=e.streams[0];remote.srcObject=remoteStream;status('Connected. You can begin your interview.')};
  pc.onicecandidate=function(e){if(e.candidate)send({kind:'candidate',candidate:e.candidate})};
  pc.onconnectionstatechange=function(){if(pc.connectionState==='connected')status('Connected. You can begin your interview.');if(['failed','disconnected'].includes(pc.connectionState))status('Connection interrupted. Check both devices and network permissions, then rejoin.',true)};
  channel=sb.channel('academy-interview:'+id,{config:{private:true,broadcast:{self:false}}});
  channel.on('broadcast',{event:'signal'},function(e){signal(e.payload)});
  channel.subscribe(async function(s){if(s==='SUBSCRIBED'){if(interviewer){var z=await sb.rpc('mark_academy_live_interview_started',{p_interview_id:id});if(z.error){status(z.error.message,true);return}}send({kind:'ready'});status('Room connected. Waiting for the other participant…')}});
  mute.disabled=false;camera.disabled=false;leave.disabled=false;status('Waiting for the other participant to connect…');
 }catch(e){join.disabled=false;status('Could not join: '+(e.message||String(e)),true);if(localStream)localStream.getTracks().forEach(function(t){t.stop()})}
 });
 mute.addEventListener('click',function(){var t=localStream&&localStream.getAudioTracks()[0];if(!t)return;t.enabled=!t.enabled;mute.textContent=t.enabled?'Mute microphone':'Unmute microphone'});
 camera.addEventListener('click',function(){var t=localStream&&localStream.getVideoTracks()[0];if(!t)return;t.enabled=!t.enabled;camera.textContent=t.enabled?'Turn camera off':'Turn camera on'});
 leave.addEventListener('click',function(){send({kind:'leave'});cleanup();status('You have left the interview room.')});
 function cleanup(){if(channel){sb.removeChannel(channel);channel=null}if(pc){pc.close();pc=null}if(localStream){localStream.getTracks().forEach(function(t){t.stop()});localStream=null}join.disabled=false;mute.disabled=true;camera.disabled=true;leave.disabled=true}
 window.addEventListener('beforeunload',cleanup);
}
async function boot(){if(!sb){host.textContent='CreatorVerse is still loading.';return}var a=await sb.auth.getUser();user=a.data&&a.data.user;if(!user){host.textContent='';host.appendChild(el('a',{href:'login.html',class:'btn btn-primary',text:'Sign in to continue'}));return}if(!id){host.textContent='This room link is incomplete.';return}
 var access=await sb.rpc('can_access_academy_interview',{p_interview_id:id});if(access.error||!access.data){host.textContent='You do not have permission to enter this interview room.';return}
 var r=await sb.from('academy_interviews').select('id,interview_type,reviewer_id,topic').eq('id',id).maybeSingle();var interview=r.data;if(!interview){var brief=await sb.rpc('get_my_academy_interview_details',{p_interview_id:id});if(brief.error||!brief.data){host.textContent='This live interview is unavailable.';return}interview=brief.data.interview}if(r.error||!interview||interview.interview_type!=='live'){host.textContent='This live interview is unavailable.';return}
 var profile=await sb.from('profiles').select('role').eq('id',user.id).maybeSingle();interviewer=interview.reviewer_id===user.id||!!(profile.data&&['admin','super_admin'].includes(profile.data.role));render(interview)}
if(window.CV_SB)boot().catch(function(e){host.textContent=e.message||String(e)});else document.addEventListener('cv-ready',function(){sb=window.CV_SB;boot().catch(function(e){host.textContent=e.message||String(e)})},{once:true});
})();