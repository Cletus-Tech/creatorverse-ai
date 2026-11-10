(function(){
function h(t,a,k){var e=document.createElement(t);Object.keys(a||{}).forEach(function(x){if(x==='text')e.textContent=a[x];else e.setAttribute(x,a[x])});(k||[]).forEach(function(n){if(n)e.appendChild(n)});return e}
var host=document.getElementById('content');
function field(label,node,required){return h('label',{class:'academy-apply-field'},[h('span',{text:label+(required?' *':'')}),node])}
function input(name,placeholder,type){return h('input',{name:name,placeholder:placeholder||'',type:type||'text'})}
function area(name,placeholder){return h('textarea',{name:name,placeholder:placeholder||'',rows:'4'})}
function notice(text,bad){return h('p',{class:'academy-apply-notice'+(bad?' error':''),text:text})}
function boot(){
 var sb=window.CV_SB;if(!sb){host.textContent='Authentication is loading. Refresh this page in a moment.';return}
 sb.auth.getUser().then(function(r){
  var user=r.data&&r.data.user;if(!user){host.textContent='';host.appendChild(h('section',{class:'academy-apply-card'},[h('span',{class:'academy-eyebrow',text:'CREATORVERSE PARTNER NETWORK'}),h('h1',{text:'Apply to create, teach or exhibit'}),h('p',{text:'Sign in before submitting a creator, instructor, teacher or exhibitor application.'}),h('a',{class:'btn btn-primary',href:'login.html',text:'Sign in to continue'})]));return}
  sb.from('courses').select('id').eq('slug','creator-partner-application').eq('published',false).maybeSingle().then(function(cr){
   if(cr.error||!cr.data){host.textContent='';host.appendChild(notice('The Creator application portal is temporarily unavailable. Please contact the platform administrator.',true));return}
   var courseId=cr.data.id;
   sb.from('academy_applications').select('id,application_no,status,application_type,created_at').eq('user_id',user.id).in('application_type',['creator','instructor','teacher','exhibitor']).order('created_at',{ascending:false}).limit(1).maybeSingle().then(function(existing){
    if(existing.error){host.textContent='';host.appendChild(notice('We could not check your previous application. Please try again.',true));return}
    if(existing.data){host.textContent='';host.appendChild(h('section',{class:'academy-apply-card'},[h('span',{class:'academy-eyebrow',text:'APPLICATION ALREADY RECEIVED'}),h('h1',{text:'Your CreatorVerse application is on file.'}),h('p',{text:'Reference: '+existing.data.application_no+' · '+String(existing.data.application_type).replace(/_/g,' ')+' · '+String(existing.data.status).replace(/_/g,' ')}),h('p',{text:'The CreatorVerse team will review your work and contact you if an interview or practical assessment is required.'}),h('a',{class:'btn btn-primary',href:'academy-status.html',text:'Track my creator application'})]));return}
    render(sb,user,courseId)
   })
  })
 })
}
function render(sb,user,courseId){
 host.textContent='';
 var form=h('form',{class:'academy-apply-form'}),message=h('div'),submit=h('button',{class:'btn btn-primary academy-apply-submit',type:'submit',text:'Submit creator application'});
 var hero=h('section',{class:'academy-apply-hero'},[h('div',{},[h('span',{class:'academy-eyebrow',text:'CREATORVERSE PARTNER NETWORK'}),h('h1',{text:'Bring your talent to CreatorVerse.'}),h('p',{text:'This application is only for people who want to create, teach, instruct or exhibit work on the platform. Regular learners do not need an application or interview to buy courses.'})])]);
 function section(title,desc){form.appendChild(h('div',{class:'academy-apply-section-head'},[h('h2',{text:title}),h('p',{text:desc})]))}
 var role=h('select',{},[['creator','Creator / Content Contributor'],['instructor','Instructor'],['teacher','Teacher / Mentor'],['exhibitor','Exhibitor / Portfolio Showcase']].map(function(v){return h('option',{value:v[0],text:v[1]})}));
 var first=input('first_name','First name'),last=input('last_name','Last name'),phone=input('phone','Phone / WhatsApp number','tel'),country=input('country','Country'),region=input('region','State / region'),email=input('email',user.email||'','email');email.value=user.email||'';email.disabled=true;
 section('Your details','Tell us who you are. Your account email is attached automatically.');
 form.appendChild(h('div',{class:'academy-apply-grid'},[field('Application pathway',role,true),field('First name',first,true),field('Last name',last,true),field('Account email',email,true),field('Phone / WhatsApp',phone,true),field('Country',country),field('State / region',region)]));
 var specialty=input('specialty','Your field or area of expertise'),occupation=input('occupation','Current role / occupation'),portfolio=input('portfolio_url','Portfolio or website URL','url'),samples=area('work_sample_urls','Paste links to your best work, one link per line…'),experience=area('prior_experience','Describe your experience, skills, projects or teaching background…'),motivation=area('motivation','Why do you want to join CreatorVerse as a partner?'),contribution=area('learning_goals','What would you create, teach, mentor or exhibit on CreatorVerse?');
 section('Your work and experience','Share evidence that helps the team understand your work. A portfolio link is useful, but not compulsory if you provide sample links.');
 form.appendChild(h('div',{class:'academy-apply-grid'},[field('Specialty / subject area',specialty,true),field('Current role',occupation),field('Portfolio / website',portfolio),field('Work samples (one URL per line)',samples,true),field('Relevant experience',experience,true),field('Why CreatorVerse?',motivation,true),field('What you plan to contribute',contribution,true)]));
 var consent=h('input',{type:'checkbox',required:'required'}),label=h('label',{class:'academy-apply-consent'},[consent,h('span',{text:'I confirm that these details and work samples are mine or that I have permission to share them. I understand that submitting this application does not grant creator or instructor access. CreatorVerse administrators may review my work and invite me to an in-platform interview or practical assessment.'})]);
 form.append(label,submit,message);host.append(hero,form);
 form.addEventListener('submit',function(e){
  e.preventDefault();if(!first.value.trim()||!last.value.trim()||!phone.value.trim()||!specialty.value.trim()||!samples.value.trim()||!experience.value.trim()||!motivation.value.trim()||!contribution.value.trim()||!consent.checked){message.textContent='Complete all required fields and confirm the declaration.';message.className='academy-apply-notice error';return}
  var urls=samples.value.split(/\n+/).map(function(v){return v.trim()}).filter(Boolean);if(urls.some(function(v){try{var u=new URL(v);return !['http:','https:'].includes(u.protocol)}catch(e){return true}})){message.textContent='Use valid http or https links for each work sample.';message.className='academy-apply-notice error';return}
  submit.disabled=true;submit.textContent='Submitting…';message.textContent='Sending your application to the CreatorVerse review team…';message.className='academy-apply-notice';
  var full=[first.value.trim(),last.value.trim()].join(' ');
  var payload={user_id:user.id,course_id:courseId,application_type:role.value,status:'draft',first_name:first.value.trim(),last_name:last.value.trim(),phone:phone.value.trim(),country:country.value.trim()||null,region:region.value.trim()||null,occupation:occupation.value.trim()||null,specialty:specialty.value.trim(),portfolio_url:portfolio.value.trim()||null,work_sample_urls:urls.join('\n'),prior_experience:experience.value.trim(),motivation:motivation.value.trim(),learning_goals:contribution.value.trim(),proposed_level:'Professional',certificate_name:full,privacy_version:'creator-partner-2026-11',consented_at:new Date().toISOString()};
  sb.from('academy_applications').insert(payload).select('id').single().then(function(a){if(a.error)throw a.error;return sb.from('academy_applications').update({status:'submitted',submitted_at:new Date().toISOString()}).eq('id',a.data.id).select('application_no').single().then(function(done){if(done.error)throw done.error;return sb.from('academy_application_events').insert({application_id:a.data.id,actor_id:user.id,event_type:'creator_application_submitted',from_status:'draft',to_status:'submitted',message:'Creator / instructor application submitted by applicant'}).then(function(ev){if(ev.error)throw ev.error;return done.data})})})
   .then(function(done){form.textContent='';form.appendChild(h('div',{class:'academy-apply-success'},[h('span',{class:'academy-eyebrow',text:'APPLICATION RECEIVED'}),h('h2',{text:'Your application has been submitted.'}),h('p',{text:'Your reference number is '+done.application_no+'. The team will review your portfolio and may invite you to an in-platform interview or practical assessment. You do not receive creator permissions until the administrator approves your application and grants access.'}),h('a',{class:'btn btn-primary',href:'academy-status.html',text:'Track application status'}),h('a',{class:'btn btn-outline',href:'courses.html',text:'Explore courses as a learner'})]))})
   .catch(function(err){message.textContent=err.message||'Unable to submit your application. Please try again.';message.className='academy-apply-notice error';submit.disabled=false;submit.textContent='Submit creator application'})
 })
}
if(window.CV_SB)boot();else document.addEventListener('cv-ready',boot);
})();