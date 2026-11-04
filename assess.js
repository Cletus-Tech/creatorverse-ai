(function(){
var C=window.CV_CONFIG||{},pg=document.body.dataset.page,Q=new URLSearchParams(location.search);
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function srt(a){return(a||[]).slice().sort(function(x,y){return x.position-y.position})}
function chip(t){return h('span',{class:'chip',text:t})}
window.CV_ASSESS={courseBlock:function(sb,user,c,enrolled,flat,done){var box=h('div');if(!user||!enrolled)return box;
 Promise.all([sb.from('quizzes').select('id,title,pass_mark').eq('course_id',c.id),sb.from('assignments').select('id,title').eq('course_id',c.id),sb.from('quiz_attempts').select('quiz_id,score,passed'),sb.from('submissions').select('assignment_id,status,grade'),sb.from('certificates').select('certificate_no,revoked').eq('course_id',c.id).maybeSingle()]).then(function(r){
  if(r[0].error||r[1].error)return;var qs=r[0].data||[],as=r[1].data||[],at=r[2].data||[],sb2=r[3].data||[],cert=r[4].data;
  var best={};at.forEach(function(a){var b=best[a.quiz_id];if(!b||a.score>b.score||(a.passed&&!b.passed))best[a.quiz_id]=a});
  var sub={};sb2.forEach(function(s){sub[s.assignment_id]=s});
  var dn=flat.filter(function(l){return done[l.id]}).length,qp=qs.filter(function(q){return best[q.id]&&best[q.id].passed}).length,ag=as.filter(function(a){return sub[a.id]&&sub[a.id].status==='graded'}).length;
  var ok=flat.length>0&&dn===flat.length&&qp===qs.length&&ag===as.length;
  box.appendChild(h('h2',{text:'Assessments and certificate'}));
  if(qs.length){box.appendChild(h('h3',{class:'mod',text:'Quizzes'}));qs.forEach(function(q){var b=best[q.id];box.appendChild(h('div',{class:'row lrow'},[h('strong',{text:q.title}),b?chip('Best '+b.score+'%'+(b.passed?' · Passed':' · Not passed')):chip('Not taken · pass mark '+q.pass_mark+'%'),h('a',{class:'btn btn-outline',href:'quiz.html?q='+q.id,text:b?'Retake':'Take quiz'})]))})}
  if(as.length){box.appendChild(h('h3',{class:'mod',text:'Assignments'}));as.forEach(function(a){var s=sub[a.id];box.appendChild(h('div',{class:'row lrow'},[h('strong',{text:a.title}),chip(!s?'Not submitted':s.status==='graded'?'Graded '+s.grade+'%':'Submitted'),h('a',{class:'btn btn-outline',href:'assignment.html?a='+a.id,text:s?'View':'Start'})]))})}
  box.appendChild(h('h3',{class:'mod',text:'Certificate'}));
  var ul=h('ul',{class:'clist'});[['Lessons completed',dn+' of '+flat.length,dn===flat.length&&flat.length>0],['Quizzes passed',qp+' of '+qs.length,qp===qs.length],['Assignments graded',ag+' of '+as.length,ag===as.length]].forEach(function(x){ul.appendChild(h('li',{},[h('span',{class:'outc'},[h('span',{class:'dot'+(x[2]?' on':'')},[x[2]?h('span',{text:'✓'}):null]),h('span',{text:x[0]+': '+x[1]})])]))});box.appendChild(ul);
  if(cert)box.appendChild(h('a',{class:'btn btn-primary',href:'certificate.html?n='+encodeURIComponent(cert.certificate_no),text:'View my certificate'}));
  else{var m=h('div',{class:'msg'});box.appendChild(h('button',{class:'btn btn-primary',type:'button',text:'Get my certificate',on:function(){if(!ok){m.textContent='Complete every requirement above first.';m.className='msg err';return}
   sb.rpc('claim_certificate',{p_course:c.id}).then(function(x){if(x.error){m.textContent=x.error.message;m.className='msg err'}else location.href='certificate.html?n='+encodeURIComponent(x.data.certificate_no)})}}));box.appendChild(m)}})
 return box}};
var main=document.getElementById('content');if(!main)return;
function note(t){main.appendChild(h('div',{class:'note',text:t}))}
function ready(f){if(window.CV_SB)f(window.CV_SB);else document.addEventListener('cv-ready',function(){f(window.CV_SB)})}
function who(sb,f){sb.auth.getSession().then(function(r){var u=r.data.session&&r.data.session.user;if(!u){location.href='login.html';return}f(u)})}
function quiz(sb){who(sb,function(u){main.textContent='';sb.rpc('get_quiz',{p_quiz:Q.get('q')||''}).then(function(r){var q=r.data;if(!q){main.appendChild(h('h1',{text:'Quiz not available'}));note('It may not exist, or you need to enrol in the course first.');return}
 sb.from('courses').select('slug').eq('id',q.course_id).maybeSingle().then(function(cr){var back='course.html?s='+encodeURIComponent((cr.data&&cr.data.slug)||'');
  main.appendChild(h('a',{class:'back',href:back,text:'← Back to course'}));main.appendChild(h('h1',{text:q.title}));main.appendChild(h('p',{text:'Pass mark: '+q.pass_mark+'%. You can retake this quiz.'}));
  if(!q.questions.length)return note('This quiz has no questions yet.');var ans={},f=h('form',{class:'quiz'}),res=h('div');
  q.questions.forEach(function(x,i){var fs=h('fieldset',{class:'qbox'},[h('legend',{text:(i+1)+'. '+x.question})]);x.options.forEach(function(o,k){var rd=h('input',{type:'radio',name:'q'+i,value:String(k)});rd.addEventListener('change',function(){ans[x.id]=k});fs.appendChild(h('label',{class:'chk'},[rd,h('span',{text:o})]))});f.appendChild(fs)});
  f.appendChild(h('button',{class:'btn btn-primary',type:'submit',text:'Submit answers'}));main.appendChild(f);main.appendChild(res);
  f.addEventListener('submit',function(e){e.preventDefault();if(Object.keys(ans).length<q.questions.length&&!confirm('Some questions are unanswered. Submit anyway?'))return;
   sb.rpc('submit_quiz',{p_quiz:q.id,p_answers:ans}).then(function(x){res.textContent='';if(x.error){res.appendChild(h('div',{class:'msg err',text:x.error.message}));return}var d=x.data;
    res.appendChild(h('div',{class:'note'},[h('strong',{text:'Score: '+d.score+'% ('+d.correct+' of '+d.total+') — '+(d.passed?'Passed':'Not passed')}),h('p',{text:d.passed?'Well done.':'You need '+d.pass_mark+'% to pass. Review the lessons and try again.'})]));res.appendChild(h('a',{class:'btn btn-outline',href:back,text:'Back to course'}))})})})})})}
function assignment(sb){who(sb,function(u){main.textContent='';sb.from('assignments').select('*,courses(slug,title)').eq('id',Q.get('a')||'').maybeSingle().then(function(r){var a=r.data;if(!a){main.appendChild(h('h1',{text:'Assignment not available'}));return}
 var back='course.html?s='+encodeURIComponent(a.courses.slug);main.appendChild(h('a',{class:'back',href:back,text:'← '+a.courses.title}));main.appendChild(h('h1',{text:a.title}));if(a.instructions)main.appendChild(h('div',{class:'lesson-text',text:a.instructions}));
 sb.from('submissions').select('*').eq('assignment_id',a.id).eq('user_id',u.id).maybeSingle().then(function(s0){var s=s0.data,box=h('div');main.appendChild(box);
  function draw(){box.textContent='';if(s&&s.status==='graded'){box.appendChild(h('div',{class:'note'},[h('strong',{text:'Graded: '+s.grade+'%'}),s.feedback?h('p',{text:'Feedback: '+s.feedback}):null]));if(s.content)box.appendChild(h('p',{text:'Your answer: '+s.content}));return}
   if(s)box.appendChild(h('div',{class:'note',text:'Submitted. You can update your submission until it is graded.'}));
   var f=h('form',{},[h('label',{class:'field',for:'c',text:'Your answer'}),h('textarea',{id:'c',rows:'6'}),h('label',{class:'field',for:'fl',text:'Attach a file (optional, up to 20 MB)'}),h('input',{id:'fl',type:'file'}),h('button',{class:'btn btn-primary',type:'submit',text:s?'Update submission':'Submit assignment'})]),m=h('div',{class:'msg'});f.querySelector('textarea').value=(s&&s.content)||'';box.appendChild(f);box.appendChild(m);
   f.addEventListener('submit',function(e){e.preventDefault();var file=f.querySelector('input[type=file]').files[0],txt=f.querySelector('textarea').value.trim();if(!txt&&!file&&!(s&&s.file_path)){m.textContent='Write an answer or attach a file.';m.className='msg err';return}
    m.textContent='Submitting…';m.className='msg';function save(path){var row={content:txt||null};if(path)row.file_path=path;var q=s?sb.from('submissions').update(row).eq('id',s.id).select('*').maybeSingle():sb.from('submissions').insert(Object.assign({assignment_id:a.id,user_id:u.id},row)).select('*').maybeSingle();
     q.then(function(x){if(x.error){m.textContent=x.error.message;m.className='msg err';return}s=x.data;draw()})}
    if(file){var p=u.id+'/'+a.id+'-'+Date.now()+'-'+file.name.replace(/[^\w.\-]+/g,'_');sb.storage.from('submissions').upload(p,file).then(function(x){if(x.error){m.textContent=x.error.message;m.className='msg err'}else save(p)})}else save(null)})}
  draw()})})})}
function certificate(){var n=Q.get('n');main.textContent='';
 if(!n){main.appendChild(h('h1',{text:'Verify a certificate'}));main.appendChild(h('p',{text:'Enter the certificate number printed on the certificate.'}));var f=h('form',{},[h('input',{name:'n',placeholder:'CV-2026-XXXXXXXX',required:''}),h('button',{class:'btn btn-primary',type:'submit',text:'Verify'})]);f.addEventListener('submit',function(e){e.preventDefault();location.href='certificate.html?n='+encodeURIComponent(f.n.value.trim())});main.appendChild(f);return}
 fetch(C.supabaseUrl+'/rest/v1/rpc/verify_certificate',{method:'POST',headers:{apikey:C.supabaseAnonKey,Authorization:'Bearer '+C.supabaseAnonKey,'Content-Type':'application/json'},body:JSON.stringify({p_no:n})}).then(function(r){return r.json()}).then(function(d){
  if(!d||!d.certificate_no){main.appendChild(h('h1',{text:'Certificate not found'}));main.appendChild(h('div',{class:'note',text:'No certificate matches “'+n+'”. Check the number and try again.'}));main.appendChild(h('a',{class:'btn btn-outline',href:'certificate.html',text:'Try another number'}));return}
  var dt=new Date(d.issued_at).toLocaleDateString(undefined,{year:'numeric',month:'long',day:'numeric'});
  main.appendChild(h('div',{class:'vbar '+(d.revoked?'bad':'ok'),text:d.revoked?'This certificate has been revoked.':'Verified: this certificate is genuine.'}));
  main.appendChild(h('div',{class:'cert'},[h('div',{class:'cert-brand',text:'CreatorVerse AI'}),h('p',{class:'cert-sm',text:'Certificate of Completion'}),h('p',{class:'cert-sm',text:'This certifies that'}),h('h1',{class:'cert-name',text:d.student_name}),h('p',{class:'cert-sm',text:'has successfully completed the course'}),h('h2',{class:'cert-course',text:d.course_title}),h('p',{class:'cert-sm',text:'Issued on '+dt}),h('p',{class:'cert-no',text:'Certificate no. '+d.certificate_no}),h('p',{class:'cert-no',text:'Verify at '+location.origin+location.pathname.replace(/[^\/]*$/,'')+'certificate.html?n='+d.certificate_no})]));
  main.appendChild(h('div',{class:'row noprint'},[h('button',{class:'btn btn-primary',type:'button',text:'Download / Print as PDF',on:function(){window.print()}}),h('a',{class:'btn btn-outline',href:'index.html',text:'Home'})]))}).catch(function(){main.appendChild(h('div',{class:'msg err',text:'Could not verify right now. Try again later.'}))})}
if(pg==='certificate')certificate();else if(pg==='quiz')ready(quiz);else if(pg==='assignment')ready(assignment);
})();
