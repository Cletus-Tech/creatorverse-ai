(function(){
var C=window.CV_CONFIG||{},pg=document.body.dataset.page,sb=null,
CDN='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js',
AUTH=['register','login','forgot','reset','dashboard','courses','course','lesson','admin'],
base=location.href.replace(/[?#].*$/,'').replace(/[^\/]*$/,''),
$=function(i){return document.getElementById(i)};
function msg(t,k){var m=$('msg');if(m){m.className='msg '+(k||'');m.textContent=t}}
function load(cb){if(window.supabase)return cb();var s=document.createElement('script');s.src=CDN;s.onload=cb;document.head.appendChild(s)}
function hasSession(){try{for(var k in localStorage)if(k.indexOf('sb-')===0)return true}catch(e){}return false}
function navState(s){document.querySelectorAll('a[href="login.html"]').forEach(function(a){a.textContent='Dashboard';a.href='dashboard.html'});
 document.querySelectorAll('a[href="register.html"]').forEach(function(a){a.textContent='Log out';a.href='#';a.addEventListener('click',function(e){e.preventDefault();sb.auth.signOut().then(function(){location.href='index.html'})})})}
function form(id,fn){var f=$(id);if(!f)return;f.addEventListener('submit',function(e){e.preventDefault();var b=f.querySelector('button');b.disabled=true;
 Promise.resolve(fn(new FormData(f))).catch(function(x){msg(x.message||'Something went wrong.','err')}).then(function(){b.disabled=false})})}
function oops(e,t){if(e){msg(/not confirmed/i.test(e.message)?'Please verify your email first. Check your inbox.':/invalid login/i.test(e.message)?'Wrong email or password.':e.message,'err');return true}}
function run(){
 sb=window.supabase.createClient(C.supabaseUrl,C.supabaseAnonKey);window.CV_SB=sb;document.dispatchEvent(new Event('cv-ready'));
 sb.auth.getSession().then(function(r){if(r.data.session)navState()});
 if(pg==='register')form('f',function(d){if(String(d.get('password')).length<8){msg('Password must be at least 8 characters.','err');return}
  return sb.auth.signUp({email:d.get('email'),password:d.get('password'),options:{data:{full_name:d.get('name')},emailRedirectTo:base+'login.html'}}).then(function(r){
   if(oops(r.error))return;if(r.data.user&&r.data.user.identities&&!r.data.user.identities.length){msg('This email is already registered. Try logging in.','err');return}
   msg('Account created. Check your email and click the verification link, then log in.','ok');$('f').reset()})});
 if(pg==='login')form('f',function(d){return sb.auth.signInWithPassword({email:d.get('email'),password:d.get('password')}).then(function(r){if(!oops(r.error))location.href='dashboard.html'})});
 if(pg==='forgot')form('f',function(d){return sb.auth.resetPasswordForEmail(d.get('email'),{redirectTo:base+'reset.html'}).then(function(r){if(!oops(r.error))msg('If that email has an account, a reset link is on its way.','ok')})});
 if(pg==='reset'){sb.auth.onAuthStateChange(function(ev){if(ev==='PASSWORD_RECOVERY'){$('f').style.display='block';msg('Enter your new password.','')}});
  form('f',function(d){if(String(d.get('password')).length<8){msg('Password must be at least 8 characters.','err');return}
   return sb.auth.updateUser({password:d.get('password')}).then(function(r){if(!oops(r.error)){msg('Password updated. Redirecting to login…','ok');setTimeout(function(){sb.auth.signOut().then(function(){location.href='login.html'})},1500)}})})}
 if(pg==='dashboard')sb.auth.getSession().then(function(r){var s=r.data.session;if(!s){location.href='login.html';return}
  var u=s.user,name=(u.user_metadata&&u.user_metadata.full_name)||'',main=$('content');
  main.innerHTML='<div class="dash-head"><div class="avatar" id="av"></div><div><h1></h1><p id="who"></p><p><span class="chip" id="vf"></span><span class="chip" id="role"></span></p></div></div><div class="panels"><div class="panel"><h3>My Learning</h3><p id="learn">No courses yet.</p><a href="courses.html" class="alt">Browse courses</a></div><div class="panel"><h3>Certificates</h3><p>Certificates you earn will appear here.</p></div><div class="panel"><h3>Community</h3><p>The creator community is in development.</p></div><div class="panel"><h3>Projects</h3><p>Your published projects will appear here.</p></div></div><h2>Account settings</h2><form id="f"><label class="field" for="name">Full name</label><input id="name" name="name" required maxlength="80"><button class="btn btn-primary" type="submit">Save changes</button></form><div id="msg" class="msg"></div><button class="btn btn-outline" id="out" type="button" style="margin-top:26px">Log out</button>';
  main.querySelector('h1').textContent='Welcome'+(name?', '+name:'');$('name').value=name;
  $('who').textContent=u.email;$('vf').textContent=u.email_confirmed_at?'Email verified':'Email not verified';$('av').textContent=(name||u.email).trim().charAt(0).toUpperCase();
  sb.from('profiles').select('role').eq('id',u.id).maybeSingle().then(function(p){var ro=(p.data&&p.data.role)||'student';$('role').textContent=ro.replace('_',' ');if(ro==='admin'||ro==='super_admin')$('role').parentNode.appendChild(Object.assign(document.createElement('a'),{href:'admin.html',className:'chip',textContent:'Admin panel'}))});
  sb.from('enrolments').select('courses(title,slug)').then(function(e){var L=$('learn');if(!L||!e.data||!e.data.length)return;L.textContent='';e.data.forEach(function(x){if(!x.courses)return;var a=document.createElement('a');a.href='course.html?s='+encodeURIComponent(x.courses.slug);a.textContent=x.courses.title;a.style.display='block';L.appendChild(a)})});$('out').addEventListener('click',function(){sb.auth.signOut().then(function(){location.href='index.html'})});
  form('f',function(d){return sb.auth.updateUser({data:{full_name:d.get('name')}}).then(function(r){var m=$('msg');m.style.display='block';if(!oops(r.error)){msg('Saved.','ok');m.style.display='block';main.querySelector('h1').textContent='Welcome, '+d.get('name');$('av').textContent=String(d.get('name')).trim().charAt(0).toUpperCase()}})})})}
if(AUTH.indexOf(pg)>-1&&!(C.supabaseUrl&&C.supabaseAnonKey)){var m=$('content');if(m)m.innerHTML='<h1>Accounts not configured</h1><div class="note">The site owner has not added the Supabase keys in config.js yet.</div><a class="btn btn-primary" href="index.html">Back to Home</a>';return}
if(C.supabaseUrl&&C.supabaseAnonKey&&(AUTH.indexOf(pg)>-1||hasSession()))load(run)
})();
