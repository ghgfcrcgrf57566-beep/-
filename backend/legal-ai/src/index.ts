export interface Env {
  DB: D1Database;
  VECTOR_INDEX?: VectorizeIndex;
  AI: Ai;
  ALLOWED_APP_VERSION: string;
  MAX_QUESTION_CHARS: string;
  MAX_RESULTS: string;
  AI_MODEL: string;
  EMBEDDING_MODEL: string;
  REINDEX_TOKEN: string;
}
type Source={article_id:number;law_name:string;article_number:string;article_text:string;chapter?:string|null;score?:number};

const HEADERS={"content-type":"application/json; charset=utf-8","cache-control":"no-store","access-control-allow-origin":"*","access-control-allow-methods":"POST, OPTIONS","access-control-allow-headers":"content-type, x-app-version"};
const SYSTEM="أنت مساعد قانوني لموسوعة القوانين اليمنية. أجب بالعربية. اعتمد أولاً على المواد المسترجعة. لا تخترع قانوناً أو رقم مادة أو نصاً قانونياً. إذا كانت المواد غير كافية فقل ذلك بوضوح. فرّق بين النص القانوني والشرح. لا تقدّم الإجابة باعتبارها استشارة قانونية ملزمة.";

export default {async fetch(request:Request,env:Env):Promise<Response>{
  const url=new URL(request.url);
  if(request.method==="OPTIONS") return new Response(null,{status:204,headers:HEADERS});
  if(url.pathname==="/health") return json({ok:true,service:"yemen-laws-legal-ai"});
  if(url.pathname==="/admin/reindex"){
    if(request.method!=="POST") return json({error:"Method not allowed"},405);
    if(!env.REINDEX_TOKEN || request.headers.get("authorization")!=="Bearer "+env.REINDEX_TOKEN) return json({error:"Unauthorized"},401);
    const u=new URL(request.url);
    const after=Number(u.searchParams.get("after")||0);
    const limit=Math.min(Math.max(Number(u.searchParams.get("limit")||40),1),60);
    if(!env.VECTOR_INDEX) return json({error:"Vectorize is not configured."},503);
    const rows=await env.DB.prepare("SELECT id,law_id,number,body FROM mawad WHERE id>? ORDER BY id LIMIT ?").bind(after,limit).all<any>();
    const articles=rows.results||[];
    if(!articles.length) return json({done:true,next_after:after,processed:0});
    const embeddings=await env.AI.run(env.EMBEDDING_MODEL,{text:articles.map((a:any)=>String(a.body))}) as {data:number[][]};
    const vectors=articles.map((a:any,i:number)=>({id:String(a.id),values:embeddings.data[i]}));
    await env.VECTOR_INDEX.upsert(vectors);
    const next=Number(articles[articles.length-1].id);
    return json({done:articles.length<limit,next_after:next,processed:articles.length});
  }
  if(url.pathname!=="/api/legal/ask") return json({error:"Not found"},404);
  if(request.method!=="POST") return json({error:"Method not allowed"},405);

  const version=request.headers.get("x-app-version")||"";
  if(env.ALLOWED_APP_VERSION && version!==env.ALLOWED_APP_VERSION) return json({error:"نسخة التطبيق غير مدعومة حالياً."},403);
  if(!(await rateLimit(request,env))) return json({error:"تم تجاوز حد الاستخدام مؤقتاً. حاول لاحقاً."},429);

  try{
    const body=await request.json() as {question?:unknown;conversation_id?:unknown};
    const question=typeof body.question==="string"?body.question.trim():"";
    const max=Number(env.MAX_QUESTION_CHARS||1200);
    if(!question) return json({error:"السؤال فارغ."},400);
    if(question.length>max) return json({error:"السؤال أطول من الحد المسموح."},400);

    const sources=await retrieve(question,env);
    if(!sources.length) return json({answer:"لم أعثر على مواد قانونية كافية في قاعدة موسوعة القوانين اليمنية للإجابة عن هذا السؤال.",sources:[]});
    const answer=await generate(question,sources,env);
    return json({answer,sources,conversation_id:typeof body.conversation_id==="string"?body.conversation_id:crypto.randomUUID()});
  }catch(e){console.error(e);return json({error:"حدث خطأ داخلي أثناء معالجة السؤال."},500);}
}};

