(function(){
function el(t,a,k){var n=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')n.textContent=a[x];else n.setAttribute(x,a[x])});(k||[]).forEach(function(c){if(c)n.appendChild(c)});return n}
function divisions(pane){var sb=window.CV_SB,box=el('div'),msg=el('p',{class:'msg'}),rows=[];
pane.append(el('h2',{text:'Division Management'}),el('p',{text:'Manage every public division card, its image, copy, features, destination, visibility and order. Deletions are moved to the recycle bin.'}),el('div',{class:'row'},[el('button',{class:'btn btn-primary',type:'button',text:'Create division'}),el('button',{class:'btn btn-outline',type:'button',text:'View revision history'})]),msg,box);
var actions=pane.querySelectorAll('.row button');
actions[0].onclick=function(){edit({slug:'new-division-'+Date.now(),title:'New division',kicker:'',description:'',image_url:'',image_alt:'',art_caption:'',features:[],status:'planned',status_label:'In development',cta_label:'Coming soon',destination:'',accent:'blue',position:rows.length+1,published:true})};
actions[1].onclick=history;
function say(t,ok){msg.textContent=t;msg.className='msg '+(ok?'ok':'err')}
function load(){sb.from('cv_divisions').select('*').order('position').then(function(r){if(r.error){say(r.error.message+' — ensure the admin migration has been applied.');return}rows=r.data||[];draw()})}
function draw(){box.textContent='';rows.forEach(function(d,i){var p=el('div',{class:'panel'}),im=d.image_url?el('img',{src:d.image_url,alt:d.image_alt||'',style:'width:100%;max-width:260px;height:110px;object-fit:cover;border-radius:12px'}):null;
p.append(el('div',{class:'row'},[im,el('div',{},[el('h3',{text:d.title}),el('p',{class:'pmeta',text:d.slug+' · '+(d.status_label||'')+' · '+(d.published?'Published':'Hidden')})])]));
p.append(el('div',{class:'row'},[
el('button',{class:'btn btn-primary',type:'button',text:'Edit',onclick:''}),
el('button',{class:'btn btn-outline',type:'button',text:'Move up'}),
el('button',{class:'btn btn-outline',type:'button',text:'Move down'}),
el('button',{class:'btn btn-outline',type:'button',text:d.published?'Hide':'Publish'}),
el('button',{class:'btn btn-outline',type:'button',text:'Move to recycle bin'})
]));
var b=p.querySelectorAll('button');b[0].onclick=function(){edit(d)};
b[1].onclick=function(){move(i,-1)};b[2].onclick=function(){move(i,1)};
b[3].onclick=function(){sb.from('cv_divisions').update({published:!d.published}).eq('id',d.id).then(function(r){if(r.error)say(r.error.message);else load()})};
b[4].onclick=function(){if(confirm('Move '+d.title+' to the recycle bin? It can be restored later.'))sb.from('cv_divisions').update({deleted_at:new Date().toISOString(),published:false}).eq('id',d.id).then(function(r){if(r.error)say(r.error.message);else load()})};
box.appendChild(p)})}
function move(i,delta){var j=i+delta;if(j<0||j>=rows.length)return;var a=rows[i],b=rows[j];Promise.all([sb.from('cv_divisions').update({position:b.position}).eq('id',a.id),sb.from('cv_divisions').update({position:a.position}).eq('id',b.id)]).then(load)}
function field(label,key,val,ta){var i=ta?el('textarea',{rows:'3'}):el('input',{type:'text'});i.value=val==null?'':val;return [el('label',{class:'field',text:label}),i]}
function edit(d){var isNew=!d.id,form=el('form',{class:'panel'}),m=el('p',{class:'msg'}),o=Object.assign({},d);
form.appendChild(el('h3',{text:isNew?'Create division':'Edit '+d.title}));
[['Title','title'],['Slug','slug'],['Kicker','kicker'],['Description','description'],['Image URL','image_url'],['Image alt text','image_alt'],['Image caption','art_caption'],['CTA label','cta_label'],['Destination (relative page or https URL)','destination'],['Status label','status_label'],['Accent style','accent'],['Display order','position']].forEach(function(x){var r=field(x[0],x[1],o[x[1]],['description'].includes(x[1]));form.append(r[0],r[1]);r[1].addEventListener('input',function(){o[x[1]]=x[1]==='position'?Number(r[1].value):r[1].value})});
var features=el('textarea',{rows:'4'});features.value=(o.features||[]).join('\n');form.append(el('label',{class:'field',text:'Features (one per line)'}),features);
var status=el('select',{},[['live','Live'],['planned','In development'],['hidden','Hidden']].map(function(x){var z=el('option',{value:x[0],text:x[1]});return z}));status.value=o.status||'planned';form.append(el('label',{class:'field',text:'Availability'}),status);
var published=el('input',{type:'checkbox'});published.checked=o.published!==false;form.append(el('label',{class:'chk'},[published,el('span',{text:'Published on public divisions page'})]));
var save=el('button',{class:'btn btn-primary',type:'submit',text:'Save changes'}),cancel=el('button',{class:'btn btn-outline',type:'button',text:'Cancel'});form.append(el('div',{class:'row'},[save,cancel]),m);cancel.onclick=function(){form.remove()};
form.onsubmit=function(e){e.preventDefault();o.features=features.value.split('\n').map(function(x){return x.trim()}).filter(Boolean);o.status=status.value;o.published=published.checked;o.updated_at=new Date().toISOString();save.disabled=true;
var q=isNew?sb.from('cv_divisions').insert(o):sb.from('cv_divisions').update(o).eq('id',o.id);q.then(function(r){if(r.error){m.textContent=r.error.message;m.className='msg err';save.disabled=false;return}m.textContent='Saved.';m.className='msg ok';setTimeout(function(){form.remove();load()},450)})};
box.prepend(form);form.scrollIntoView({behavior:'smooth',block:'start'})}
function history(){sb.from('cv_admin_revisions').select('*').eq('entity_type','division').order('created_at',{ascending:false}).limit(60).then(function(r){if(r.error)return say(r.error.message);var p=el('div',{class:'panel'});p.append(el('h3',{text:'Division revision history'}),el('p',{class:'pmeta',text:'Each save, publish, hide and delete is recorded. Restore uses the saved previous snapshot.'}));(r.data||[]).forEach(function(v){var row=el('div',{class:'row'},[el('span',{},[el('strong',{text:v.action+' · '+(v.after_data&&v.after_data.title||v.before_data&&v.before_data.title||'Division')}),el('small',{text:new Date(v.created_at).toLocaleString()})])]);var snap=v.before_data||v.after_data;if(snap){var btn=el('button',{class:'btn btn-outline',type:'button',text:'Restore this version'});btn.onclick=function(){if(!confirm('Restore this saved division version?'))return;sb.rpc('cv_restore_content_revision',{p_revision_id:v.id}).then(function(x){if(x.error)say(x.error.message);else{say('Version restored. A new revision has been recorded.',true);load();history()}})};row.appendChild(btn)}p.appendChild(row)});box.prepend(p)})}
load();
}
window.CV_CMS=window.CV_CMS||{};window.CV_CMS.divisions=divisions;
})();