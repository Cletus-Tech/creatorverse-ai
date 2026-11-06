(function(){
'use strict';
var root=document.querySelector('.cv-messages-page');if(!root)return;
var sb=null,user=null,me=null,profiles={},conversations=[],active=null,messageChannel=null,presenceChannel=null,presence={},stories=[],storyTimer=null,searchTimer=null;
var $=function(id){return document.getElementById(id)};
function node(tag,attrs,children){var n=document.createElement(tag);Object.keys(attrs||{}).forEach(function(k){if(k==='text')n.textContent=attrs[k];else if(k==='class')n.className=attrs[k];else n.setAttribute(k,attrs[k])});(children||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function initials(p){return((p&&p.full_name)||p&&p.username||'Creator').trim().split(/\s+/).slice(0,2).map(function(x){return x[0]||''}).join('').toUpperCase()}
function avatar(p,online){var box=node('div',{class:'msg-avatar'});if(p&&p.avatar_url)box.appendChild(node('img',{src:p.avatar_url,alt:''}));else box.appendChild(node('span',{text:initials(p)}));if(online)box.appendChild(node('i',{class:'online-indicator'}));return box}
function profileName(p){return p&&(p.full_name||p.username)||'Creator'}
function timeLabel(d){var x=new Date(d);return x.toLocaleTimeString([], {hour:'numeric',minute:'2-digit'})}
function ago(d){var n=Date.now()-new Date(d).getTime();if(n<60000)return'now';if(n<3600000)return Math.floor(n/60000)+'m';if(n<86400000)return Math.floor(n/3600000)+'h';return new Date(d).toLocaleDateString([], {month:'short',day:'numeric'})}
function online(id){return !!presence[id]}
function setStatus(t){$('online-count').textContent=t}
function showError(target,t){target.textContent=t||''}
function otherId(c){return c.user_a===user.id?c.user_b:c.user_a}
function uniqueProfiles(ids){return sb.from('profiles').select('id,full_name,username,avatar_url,bio,role').in('id',ids).then(function(r){if(r.error)throw r.error;(r.data||[]).forEach(function(p){profiles[p.id]=p});return r.data||[]})}
function presenceState(){var state=presenceChannel&&presenceChannel.presenceState?presenceChannel.presenceState():{};presence={};Object.keys(state||{}).forEach(function(k){var item=(state[k]||[])[0];if(item&&item.user_id)presence[item.user_id]=item});setStatus(Object.keys(presence).filter(function(id){return id!==user.id}).length+' creators online');renderConversations();if(active)renderChatHeader()}
function startPresence(){
 presenceChannel=sb.channel('cv:presence',{config:{private:true,presence:{key:user.id}}});
 presenceChannel.on('presence',{event:'sync'},presenceState).on('presence',{event:'join'},presenceState).on('presence',{event:'leave'},presenceState)
 .subscribe(function(status){if(status==='SUBSCRIBED'){presenceChannel.track({user_id:user.id,full_name:profileName(me),avatar_url:me.avatar_url||null,online_at:new Date().toISOString()});setStatus('You are online');}});
}
function loadConversations(){
 return sb.from('cv_conversations').select('*').or('user_a.eq.'+user.id+',user_b.eq.'+user.id).order('last_message_at',{ascending:false}).then(async function(r){
  if(r.error)throw r.error;conversations=r.data||[];
  var ids=conversations.map(otherId).filter(function(x){return x!==user.id});
  if(ids.length)await uniqueProfiles(Array.from(new Set(ids)));
  renderConversations();
  var cids=conversations.map(function(c){return c.id});
  if(cids.length){var mr=await sb.from('cv_direct_messages').select('conversation_id,body,sender_id,created_at').in('conversation_id',cids).order('created_at',{ascending:false}).limit(250);if(!mr.error){var last={};(mr.data||[]).forEach(function(m){if(!last[m.conversation_id])last[m.conversation_id]=m});conversations.forEach(function(c){c._last=last[c.id]||null});renderConversations();}}
 });
}
function renderConversations(){
 var box=$('conversation-list');box.textContent='';
 if(!conversations.length){box.appendChild(node('div',{class:'msg-loading',text:'No messages yet. Start a conversation with a creator.'}));return}
 conversations.forEach(function(c){
  var id=otherId(c),p=profiles[id]||{full_name:'Creator'},last=c._last,activeClass=active&&active.id===c.id;
  var b=node('button',{type:'button',class:'msg-conversation'+(activeClass?' active':'')});
  b.appendChild(avatar(p,online(id)));
  var copy=node('span',{class:'msg-conversation-copy'},[node('strong',{text:profileName(p)}),node('small',{text:last?(last.sender_id===user.id?'You: ':'')+last.body:'Start a conversation'})]);
  b.appendChild(copy);b.appendChild(node('time',{class:'msg-conversation-time',text:ago(last?last.created_at:c.last_message_at)}));
  b.addEventListener('click',function(){openConversation(c)});box.appendChild(b);
 });
}
function renderChatHeader(){
 if(!active)return;var id=otherId(active),p=profiles[id]||{full_name:'Creator'},box=$('chat-person');box.textContent='';
 box.appendChild(avatar(p,online(id)));box.appendChild(node('div',{},[node('strong',{text:profileName(p)}),node('small',{text:online(id)?'Online now':'Offline'})]));
}
function showChat(on){$('chat-empty').hidden=!!on;$('chat-active').hidden=!on}
function messageNode(m){
 var mine=m.sender_id===user.id,p=profiles[m.sender_id]||me,row=node('div',{class:'msg-bubble-row'+(mine?' mine':'')});
 var av=node('div',{class:'msg-bubble-avatar'});if(p&&p.avatar_url)av.appendChild(node('img',{src:p.avatar_url,alt:''}));
 var bubble=node('div',{class:'msg-bubble'},[node('div',{text:m.body}),node('time',{text:timeLabel(m.created_at)})]);
 row.appendChild(av);row.appendChild(bubble);return row;
}
function appendMessage(m){
 var thread=$('chat-thread');if(thread.querySelector('[data-message-id="'+m.id+'"]'))return;
 var n=messageNode(m);n.setAttribute('data-message-id',m.id);thread.appendChild(n);thread.scrollTop=thread.scrollHeight;
}
function openConversation(c){
 active=c;showChat(true);renderChatHeader();renderConversations();$('chat-thread').textContent='Loading messages…';
 if(messageChannel){sb.removeChannel(messageChannel);messageChannel=null}
 sb.from('cv_direct_messages').select('*').eq('conversation_id',c.id).order('created_at',{ascending:true}).limit(250).then(function(r){
  if(r.error){$('chat-thread').textContent='Messages could not be loaded. '+r.error.message;return}
  if(!active||active.id!==c.id)return;
  var thread=$('chat-thread');thread.textContent='';
  if(!(r.data||[]).length)thread.appendChild(node('div',{class:'msg-thread-empty',text:'This is the beginning of your conversation. Say hello.'}));
  (r.data||[]).forEach(appendMessage);
 });
 messageChannel=sb.channel('cv:messages:'+c.id);
 messageChannel.on('postgres_changes',{event:'INSERT',schema:'public',table:'cv_direct_messages',filter:'conversation_id=eq.'+c.id},function(payload){
  if(active&&active.id===c.id){var empty=$('chat-thread').querySelector('.msg-thread-empty');if(empty)empty.remove();appendMessage(payload.new)}
  var conv=conversations.find(function(x){return x.id===c.id});if(conv){conv._last=payload.new;conv.last_message_at=payload.new.created_at;conversations.sort(function(a,b){return new Date(b.last_message_at)-new Date(a.last_message_at)});renderConversations()}
 }).subscribe();
}
function startConversation(profile){
 if(!profile||profile.id===user.id)return;
 var ids=[user.id,profile.id].sort();
 sb.from('cv_conversations').select('*').eq('user_a',ids[0]).eq('user_b',ids[1]).maybeSingle().then(function(r){
  if(r.error)throw r.error;
  if(r.data)return r.data;
  return sb.from('cv_conversations').insert({user_a:ids[0],user_b:ids[1],created_by:user.id}).select('*').single().then(function(created){
   if(created.error&&created.error.code==='23505')return sb.from('cv_conversations').select('*').eq('user_a',ids[0]).eq('user_b',ids[1]).single();
   if(created.error)throw created.error;return created.data;
  });
 }).then(async function(c){if(!profiles[profile.id])profiles[profile.id]=profile;if(!conversations.some(function(x){return x.id===c.id})){conversations.unshift(c)}await loadConversations();openConversation(c)})
 .catch(function(e){alert(e.message||'Could not start this conversation. Check whether either person has blocked the other.')});
}
function searchPeople(term){
 var results=$('people-results');if(!term){results.hidden=true;return}
 sb.from('profiles').select('id,full_name,username,avatar_url,bio').or('full_name.ilike.%'+term+'%,username.ilike.%'+term+'%').neq('id',user.id).limit(20).then(function(r){
  results.hidden=false;results.textContent='';results.appendChild(node('div',{class:'msg-people-heading',text:'CREATORS'}));
  if(r.error){results.appendChild(node('div',{class:'msg-loading',text:'Search is temporarily unavailable.'}));return}
  var rows=(r.data||[]).filter(function(p){return !isBlocked(p.id)});
  if(!rows.length){results.appendChild(node('div',{class:'msg-loading',text:'No creators found.'}));return}
  rows.forEach(function(p){profiles[p.id]=p;var b=node('button',{type:'button',class:'msg-person-result'},[avatar(p,online(p.id)),node('span',{text:profileName(p)})]);b.addEventListener('click',function(){results.hidden=true;$('people-search').value='';startConversation(p)});results.appendChild(b)});
 });
}
function isBlocked(id){return false}
function renderStories(){
 var rail=$('story-rail');rail.textContent='';
 var mine=stories.filter(function(s){return s.user_id===user.id});
 var add=node('button',{type:'button',class:'msg-story-item is-own'},[
  node('span',{class:'msg-story-avatar'},[me.avatar_url?node('img',{src:me.avatar_url,alt:''}):node('span',{text:initials(me)}),node('i',{class:'msg-story-add',text:'+'})]),
  node('strong',{text:'Your story'})
 ]);
 add.addEventListener('click',function(){if(mine.length)openStoryGroup(user.id,0);else openStoryModal()});rail.appendChild(add);
 var grouped={};stories.filter(function(s){return s.user_id!==user.id}).forEach(function(s){if(!grouped[s.user_id])grouped[s.user_id]=[];grouped[s.user_id].push(s)});
 Object.keys(grouped).forEach(function(id){
  var p=profiles[id]||{full_name:'Creator'},b=node('button',{type:'button',class:'msg-story-item'},[
   node('span',{class:'msg-story-avatar'},[p.avatar_url?node('img',{src:p.avatar_url,alt:''}):node('span',{text:initials(p)})]),
   node('strong',{text:profileName(p)})
  ]);
  b.addEventListener('click',function(){openStoryGroup(id,0)});rail.appendChild(b);
 });
 if(!stories.length)rail.appendChild(node('div',{class:'msg-loading',text:'No stories yet. Share the first update.'}));
}
function loadStories(){
 return sb.from('cv_stories').select('*').gt('expires_at',new Date().toISOString()).order('created_at',{ascending:true}).then(async function(r){
  if(r.error)throw r.error;stories=r.data||[];
  var ids=Array.from(new Set(stories.map(function(s){return s.user_id}).filter(function(id){return !profiles[id]})));
  if(ids.length)await uniqueProfiles(ids);renderStories();
 });
}
function openStoryModal(){$('story-create-modal').classList.add('open');$('story-create-modal').setAttribute('aria-hidden','false')}
function closeModal(id){$(id).classList.remove('open');$(id).setAttribute('aria-hidden','true')}
function openStoryGroup(id,index){
 var list=stories.filter(function(s){return s.user_id===id});if(!list.length)return;
 var s=list[index%list.length],p=profiles[id]||me,content=$('story-viewer-content'),foot=$('story-viewer-foot');
 $('story-viewer-owner').textContent='';$('story-viewer-owner').appendChild(avatar(p,false));$('story-viewer-owner').appendChild(node('span',{text:profileName(p)+' · '+ago(s.created_at)}));
 content.textContent='';if(s.media_type==='image'&&s.media_url)content.appendChild(node('img',{src:s.media_url,alt:'Story'}));if(s.content)content.appendChild(node('p',{text:s.content}));
 content.style.background=s.media_type==='text'?storyBackground(s.background):'transparent';
 foot.textContent='';if(s.user_id===user.id){sb.from('cv_story_views').select('viewer_id',{count:'exact',head:true}).eq('story_id',s.id).then(function(r){foot.textContent=(r.count||0)+' views'});}else{
  sb.from('cv_story_views').upsert({story_id:s.id,viewer_id:user.id},{onConflict:'story_id,viewer_id'}).then(function(){});
  foot.textContent='Shared with the CreatorVerse community';
 }
 var viewer=$('story-viewer');viewer.classList.add('open');viewer.setAttribute('aria-hidden','false');
 var bar=viewer.querySelector('.msg-viewer-progress i');bar.style.transition='none';bar.style.width='0';requestAnimationFrame(function(){bar.style.transition='width 6s linear';bar.style.width='100%'});
 if(storyTimer)clearTimeout(storyTimer);storyTimer=setTimeout(function(){if(index+1<list.length)openStoryGroup(id,index+1);else closeModal('story-viewer')},6000);
}
function storyBackground(k){var map={aurora:'linear-gradient(135deg,#234c85,#674a9a)',sunset:'linear-gradient(135deg,#9c4c73,#e48b61)',ocean:'linear-gradient(135deg,#126c82,#344d91)',orchid:'linear-gradient(135deg,#7047a3,#b45b98)',midnight:'linear-gradient(135deg,#17234d,#3b427e)'};return map[k]||map.aurora}
function renderPreview(){var file=$('story-image').files[0],box=$('story-preview');box.textContent=$('story-content').value||'Your story preview will appear here.';box.style.background='linear-gradient(130deg,#172c5a,#4e367d)';if(file){var u=URL.createObjectURL(file);box.textContent='';box.appendChild(node('img',{src:u,alt:'Story preview',style:'max-width:100%;max-height:190px;object-fit:contain;border-radius:9px'}));}}
function createStory(e){
 e.preventDefault();var content=$('story-content').value.trim(),file=$('story-image').files[0],btn=$('story-publish'),err=$('story-error');
 err.textContent='';if(!content&&!file){err.textContent='Add a short update or choose a photo.';return}
 if(file&&(!/^image\/(jpeg|png|webp|gif)$/.test(file.type)||file.size>12*1024*1024)){err.textContent='Choose a JPG, PNG, WEBP or GIF image up to 12 MB.';return}
 btn.disabled=true;btn.textContent='Sharing…';
 var upload=Promise.resolve(null);
 if(file){var ext=(file.name.split('.').pop()||'jpg').toLowerCase(),path=user.id+'/stories/'+crypto.randomUUID()+'.'+ext;
  upload=sb.storage.from('community-media').upload(path,file,{cacheControl:'3600',upsert:false,contentType:file.type}).then(function(r){if(r.error)throw r.error;return sb.storage.from('community-media').getPublicUrl(path).data.publicUrl});
 }
 upload.then(function(url){return sb.from('cv_stories').insert({user_id:user.id,content:content,media_url:url,media_type:file?'image':'text',background:'aurora'}).select('*').single()})
 .then(async function(r){if(r.error)throw r.error;stories.push(r.data);if(!profiles[user.id])profiles[user.id]=me;renderStories();closeModal('story-create-modal');$('story-form').reset();renderPreview();})
 .catch(function(x){err.textContent=x.message||'Could not share your story.'})
 .finally(function(){btn.disabled=false;btn.textContent='Share story'});
}
function sendMessage(e){
 e.preventDefault();if(!active)return;var input=$('message-input'),body=input.value.trim();if(!body)return;
 var btn=$('message-send');btn.disabled=true;
 sb.from('cv_direct_messages').insert({conversation_id:active.id,sender_id:user.id,body:body}).select('*').single().then(function(r){
  if(r.error)throw r.error;input.value='';input.style.height='auto';var empty=$('chat-thread').querySelector('.msg-thread-empty');if(empty)empty.remove();appendMessage(r.data);
 }).catch(function(x){alert(x.message||'Message could not be sent.')}).finally(function(){btn.disabled=false;input.focus()});
}
function init(){
 sb=window.CV_SB;if(!sb){$('conversation-list').textContent='Could not connect to CreatorVerse. Refresh the page to try again.';return}
 sb.auth.getSession().then(async function(r){
  user=r.data&&r.data.session&&r.data.session.user;
  if(!user){location.href='login.html?next=messages.html';return}
  var pr=await sb.from('profiles').select('id,full_name,username,avatar_url,bio,role').eq('id',user.id).maybeSingle();
  if(pr.error)throw pr.error;me=pr.data||{id:user.id,full_name:user.user_metadata&&user.user_metadata.full_name||'Creator'};profiles[user.id]=me;
  startPresence();
  await Promise.all([loadConversations(),loadStories()]);
  sb.channel('cv:stories').on('postgres_changes',{event:'INSERT',schema:'public',table:'cv_stories'},function(p){if(p.new.expires_at>new Date().toISOString()){stories.push(p.new);if(!profiles[p.new.user_id])uniqueProfiles([p.new.user_id]).then(renderStories);else renderStories()}}).on('postgres_changes',{event:'DELETE',schema:'public',table:'cv_stories'},function(p){stories=stories.filter(function(s){return s.id!==p.old.id});renderStories()}).subscribe();
 }).catch(function(e){$('conversation-list').textContent='CreatorVerse Connect could not load: '+(e.message||'Please refresh.');});
}
$('new-message').addEventListener('click',function(){$('people-search').focus();$('people-search').placeholder='Type a creator name to start a chat…'});
$('empty-new-message').addEventListener('click',function(){$('people-search').focus()});
$('people-search').addEventListener('input',function(){var term=this.value.trim();if(searchTimer)clearTimeout(searchTimer);searchTimer=setTimeout(function(){searchPeople(term)},250)});
$('message-form').addEventListener('submit',sendMessage);
$('message-input').addEventListener('keydown',function(e){if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();$('message-form').requestSubmit()}});
$('message-input').addEventListener('input',function(){this.style.height='auto';this.style.height=Math.min(this.scrollHeight,125)+'px'});
$('story-create-open').addEventListener('click',openStoryModal);
$('story-form').addEventListener('submit',createStory);
$('story-content').addEventListener('input',renderPreview);$('story-image').addEventListener('change',renderPreview);
document.querySelectorAll('[data-close]').forEach(function(b){b.addEventListener('click',function(){if(storyTimer)clearTimeout(storyTimer);closeModal(b.dataset.close)})});
$('story-viewer').addEventListener('click',function(e){if(e.target===$('story-viewer')){if(storyTimer)clearTimeout(storyTimer);closeModal('story-viewer')}});
document.addEventListener('cv-ready',init,{once:true});
if(window.CV_SB)init();
window.addEventListener('beforeunload',function(){if(presenceChannel)sb.removeChannel(presenceChannel);if(messageChannel)sb.removeChannel(messageChannel)});
})();