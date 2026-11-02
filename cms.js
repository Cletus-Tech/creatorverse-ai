(function(){
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else if(i==='value')e.value=a[i];else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
var FOLDERS=['general','homepage','founder','course-thumbnails','banners','videos'],MAX=52428800;
function kind(f){return /^image\//.test(f.type)?'image':/^video\//.test(f.type)?'video':'file'}
function clean(n){return n.replace(/[^\w.\-]+/g,'_')}
function up(file,folder,path,replace){var sb=window.CV_SB;if(file.size>MAX)return Promise.reject(new Error('File is larger than 50 MB.'));
 path=path||folder+'/'+Date.now()+'-'+clean(file.name);
 return sb.storage.from('media').upload(path,file,{upsert:!!replace,contentType:file.type}).then(function(r){if(r.error)throw r.error;
  var url=sb.storage.from('media').getPublicUrl(path).data.publicUrl,row={path:path,url:url,name:file.name,kind:kind(file),folder:path.split('/')[0],size:file.size};
  return sb.from('media_files').upsert(row,{onConflict:'path'}).then(function(x){if(x.error)throw x.error;return url})})}
window.CV_MEDIA={upload:up};
function pick(kindWanted,input){var sb=window.CV_SB,s=h('select',{},[h('option',{value:'',text:'Choose from media library…'})]);
 sb.from('media_files').select('url,name,folder').eq('kind',kindWanted).order('created_at',{ascending:false}).then(function(r){(r.data||[]).forEach(function(m){s.appendChild(h('option',{value:m.url,text:m.folder+' / '+m.name}))})});
 s.addEventListener('change',function(){if(s.value){input.value=s.value;if(input.dispatchEvent)input.dispatchEvent(new Event('input'))}});return s}
function media(pane){var sb=window.CV_SB,cur='all';pane.appendChild(h('h2',{text:'Media library'}));
 var fs=h('select',{id:'mfolder'},FOLDERS.map(function(f){return h('option',{value:f,text:f})})),fi=h('input',{type:'file',multiple:'',accept:'image/*,video/*'}),m=h('div',{class:'msg'}),
 flt=h('select',{},[h('option',{value:'all',text:'Show all folders'})].concat(FOLDERS.map(function(f){return h('option',{value:f,text:f})}))),grid=h('div',{class:'panels'});
 var go=h('button',{class:'btn btn-primary',type:'button',text:'Upload',on:function(){var fl=[].slice.call(fi.files);if(!fl.length){m.textContent='Choose files first.';m.className='msg err';return}
  m.textContent='Uploading…';m.className='msg';Promise.all(fl.map(function(f){return up(f,fs.value)})).then(function(){m.textContent='Uploaded.';m.className='msg ok';fi.value='';load()}).catch(function(e){m.textContent=e.message;m.className='msg err'})}});
 [h('label',{class:'field',text:'Folder'}),fs,h('label',{class:'field',text:'Files (images or videos, up to 50 MB each)'}),fi,go,m,h('label',{class:'field',text:'View'}),flt,grid].forEach(function(e){pane.appendChild(e)});
 flt.addEventListener('change',function(){cur=flt.value;load()});
 function load(){var q=sb.from('media_files').select('*').order('created_at',{ascending:false});if(cur!=='all')q=q.eq('folder',cur);
  q.then(function(r){grid.textContent='';if(!(r.data||[]).length)return grid.appendChild(h('p',{text:'No media in this view.'}));
   r.data.forEach(function(f){var pv=f.kind==='image'?h('img',{class:'thumb',src:f.url,alt:''}):f.kind==='video'?h('video',{class:'thumb',src:f.url,controls:''}):h('p',{text:'(file)'});
    var rp=h('input',{type:'file',style:'display:none',accept:f.kind==='image'?'image/*':'video/*'});
    rp.addEventListener('change',function(){if(rp.files[0])up(rp.files[0],f.folder,f.path,true).then(load).catch(function(e){alert(e.message)})});
    grid.appendChild(h('div',{class:'panel'},[pv,h('p',{text:f.name+' · '+f.folder}),h('div',{class:'row'},[
     h('button',{class:'btn btn-outline',type:'button',text:'Copy URL',on:function(){navigator.clipboard.writeText(f.url).then(function(){alert('URL copied')})}}),
     h('button',{class:'btn btn-outline',type:'button',text:'Replace',on:function(){rp.click()}}),
     h('button',{class:'btn btn-outline',type:'button',text:'Delete',on:function(){if(confirm('Delete '+f.name+'? Pages using it will lose the file.'))sb.storage.from('media').remove([f.path]).then(function(x){if(x.error)return alert(x.error.message);sb.from('media_files').delete().eq('id',f.id).then(load)})}})]),rp]))})})}
 load()}
var KEYS=[['banner_text','Announcement banner text','t'],['banner_link','Banner link (optional, https://…)','t'],['about_text','About page text (blank line between paragraphs)','ta']];
function site(pane){var sb=window.CV_SB;pane.appendChild(h('h2',{text:'Website content'}));pane.appendChild(h('p',{text:'Leave a field empty to use the website default.'}));
 var f=h('form',{class:'mini'}),inp={},m=h('div',{class:'msg'});
 KEYS.forEach(function(k){var i=k[2]==='ta'?h('textarea',{rows:k[0]==='about_text'?'8':'3',name:k[0]}):h('input',{name:k[0],type:'text'});inp[k[0]]=i;f.appendChild(h('label',{class:'field',text:k[1]}));f.appendChild(i);
  if(k[2]==='img'||k[2]==='vid'){var fi=h('input',{type:'file',accept:k[2]==='img'?'image/*':'video/*'});fi.addEventListener('change',function(){if(fi.files[0]){m.textContent='Uploading…';m.className='msg';up(fi.files[0],k[2]==='img'?'founder':'videos').then(function(u){i.value=u;m.textContent='Uploaded. Press Save to publish it on the website.';m.className='msg ok'}).catch(function(e){m.textContent=e.message;m.className='msg err'})}});
   f.appendChild(fi);f.appendChild(pick(k[2]==='img'?'image':'video',i))}});
 f.appendChild(h('button',{class:'btn btn-primary',type:'submit',text:'Save website content'}));f.appendChild(m);pane.appendChild(f);
 sb.from('site_content').select('key,value').then(function(r){(r.data||[]).forEach(function(x){if(inp[x.key])inp[x.key].value=x.value})});
 f.addEventListener('submit',function(e){e.preventDefault();var set=[],del=[];KEYS.forEach(function(k){var v=inp[k[0]].value.trim();v?set.push({key:k[0],value:v,updated_at:new Date().toISOString()}):del.push(k[0])});
  Promise.all([set.length?sb.from('site_content').upsert(set):{},del.length?sb.from('site_content').delete().in('key',del):{}]).then(function(r){var er=(r[0]&&r[0].error)||(r[1]&&r[1].error);m.textContent=er?er.message:'Saved. Refresh the website to see the changes.';m.className='msg '+(er?'err':'ok')})})}
window.CV_CMS={media:media,site:site,pick:pick};
})();
