(function(){
var root=document.getElementById('community-app');if(!root)return;
var sb=null,user=null,role='',filter='all',sort='new',term='',posts=[],profiles={},creators=[],saved={},liked={},following=[],followed={},blocked={},commentsOpen={},$=function(id){return document.getElementById(id)};
function el(t,a,children){var n=document.createElement(t);Object.keys(a||{}).forEach(function(k){if(k==='text')n.textContent=a[k];else if(k==='class')n.className=a[k];else if(k==='style')n.setAttribute('style',a[k]);else n.setAttribute(k,a[k])});(children||[]).forEach(function(x){if(x)n.appendChild(x)});return n}
function msg(t,bad){$('community-msg').textContent=t||'';$('community-msg').className='community-msg'+(bad?' error':'')}
function modal(on){$('post-modal').classList.toggle('open',!!on);document.body.style.overflow=on?'hidden':''}
function initials(p){return((p&&p.full_name)||'Creator').trim().split(/\s+/).slice(0,2).map(function(x){return x[0]||''}).join('').toUpperCase()}
function avatar(p){return p&&p.avatar_url?el('img',{src:p.avatar_url,alt:''}):el('span',{text:initials(p)})}
function load(){
 if(!sb){$('community-feed').textContent='Connecting to CreatorVerse…';return}
 $('community-feed').textContent='Loading the community…';
 sb.auth.getSession().then(async function(sessionResult){
  user=sessionResult.data&&sessionResult.data.session&&sessionResult.data.session.user||null;
  var postResult=await sb.from('community_posts').select('*').eq('status','published').order('created_at',{ascending:false}).limit(100);
  if(postResult.error)throw postResult.error;
  posts=postResult.data||[];
  // Render the public feed immediately; optional social data must never hold posts behind a spinner.
  posts.forEach(function(p){p._likes=0});
  draw();
  var ids=Array.from(new Set(posts.map(function(p){return p.user_id})));
  if(user)ids.push(user.id);
  var jobs=[
   ids.length?sb.from('profiles').select('id,full_name,avatar_url,username,bio,cover_url,location,website_url,skills,status_text').in('id',ids):Promise.resolve({data:[]}),
   user?sb.from('community_likes').select('post_id').eq('user_id',user.id):Promise.resolve({data:[]}),
   user?sb.from('community_saves').select('post_id').eq('user_id',user.id):Promise.resolve({data:[]}),
   user?sb.from('profiles').select('role').eq('id',user.id).maybeSingle():Promise.resolve({data:null}),
   user?sb.from('community_follows').select('following_id').eq('follower_id',user.id):Promise.resolve({data:[]}),
   posts.length?sb.from('community_likes').select('post_id').in('post_id',posts.map(function(p){return p.id})):Promise.resolve({data:[]}),
   sb.from('profiles').select('id,full_name,avatar_url,username,bio,skills,status_text').order('created_at',{ascending:false}).limit(40)
  ];
  var results=await Promise.all(jobs);
  results.forEach(function(result,index){if(result&&result.error)console.warn('Community optional query '+index+':',result.error.message)});
  (results[0].data||[]).forEach(function(p){profiles[p.id]=p});
  (results[1].data||[]).forEach(function(v){liked[v.post_id]=1});
  (results[2].data||[]).forEach(function(v){saved[v.post_id]=1});
  role=results[3].data&&results[3].data.role||'';
  if(user){
   var br=await sb.from('community_blocks').select('blocked_id').eq('blocker_id',user.id);
   if(br.error)console.warn('Blocked creators could not be loaded:',br.error.message);
   (br.data||[]).forEach(function(v){blocked[v.blocked_id]=1});
  }
  (results[4].data||[]).forEach(function(v){followed[v.following_id]=1;following.push(v.following_id)});
  var counts={};(results[5].data||[]).forEach(function(v){counts[v.post_id]=(counts[v.post_id]||0)+1});
  posts.forEach(function(p){p._likes=counts[p.id]||0});
  creators=(results[6].data||[]).filter(function(p){return !user||p.id!==user.id});
  creators.forEach(function(p){profiles[p.id]=p});
  renderCreators();draw();
 }).catch(function(e){
  console.error('CreatorVerse community load failed:',e);
  $('community-feed').textContent='Could not load the community: '+(e&&e.message||'Please refresh and try again.');
 });
}
function notifyPanel(){var old=$('community-notifications');if(old){old.remove();return}if(!user)return;var panel=el('div',{id:'community-notifications',class:'community-notifications'});panel.textContent='Loading notifications…';$('community-app').insertBefore(panel,$('community-app').children[1]);sb.from('community_notifications').select('id,type,message,is_read,created_at,actor_id,post_id').order('created_at',{ascending:false}).limit(25).then(async function(r){panel.textContent='';if(r.error){panel.textContent='Notifications unavailable: '+r.error.message;return}var rows=r.data||[];var ids=Array.from(new Set(rows.map(function(x){return x.actor_id}).filter(Boolean)));var ps=ids.length?await sb.from('profiles').select('id,full_name,username,avatar_url').in('id',ids):{data:[]};var map={};(ps.data||[]).forEach(function(p){map[p.id]=p});if(!rows.length){panel.textContent='You are all caught up.';return}rows.forEach(function(n){var who=map[n.actor_id];var row=el('button',{class:'notification-row'+(n.is_read?'':' unread')});row.append(el('strong',{text:(who&&who.full_name||'Someone')+' '+n.message}),el('small',{text:new Date(n.created_at).toLocaleString()}));row.onclick=function(){sb.from('community_notifications').update({is_read:true}).eq('id',n.id).then(function(){row.classList.remove('unread')});if(n.post_id){var card=document.querySelector('[data-post-id="'+n.post_id+'"]');if(card)card.scrollIntoView({behavior:'smooth',block:'center'})}};panel.append(row)})})}
async function reportTarget(kind,id){if(!user)return location.href='login.html';var reason=prompt('Why are you reporting this '+kind+'? (Spam, harassment, harmful content, impersonation, other)');if(!reason)return;var payload={reporter_id:user.id,reason:reason.slice(0,80),details:''};payload[kind==='post'?'post_id':'comment_id']=id;var r=await sb.from('community_reports').insert(payload);if(r.error)return msg(r.error.message,true);msg('Report submitted for moderator review.')}
async function toggleBlock(id,name){if(!user)return location.href='login.html';var was=!!blocked[id];if(!confirm((was?'Unblock ':'Block ')+(name||'this creator')+'? '+(was?'Their content will appear again.':'Their posts will be hidden from your feed.')))return;var r=was?await sb.from('community_blocks').delete().eq('blocker_id',user.id).eq('blocked_id',id):await sb.from('community_blocks').insert({blocker_id:user.id,blocked_id:id});if(r.error)return msg(r.error.message,true);if(was)delete blocked[id];else blocked[id]=1;msg(was?'Creator unblocked.':'Creator blocked.');draw();renderCreators()}
async function blockedPanel(){
 var old=$('community-blocked-panel');if(old){old.remove();return}
 if(!user)return location.href='login.html';
 var panel=el('section',{id:'community-blocked-panel',class:'community-notifications'});
 panel.textContent='Loading blocked creators…';
 $('community-app').insertBefore(panel,$('community-app').children[1]);
 var r=await sb.from('community_blocks').select('blocked_id,created_at').eq('blocker_id',user.id).order('created_at',{ascending:false});
 if(r.error){panel.textContent='Could not load blocked creators: '+r.error.message;return}
 var ids=(r.data||[]).map(function(x){return x.blocked_id});
 if(!ids.length){panel.textContent='You have not blocked any creators.';return}
 var p=await sb.from('profiles').select('id,full_name,username,avatar_url').in('id',ids);
 if(p.error){panel.textContent='Could not load creator profiles: '+p.error.message;return}
 panel.textContent='';
 (p.data||[]).forEach(function(person){
  var row=el('div',{class:'blocked-creator-row'});
  var link=el('a',{href:'profile.html?u='+encodeURIComponent(person.username||person.id),text:person.full_name||'CreatorVerse member'});
  var unblock=el('button',{class:'creator-discovery-follow',text:'Unblock'});
  unblock.onclick=async function(){unblock.disabled=true;var z=await sb.from('community_blocks').delete().eq('blocker_id',user.id).eq('blocked_id',person.id);if(z.error){unblock.disabled=false;msg(z.error.message,true);return}delete blocked[person.id];row.remove();renderCreators();draw();msg('Creator unblocked.');if(!panel.querySelector('.blocked-creator-row'))panel.textContent='You have not blocked any creators.'};
  row.append(link,unblock);panel.append(row);
 });
}
async function loadModeration(){var panel=$('community-moderation');if(!panel)return;panel.hidden=false;panel.textContent='Loading reports…';var r=await sb.from('community_reports').select('*').order('created_at',{ascending:false}).limit(100);panel.textContent='';if(r.error){panel.textContent='Could not load reports: '+r.error.message;return}if(!r.data.length){panel.textContent='No reports awaiting review.';return}r.data.forEach(function(report){var row=el('div',{class:'moderation-row'});row.append(el('div',{class:'moderation-copy'},[el('strong',{text:report.post_id?'Reported post':'Reported comment'}),el('small',{text:report.reason+' · '+new Date(report.created_at).toLocaleString()}),el('code',{text:report.post_id||report.comment_id})]));var select=el('select',{'aria-label':'Report status'});['open','reviewing','resolved','dismissed'].forEach(function(s){select.append(el('option',{value:s,text:s.charAt(0).toUpperCase()+s.slice(1)}))});select.value=report.status;select.onchange=async function(){var z=await sb.from('community_reports').update({status:select.value}).eq('id',report.id);if(z.error){msg(z.error.message,true);select.value=report.status}else{report.status=select.value;msg('Report status updated.')}};row.append(select);panel.append(row)})}
function renderCreators(){var box=$('creator-discovery-list');if(!box)return;box.textContent='';if(!creators.length){box.textContent='Creator profiles will appear here.';return}creators.filter(function(p){return !blocked[p.id]}).slice(0,12).forEach(function(p){var a=el('a',{class:'creator-discovery-item',href:'profile.html?u='+encodeURIComponent(p.username||p.id)});a.appendChild(el('span',{class:'creator-discovery-avatar'},[avatar(p)]));var meta=el('span',{class:'creator-discovery-meta'},[el('strong',{text:p.full_name||'CreatorVerse member'}),el('small',{text:p.username?'@'+p.username:(p.skills||[]).slice(0,2).join(' · ')||'Creator'})]);a.appendChild(meta);if(user&&user.id!==p.id){var b=el('button',{class:'creator-discovery-follow',text:followed[p.id]?'Following':'Follow'});b.onclick=function(e){e.preventDefault();e.stopPropagation();var was=!!followed[p.id],q=was?sb.from('community_follows').delete().eq('follower_id',user.id).eq('following_id',p.id):sb.from('community_follows').insert({follower_id:user.id,following_id:p.id});q.then(function(r){if(r.error)return msg(r.error.message,true);if(was){delete followed[p.id];following=following.filter(function(id){return id!==p.id})}else{followed[p.id]=1;following.push(p.id)}renderCreators();draw()})};a.appendChild(b)}if(user&&user.id!==p.id){var bl=el('button',{class:'creator-discovery-follow',text:blocked[p.id]?'Unblock':'Block'});bl.onclick=function(e){e.preventDefault();e.stopPropagation();toggleBlock(p.id,p.full_name)};a.appendChild(bl)}box.appendChild(a)})}
function draw(){
 var list=posts.filter(function(p){var text=(p.title+' '+p.description+' '+p.category+' '+(p.tags||[]).join(' ')+' '+((profiles[p.user_id]||{}).full_name||'')).toLowerCase();return(!blocked[p.user_id])&&(!term||text.indexOf(term)>-1)&&(filter!=='saved'||saved[p.id])&&(filter!=='following'||following.indexOf(p.user_id)>-1)});
 if(sort==='popular')list.sort(function(a,b){return (b._likes||0)-(a._likes||0)});else list.sort(function(a,b){return new Date(b.created_at)-new Date(a.created_at)});
 var feed=$('community-feed');feed.textContent='';if(!list.length){feed.appendChild(el('div',{class:'feed-empty'},[el('div',{class:'empty-orb',text:'✦'}),el('h3',{text:filter==='saved'?'No saved creations yet':filter==='following'?'Your following feed is ready':'The community is waiting for its first showcase'}),el('p',{text:'Be among the first to share a project, a design, an experiment or a learning milestone.'}),el('button',{class:'btn btn-primary',text:'Share your work',id:'empty-create'})]));var b=feed.querySelector('#empty-create');if(b)b.onclick=function(){user?modal(true):location.href='login.html'};return}
 list.forEach(function(p){feed.appendChild(card(p))})
}
function card(p){
 var profile=profiles[p.user_id]||{},likedByMe=!!liked[p.id],savedByMe=!!saved[p.id],isOwner=user&&user.id===p.user_id,isAdmin=role==='admin'||role==='super_admin';
 var art=el('img',{class:'pin-image',src:p.image_url,alt:p.title,loading:'lazy'});art.onerror=function(){art.style.display='none'};
 var followBtn=null;if(user&&user.id!==p.user_id){followBtn=el('button',{class:'pin-follow'+(followed[p.user_id]?' active':''),text:followed[p.user_id]?'Following':'+ Follow'});followBtn.onclick=function(){var req=followed[p.user_id]?sb.from('community_follows').delete().eq('follower_id',user.id).eq('following_id',p.user_id):sb.from('community_follows').insert({follower_id:user.id,following_id:p.user_id});req.then(function(z){if(z.error)return msg(z.error.message,true);if(followed[p.user_id]){delete followed[p.user_id];following=following.filter(function(x){return x!==p.user_id})}else{followed[p.user_id]=1;following.push(p.user_id)}draw()})}}
 var author=el('div',{class:'pin-author'},[el('a',{class:'pin-avatar',href:'profile.html?u='+encodeURIComponent(profile.username||p.user_id)},[avatar(profile)]),el('div',{class:'pin-author-meta'},[el('a',{href:'profile.html?u='+encodeURIComponent(profile.username||p.user_id),text:profile.full_name||'CreatorVerse member'}),el('span',{text:new Date(p.created_at).toLocaleDateString()})]),followBtn]);
 var actions=el('div',{class:'pin-actions'},[el('button',{class:'pin-action'+(likedByMe?' active':''),text:(likedByMe?'♥':'♡')+' '+(p._likes||''),title:'Like this creation'}),el('button',{class:'pin-action'+(savedByMe?' active':''),text:savedByMe?'Saved':'Save',title:'Save this creation'}),el('button',{class:'pin-action',text:'Comment'})]);
 actions.children[0].onclick=function(){if(!user)return location.href='login.html';var call=likedByMe?sb.from('community_likes').delete().eq('post_id',p.id).eq('user_id',user.id):sb.from('community_likes').insert({post_id:p.id,user_id:user.id});call.then(function(r){if(r.error)return msg(r.error.message,true);liked[p.id]=likedByMe?0:1;draw()})};
 actions.children[1].onclick=function(){if(!user)return location.href='login.html';var call=savedByMe?sb.from('community_saves').delete().eq('post_id',p.id).eq('user_id',user.id):sb.from('community_saves').insert({post_id:p.id,user_id:user.id});call.then(function(r){if(r.error)return msg(r.error.message,true);saved[p.id]=savedByMe?0:1;draw()})};
 var comments=el('div',{class:'pin-comments'});actions.children[2].onclick=function(){comments.classList.toggle('open');if(comments.classList.contains('open'))loadComments(p.id,comments)};
 var footer=el('div',{class:'pin-footer'},[author,el('h3',{text:p.title}),p.description?el('p',{class:'pin-description',text:p.description}):null,el('span',{class:'pin-category',text:p.category}),p.destination_url?el('a',{class:'pin-link',href:p.destination_url,target:'_blank',rel:'noopener',text:'View project ↗'}):null,actions,comments]);
 var box=el('article',{class:'pin-card','data-post-id':p.id},[el('div',{class:'pin-art-wrap'},[art]),footer]);
 if(isOwner||isAdmin){var menu=el('div',{class:'pin-menu'}),hide=el('button',{text:'Hide post'}),del=el('button',{text:'Delete post'});hide.onclick=function(){sb.from('community_posts').update({status:'hidden'}).eq('id',p.id).then(function(r){if(r.error)return msg(r.error.message,true);posts=posts.filter(function(x){return x.id!==p.id});draw()})};del.onclick=function(){if(!confirm('Permanently delete this post and its comments?'))return;sb.from('community_posts').delete().eq('id',p.id).then(function(r){if(r.error)return msg(r.error.message,true);posts=posts.filter(function(x){return x.id!==p.id});draw()})};menu.append(hide,del);footer.insertBefore(menu,footer.children[0])}
 if(!isOwner&&user){var blockPost=el('button',{class:'comment-tool',text:blocked[p.user_id]?'Unblock creator':'Block creator'});blockPost.onclick=function(){toggleBlock(p.user_id,profile.full_name)};footer.append(blockPost);var reportPost=el('button',{class:'comment-tool',text:'Report post'});reportPost.onclick=function(){reportTarget('post',p.id)};footer.append(reportPost)}
 return box
}
function loadComments(id,box){box.textContent='Loading comments…';sb.from('community_comments').select('*').eq('post_id',id).order('created_at',{ascending:true}).then(async function(r){box.textContent='';if(r.error){box.textContent=r.error.message;return}var list=r.data||[],ids=Array.from(new Set(list.map(function(c){return c.user_id})));var ps=ids.length?await sb.from('profiles').select('id,full_name,username,avatar_url').in('id',ids):{data:[]};(ps.data||[]).forEach(function(p){profiles[p.id]=p});var roots=list.filter(function(c){return !c.parent_id}),children={};list.filter(function(c){return c.parent_id}).forEach(function(c){(children[c.parent_id]||(children[c.parent_id]=[])).push(c)});function drawComment(c,depth){var p=profiles[c.user_id]||{},row=el('div',{class:'comment-row'+(depth?' comment-reply':'')});row.append(el('strong',{text:p.full_name||'Creator'}),el('p',{text:c.body}));if(user){var reply=el('button',{class:'comment-tool',text:'Reply'});reply.onclick=function(){var form=el('form',{class:'comment-form'}),input=el('input',{placeholder:'Write a reply…',maxlength:'1000',required:''});form.append(input,el('button',{class:'btn btn-primary',text:'Send'}));form.onsubmit=function(e){e.preventDefault();sb.from('community_comments').insert({post_id:id,parent_id:c.id,user_id:user.id,body:input.value.trim()}).then(function(x){if(x.error)return msg(x.error.message,true);loadComments(id,box)})};row.append(form)};if(c.user_id!==user.id){var report=el('button',{class:'comment-tool',text:'Report'});report.onclick=function(){reportTarget('comment',c.id)};row.append(report)}}box.append(row);(children[c.id]||[]).forEach(function(ch){drawComment(ch,depth+1)})}roots.forEach(function(c){drawComment(c,0)});if(user){var f=el('form',{class:'comment-form'}),i=el('input',{name:'body',placeholder:'Add a thoughtful comment…',maxlength:'1000',required:''});f.append(i,el('button',{class:'btn btn-primary',text:'Send'}));f.onsubmit=function(e){e.preventDefault();sb.from('community_comments').insert({post_id:id,user_id:user.id,body:i.value.trim()}).then(function(x){if(x.error)return msg(x.error.message,true);loadComments(id,box)})};box.append(f)}else box.append(el('a',{href:'login.html',text:'Log in to comment'}))})}
async function openComposer(){
 // The page can render before Supabase finishes initializing. Resolve the client/session
 // on demand so the primary Create Post action never silently redirects or does nothing.
 if(!sb&&window.CV_SB)sb=window.CV_SB;
 var attempts=0;
 while(!sb&&attempts<24){await new Promise(function(resolve){setTimeout(resolve,500)});if(window.CV_SB)sb=window.CV_SB;attempts++}
 if(!sb){msg('Community is still connecting. Please try again in a moment.',true);return}
 try{
  var sessionResult=await sb.auth.getSession();
  user=sessionResult.data&&sessionResult.data.session&&sessionResult.data.session.user||null;
  if(!user){location.href='login.html';return}
  modal(true);
 }catch(e){msg('Could not verify your account: '+(e.message||'Please refresh and try again.'),true)}
}
var nb=el('button',{class:'btn btn-outline',id:'community-notify-toggle',text:'Notifications'});document.querySelector('.community-actions').append(nb);nb.onclick=notifyPanel;var bb=el('button',{class:'btn btn-outline',id:'community-blocked-toggle',text:'Blocked creators'});document.querySelector('.community-actions').append(bb);bb.onclick=blockedPanel;var mp=el('section',{id:'community-moderation',class:'community-moderation',hidden:'hidden'});document.querySelector('.community-main').insertBefore(mp,document.querySelector('.community-main').firstChild);var openPostButton=$('open-post'),sideCreate=$('side-create'),closePost=$('close-post'),cancelPost=$('cancel-post');
if(openPostButton)openPostButton.addEventListener('click',function(e){e.preventDefault();openComposer()});
if(sideCreate)sideCreate.addEventListener('click',function(e){e.preventDefault();openComposer()});
if(closePost)closePost.addEventListener('click',function(e){e.preventDefault();modal(false)});
if(cancelPost)cancelPost.addEventListener('click',function(e){e.preventDefault();modal(false)});

$('community-search').oninput=function(){term=this.value.toLowerCase().trim();draw()};
$('feed-sort').onchange=function(){sort=this.value;draw()};
$('community-tabs').addEventListener('click',function(e){var b=e.target.closest('button[data-filter]');if(!b)return;filter=b.dataset.filter;this.querySelectorAll('button').forEach(function(x){x.classList.toggle('active',x===b)});$('feed-caption').textContent=filter==='saved'?'Your saved inspiration':filter==='following'?'Creations from creators you follow':'Fresh ideas from the CreatorVerse community';draw()});
var file=$('post-form').elements.image,preview=$('upload-preview');file.onchange=function(){preview.textContent='';var f=file.files[0];if(f){if(f.size>12*1024*1024){file.value='';preview.textContent='Image must be 12 MB or smaller.';return}var im=el('img',{alt:'Image preview'});im.src=URL.createObjectURL(f);preview.appendChild(im)}};
$('post-form').onsubmit=function(e){e.preventDefault();if(!user)return location.href='login.html';var form=e.currentTarget,d=new FormData(form),f=d.get('image'),btn=$('publish-post');if(!f||!f.size)return;$('post-msg').textContent='Uploading your image…';btn.disabled=true;
 var ext=(f.name.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,'');var path=user.id+'/'+Date.now()+'-'+Math.random().toString(36).slice(2,8)+'.'+ext;
 sb.storage.from('community-media').upload(path,f,{upsert:false,contentType:f.type}).then(function(up){if(up.error)throw up.error;var url=sb.storage.from('community-media').getPublicUrl(path).data.publicUrl;return sb.from('community_posts').insert({user_id:user.id,title:String(d.get('title')).trim(),description:String(d.get('description')||'').trim(),category:d.get('category'),destination_url:String(d.get('destination_url')||'').trim()||null,image_url:url}).select().single()}).then(function(r){if(r.error)throw r.error;posts.unshift(r.data);profiles[user.id]=profiles[user.id]||{full_name:user.user_metadata&&user.user_metadata.full_name||'Creator',id:user.id};modal(false);form.reset();preview.textContent='Your image preview will appear here.';msg('Your creation has been published.');draw()}).catch(function(err){$('post-msg').textContent=err.message||'Could not publish this post.'}).finally(function(){btn.disabled=false})};
function boot(client){if(sb)return;sb=client;load();sb.auth.getSession().then(function(r){var u=r.data.session&&r.data.session.user;if(!u)return;sb.from('profiles').select('role').eq('id',u.id).maybeSingle().then(function(x){if(x.data&&['admin','super_admin'].indexOf(x.data.role)>-1){var h=el('div',{class:'moderation-heading'},[el('h3',{text:'Community moderation'}),el('button',{class:'btn btn-outline',text:'Refresh reports'})]);h.children[1].onclick=loadModeration;mp.append(h);loadModeration()}})})}
if(window.CV_SB)boot(window.CV_SB);
document.addEventListener('cv-ready',function(){if(window.CV_SB)boot(window.CV_SB)});
/* Community must not depend solely on auth.js successfully loading its CDN script. */
setTimeout(function(){
 if(sb||window.CV_SB)return;
 var cfg=window.CV_CONFIG||{};
 if(!cfg.supabaseUrl||!cfg.supabaseAnonKey){$('community-feed').textContent='Community connection is not configured. Please contact the site administrator.';return}
 $('community-feed').textContent='Connecting to the community service…';
 var sources=[
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js',
  'https://unpkg.com/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js'
 ],index=0;
 function trySdk(){
  if(window.supabase&&window.supabase.createClient){try{boot(window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey))}catch(e){$('community-feed').textContent='Community could not initialize: '+e.message}return}
  if(index>=sources.length){$('community-feed').textContent='Could not connect to the community service. Check your internet connection and refresh.';return}
  var script=document.createElement('script'),done=false,timer=setTimeout(function(){if(done)return;done=true;script.remove();index++;trySdk()},9000);
  script.src=sources[index];script.onload=function(){if(done)return;done=true;clearTimeout(timer);if(window.supabase&&window.supabase.createClient)trySdk();else{index++;trySdk()}};
  script.onerror=function(){if(done)return;done=true;clearTimeout(timer);index++;trySdk()};
  document.head.appendChild(script);
 }
 trySdk();
},7000);
})();