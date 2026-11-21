(function(){
 if(window.__cvBillboardOverlayStarted)return;window.__cvBillboardOverlayStarted=true;
 var sb=null,shown=false,timer=null,poll=null,channel=null,root=null;
 function pageKey(){var p=(location.pathname.split('/').pop()||'index.html').toLowerCase();if(p==='index.html'||p==='')return 'landing';if(p==='community.html')return 'community';if(p==='profile.html')return 'profiles';if(/dashboard|admin/.test(p))return 'dashboards';if(/campus/.test(p))return 'campus';if(/learn|course|lesson|quiz|academic|exam|certificate/.test(p))return 'learning';if(/message|notification/.test(p))return 'messages';if(/marketplace/.test(p))return 'marketplace';return 'other'}
 function node(tag,cls,txt){var n=document.createElement(tag);if(cls)n.className=cls;if(txt)n.textContent=txt;return n}
 function roleFor(session){if(!session||!session.user)return Promise.resolve('');return sb.from('profiles').select('role').eq('id',session.user.id).maybeSingle().then(function(r){return r.data&&r.data.role||''}).catch(function(){return ''})}
 function audienceOk(x,role){var a=x.target_audience||'whole_platform';return a==='whole_platform'||a==='students'&&role==='student'||a==='creators'&&role==='creator'||a==='administrators'&&['admin','super_admin'].indexOf(role)>=0}
 function alreadyShown(id,page){try{return sessionStorage.getItem('cv-bb-overlay:'+id+':'+page)==='1'}catch(e){return false}}
 function markShown(id,page){try{sessionStorage.setItem('cv-bb-overlay:'+id+':'+page,'1')}catch(e){}}
 function remove(){if(timer)clearTimeout(timer);timer=null;shown=false;if(root){var oldRoot=root;oldRoot.classList.remove('cv-bb-overlay-visible');setTimeout(function(){if(oldRoot.parentNode)oldRoot.remove();if(root===oldRoot)root=null},260)}}
 function show(x){
  if(shown)return;shown=true;var page=pageKey();markShown(x.id,page);
  root=node('aside','cv-bb-overlay');root.dataset.itemId=x.id;root.setAttribute('role','dialog');root.setAttribute('aria-label','CreatorVerse announcement');
  var card=node('div','cv-bb-overlay-card');card.style.setProperty('--cv-bb-bg',x.background_color||'#071426');card.style.setProperty('--cv-bb-accent',x.accent_color||'#12a984');card.style.setProperty('--cv-bb-text',x.text_color||'#f2f7ff');
  var close=node('button','cv-bb-overlay-close','×');close.type='button';close.setAttribute('aria-label','Dismiss announcement');close.addEventListener('click',remove);
  if(x.media_url&&x.media_type==='image'){var img=node('img','cv-bb-overlay-media');img.src=x.media_url;img.alt=x.title||'Announcement';card.appendChild(img)}
  if(x.media_url&&x.media_type==='video'){var video=node('video','cv-bb-overlay-media');video.src=x.media_url;video.autoplay=true;video.muted=true;video.loop=true;video.playsInline=true;card.appendChild(video)}
  var copy=node('div','cv-bb-overlay-copy');if(x.kicker_text)copy.appendChild(node('span','cv-bb-overlay-kicker',x.kicker_text));
  copy.appendChild(node('strong','cv-bb-overlay-title',x.title||'CreatorVerse update'));if(x.message)copy.appendChild(node('p','cv-bb-overlay-message',x.message));
  if(x.button_label&&x.button_url){var a=node('a','cv-bb-overlay-action',x.button_label);a.href=x.button_url;if(/^https?:\/\//i.test(x.button_url)){a.target='_blank';a.rel='noopener noreferrer'}copy.appendChild(a)}
  card.appendChild(copy);card.appendChild(close);root.appendChild(card);document.body.appendChild(root);
  requestAnimationFrame(function(){if(root)root.classList.add('cv-bb-overlay-visible')});
  timer=setTimeout(remove,Math.max(3,Math.min(120,Number(x.overlay_duration_seconds)||8))*1000);
 }
 function refresh(){
  if(!sb)return Promise.resolve();
  return Promise.all([sb.auth.getSession(),sb.from('billboard_items').select('id,title,message,media_type,media_url,button_label,button_url,starts_at,ends_at,is_published,display_order,target_audience,background_color,accent_color,text_color,kicker_text,overlay_enabled,overlay_pages,overlay_duration_seconds').eq('is_published',true).eq('overlay_enabled',true).order('display_order',{ascending:true})]).then(function(results){
   var session=results[0].data&&results[0].data.session,rows=results[1].data||[],page=pageKey();return roleFor(session).then(function(role){
    var now=Date.now(),candidate=rows.find(function(x){var pages=x.overlay_pages||['all'];return audienceOk(x,role)&&(pages.indexOf('all')>=0||pages.indexOf(page)>=0)&&(!x.starts_at||new Date(x.starts_at).getTime()<=now)&&(!x.ends_at||new Date(x.ends_at).getTime()>now)&&!alreadyShown(x.id,page)});
    if(shown&&root&&!rows.some(function(x){return x.id===root.dataset.itemId&&x.is_published&&x.overlay_enabled&&audienceOk(x,role)&&(x.overlay_pages||['all']).some(function(k){return k==='all'||k===page})}))remove();
    if(candidate&&!shown)show(candidate);
   });
  }).catch(function(e){console.warn('CreatorVerse page billboard overlay unavailable:',e)});
 }
 function start(client){sb=client;window.CV_SB=window.CV_SB||sb;refresh();try{channel=sb.channel('cv-global-billboard-overlay').on('postgres_changes',{event:'*',schema:'public',table:'billboard_items'},refresh).subscribe()}catch(e){}poll=setInterval(refresh,30000)}
 function init(){var cfg=window.CV_CONFIG||{};if(window.CV_SB){start(window.CV_SB);return}if(!cfg.supabaseUrl||!cfg.supabaseAnonKey){setTimeout(init,400);return}
  function create(){try{start(window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey))}catch(e){console.warn(e)}}
  if(window.supabase&&window.supabase.createClient){create();return}
  var s=document.createElement('script');s.src='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js';s.onload=create;s.onerror=function(){console.warn('Billboard overlay could not load Supabase client')};document.head.appendChild(s)
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
})();
