(function(){
var C=window.CV_CONFIG||{},pg=document.body.dataset.page,sb=null,
CDN='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js',
AUTH=['register','login','forgot','reset','dashboard','courses','course','lesson','admin','quiz','assignment','community','profile','ai'],
base=location.href.replace(/[?#].*$/,'').replace(/[^\/]*$/,''),
$=function(i){return document.getElementById(i)};
function msg(t,k){var m=$('msg');if(m){m.className='msg '+(k||'');m.textContent=t}}
function load(cb){if(window.supabase&&window.supabase.createClient)return cb();var urls=[CDN,'https://unpkg.com/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js'],i=0;function attempt(){if(window.supabase&&window.supabase.createClient)return cb();if(i>=urls.length){console.error('CreatorVerse: Supabase SDK could not be loaded from either CDN.');document.dispatchEvent(new Event('cv-sdk-error'));return}var s=document.createElement('script'),done=false,t=setTimeout(function(){if(done)return;done=true;s.remove();i++;attempt()},8000);s.src=urls[i];s.onload=function(){if(done)return;done=true;clearTimeout(t);if(window.supabase&&window.supabase.createClient)cb();else{i++;attempt()}};s.onerror=function(){if(done)return;done=true;clearTimeout(t);s.remove();i++;attempt()};document.head.appendChild(s)}attempt()}
function hasSession(){try{for(var k in localStorage)if(k.indexOf('sb-')===0)return true}catch(e){}return false}
function navState(s){document.querySelectorAll('a[href="login.html"]').forEach(function(a){a.textContent='Dashboard';a.href='dashboard.html'}); 
 sb.from('profiles').select('role').eq('id',s.user.id).maybeSingle().then(function(r){
  var role=r.data&&r.data.role;
  if(role==='admin'||role==='super_admin'){
   document.querySelectorAll('.nav-right,.mobile-menu').forEach(function(box){
    if(box.querySelector('a[href="admin.html"]'))return;
    var link=document.createElement('a');link.href='admin.html';link.textContent='Admin Panel';link.className='btn btn-primary cv-admin-nav';
    var logout=box.querySelector('a[href="#"]');if(logout)box.insertBefore(link,logout);else box.appendChild(link);
   });
   var bottom=document.querySelector('.bottom-nav');
   if(bottom&&!bottom.querySelector('a[href="admin.html"]')){var x=document.createElement('a');x.href='admin.html';x.textContent='Admin';x.className='cv-admin-bottom';bottom.appendChild(x)}
  }
 });
 document.querySelectorAll('a[href="register.html"]').forEach(function(a){a.textContent='Log out';a.href='#';a.addEventListener('click',function(e){e.preventDefault();sb.auth.signOut().then(function(){location.href='index.html'})})})}
function form(id,fn){var f=$(id);if(!f)return;f.addEventListener('submit',function(e){e.preventDefault();var b=f.querySelector('button');b.disabled=true;
 Promise.resolve(fn(new FormData(f))).catch(function(x){msg(x.message||'Something went wrong.','err')}).then(function(){b.disabled=false})})}
function oops(e,t){if(e){msg(/not confirmed/i.test(e.message)?'Please verify your email first. Check your inbox.':/invalid login/i.test(e.message)?'Wrong email or password.':e.message,'err');return true}}
function run(){
 sb=window.supabase.createClient(C.supabaseUrl,C.supabaseAnonKey);window.CV_SB=sb;document.dispatchEvent(new Event('cv-ready'));
 sb.auth.getSession().then(function(r){if(r.data.session)navState(r.data.session)});
 if(pg==='register')form('f',function(d){if(String(d.get('password')).length<8){msg('Password must be at least 8 characters.','err');return}
  return sb.auth.signUp({email:d.get('email'),password:d.get('password'),options:{data:{full_name:d.get('name')},emailRedirectTo:base+'login.html'}}).then(function(r){
   if(oops(r.error))return;if(r.data.user&&r.data.user.identities&&!r.data.user.identities.length){msg('This email is already registered. Try logging in.','err');return}
   msg('Account created. Check your email and click the verification link, then log in.','ok');$('f').reset()})});
 if(pg==='login')form('f',function(d){return sb.auth.signInWithPassword({email:d.get('email'),password:d.get('password')}).then(function(r){if(!oops(r.error))location.href='dashboard.html'})});
 if(pg==='forgot')form('f',function(d){return sb.auth.resetPasswordForEmail(d.get('email'),{redirectTo:base+'reset.html'}).then(function(r){if(!oops(r.error))msg('If that email has an account, a reset link is on its way.','ok')})});
 if(pg==='reset'){sb.auth.onAuthStateChange(function(ev){if(ev==='PASSWORD_RECOVERY'){$('f').style.display='block';msg('Enter your new password.','')}});
  form('f',function(d){if(String(d.get('password')).length<8){msg('Password must be at least 8 characters.','err');return}
   return sb.auth.updateUser({password:d.get('password')}).then(function(r){if(!oops(r.error)){msg('Password updated. Redirecting to login…','ok');setTimeout(function(){sb.auth.signOut().then(function(){location.href='login.html'})},1500)}})})}
 if(pg==='dashboard')sb.auth.getSession().then(function(r){var s=r.data.session;if(!s){location.href='login.html';return}window.CV_DASH(sb,s,{msg:msg,form:form,oops:oops})})}
if(AUTH.indexOf(pg)>-1&&!(C.supabaseUrl&&C.supabaseAnonKey)){var m=$('content');if(m)m.innerHTML='<h1>Accounts not configured</h1><div class="note">The site owner has not added the Supabase keys in config.js yet.</div><a class="btn btn-primary" href="index.html">Back to Home</a>';return}
if(C.supabaseUrl&&C.supabaseAnonKey&&(AUTH.indexOf(pg)>-1||hasSession()))load(run)
})();
