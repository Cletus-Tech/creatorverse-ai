(function(){
'use strict';
var host=document.getElementById('content'),params=new URLSearchParams(location.search),id=params.get('id'),sb=window.CV_SB,user,interview,invitation,stream,recorder,chunks=[],blob,startedAt=0,tick;
function el(t,a,children){var n=document.createElement(t);Object.keys(a||{}).forEach(function(k){if(k==='text')n.textContent=a[k];else n.setAttribute(k,a[k])});(children||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function message(t,bad){var n=el('p',{class:'cv-interview-message'+(bad?' error':'') ,text:t});host.appendChild(n);return n}
function stopTracks(){if(stream)stream.getTracks().forEach(function(t){t.stop()});stream=null}
function fmt(s){var m=Math.floor(s/60),r=s%60;return m+':'+String(r).padStart(2,'0')}
function render(){
 host.textContent='';host.classList.add('academy-interview-page');
 var type=interview.interview_type,live=type==='live',video=type==='recorded_video';
 host.appendChild(el('div',{class:'cv-interview-hero'},[el('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · INTERVIEW'},),el('h1',{text:live?'Your live interview':video?'Audiovisual defence':'Audio defence'}),el('p',{text:'Read the assignment carefully and submit your response before the deadline.'})]));
 var panel=el('section',{class:'cv-interview-panel'},[
  el('div',{class:'cv-interview-meta'},[el('span',{class:'academy-status-pill',text:type.replace('recorded_','').replace('_',' ')}),el('span',{text:'Round '+(interview.round_number||1)}),el('span',{text:'Deadline: '+new Date(invitation.ends_at).toLocaleString()+' · '+(invitation.timezone||'')})]),
  el('h2',{text:interview.topic||'Interview topic'}),
  el('div',{class:'cv-interview-instructions'},[el('h3',{text:'Instructions'}),el('p',{text:interview.instructions||invitation.learner_instructions||'Follow the instructions provided by your Academy interviewer.'})]),
  el('div',{class:'cv-interview-meta'},[el('span',{text:'Preparation: '+fmt(interview.preparation_seconds||0)}),el('span',{text:'Maximum duration: '+fmt(interview.max_duration_seconds||600)})])
 ]);
 if(Array.isArray(interview.assessment_criteria)&&interview.assessment_criteria.length){var ul=el('ul',{class:'cv-interview-criteria'});interview.assessment_criteria.forEach(function(v){ul.appendChild(el('li',{text:v}))});panel.appendChild(el('div',{class:'cv-interview-instructions'},[el('h3',{text:'What will be assessed'}),ul]))}
 host.appendChild(panel);
 if(interview.status==='submitted'||interview.status==='completed'){host.appendChild(el('div',{class:'cv-interview-panel'},[el('h3',{text:'Response received'}),el('p',{text:'Your response has been submitted successfully. You can return to your admission status page for updates.'}),el('a',{class:'btn btn-primary',href:'academy-status.html',text:'Back to admission status'})]));return}
 if(live){var livePanel=el('section',{class:'cv-interview-panel'},[el('h2',{text:'Secure CreatorVerse live room'}),el('p',{text:'This session is designed to take place inside CreatorVerse. Your interviewer will open the same room from their assigned workspace.'}),el('a',{class:'btn btn-primary',href:'academy-live-room.html?interview='+encodeURIComponent(id),text:'Enter live interview room'})]);host.appendChild(livePanel);return}
 var consent=el('input',{type:'checkbox'}),consentWrap=el('label',{class:'cv-interview-consent'},[consent,el('span',{text:'I consent to recording and submitting this response for Academy assessment. I understand it will be stored privately and accessible only to authorised Academy staff assigned to review it.'})]);
 var preview=el(video?'video':'audio',{class:'cv-interview-preview',controls:'controls'});if(video)preview.setAttribute('playsinline','');
 var timer=el('strong',{class:'cv-interview-timer',text:'0:00'}),status=el('p',{class:'cv-interview-status',text:'Allow microphone'+(video?' and camera':'')+' access when you are ready.'});
 var start=el('button',{class:'btn btn-primary',type:'button',text:'Start recording'}),stop=el('button',{class:'btn btn-outline',type:'button',text:'Stop recording'}),submit=el('button',{class:'btn btn-primary',type:'button',text:'Submit defence'});stop.disabled=true;submit.disabled=true;
 var actions=el('div',{class:'cv-interview-actions'},[start,stop,submit]);
 var rec=el('section',{class:'cv-interview-panel'},[el('h2',{text:'Record your defence'}),el('p',{text:video?'Record a clear video with your face and voice. Keep your device steady and speak clearly.':'Record your explanation in a quiet place and speak clearly.'}),consentWrap,preview,timer,actions,status]);
 host.appendChild(rec);
 start.addEventListener('click',async function(){
  try{
   start.disabled=true;status.textContent='Requesting device permission…';
   stream=await navigator.mediaDevices.getUserMedia(video?{audio:true,video:{facingMode:'user'}}:{audio:true});
   if(video){preview.srcObject=stream;preview.muted=true;await preview.play().catch(function(){})}
   if(!window.MediaRecorder){status.textContent='This browser does not support secure in-page recording. Please use an updated Chrome or Edge browser.';start.disabled=false;stopTracks();return}
   var candidates=video?['video/webm;codecs=vp9,opus','video/webm;codecs=vp8,opus','video/webm','video/mp4']:['audio/webm;codecs=opus','audio/webm','audio/mp4'];
   var mime=candidates.find(function(m){return window.MediaRecorder&&MediaRecorder.isTypeSupported(m)})||'';
   recorder=new MediaRecorder(stream,mime?{mimeType:mime}:undefined);chunks=[];startedAt=Date.now();
   recorder.ondataavailable=function(e){if(e.data&&e.data.size)chunks.push(e.data)};
   recorder.onstop=function(){blob=new Blob(chunks,{type:recorder.mimeType|| (video?'video/webm':'audio/webm')});if(preview.srcObject){preview.srcObject=null;stopTracks()}preview.src=URL.createObjectURL(blob);preview.controls=true;preview.muted=false;submit.disabled=false;status.textContent='Recording ready. Review it before submitting.';clearInterval(tick);timer.textContent=fmt(Math.round((Date.now()-startedAt)/1000))};
   recorder.start(1000);stop.disabled=false;status.textContent='Recording…';tick=setInterval(function(){var secs=Math.floor((Date.now()-startedAt)/1000);timer.textContent=fmt(secs);if(secs>=(interview.max_duration_seconds||600)){recorder.stop();stop.disabled=true}},500)
  }catch(e){status.textContent='Could not start recording: '+(e.message||String(e));start.disabled=false;stopTracks()}
 });
 stop.addEventListener('click',function(){if(recorder&&recorder.state!=='inactive'){recorder.stop();stop.disabled=true;start.disabled=false}});
 submit.addEventListener('click',async function(){
  if(!blob){status.textContent='Record your response first.';return}
  if(!consent.checked){status.textContent='Please confirm recording consent before submitting.';return}
  var seconds=Math.max(1,Math.round((Date.now()-startedAt)/1000));if(seconds>(interview.max_duration_seconds||600)+3){status.textContent='The recording exceeds the maximum duration.';return}if(blob.size>104857600){status.textContent='This recording is larger than the 100 MB upload limit. Record a shorter response or reduce the video resolution.';return}
  submit.disabled=true;status.textContent='Uploading your private recording…';
  try{
   var ext=blob.type.indexOf('mp4')>-1?'mp4':'webm',path=id+'/'+user.id+'/'+Date.now()+'.'+ext;
   var up=await sb.storage.from('academy-interviews').upload(path,blob,{contentType:(blob.type||'application/octet-stream').split(';')[0],upsert:false});if(up.error)throw up.error;
   status.textContent='Finalising your submission…';
   var result=await sb.rpc('submit_academy_interview_response',{p_interview_id:id,p_media_path:path,p_duration_seconds:seconds,p_consent:true});if(result.error){await sb.storage.from('academy-interviews').remove([path]);throw result.error}
   rec.textContent='';rec.appendChild(el('h2',{text:'Defence submitted'}));rec.appendChild(el('p',{text:'Your recording has been uploaded securely. The assigned interviewer will review it and your admission status will update when a decision is made.'}));rec.appendChild(el('a',{class:'btn btn-primary',href:'academy-status.html',text:'Return to admission status'}));
  }catch(e){status.textContent=e.message||'Unable to submit your recording. Please try again.';submit.disabled=false}
 });
 window.addEventListener('beforeunload',stopTracks);
}
async function boot(){
 if(!sb){message('CreatorVerse is still loading. Refresh this page.');return}
 var auth=await sb.auth.getUser();user=auth.data&&auth.data.user;if(!user){host.textContent='';host.appendChild(el('a',{class:'btn btn-primary',href:'login.html',text:'Sign in to continue'}));return}
 if(!id){message('This interview link is incomplete.',true);return}
 var brief=await sb.rpc('get_my_academy_interview_details',{p_interview_id:id});
 if(brief.error||!brief.data||!brief.data.interview||!brief.data.invitation){message('This interview is unavailable or is not assigned to your account.',true);return}
 interview=brief.data.interview;invitation=brief.data.invitation;render()
}
if(window.CV_SB)boot().catch(function(e){message(e.message||String(e),true)});else document.addEventListener('cv-ready',function(){sb=window.CV_SB;boot().catch(function(e){message(e.message||String(e),true)})},{once:true});
})();