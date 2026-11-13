(function(){
'use strict';
if(document.getElementById('cv-global-search'))return;
var entries=[
 {title:'Academic',detail:'WAEC, NECO, GCE, JAMB and tertiary study',href:'academic.html',tags:'education school exams waec neco gce jamb university'},
 {title:'WAEC preparation',detail:'Secondary examination pathway',href:'academic-exam.html?exam=waec',tags:'waec exam'},
 {title:'NECO preparation',detail:'Secondary examination pathway',href:'academic-exam.html?exam=neco',tags:'neco exam'},
 {title:'GCE preparation',detail:'General Certificate of Education',href:'academic-exam.html?exam=gce',tags:'gce exam'},
 {title:'JAMB preparation',detail:'University entrance examination pathway',href:'academic-exam.html?exam=jamb',tags:'jamb utme exam'},
 {title:'Tertiary academics',detail:'University and higher-institution learning',href:'academic-tertiary.html',tags:'university polytechnic college faculty department semester'},
 {title:'Digital Skills',detail:'Practical creative, technology and business skills',href:'digital-skills.html',tags:'skills ai design coding business creative'},
 {title:'Courses',detail:'Browse available courses and learning paths',href:'courses.html',tags:'lessons training modules academy'},
 {title:'Housing',detail:'Campus accommodation and roommate matching',href:'campus-housing.html',tags:'hostel lodge rent roommate accommodation'},
 {title:'Marketplace',detail:'Buy and sell, campus vendors and student services',href:'marketplace.html',tags:'shop products sellers vendors services rentals'},
 {title:'Campus Life',detail:'Student services and campus resources',href:'campus.html',tags:'campus errands study student life'},
 {title:'Community',detail:'Posts, discussions and creator connections',href:'community.html',tags:'social posts groups people'},
 {title:'Messages',detail:'Private conversations and stories',href:'messages.html',tags:'chat inbox stories communication'},
 {title:'Dashboard',detail:'Your account and learning activity',href:'dashboard.html',tags:'profile account progress'},
 {title:'Notifications',detail:'Your latest CreatorVerse updates',href:'notifications.html',tags:'alerts updates'},
 {title:'CreatorVerse AI',detail:'Get help navigating the platform',href:'ai.html',tags:'assistant help ai'}
];
var css=document.createElement('link');css.rel='stylesheet';css.href='unified-search.css?v=20261113-1';document.head.appendChild(css);
var wrap=document.createElement('div');wrap.id='cv-global-search';wrap.className='cv-search-overlay';wrap.hidden=true;
wrap.innerHTML='<div class="cv-search-backdrop" data-search-close></div><section class="cv-search-dialog" role="dialog" aria-modal="true" aria-labelledby="cv-search-title"><header><div><span>CREATORVERSE</span><h2 id="cv-search-title">Find your next step.</h2></div><button type="button" class="cv-search-close" aria-label="Close search" data-search-close>×</button></header><label class="cv-search-input-wrap"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><path d="m16 16 5 5"></path></svg><input id="cv-search-input" type="search" autocomplete="off" placeholder="Search spaces, courses and tools" aria-label="Search CreatorVerse"><kbd>ESC</kbd></label><div class="cv-search-meta"><span id="cv-search-count">POPULAR DESTINATIONS</span><span>↑ ↓ to navigate · Enter to open</span></div><div id="cv-search-results" class="cv-search-results"></div><footer><span>CreatorVerse · One connected platform</span><span>Ctrl K / ⌘ K</span></footer></section>';
document.body.appendChild(wrap);
var input=wrap.querySelector('#cv-search-input'),results=wrap.querySelector('#cv-search-results'),count=wrap.querySelector('#cv-search-count'),trigger=null,active=0,lastFocus=null;
function render(q){
 var term=(q||'').trim().toLowerCase(),found=entries.filter(function(x){return !term||(x.title+' '+x.detail+' '+x.tags).toLowerCase().includes(term)}).slice(0,9);
 active=0;count.textContent=term?found.length+' RESULTS':'POPULAR DESTINATIONS';
 results.innerHTML='';
 if(!found.length){var empty=document.createElement('div');empty.className='cv-search-empty';empty.textContent='No matching CreatorVerse destinations. Try another keyword.';results.appendChild(empty);return}
 found.forEach(function(item,i){var a=document.createElement('a');a.className='cv-search-result'+(i===0?' is-active':'');a.href=item.href;a.dataset.index=String(i);var copy=document.createElement('span');copy.className='cv-search-result-copy';var title=document.createElement('strong');title.textContent=item.title;var detail=document.createElement('small');detail.textContent=item.detail;copy.append(title,detail);var arrow=document.createElement('b');arrow.textContent='↗';a.append(copy,arrow);a.addEventListener('mouseenter',function(){setActive(i)});a.addEventListener('click',close);results.appendChild(a)});
}
function setActive(i){var links=results.querySelectorAll('a');if(!links.length)return;active=Math.max(0,Math.min(i,links.length-1));links.forEach(function(a,n){a.classList.toggle('is-active',n===active)});links[active].scrollIntoView({block:'nearest'})}
function open(){lastFocus=document.activeElement;wrap.hidden=false;document.body.classList.add('cv-search-open');render('');input.value='';setTimeout(function(){input.focus()},20)}
function close(){if(wrap.hidden)return;wrap.hidden=true;document.body.classList.remove('cv-search-open');if(lastFocus&&lastFocus.focus)lastFocus.focus()}
document.querySelectorAll('.cv-search-trigger').forEach(function(b){trigger=b;b.addEventListener('click',open)});
wrap.querySelectorAll('[data-search-close]').forEach(function(b){b.addEventListener('click',close)});
input.addEventListener('input',function(){render(input.value)});
input.addEventListener('keydown',function(e){var links=results.querySelectorAll('a');if(e.key==='ArrowDown'){e.preventDefault();setActive(active+1)}else if(e.key==='ArrowUp'){e.preventDefault();setActive(active-1)}else if(e.key==='Enter'&&links[active]){e.preventDefault();links[active].click()}});
document.addEventListener('keydown',function(e){if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='k'){e.preventDefault();if(wrap.hidden)open();else close()}else if(e.key==='Escape'&&!wrap.hidden)close()});
})();
