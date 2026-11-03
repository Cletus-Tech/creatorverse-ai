(function(){
var HD=window.CV_HOME;
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function homepage(pane){var sb=window.CV_SB,S=HD.merge(HD.D,{}),draftId=null,vers=[],courses=[],box=h('div'),msg=h('div',{class:'msg'});
 function say(t,k){msg.textContent=t;msg.className='msg '+(k||'')}
 function T(l,o,k,ta){var i=ta?h('textarea',{rows:'3'}):h('input',{type:'text'});i.value=o[k]||'';i.addEventListener('input',function(){o[k]=i.value});return[h('label',{class:'field',text:l}),i]}
 function K(l,o,k){var i=h('input',{type:'checkbox'});i.checked=o[k]!==false;i.addEventListener('change',function(){o[k]=i.checked});return h('label',{class:'chk'},[i,h('span',{text:l})])}
 function O(l,o,k,opts){var s=h('select',{},opts.map(function(x){return h('option',{value:x[0],text:x[1]})}));s.value=o[k]||opts[0][0];s.addEventListener('change',function(){o[k]=s.value});return[h('label',{class:'field',text:l}),s]}
 function M(l,o,k,kind,folder){var r=T(l,o,k),i=r[1],f=h('input',{type:'file',accept:kind+'/*'});
  f.addEventListener('change',function(){if(f.files[0]){say('Uploading…');window.CV_MEDIA.upload(f.files[0],folder).then(function(u){i.value=u;o[k]=u;say('Uploaded. Save the draft to keep it.','ok')}).catch(function(e){say(e.message,'err')})}});
  return r.concat([f,window.CV_CMS.pick(kind,i),h('button',{class:'btn btn-outline',type:'button',text:'Remove',on:function(){i.value='';o[k]=''}})])}
 function add(parent,list){list.forEach(function(e){if(e)parent.appendChild(e)});return parent}
 function mv(a,i,d){var j=i+d;if(j<0||j>=a.length)return;var x=a[i];a[i]=a[j];a[j]=x;draw()}
 function draw(){box.textContent='';var H=S.hero;
  var hb=h('div',{class:'panel'},[h('h3',{text:'Hero banner'})]);
  add(hb,[K('Show hero',H,'visible')].concat(T('Headline (new line = line break; *words* are highlighted)',H,'title',1),T('Description',H,'text',1),
   [h('h3',{class:'mod',text:'Buttons'}),K('Show primary button',H.primary,'visible')],T('Primary label',H.primary,'label'),T('Primary destination (page or link)',H.primary,'url'),
   [K('Show Watch Introduction button',H.secondary,'visible')],T('Watch Introduction label',H.secondary,'label'),
   [h('h3',{class:'mod',text:'Founder portrait and video'}),h('p',{text:'The photo, name, biography and introduction video are managed in Founder Profile and Introduction Video (left menu). Here you control how they appear on the homepage.'}),K('Show portrait',H.portrait,'visible')],O('Portrait position',H.portrait,'position',[['right','Right'],['left','Left']]),O('Portrait style',H.portrait,'style',[['cutout','Cutout (transparent image)'],['framed','Framed photo']]),[K('Show founder name and title',H.founder,'visible')]));
  box.appendChild(hb);box.appendChild(h('h2',{text:'Sections'}));
  S.sections.forEach(function(sc,i){var p=h('div',{class:'panel'},[h('h3',{text:sc.type.toUpperCase()}),h('div',{class:'row'},[
    h('button',{class:'btn btn-outline',type:'button',text:'Up',on:function(){mv(S.sections,i,-1)}}),h('button',{class:'btn btn-outline',type:'button',text:'Down',on:function(){mv(S.sections,i,1)}}),
    h('button',{class:'btn btn-outline',type:'button',text:'Remove',on:function(){if(confirm('Remove this section?')){S.sections.splice(i,1);draw()}}})])]);
   add(p,[K('Visible on homepage',sc,'visible')].concat(T('Title',sc,'title'),sc.type==='cta'?T('Text',sc,'text',1):T('Subtitle',sc,'subtitle')));
   if(sc.type==='cta')add(p,T('Button label',sc,'label').concat(T('Button destination',sc,'url')));
   if(sc.type==='courses'){sc.ids=sc.ids||[];p.appendChild(h('p',{text:'Choose featured courses (none chosen = the 4 newest published courses):'}));
    courses.forEach(function(c){var k=h('input',{type:'checkbox'});k.checked=sc.ids.indexOf(c.id)>-1;k.addEventListener('change',function(){sc.ids=sc.ids.filter(function(x){return x!==c.id});if(k.checked)sc.ids.push(c.id)});p.appendChild(h('label',{class:'chk'},[k,h('span',{text:c.title})]))});if(!courses.length)p.appendChild(h('p',{text:'No published courses yet.'}))}
   if(['cards','faq','testimonials'].indexOf(sc.type)>-1){sc.items=sc.items||[];var L=sc.type==='faq'?['Question','Answer']:sc.type==='testimonials'?['Name and role','Quote']:['Title','Text'];
    sc.items.forEach(function(it,n){var w=h('div',{class:'mini'});add(w,T(L[0],it,'title').concat(T(L[1],it,'text',1)));w.appendChild(h('button',{class:'btn btn-outline',type:'button',text:'Remove item',on:function(){sc.items.splice(n,1);draw()}}));p.appendChild(w)});
    p.appendChild(h('button',{class:'btn btn-outline',type:'button',text:'Add item',on:function(){sc.items.push({title:'',text:''});draw()}}))}
   box.appendChild(p)});
  var ty=h('select',{},[['cards','Info cards (Why CreatorVerse, benefits, how it works)'],['faq','FAQ'],['testimonials','Testimonials'],['courses','Featured courses'],['categories','Categories'],['cta','Call to action']].map(function(x){return h('option',{value:x[0],text:x[1]})}));
  box.appendChild(h('div',{class:'row'},[ty,h('button',{class:'btn btn-outline',type:'button',text:'Add section',on:function(){S.sections.push({id:ty.value+'-'+Date.now(),type:ty.value,visible:true,title:'New section',subtitle:'',text:'',items:[],ids:[]});draw()}})]));
  box.appendChild(h('div',{class:'row'},[h('button',{class:'btn btn-outline',type:'button',text:'Save draft',on:function(){save()}}),h('button',{class:'btn btn-outline',type:'button',text:'Preview',on:function(){save().then(function(ok){if(ok)window.open('index.html?preview=1','_blank')})}}),h('button',{class:'btn btn-primary',type:'button',text:'Publish to website',on:publish})]));
  box.appendChild(h('h2',{text:'Published history'}));var hl=h('div');box.appendChild(hl);
  vers.filter(function(v){return v.status==='published'}).forEach(function(v){hl.appendChild(h('div',{class:'row'},[h('span',{text:new Date(v.created_at).toLocaleString()}),h('button',{class:'btn btn-outline',type:'button',text:'Load into draft',on:function(){if(confirm('Replace the draft with this version?')){S=HD.merge(HD.D,v.content);draw();say('Loaded. Save the draft or publish it.','ok')}}})]))});
  if(!hl.children.length)hl.appendChild(h('p',{text:'Nothing published yet. The website shows built-in defaults.'}))}
 function save(){say('Saving…');var q=draftId?sb.from('homepage_versions').update({content:S}).eq('id',draftId).select('id').maybeSingle():sb.from('homepage_versions').insert({status:'draft',content:S}).select('id').maybeSingle();
  return q.then(function(r){if(r.error){say(r.error.message,'err');return false}if(r.data)draftId=r.data.id;say('Draft saved.','ok');return true})}
 function publish(){if(!confirm('Publish this version to the live website?'))return;save().then(function(ok){if(!ok)return;sb.from('homepage_versions').insert({status:'published',content:S}).select('*').maybeSingle().then(function(r){if(r.error)return say(r.error.message,'err');vers.unshift(r.data);draw();say('Published. Refresh the website to see it.','ok')})})}
 pane.appendChild(h('h2',{text:'Homepage Manager'}));pane.appendChild(h('p',{text:'Changes stay in a draft until you press Publish. Use Preview to see the draft on the real homepage.'}));pane.appendChild(box);pane.appendChild(msg);
 sb.from('courses').select('id,title').eq('published',true).then(function(r){courses=r.data||[]});
 sb.from('homepage_versions').select('*').order('created_at',{ascending:false}).limit(30).then(function(r){vers=r.data||[];var d=vers.filter(function(v){return v.status==='draft'})[0];if(d)draftId=d.id;var b=d||vers.filter(function(v){return v.status==='published'})[0];if(b)S=HD.merge(HD.D,b.content);draw()});
 draw()}
window.CV_CMS=window.CV_CMS||{};window.CV_CMS.homepage=homepage;
})();
