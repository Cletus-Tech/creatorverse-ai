(function(){
var app=document.getElementById('profile-app');if(!app)return;
var sb=null,me=null,target=null,profile=null,posts=[],following=false,activeTab='posts',followerCount=0,followingCount=0,postCount=0;
function node(tag,attrs,children){
 var el=document.createElement(tag);
 Object.keys(attrs||{}).forEach(function(key){
  if(key==='text')el.textContent=attrs[key];
  else if(key==='class')el.className=attrs[key];
  else if(key==='checked')el.checked=!!attrs[key];
  else el.setAttribute(key,attrs[key]);
 });
 (children||[]).forEach(function(child){if(child)el.appendChild(child)});
 return el;
}
function initials(value){return String(value||'Creator').trim().split(/\s+/).slice(0,2).map(function(x){return x[0]||''}).join('').toUpperCase()}
function count(query){return query.then(function(result){if(result.error)throw result.error;return result.count||0})}
function safeUrl(value){var url=String(value||'').trim();if(!url)return '';try{var parsed=new URL(url);return ['http:','https:'].includes(parsed.protocol)?parsed.href:''}catch(_){return ''}}
function errorText(error){return error&&error.message?error.message:String(error||'Something went wrong.')}
function load(client){
 if(sb)return;sb=client;
 sb.auth.getSession().then(async function(sessionResult){
  me=sessionResult.data.session&&sessionResult.data.session.user;
  var key=new URLSearchParams(location.search).get('u');
  if(!key){if(!me){location.href='login.html';return}key=me.id}
  var query=sb.from('public_profiles').select('*');
  var profileResult=key.includes('-')&&key.length>30
    ?await query.eq('id',key).maybeSingle()
    :await query.eq('username',key).maybeSingle();
  if(profileResult.error)throw profileResult.error;
  profile=profileResult.data;
  if(me&&profile&&profile.id===me.id){
   var own=await sb.from('profiles').select('full_name,username,avatar_url,avatar_is_public,bio,cover_url,location,website_url,skills,status_text,verified_badge,created_at').eq('id',me.id).maybeSingle();
   if(own.error)throw own.error;
   if(own.data)profile=Object.assign({},profile,own.data);
  }
  if(!profile){app.innerHTML='<div class="profile-error">This creator profile could not be found.</div>';return}
  target=profile.id;
  var result=await Promise.all([
   sb.from('community_posts').select('*').eq('user_id',target).eq('status','published').order('created_at',{ascending:false}).limit(100),
   count(sb.from('community_follows').select('*',{count:'exact',head:true}).eq('following_id',target)),
   count(sb.from('community_follows').select('*',{count:'exact',head:true}).eq('follower_id',target)),
   count(sb.from('community_posts').select('*',{count:'exact',head:true}).eq('user_id',target).eq('status','published')),
   me&&me.id!==target?sb.from('community_follows').select('follower_id').eq('follower_id',me.id).eq('following_id',target).maybeSingle():Promise.resolve({data:null})
  ]);
  if(result[0].error)throw result[0].error;
  posts=result[0].data||[];followerCount=result[1];followingCount=result[2];postCount=result[3];following=!!result[4].data;
  render();
 }).catch(function(error){
  app.innerHTML='';
  app.appendChild(node('div',{class:'profile-error'},[
   node('h2',{text:'Profile could not be loaded'}),
   node('p',{text:errorText(error)}),
   node('button',{class:'primary',type:'button',text:'Try again'})
  ]));
  app.querySelector('button').onclick=function(){location.reload()};
 });
}
function render(){
 app.textContent='';
 var isMe=!!(me&&me.id===target);
 var cover=node('div',{class:'profile-cover'});
 var coverUrl=safeUrl(profile.cover_url);if(coverUrl)cover.style.backgroundImage='url("'+coverUrl.replace(/"/g,'')+'")';
 var coverShade=node('div',{class:'profile-cover-shade'});
 cover.appendChild(coverShade);
 var avatar=node('div',{class:'profile-avatar'});
 var avatarUrl=safeUrl(profile.avatar_url);
 if(avatarUrl)avatar.appendChild(node('img',{src:avatarUrl,alt:(profile.full_name||'Creator')+' profile photo'}));
 else avatar.textContent=initials(profile.full_name);
 var name=node('h1',{class:'profile-name',text:profile.full_name||'CreatorVerse member'});
 var badge=window.CV_BADGE_ICON&&window.CV_BADGE_ICON(profile);if(badge)name.appendChild(badge);
 var handle=node('div',{class:'profile-handle',text:'@'+(profile.username||'creator')});
 var identity=node('div',{class:'profile-identity'},[avatar,node('div',{class:'profile-identity-copy'},[name,handle])]);
 var buttons=node('div',{class:'profile-buttons'});
 if(isMe){
  buttons.append(node('button',{class:'primary',type:'button',text:'Edit profile',id:'edit-toggle'}));
 }else if(me){
  buttons.append(
   node('button',{class:'primary',type:'button',text:following?'Following':'＋ Follow',id:'follow-toggle'}),
   node('a',{class:'profile-message-button',href:'messages.html?to='+encodeURIComponent(target),text:'Message'})
  );
 }else{
  buttons.append(node('a',{class:'primary',href:'login.html?next='+encodeURIComponent('profile.html?u='+(profile.username||target)),text:'Log in to follow'}));
 }
 var head=node('section',{class:'profile-head'},[
  node('div',{class:'profile-head-row'},[identity,buttons]),
  profile.status_text?node('div',{class:'profile-status',text:profile.status_text}):null,
  profile.bio?node('p',{class:'profile-bio',text:profile.bio}):null,
  node('div',{class:'profile-meta'},[
   profile.location?node('span',{text:'⌖ '+profile.location}):null,
   safeUrl(profile.website_url)?node('a',{href:safeUrl(profile.website_url),target:'_blank',rel:'noopener noreferrer',text:'Website ↗'}):null,
   (profile.skills||[]).length?node('span',{text:'Skills · '+profile.skills.join(' · ')}):null
  ]),
  node('div',{class:'profile-stats'},[
   node('button',{class:'profile-stat',id:'followers-btn',type:'button'},[node('strong',{text:String(followerCount)}),document.createTextNode(' Followers')]),
   node('button',{class:'profile-stat',id:'following-btn',type:'button'},[node('strong',{text:String(followingCount)}),document.createTextNode(' Following')]),
   node('span',{class:'profile-stat'},[node('strong',{text:String(postCount)}),document.createTextNode(' Posts')])
  ])
 ]);
 var edit=buildEditForm(isMe);
 var list=node('div',{class:'profile-list',id:'profile-list','aria-live':'polite'});
 var content=node('section',{class:'profile-section'});
 content.appendChild(node('div',{class:'profile-section-heading'},[
  node('div',{},[node('span',{class:'profile-eyebrow',text:'CREATOR ACTIVITY'}),node('h2',{text:isMe?'Your profile':(profile.full_name||'Creator')+'’s profile'})])
 ]));
 var tabs=node('nav',{class:'profile-tabs','aria-label':'Profile sections'});
 [['posts','Posts'],['about','About'],['photos','Photos'],['videos','Videos']].forEach(function(item){
  var button=node('button',{type:'button','data-profile-tab':item[0],text:item[1]});
  if(activeTab===item[0])button.classList.add('active');
  tabs.appendChild(button);
 });
 var panel=node('div',{class:'profile-tab-panel',id:'profile-tab-panel'});
 content.append(tabs,panel);
 app.append(cover,head,edit,list,content);
 renderTab();
 tabs.addEventListener('click',function(event){
  var button=event.target.closest('button[data-profile-tab]');if(!button)return;
  activeTab=button.getAttribute('data-profile-tab');
  tabs.querySelectorAll('button').forEach(function(tab){tab.classList.toggle('active',tab===button)});
  renderTab();
 });
 if(isMe){
  document.getElementById('edit-toggle').onclick=function(){edit.classList.toggle('open');if(edit.classList.contains('open'))edit.scrollIntoView({behavior:'smooth',block:'center'})};
  edit.onsubmit=saveProfile;
 }else if(me){
  document.getElementById('follow-toggle').onclick=toggleFollow;
 }
 document.getElementById('followers-btn').onclick=function(){showList('followers')};
 document.getElementById('following-btn').onclick=function(){showList('following')};
}
function buildEditForm(isMe){
 var edit=node('form',{class:'profile-edit',id:'profile-edit'});
 if(!isMe)return edit;
 edit.appendChild(node('div',{class:'profile-edit-heading'},[
  node('h3',{text:'Edit your profile'}),
  node('p',{text:'Keep your public creator information current and easy to discover.'})
 ]));
 function field(label,name,value,type){
  var input=node(type==='textarea'?'textarea':'input',{name:name});
  if(type!=='textarea')input.value=value||'';
  else{input.value=value||'';input.rows=3}
  if(name==='website_url')input.type='url';
  if(name==='username')input.maxLength=30;
  var wrapper=node('label',{text:label},[input]);edit.appendChild(wrapper);
 }
 field('Display name','full_name',profile.full_name);
 field('Username','username',profile.username);
 field('Status','status_text',profile.status_text);
 field('Location','location',profile.location);
 field('Website URL','website_url',profile.website_url);
 field('Bio','bio',profile.bio,'textarea');
 field('Skills (comma separated)','skills',(profile.skills||[]).join(', '));
 field('Cover image URL (optional)','cover_url',profile.cover_url);
 edit.appendChild(node('label',{text:'Upload profile photo'},[node('input',{name:'avatar_file',type:'file',accept:'image/jpeg,image/png,image/webp'})]));
 edit.appendChild(node('label',{text:'Upload cover photo'},[node('input',{name:'cover_file',type:'file',accept:'image/jpeg,image/png,image/webp'})]));
 var avatarVisible=node('input',{name:'avatar_is_public',type:'checkbox',checked:!!profile.avatar_is_public});
 edit.appendChild(node('label',{class:'profile-visibility-option'},[avatarVisible,document.createTextNode('Make my profile photo visible to other members')]));
 var status=node('div',{class:'profile-edit-status','aria-live':'polite'});
 var actions=node('div',{class:'profile-edit-actions'},[
  node('button',{class:'profile-cancel',type:'button',text:'Cancel'}),
  node('button',{class:'primary',type:'submit',text:'Save changes'})
 ]);
 actions.children[0].onclick=function(){edit.classList.remove('open')};
 edit.append(status,actions);
 return edit;
}
async function uploadProfileImage(file,prefix){
 if(!file||!file.size)return null;
 if(!/^image\/(jpeg|png|webp)$/.test(file.type)||file.size>5*1024*1024)throw new Error('Choose a JPG, PNG or WEBP image up to 5 MB.');
 var extension=(file.name.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,'');
 var path=target+'/'+prefix+'_'+Date.now()+'.'+extension;
 var uploaded=await sb.storage.from('profile-avatars').upload(path,file,{upsert:false,contentType:file.type});
 if(uploaded.error)throw uploaded.error;
 return sb.storage.from('profile-avatars').getPublicUrl(path).data.publicUrl;
}
async function saveProfile(event){
 event.preventDefault();
 var form=event.currentTarget,status=form.querySelector('.profile-edit-status'),button=form.querySelector('button[type="submit"]');
 var data=new FormData(form),updates={};
 ['full_name','username','status_text','location','website_url','bio','cover_url'].forEach(function(key){
  updates[key]=String(data.get(key)||'').trim()||null;
 });
 updates.avatar_is_public=data.get('avatar_is_public')==='on';
 updates.skills=String(data.get('skills')||'').split(',').map(function(value){return value.trim()}).filter(Boolean);
 button.disabled=true;status.textContent='Saving your profile…';
 try{
  var avatar=await uploadProfileImage(data.get('avatar_file'),'avatar');
  var cover=await uploadProfileImage(data.get('cover_file'),'cover');
  if(avatar)updates.avatar_url=avatar;
  if(cover)updates.cover_url=cover;
  if(updates.website_url&&!safeUrl(updates.website_url))throw new Error('Enter a valid website URL beginning with https://');
  var result=await sb.from('profiles').update(updates).eq('id',target);
  if(result.error)throw result.error;
  status.textContent='Profile saved. Refreshing your public profile…';
  location.reload();
 }catch(error){
  status.textContent='Could not save your profile: '+errorText(error);
  button.disabled=false;
 }
}
async function toggleFollow(){
 var button=document.getElementById('follow-toggle');if(!button||!me)return;
 button.disabled=true;
 try{
  if(following){
   var removed=await sb.from('community_follows').delete().eq('follower_id',me.id).eq('following_id',target);
   if(removed.error)throw removed.error;
   following=false;followerCount=Math.max(0,followerCount-1);
  }else{
   var added=await sb.from('community_follows').insert({follower_id:me.id,following_id:target});
   if(added.error)throw added.error;
   following=true;followerCount+=1;
  }
  render();
 }catch(error){
  button.disabled=false;alert('Could not update your follow status: '+errorText(error));
 }
}
function renderTab(){
 var panel=document.getElementById('profile-tab-panel');if(!panel)return;
 panel.textContent='';
 if(activeTab==='about'){
  var facts=[
   ['About',profile.bio||'This creator has not added a bio yet.'],
   ['Location',profile.location||'Not shared'],
   ['Website',safeUrl(profile.website_url)||'Not shared'],
   ['Skills',(profile.skills||[]).length?profile.skills.join(' · '):'Not added yet'],
   ['Joined',profile.created_at?new Date(profile.created_at).toLocaleDateString(undefined,{month:'long',year:'numeric'}):'CreatorVerse member']
  ];
  panel.appendChild(node('div',{class:'profile-about-grid'},facts.map(function(item){
   return node('article',{class:'profile-about-card'},[node('span',{text:item[0]}),node('p',{text:item[1]})]);
  })));
  return;
 }
 var list=posts;
 if(activeTab==='photos')list=posts.filter(function(post){return !!post.image_url&&post.media_type!=='video'});
 if(activeTab==='videos')list=posts.filter(function(post){return !!post.image_url&&post.media_type==='video'});
 if(!list.length){
  panel.appendChild(node('div',{class:'profile-empty'},[
   node('h3',{text:activeTab==='photos'?'No photos yet':activeTab==='videos'?'No videos yet':'No public posts yet'}),
   node('p',{text:activeTab==='posts'?'When this creator shares an update, it will appear here.':'Media shared by this creator will appear here.'})
  ]));
  return;
 }
 var grid=node('div',{class:'profile-posts'});
 list.forEach(function(post){
  var href='community.html#post-'+encodeURIComponent(post.id);
  var card=node('a',{href:href,class:'profile-post'});
  if(post.image_url){
   if(post.media_type==='video')card.appendChild(node('div',{class:'profile-post-video'},[
    node('video',{src:post.image_url,muted:'muted',playsinline:'playsinline',preload:'metadata'}),
    node('span',{text:'▶ Video'})
   ]));
   else card.appendChild(node('img',{src:post.image_url,alt:post.title||'Creator post',loading:'lazy'}));
  }else card.appendChild(node('div',{class:'profile-post-text-art'},[node('span',{text:'CREATORVERSE'}),node('strong',{text:post.category||'Community post'})]));
  card.appendChild(node('div',{class:'profile-post-copy'},[
   node('h3',{text:post.title||'Community update'}),
   node('p',{text:post.description||''}),
   node('small',{text:(post.category||'Community')+' · '+(post.created_at?new Date(post.created_at).toLocaleDateString():'')})
  ]));
  grid.appendChild(card);
 });
 panel.appendChild(grid);
}
async function showList(which){
 var box=document.getElementById('profile-list');if(!box)return;
 box.classList.toggle('open');if(!box.classList.contains('open'))return;
 box.textContent='Loading '+which+'…';
 var column=which==='followers'?'follower_id':'following_id';
 var result=await sb.from('community_follows').select(column).eq(which==='followers'?'following_id':'follower_id',target);
 if(result.error){box.textContent='Could not load '+which+': '+result.error.message;return}
 var ids=(result.data||[]).map(function(row){return row[column]});
 if(!ids.length){box.textContent='No '+which+' yet.';return}
 var people=await sb.from('public_profiles').select('id,full_name,username,avatar_url,verified_badge').in('id',ids);
 if(people.error){box.textContent='Could not load creator profiles.';return}
 box.textContent='';
 (people.data||[]).forEach(function(person){
  var label=node('span',{text:person.full_name||'Creator'});
  var badge=window.CV_BADGE_ICON&&window.CV_BADGE_ICON(person);if(badge)label.appendChild(badge);
  var link=node('a',{href:'profile.html?u='+encodeURIComponent(person.username||person.id),class:'profile-list-person'},[
   person.avatar_url?node('img',{src:person.avatar_url,alt:''}):node('span',{class:'profile-list-avatar',text:initials(person.full_name)}),
   label
  ]);
  box.appendChild(link);
 });
}
function boot(){if(window.CV_SB)load(window.CV_SB)}
boot();document.addEventListener('cv-ready',boot);
})();