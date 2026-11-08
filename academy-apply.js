(function(){
function h(t,a,children){var e=document.createElement(t);Object.keys(a||{}).forEach(function(k){if(k==='text')e.textContent=a[k];else e.setAttribute(k,a[k])});(children||[]).forEach(function(x){if(x)e.appendChild(x)});return e}
var host=document.getElementById('content'),params=new URLSearchParams(location.search),slug=params.get('course');
function notice(t,bad){var n=h('div',{class:'academy-apply-notice'+(bad?' error':'')});n.textContent=t;return n}
function field(label,node,required){var l=h('label',{class:'academy-apply-field'},[h('span',{text:label+(required?' *':'')})]);l.appendChild(node);return l}
function input(name,placeholder,type){return h('input',{name:name,placeholder:placeholder||'',type:type||'text'})}
function textarea(name,placeholder){return h('textarea',{name:name,placeholder:placeholder||'',rows:'4'})}
function start(){
 var sb=window.CV_SB;if(!sb){host.textContent='Authentication is still loading. Please refresh this page.';return}
 sb.auth.getUser().then(function(ur){
  var user=ur.data&&ur.data.user;
  if(!user){host.textContent='';host.appendChild(h('section',{class:'academy-apply-card'},[h('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY'}),h('h1',{text:'Apply for admission'}),h('p',{text:'Sign in to your CreatorVerse account before starting an Academy application.'}),h('a',{class:'btn btn-primary',href:'login.html',text:'Sign in to continue'})]));return}
  if(!slug){host.textContent='';var wrap=h('section',{class:'academy-apply-card'},[h('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · ADMISSIONS'}),h('h1',{text:'Choose a course to apply for'}),h('p',{text:'Select the learning pathway you want to join. Your application and admission updates will stay connected to your student account.'})]);host.appendChild(wrap);sb.from('courses').select('id,title,slug,description,thumbnail_url,price_ngn,level').eq('published',true).order('title').then(function(cr){if(cr.error){wrap.appendChild(notice('Courses could not be loaded. Please refresh and try again.',true));return}var grid=h('div',{class:'academy-apply-course-grid'});(cr.data||[]).forEach(function(c){grid.appendChild(h('article',{class:'academy-apply-course-option'},[c.thumbnail_url?h('img',{src:c.thumbnail_url,alt:c.title}):null,h('h2',{text:c.title}),h('p',{text:c.description||'Practical learning with CreatorVerse Academy.'}),h('span',{class:'academy-apply-course-tag',text:Number(c.price_ngn)>0?'₦'+Number(c.price_ngn).toLocaleString('en-NG'):'Free'}),h('a',{class:'btn btn-primary',href:'academy-apply.html?course='+encodeURIComponent(c.slug),text:'Apply for this course'})]))});if(!(cr.data||[]).length)grid.appendChild(notice('There are no published courses accepting applications at the moment.',false));wrap.appendChild(grid)});return;}
  sb.from('courses').select('id,title,slug,description,thumbnail_url,price_ngn,level').eq('slug',slug||'').eq('published',true).maybeSingle().then(function(cr){
   if(cr.error||!cr.data){host.textContent='';host.appendChild(notice('This course is not available for applications yet.',true));return}
   var course=cr.data;sb.from('academy_applications').select('id,status,application_no').eq('user_id',user.id).eq('course_id',course.id).order('created_at',{ascending:false}).limit(1).maybeSingle().then(function(ar){if(ar.error){host.textContent='';host.appendChild(notice('We could not verify your existing application. Please open your Academy status page before trying again.',true));host.appendChild(h('a',{class:'btn btn-outline',href:'academy-status.html',text:'Open admission status'}));return}if(ar.data){host.textContent='';host.appendChild(h('section',{class:'academy-apply-card'},[h('span',{class:'academy-eyebrow',text:'APPLICATION ALREADY EXISTS'}),h('h1',{text:'You have already applied for this course.'}),h('p',{text:'Application reference: '+ar.data.application_no+'. Your current status is '+String(ar.data.status||'submitted').replace(/_/g,' ')+'. You do not need to submit another application.'}),h('a',{class:'btn btn-primary',href:'academy-status.html',text:'View application status'})]));return}render(sb,user,course)})
  })
 })
}
function render(sb,user,course){
 host.textContent='';
 var hero=h('section',{class:'academy-apply-hero'},[h('div',{},[h('span',{class:'academy-eyebrow',text:'CREATORVERSE ACADEMY · ADMISSIONS'}),h('h1',{text:'Your learning journey starts here.'}),h('p',{text:'Tell us about your goals and experience. Our team will review your application and confirm the right entry level.'}),h('span',{class:'academy-apply-course-tag',text:course.title})]),course.thumbnail_url?h('img',{src:course.thumbnail_url,alt:course.title+' course artwork'}):null]);
 var form=h('form',{class:'academy-apply-form'}),message=h('div'),questionsBox=h('section',{class:'academy-apply-section'}),questionFields=[];
 function section(title,desc){form.appendChild(h('div',{class:'academy-apply-section-head'},[h('h2',{text:title}),h('p',{text:desc})]))}
 section('Applicant information','Use your real details. Your account email is attached automatically.');
 var email=input('email',user.email,'email');email.value=user.email||'';email.disabled=true;
 var first=input('first_name','First name'),middle=input('middle_name','Middle name'),last=input('last_name','Last name');
 var phone=input('phone','Phone / WhatsApp number','tel'),country=input('country','Country'),region=input('region','State / region');
 var grid=h('div',{class:'academy-apply-grid'},[field('First name',first,true),field('Middle name',middle),field('Last name',last,true),field('Account email',email,true),field('Phone number',phone),field('Country',country),field('State / region',region)]);
 form.appendChild(grid);
 section('Your background','Help us understand your current experience and learning objectives.');
 var education=h('select',{},['Select education level','Secondary school','Diploma / Certificate','Undergraduate','Graduate','Postgraduate','Other'].map(function(x,i){return h('option',{value:i?x:'',text:x})}));
 var occupation=input('occupation','Occupation (optional)'),experience=textarea('prior_experience','Describe what you have learned or built so far…'),portfolio=input('portfolio_url','Portfolio, website or work sample URL','url'),motivation=textarea('motivation','Why do you want to study this course?'),goals=textarea('learning_goals','What do you want to be able to do after this programme?');
 var background=h('div',{class:'academy-apply-grid'},[field('Highest education',education),field('Occupation',occupation),field('Prior experience',experience),field('Portfolio / work sample',portfolio),field('Motivation',motivation,true),field('Learning goals',goals,true)]);
 form.appendChild(background);
 section('Proposed entry level','Choose the level you believe best describes your current ability. The Academy confirms your final placement after reviewing your evidence.');
 var proposed=h('select',{},['Beginner','Foundation','Intermediate','Advanced','Professional'].map(function(x){return h('option',{value:x,text:x})}));proposed.value=course.level||'Beginner';
 form.appendChild(field('Your proposed level',proposed,true));
 section('Course diagnostic','Answer the course-specific questions below. If no diagnostic questions are published yet, this section will be skipped.');
 form.appendChild(questionsBox);
 var consent=h('input',{type:'checkbox',required:'required'}),consentLabel=h('label',{class:'academy-apply-consent'},[consent,h('span',{text:'I confirm that the information provided is accurate and agree that CreatorVerse Academy may use it to review this application and contact me about admission. I understand that submitting an application does not guarantee admission or course access.'})]);
 form.appendChild(consentLabel);
 var submit=h('button',{class:'btn btn-primary academy-apply-submit',type:'submit',text:'Submit application'});form.appendChild(submit);form.appendChild(message);
 host.append(hero,form);
 sb.from('academy_diagnostic_questions').select('id,prompt,response_type,options,required,position').eq('course_id',course.id).eq('published',true).eq('active',true).order('position').then(function(qr){
  if(qr.error){questionsBox.appendChild(notice('The diagnostic is temporarily unavailable. You can still submit the application and complete the diagnostic when it is enabled.',false));return}
  var qs=qr.data||[];if(!qs.length){questionsBox.appendChild(h('p',{class:'academy-apply-muted',text:'No diagnostic questions are required at this stage.'}));return}
  qs.forEach(function(q){
   var node;if(q.response_type==='single_choice'){node=h('select',{},(q.options||[]).map(function(o){var v=typeof o==='string'?o:o.value;var label=typeof o==='string'?o:o.label;return h('option',{value:v,text:label})}));node.insertBefore(h('option',{value:'',text:'Choose an answer'}),node.firstChild)}
   else node=q.response_type==='short_text'?input('','Your answer'):q.response_type==='url'?input('','https://…','url'):textarea('','Write your answer…');
   if(q.required)node.required=true;
   var wrap=field(q.prompt,node,q.required);questionsBox.appendChild(wrap);questionFields.push({id:q.id,node:node,required:q.required,type:q.response_type})
  })
 });
 form.addEventListener('submit',function(e){
  e.preventDefault();message.textContent='Saving your application…';message.className='academy-apply-notice';submit.disabled=true;
  if(!first.value.trim()||!last.value.trim()||!motivation.value.trim()||!goals.value.trim()){message.textContent='Please complete all required fields.';message.className='academy-apply-notice error';submit.disabled=false;return}
  var missing=questionFields.some(function(q){return q.required&&!q.node.value.trim()});if(missing){message.textContent='Please answer each required diagnostic question.';message.className='academy-apply-notice error';submit.disabled=false;return}
  sb.from('academy_applications').select('id,status').eq('user_id',user.id).eq('course_id',course.id).in('status',['draft']).order('created_at',{ascending:false}).limit(1).maybeSingle().then(function(existing){
   if(existing.error)throw existing.error;
   var payload={user_id:user.id,course_id:course.id,status:'draft',first_name:first.value.trim(),middle_name:middle.value.trim()||null,last_name:last.value.trim(),phone:phone.value.trim()||null,country:country.value.trim()||null,region:region.value.trim()||null,education_level:education.value||null,occupation:occupation.value.trim()||null,prior_experience:experience.value.trim()||null,portfolio_url:portfolio.value.trim()||null,motivation:motivation.value.trim(),learning_goals:goals.value.trim(),proposed_level:proposed.value,certificate_name:[first.value,middle.value,last.value].filter(Boolean).join(' '),privacy_version:'academy-admissions-2026-11',consented_at:new Date().toISOString()};
   var save=existing.data?sb.from('academy_applications').update(payload).eq('id',existing.data.id).select('id').single():sb.from('academy_applications').insert(payload).select('id').single();
   return save.then(function(a){if(a.error)throw a.error;var appId=a.data.id;var responses=questionFields.map(function(q){return{application_id:appId,question_id:q.id,response_text:q.node.value.trim()||null,response_url:q.type==='url'?q.node.value.trim()||null:null}}).filter(function(x){return x.response_text||x.response_url});
    var chain=responses.length?sb.from('academy_diagnostic_responses').upsert(responses,{onConflict:'application_id,question_id'}):Promise.resolve({error:null});
    return Promise.resolve(chain).then(function(rr){if(rr.error)throw rr.error;return sb.from('academy_applications').update({status:'submitted',submitted_at:new Date().toISOString()}).eq('id',appId).select('application_no').single().then(function(done){if(done.error)throw done.error;return sb.from('academy_application_events').insert({application_id:appId,actor_id:user.id,event_type:'submitted',from_status:'draft',to_status:'submitted',message:'Application submitted by applicant'}).then(function(ev){if(ev.error)throw ev.error;return done.data})})})
   })
  }).then(function(done){form.textContent='';form.appendChild(h('div',{class:'academy-apply-success'},[h('span',{class:'academy-eyebrow',text:'APPLICATION RECEIVED'}),h('h2',{text:'Your application has been submitted.'}),h('p',{text:'Your reference number is '+done.application_no+'. The Academy team will review your information and contact you with the next step. Submitting this form does not create an enrolment or unlock course lessons.'}),h('a',{class:'btn btn-primary',href:'academy-status.html',text:'Track my admission status'}),h('a',{class:'btn btn-outline',href:'courses.html',text:'Explore more courses'})]))}).catch(function(err){message.textContent=err.message||'Unable to submit application. Please try again.';message.className='academy-apply-notice error';submit.disabled=false})
 })
}
if(window.CV_SB)start();else document.addEventListener('cv-ready',start);
})();