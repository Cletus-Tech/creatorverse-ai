(function(){
var host=document.getElementById('cv-billboard');if(!host)return;
var sb=window.CV_SB,items=[],index=0,timer=null,channel=null;
function node(tag,cls,text){var n=document.createElement(tag);if(cls)n.className=cls;if(text)n.textContent=text;return n}
function track(id){if(sb)sb.rpc('record_billboard_click',{p_item_id:id}).then(function(r){if(r.error)console.warn('Billboard click tracking:',r.error.message)})}
function active(){var now=Date.now();return items.filter(function(x){return x.is_published&&(!x.starts_at||new Date(x.starts_at).getTime()<=now)&&(!x.ends_at||new Date(x.ends_at).getTime()>now)})}
function draw(){var a=active();if(!a.length){host.hidden=true;return}host.hidden=false;if(index>=a.length)index=0;var x=a[index];host.textContent='';host.classList.remove('bb-enter');void host.offsetWidth;host.classList.add('bb-enter');
var inner=node('div','bb-display-inner'),copy=node('div','bb-copy'),tag=node('span','bb-live-tag','CREATORVERSE · PRE-UNIVERSITY');copy.appendChild(tag);copy.appendChild(node('h2','',x.title));if(x.message)copy.appendChild(node('p','',x.message));
if(x.button_label&&x.button_url){var cta=node('a','bb-cta',x.button_label);cta.href=x.button_url;cta.addEventListener('click',function(){track(x.id)});if(/^https?:\/\//i.test(x.button_url)){cta.target='_blank';cta.rel='noopener noreferrer'}copy.appendChild(cta)}
inner.appendChild(copy);
if(x.media_url&&x.media_type==='image'){var img=node('img','bb-media');img.src=x.media_url;img.alt=x.title;img.loading='lazy';inner.insertBefore(img,copy)}
if(x.media_url&&x.media_type==='video'){var video=node('video','bb-media');video.src=x.media_url;video.autoplay=true;video.muted=true;video.loop=false;video.playsInline=true;video.addEventListener('ended',function(){next()},{once:true});inner.insertBefore(video,copy)}
host.appendChild(inner);var count=node('div','bb-counter',(index+1)+' / '+a.length);host.appendChild(count);
clearTimeout(timer);if(!(x.media_type==='video'&&x.media_url)){timer=setTimeout(next,Math.max(3,Math.min(120,Number(x.duration_seconds)||10))*1000)}}
function next(){var a=active();if(!a.length)return;index=(index+1)%a.length;draw()}
function refresh(){if(!sb){host.hidden=true;return}sb.from('billboard_items').select('id,title,message,media_type,media_url,button_label,button_url,starts_at,ends_at,is_published,display_order,duration_seconds').eq('is_published',true).order('display_order',{ascending:true}).then(function(r){if(r.error){console.warn('Billboard unavailable:',r.error.message);host.hidden=true;return}items=r.data||[];index=0;draw()})}
document.addEventListener('cv-ready',function(){sb=window.CV_SB;refresh();if(sb){channel=sb.channel('preuniversity-billboard').on('postgres_changes',{event:'*',schema:'public',table:'billboard_items'},refresh).subscribe()}});
if(window.CV_SB){sb=window.CV_SB;refresh()}else setTimeout(function(){if(window.CV_SB){sb=window.CV_SB;refresh()}},1800);
})();
