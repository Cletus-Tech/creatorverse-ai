import { createClient } from "npm:@supabase/supabase-js@2";
const allowedOrigins=["https://creatorverse-ai.vercel.app","https://cletus-tech.github.io"];
function corsHeaders(origin:string){return {"Access-Control-Allow-Origin":allowedOrigins.includes(origin)?origin:"https://creatorverse-ai.vercel.app","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS","Vary":"Origin"}}
function reply(body:unknown,status=200,origin=""){return new Response(JSON.stringify(body),{status,headers:{...corsHeaders(origin),"Content-Type":"application/json"}})}
function tokens(v:string){return [...new Set(v.toLowerCase().replace(/[^a-z0-9\s]/g," ").split(/\s+/).filter(x=>x.length>2))]}
function score(q:string,item:{title:string;content:string;tags?:string[]}){const words=tokens(q),title=tokens(item.title),body=tokens(item.content),tags=(item.tags||[]).flatMap(tokens);return words.reduce((n,w)=>n+(title.includes(w)?6:0)+(tags.includes(w)?4:0)+(body.includes(w)?1:0),0)}
const general="You are CreatorVerse AI, a capable, thoughtful and practical general-purpose assistant. Understand intent, reason carefully, use conversation context, give direct useful answers and avoid unnecessary verbosity. Teach step by step, produce polished work and actionable plans. Never invent facts or claim actions you did not perform.";
const creator="You are the official CreatorVerse AI guide. Answer about CreatorVerse Academy, Marketplace, Affiliate Network, Realty, Business, Community, accounts, admin and platform features. Use supplied published knowledge as the source of truth. Never invent features, prices, courses, policies or release status. If unknown, say so. Help normally with general learning and creative requests.";
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get("Origin")||"",respond=(body:unknown,status=200)=>reply(body,status,origin);
 if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders(origin)});
 if(req.method!=="POST")return respond({error:"Method not allowed"},405);
 const auth=req.headers.get("Authorization");if(!auth?.startsWith("Bearer "))return respond({error:"Please sign in to use CreatorVerse AI."},401);
 try{
  const client=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_ANON_KEY")!,{global:{headers:{Authorization:auth}}});
  const {data:userData,error:userError}=await client.auth.getUser(auth.slice(7));if(userError||!userData.user)return respond({error:"Your session has expired. Please sign in again."},401);
  const p=await req.json(),question=String(p.question||"").trim().slice(0,8000),mode=p.mode==="creatorverse"?"creatorverse":"general",history=Array.isArray(p.history)?p.history.slice(-10).map((m:any)=>({role:m?.role==="assistant"?"assistant":"user",content:String(m?.content||"").slice(0,5000)})).filter((m:any)=>m.content):[],context=String(p.context||"").slice(0,1800);
  if(!question)return respond({error:"Type a question first."},400);
  const {data,error}=await client.from("cv_ai_knowledge").select("id,title,content,category,tags,visibility").eq("status","published").limit(180);
  if(error)return respond({error:"I couldn't access CreatorVerse's knowledge base.",detail:error.message},500);
  const ranked=(data||[]).map((x:any)=>({...x,relevance:score(question,x)})).filter((x:any)=>x.relevance>0).sort((a:any,b:any)=>b.relevance-a.relevance).slice(0,4);
  const key=Deno.env.get("AI_API_KEY")||Deno.env.get("OPENAI_API_KEY");if(!key)return respond({error:"Gemini API key is not configured in Supabase Edge Function secrets."},503);
  const base=(Deno.env.get("AI_BASE_URL")||"https://generativelanguage.googleapis.com/v1beta/openai").replace(/\/+$/,""),preferred=Deno.env.get("AI_MODEL")||"gemini-3.8-flash",models=[preferred,"gemini-3.7-flash","gemini-3.6-flash","gemini-3.5-flash-lite"].filter((x,i,a)=>a.indexOf(x)===i),knowledge=ranked.map((x:any)=>({title:x.title,category:x.category,content:String(x.content).slice(0,2500)}));
  const system=(mode==="creatorverse"?creator:general)+"\n\nCurrent website context (may be incomplete; never claim to control the page):\n"+context+"\n\nRelevant approved CreatorVerse knowledge:\n"+(knowledge.length?JSON.stringify(knowledge):"No matching excerpts. Do not fabricate platform-specific facts.");
  const messages=[{role:"system",content:system},...history,{role:"user",content:question}];
  let upstream:Response|null=null,lastStatus=0;
  for(let i=0;i<models.length;i++){
   const ctl=new AbortController(),timer=setTimeout(()=>ctl.abort(),25000);
   try{upstream=await fetch(base+"/chat/completions",{method:"POST",signal:ctl.signal,headers:{"Content-Type":"application/json","Authorization":"Bearer "+key},body:JSON.stringify({model:models[i],messages,max_tokens:1100,stream:p.stream===true})});}
   catch(e){clearTimeout(timer);console.error("AI request failed",String(e));if(i===models.length-1)return respond({error:"The AI provider did not respond in time. Please try again.",code:"AI_PROVIDER_TIMEOUT"},504);continue}
   clearTimeout(timer);if(upstream.ok)break;lastStatus=upstream.status;const detail=await upstream.text();console.error("AI provider error",models[i],lastStatus,detail.slice(0,800));if(![404,429,503].includes(lastStatus)||i===models.length-1){upstream=null;break}
   upstream=null;
  }
  if(!upstream)return respond({error:lastStatus===429||lastStatus===503?"Gemini is busy or its free-tier capacity is temporarily exhausted. Try again shortly.":lastStatus===401?"Gemini rejected the API key. Verify the key and its Google AI Studio project.":lastStatus===404?"The configured Gemini models are unavailable for this key.":"Gemini could not complete the request.",code:"AI_PROVIDER_ERROR",providerStatus:lastStatus},502);
  if(p.stream===true){if(!upstream.body)return respond({error:"The provider did not return a response stream."},502);return new Response(upstream.body,{status:200,headers:{...corsHeaders(origin),"Content-Type":"text/event-stream; charset=utf-8","Cache-Control":"no-cache, no-transform","Connection":"keep-alive","X-Accel-Buffering":"no"}})}
  const result=await upstream.json(),answer=result?.choices?.[0]?.message?.content?.trim();if(!answer)return respond({error:"Gemini returned an empty response. Try again."},502);
  return respond({answer,mode,model:preferred,sources:ranked.map((x:any)=>({id:x.id,title:x.title,category:x.category})),matched:ranked.length>0,usage:result.usage||null});
 }catch(e){console.error("CreatorVerse assistant error",e);return respond({error:"Something went wrong while generating your response.",code:"AI_INTERNAL_ERROR"},500)}
});