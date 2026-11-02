(function(){
var D={hero:{visible:true,title:"Learn AI.\nCreate *Without Limits.*\nBuild Your Future.",text:"Discover practical AI skills, master creative tools, and develop the knowledge to turn your ideas into real opportunities.",
 primary:{label:"Explore Courses",url:"courses.html",visible:true},secondary:{label:"Watch Introduction",visible:true},
 video:{enabled:false,url:"",thumbnail:""},portrait:{url:"",visible:true,position:"right",style:"cutout"},
 founder:{visible:true,name:"Cletus Tech",designation:"Founder, CreatorVerse",description:""}},
 sections:[{id:"categories",type:"categories",visible:true,title:"Explore Learning Categories",subtitle:"Find the skill you want to build next."},
 {id:"courses",type:"courses",visible:true,title:"Featured Courses",subtitle:"",ids:[]},
 {id:"cta",type:"cta",visible:true,title:"Start learning today",text:"Create a free account and begin your first course.",label:"Get Started",url:"register.html"}]};
function isO(x){return x&&typeof x==='object'&&!Array.isArray(x)}
function merge(a,b){var o=JSON.parse(JSON.stringify(a));(function m(t,s){for(var k in s){if(isO(s[k])&&isO(t[k]))m(t[k],s[k]);else t[k]=s[k]}})(o,b||{});return o}
window.CV_HOME={D:D,merge:merge};
})();
