(function(){
var host=document.getElementById('cv-billboard');if(!host)return;
var sb=window.CV_SB||null,items=[],index=0,timer=null,poll=null,channel=null,loading=false,countdownTimer=null,typeTimer=null;
function node(tag,cls,text){var n=document.createElement(tag);if(cls)n.className=cls;if(text)n.textContent=text;return n}
function active(){var now=Date.now();return items.filter(function(x){return x.is_published&&(!x.starts_at||new Date(x.starts_at).getTime()<=now)&&(!x.ends_at||new Date(x.ends_at).getTime()>now)})}
function scheduleUpcoming(){clearTimeout(timer);var upcoming=items.filter(function(x){return x.is_published&&x.starts_at&&new Date(x.starts_at).getTime()>Date.now()}).sort(function(a,b){return new Date(a.starts_at)-new Date(b.starts_at)})[0];if(upcoming)timer=setTimeout(draw,Math.max(1000,new Date(upcoming.starts_at).getTime()-Date.now()+250))}
function draw(){
 var a=active();if(!a.length){host.hidden=true;clearTimeout(timer);scheduleUpcoming();return}
 host.hidden=false;if(index>=a.length)index=0;var x=a[index];host.style.setProperty('--bb-background',x.background_color||'#071426');host.style.setProperty('--bb-accent',x.accent_color||'#12a984');host.style.setProperty('--bb-button',x.button_color||'#247be9');host.style.setProperty('--bb-end',x.background_end_color||'#15214a');host.style.setProperty('--bb-text',x.text_color||'#f2f7ff');host.style.setProperty('--bb-overlay',String(Math.max(0,Math.min(.95,Number(x.overlay_opacity)||.58))));host.dataset.transition=x.transition_effect||'slide';host.textContent='';clearInterval(countdownTimer);clearInterval(typeTimer);host.classList.remove('bb-enter');void host.offsetWidth;host.classList.add('bb-enter');
 var inner=node('div','bb-display-inner'),copy=node('div','bb-copy');copy.appendChild(node('span','bb-live-tag',x.kicker_text||'CREATORVERSE · PRE-UNIVERSITY'));var headline=node('h2','bb-title',x.title);copy.appendChild(headline);if(x.title_animation==='typewriter'){var chars=Array.from(x.title||''),pos=0;headline.textContent='';typeTimer=setInterval(function(){if(pos>=chars.length){clearInterval(typeTimer);return}headline.textContent+=chars[pos++];},34)}else if(x.title_animation==='fade'||x.title_animation==='rise'){headline.classList.add('bb-title-'+x.title_animation)}if(x.message)copy.appendChild(node('p','',x.message));if(x.media_type==='countdown'){var cd=node('div','bb-countdown'),label=node('div','bb-countdown-label','TIME REMAINING'),units=node('div','bb-countdown-units'),target=new Date(x.countdown_target_at).getTime(),parts={};[['days','DAYS'],['hours','HOURS'],['minutes','MINUTES'],['seconds','SECONDS'],['milliseconds','MS']].forEach(function(u){var unit=node('div','bb-countdown-unit'),num=node('strong','',u[0]==='milliseconds'?'000':'00');unit.appendChild(num);unit.appendChild(node('span','',u[1]));units.appendChild(unit);parts[u[0]]=num});cd.appendChild(label);cd.appendChild(units);copy.appendChild(cd);function tick(){var diff=Math.max(0,target-Date.now());if(!isFinite(target)){diff=0}var vals={days:Math.floor(diff/86400000),hours:Math.floor(diff%86400000/3600000),minutes:Math.floor(diff%3600000/60000),seconds:Math.floor(diff%60000/1000),milliseconds:Math.floor(diff%1000)};Object.keys(parts).forEach(function(k){parts[k].textContent=k==='days'?String(vals[k]):String(vals[k]).padStart(k==='milliseconds'?3:2,'0')});if(diff<=0){clearInterval(countdownTimer);label.textContent=x.countdown_complete_label||'EVENT STARTED';units.hidden=true}}tick();countdownTimer=setInterval(tick,37)}
 if(x.button_label&&x.button_url){var cta=node('a','bb-cta',x.button_label);cta.href=x.button_url;if(/^https?:\/\//i.test(x.button_url)){cta.target='_blank';cta.rel='noopener noreferrer'}copy.appendChild(cta)}
 inner.appendChild(copy);
 if(x.media_url&&x.media_type==='image'){var img=node('img','bb-media');img.src=x.media_url;img.alt=x.title;img.loading='eager';img.style.objectFit=x.media_fit==='contain'?'contain':'cover';img.onerror=function(){img.remove()};inner.insertBefore(img,copy)}
 var video=null;if(x.media_url&&x.media_type==='video'){video=node('video','bb-media');video.src=x.media_url;video.autoplay=true;video.muted=true;video.playsInline=true;video.preload='metadata';video.style.objectFit=x.media_fit==='contain'?'contain':'cover';video.addEventListener('ended',next,{once:true});video.addEventListener('error',function(){console.warn('Billboard video could not load:',x.title)},{once:true});inner.insertBefore(video,copy)}
 host.appendChild(inner);host.appendChild(node('div','bb-counter',(index+1)+' / '+a.length));
 clearTimeout(timer);timer=setTimeout(next,Math.max(3,Math.min(120,Number(x.duration_seconds)||10))*1000);
 if(video){var play=video.play();if(play&&play.catch)play.catch(function(){/* muted autoplay may be restricted; slide timer remains */})}
}
function next(){clearTimeout(timer);var a=active();if(!a.length){draw();return}index=(index+1)%a.length;draw()}
function refresh(){
 if(!sb||loading)return;loading=true;var current=active()[index],currentId=current&&current.id;
 sb.from('billboard_items').select('id,title,message,media_type,media_url,button_label,button_url,starts_at,ends_at,is_published,display_order,duration_seconds,countdown_target_at,countdown_timezone,countdown_complete_label,background_color,background_end_color,accent_color,button_color,text_color,title_animation,transition_effect,media_fit,overlay_opacity,kicker_text').eq('is_published',true).order('display_order',{ascending:true}).then(function(r){
  if(r.error){console.warn('Billboard unavailable:',r.error.message);if(!items.length)host.hidden=true;return}
  items=r.data||[];var a=active(),keep=a.findIndex(function(x){return x.id===currentId});index=keep>=0?keep:Math.min(index,Math.max(0,a.length-1));draw();
 }).catch(function(e){console.warn('Billboard refresh failed:',e)}).finally(function(){loading=false})
}
function start(client){sb=client;window.CV_SB=sb;refresh();try{channel=sb.channel('preuniversity-billboard').on('postgres_changes',{event:'*',schema:'public',table:'billboard_items'},refresh).subscribe()}catch(e){console.warn('Billboard realtime subscription unavailable:',e)}if(!poll)poll=setInterval(refresh,60000)}
function init(){
 if(sb){start(sb);return}
 var cfg=window.CV_CONFIG||{};if(!cfg.supabaseUrl||!cfg.supabaseAnonKey){console.error('Billboard: Supabase project configuration is missing.');return}
 function create(){try{start(window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey))}catch(e){console.error('Billboard could not connect to Supabase:',e)}}
 if(window.supabase&&window.supabase.createClient){create();return}
 var urls=['https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js','https://unpkg.com/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js'],i=0;
 function load(){if(window.supabase&&window.supabase.createClient){create();return}if(i>=urls.length){console.error('Billboard could not load the Supabase client.');return}var s=document.createElement('script');s.src=urls[i++];s.onload=function(){if(window.supabase&&window.supabase.createClient)create();else load()};s.onerror=load;document.head.appendChild(s)}load()
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
})();