async function retrieve(q:string,env:Env){
  const limit=Math.min(Math.max(Number(env.MAX_RESULTS||8),3),12);
  const [semantic,lexical]=await Promise.all([semanticSearch(q,env,limit),lexicalSearch(q,env,limit)]);
  const map=new Map<number,Source>();
  for(const x of [...semantic,...lexical]){const old=map.get(x.article_id);if(!old||(x.score||0)>(old.score||0))map.set(x.article_id,x);}
  return [...map.values()].sort((a,b)=>(b.score||0)-(a.score||0)).slice(0,limit);
}
async function semanticSearch(q:string,env:Env,limit:number):Promise<Source[]>{
  if(!env.VECTOR_INDEX)return [];
  try{
    const emb=await env.AI.run(env.EMBEDDING_MODEL,{text:[q]}) as {data:number[][]};
    const vector=emb.data?.[0]; if(!vector)return [];
    const result=await env.VECTOR_INDEX.query(vector,{topK:limit,returnMetadata:"none"});
    const ids=(result.matches||[]).map((m:any)=>Number(m.id)).filter(Number.isFinite);
    if(!ids.length)return [];
    const ph=ids.map(()=>"?").join(",");
    const rows=await env.DB.prepare("SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter FROM mawad m JOIN laws l ON l.id=m.law_id LEFT JOIN fusul f ON f.id=m.fasl_id LEFT JOIN abwab b ON b.id=m.bab_id WHERE m.id IN ("+ph+")").bind(...ids).all<Source>();
    const scores=new Map((result.matches||[]).map((m:any)=>[Number(m.id),Number(m.score||0)]));
    return (rows.results||[]).map(r=>({...r,score:scores.get(r.article_id)||0}));
  }catch(e){console.error("semantic",e);return [];}
}
async function lexicalSearch(q:string,env:Env,limit:number):Promise<Source[]>{
  const terms=normalize(q).split(/\s+/).filter(x=>x.length>=2).slice(0,10);
  if(!terms.length)return [];
  const clauses=terms.map(()=>"(m.body LIKE ? OR m.number LIKE ? OR l.name LIKE ?)").join(" OR ");
  const args:string[]=[]; for(const t of terms)args.push("%"+t+"%","%"+t+"%","%"+t+"%");
  const rows=await env.DB.prepare("SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter FROM mawad m JOIN laws l ON l.id=m.law_id LEFT JOIN fusul f ON f.id=m.fasl_id LEFT JOIN abwab b ON b.id=m.bab_id WHERE "+clauses+" LIMIT 80").bind(...args).all<Source>();
  return (rows.results||[]).map(r=>{const hay=normalize(r.law_name+" "+r.article_number+" "+r.article_text);const hits=terms.reduce((n,t)=>n+(hay.includes(t)?1:0),0);return {...r,score:hits/terms.length};}).sort((a,b)=>(b.score||0)-(a.score||0)).slice(0,limit);
}
async function generate(q:string,sources:Source[],env:Env):Promise<string>{
  const context=sources.map((s,i)=>"[مصدر "+(i+1)+"] القانون: "+s.law_name+" | المادة: "+s.article_number+"\nالنص القانوني:\n"+s.article_text).join("\n\n");
  const prompt=SYSTEM+"\n\nالسؤال:\n"+q+"\n\nالمواد المسترجعة من قاعدة الموسوعة:\n"+context+"\n\nاكتب إجابة عربية واضحة. ابدأ بالجواب المباشر ثم اذكر المواد المستند إليها. إذا كانت غير كافية فلا تخمّن.";
  const out=await env.AI.run(env.AI_MODEL,{messages:[{role:"system",content:SYSTEM},{role:"user",content:prompt}],max_tokens:900,temperature:0.1}) as any;
  return typeof out?.response==="string"?out.response.trim():typeof out?.result?.response==="string"?out.result.response.trim():typeof out?.choices?.[0]?.message?.content==="string"?out.choices[0].message.content.trim():"تعذر توليد الإجابة من المواد المسترجعة.";
}
function normalize(v:string){return v.toLowerCase().replace(/[ً-ٟ]/g,"").replace(/[إأآٱ]/g,"ا").replace(/ى/g,"ي").replace(/ة/g,"ه").replace(/ـ/g,"").replace(/[^\u0600-\u06FF\w\s]/g," ").replace(/\s+/g," ").trim();}
async function rateLimit(request:Request,env:Env){
  const ip=request.headers.get("CF-Connecting-IP")||"unknown";
  const data=new TextEncoder().encode(ip);
  const digest=await crypto.subtle.digest("SHA-256",data);
  const key=[...new Uint8Array(digest)].map(b=>b.toString(16).padStart(2,"0")).join("");
  const bucket=Math.floor(Date.now()/60000);
  const row=await env.DB.prepare("SELECT count FROM ai_rate_limits WHERE key=? AND bucket=?").bind(key,bucket).first<{count:number}>();
  const count=(row?.count||0)+1;
  if(count>20)return false;
  await env.DB.prepare("INSERT INTO ai_rate_limits(key,bucket,count) VALUES(?,?,?) ON CONFLICT(key,bucket) DO UPDATE SET count=count+1").bind(key,bucket,1).run();
  await env.DB.prepare("DELETE FROM ai_rate_limits WHERE bucket<?").bind(bucket-2).run();
  return true;
}
function json(data:unknown,status=200){return new Response(JSON.stringify(data),{status,headers:HEADERS});}
