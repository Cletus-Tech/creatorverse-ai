(function(){
function h(t,a,k){var e=document.createElement(t);for(var i in a||{}){if(i==='text')e.textContent=a[i];else if(i==='on')e.addEventListener('click',a[i]);else e.setAttribute(i,a[i])}(k||[]).forEach(function(c){if(c)e.appendChild(c)});return e}
function srt(a){return(a||[]).slice().sort(function(x,y){return x.position-y.position})}
function bar(p){return h('div',{class:'progress'},[h('span',{style:'width:'+p+'%'})])}
function ccard(c,p){var th=c.thumbnail_url?h('img',{src:c.thumbnail_url,alt:'',loading:'lazy'}):h('span',{class:'nothumb',text:'▶'});
 return h('a',{class:'course-card linkcard',href:'course.html?s='+encodeURIComponent(c.slug)},[h('div',{class:'cthumb'},[th]),h('div',{class:'cbody'},[h('h3',{text:c.title}),bar(p.pct),h('div',{class:'meta'},[h('span',{text:p.done+' of '+p.total+' lessons'}),h('span',{text:p.pct+'%'})])])])}
window.CV_DASH=function(sb,session,X){var u=session.user,name=(u.user_metadata&&u.user_metadata.full_name)||'',main=document.getElementById('content');
 Promise.all([sb.from('enrolments').select('created_at,courses(id,slug,title,thumbnail_url,modules(id,position,lessons(id,title,position)))').order('created_at',{ascending:false}),
  sb.from('lesson_progress').select('lesson_id,completed_at').order('completed_at',{ascending:false}),sb.from('profiles').select('role').eq('id',u.id).maybeSingle()]).then(function(r){
  var en=(r[0].data||[]).filter(function(e){return e.courses}),pr=r[1].data||[],ro=(r[2].data&&r[2].data.role)||'student',done={},all={};pr.forEach(function(p){done[p.lesson_id]=p.completed_at});
  var cs=en.map(function(e){var c=e.courses,ls=[];srt(c.modules).forEach(function(m){srt(m.lessons).forEach(function(l){ls.push(l);all[l.id]={t:l.title,c:c.title}})});
   var d=ls.filter(function(l){return done[l.id]}).length;return{c:c,total:ls.length,done:d,pct:ls.length?Math.round(100*d/ls.length):0,next:ls.filter(function(l){return !done[l.id]})[0]||ls[0]}});
  var tl=cs.reduce(function(a,x){return a+x.total},0),td=cs.reduce(function(a,x){return a+x.done},0);
  main.textContent='';
  var head=h('div',{class:'dash-hero'},[h('div',{class:'avatar',text:(name||u.email).trim().charAt(0).toUpperCase()}),h('div',{},[h('h1',{text:'Welcome back'+(name?', '+name:'')}),h('p',{text:u.email}),
   h('p',{},[h('span',{class:'chip',text:u.email_confirmed_at?'Email verified':'Email not verified'}),h('span',{class:'chip',text:ro.replace('_',' ')}),(ro==='admin'||ro==='super_admin')?h('a',{class:'chip',href:'admin.html',text:'Admin panel'}):null])])]);
  main.appendChild(head);
  main.appendChild(h('div',{class:'stats'},[['Enrolled courses',cs.length],['Lessons completed',td],['Overall progress',tl?Math.round(100*td/tl)+'%':'0%']].map(function(s){return h('div',{class:'stat'},[h('strong',{text:String(s[1])}),h('span',{text:s[0]})])})));
  if(!cs.length){main.appendChild(h('div',{class:'note',text:'You have not enrolled in a course yet.'}));main.appendChild(h('a',{class:'btn btn-primary',href:'courses.html',text:'Explore Courses'}))}
  else{var cur=cs.filter(function(x){return x.next&&x.pct<100})[0]||cs[0];
   main.appendChild(h('h2',{text:'Continue learning'}));
   main.appendChild(h('div',{class:'contcard'},[cur.c.thumbnail_url?h('img',{src:cur.c.thumbnail_url,alt:''}):null,h('div',{},[h('h3',{text:cur.c.title}),h('p',{text:cur.next?(cur.pct===100?'Course completed. Review: ':'Next lesson: ')+cur.next.title:'No lessons yet'}),bar(cur.pct),cur.next?h('a',{class:'btn btn-primary',href:'lesson.html?l='+cur.next.id,text:cur.pct===100?'Review':'Continue'}):null])]));
   main.appendChild(h('h2',{text:'My courses'}));var g=h('div',{class:'grid'});cs.forEach(function(x){g.appendChild(ccard(x.c,x))});main.appendChild(g);
   var act=pr.slice(0,6).filter(function(p){return all[p.lesson_id]});
   if(act.length){main.appendChild(h('h2',{text:'Recent activity'}));var ul=h('ul',{class:'act'});act.forEach(function(p){ul.appendChild(h('li',{},[h('span',{text:'Completed “'+all[p.lesson_id].t+'”'}),h('small',{text:all[p.lesson_id].c+' · '+new Date(p.completed_at).toLocaleDateString()})]))});main.appendChild(ul)}}
  var extra=h('div');main.appendChild(extra);
  Promise.all([sb.from('certificates').select('certificate_no,course_title,issued_at,revoked').order('issued_at',{ascending:false}),sb.from('quiz_attempts').select('score,passed,created_at,quizzes(title)').order('created_at',{ascending:false}).limit(5)]).then(function(z){
   var cr=(z[0].data||[]),qa=(z[1].data||[]);if(cr.length){extra.appendChild(h('h2',{text:'My certificates'}));cr.forEach(function(c){extra.appendChild(h('div',{class:'row lrow'},[h('strong',{text:c.course_title}),h('small',{text:new Date(c.issued_at).toLocaleDateString()+(c.revoked?' · revoked':'')}),h('a',{class:'btn btn-outline',href:'certificate.html?n='+encodeURIComponent(c.certificate_no),text:'View'})]))})}
   if(qa.length){extra.appendChild(h('h2',{text:'Recent quiz results'}));qa.forEach(function(x){extra.appendChild(h('div',{class:'row lrow'},[h('strong',{text:(x.quizzes&&x.quizzes.title)||'Quiz'}),h('span',{class:'chip',text:x.score+'% · '+(x.passed?'Passed':'Not passed')}),h('small',{text:new Date(x.created_at).toLocaleDateString()})]))})}});
  main.appendChild(h('h2',{text:'Account settings'}));
  var f=h('form',{id:'f'},[h('label',{class:'field',for:'name',text:'Full name'}),h('input',{id:'name',name:'name',required:'',maxlength:'80'}),h('button',{class:'btn btn-primary',type:'submit',text:'Save changes'})]);
  main.appendChild(f);main.appendChild(h('div',{id:'msg',class:'msg'}));f.name.value=name;
  main.appendChild(h('button',{class:'btn btn-outline',type:'button',style:'margin-top:26px',text:'Log out',on:function(){sb.auth.signOut().then(function(){location.href='index.html'})}}));
  X.form('f',function(d){return sb.auth.updateUser({data:{full_name:d.get('name')}}).then(function(r){if(!X.oops(r.error))X.msg('Saved.','ok')})})})};
})();
