(function(){
var f=location.pathname.split('/').pop()||'index.html',q=location.search;
if(f==='category.html')f='learn.html';
var L=[['Home','index.html'],['Learn','learn.html'],['Community','soon.html?p=community'],['Resources','soon.html?p=resources'],['About','about.html']];
function act(h){return h===f+q||h===f&&h.indexOf('?')<0?' class="active"':''}
var links=L.map(function(l){return '<a href="'+l[1]+'"'+act(l[1])+'>'+l[0]+'</a>'}).join('');
var mob=L.map(function(l){return '<a href="'+l[1]+'">'+l[0]+'</a>'}).join('');
var logo='<svg viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20 2 L36 11 V29 L20 38 L4 29 V11 Z" stroke="#a87bff" stroke-width="1.6" fill="rgba(139,59,255,0.08)"/><circle cx="20" cy="20" r="6.5" stroke="#c9b3ff" stroke-width="1.6" fill="rgba(139,59,255,0.15)"/></svg>';
var h=document.getElementById('site-header');
if(h)h.outerHTML='<nav class="nav" id="nav"><a class="nav-left" href="index.html"><div class="logo-mark">'+logo+'</div><div class="brand-text"><span class="brand-name">CREATORVERSE <span>AI</span></span><span class="brand-sub">Powered by Cletus Tech</span></div></a><div class="nav-center">'+links+'</div><div class="nav-right"><a class="btn btn-ghost" href="login.html">Login</a><a class="btn btn-primary" href="register.html">Get Started</a><button class="menu-btn" id="menu-btn" aria-label="Open menu" aria-expanded="false"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg></button></div></nav><div class="mobile-menu" id="mobile-menu">'+mob+'<a class="btn btn-ghost" href="login.html">Login</a><a class="btn btn-primary" href="register.html">Get Started</a></div>';
var ft=document.getElementById('site-footer');
if(ft)ft.outerHTML='<footer class="footer"><div class="footer-in"><div><span class="brand-name" style="font-size:18px;font-weight:700">CREATORVERSE <span style="color:var(--electric-purple)">AI</span></span><p style="color:var(--soft-gray);font-size:14px;margin-top:8px;max-width:260px">Learn AI. Create without limits. Build your future.</p></div><div><h4>Explore</h4><a href="learn.html">Learn</a><a href="soon.html?p=community">Community</a><a href="soon.html?p=resources">Resources</a><a href="about.html">About</a></div><div><h4>Legal</h4><a href="legal.html?p=privacy">Privacy Policy</a><a href="legal.html?p=terms">Terms of Service</a></div><div id="footer-contact"></div></div><div class="copy">&copy; '+new Date().getFullYear()+' CreatorVerse AI. All rights reserved.</div></footer>';
var b=document.getElementById('menu-btn'),m=document.getElementById('mobile-menu');
if(b)b.addEventListener('click',function(){var o=m.classList.toggle('open');b.setAttribute('aria-expanded',o)});
})();
