import {CAPACITIES,PHASES,fail,object,text,integer,scope,exact,options,relay} from './policy.mjs';
const encoder=new TextEncoder();
const random=()=>crypto.randomUUID().replaceAll('-','');
const now=()=>Date.now()/1000;
const b64=bytes=>btoa(String.fromCharCode(...bytes)).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
const decode=s=>Uint8Array.from(atob(s.replaceAll('-','+').replaceAll('_','/')),c=>c.charCodeAt(0));
const send=(ws,value)=>{try{ws.send(JSON.stringify(value));}catch{}};
export default {fetch(request,env){return env.DIRECTORY.get(env.DIRECTORY.idFromName('public-v1')).fetch(request);}};

// A single SQLite-backed Durable Object, supported on Workers Free. No game
// process, game packets, active timers, or paid TURN service is created here.
export class Directory {
  constructor(ctx,env){
    this.ctx=ctx;this.env=env;this.rooms=new Map();this.key=null;
    ctx.blockConcurrencyWhile(async()=>{
      let raw=await ctx.storage.get('signing-key');
      if(!raw){raw=crypto.getRandomValues(new Uint8Array(32));await ctx.storage.put('signing-key',raw);}
      this.key=await crypto.subtle.importKey('raw',raw,{name:'HMAC',hash:'SHA-256'},false,['sign','verify']);
      this.rooms=await ctx.storage.list({prefix:'room:'});
      this.rooms=new Map([...this.rooms].map(([k,v])=>[v.id,v]));
      ctx.storage.sql.exec('CREATE TABLE IF NOT EXISTS rate (ip TEXT PRIMARY KEY,tokens REAL,stamp REAL)');
      this.hydrate();
    });
  }
  hydrate(){
    for(const ws of this.ctx.getWebSockets()){
      const a=ws.deserializeAttachment();if(!a?.uid||a.peer!==1)continue;
      const room=this.rooms.get(a.room);if(room&&a.status)Object.assign(room,a.status);
    }
  }
  host(room){return this.peers(room).find(ws=>ws.deserializeAttachment().peer===1);}
  async sign(value){const data=b64(encoder.encode(JSON.stringify(value)));return data+'.'+b64(new Uint8Array(await crypto.subtle.sign('HMAC',this.key,encoder.encode(data))));}
  async verify(token,kind){
    try{
      const [data,signature]=token.split('.');
      if(!await crypto.subtle.verify('HMAC',this.key,decode(signature),encoder.encode(data)))fail(401,'다시 연결하세요.');
      const value=JSON.parse(new TextDecoder().decode(decode(data)));
      if(value.kind!==kind||value.exp<now())fail(401,'연결 시간이 만료되었습니다.');return value;
    }catch{fail(401,'다시 연결하세요.');}
  }
  async network(request){
    let ip=request.headers.get('CF-Connecting-IP')||'127.0.0.1';
    // Public addresses are grouped only when identical; IPv6 privacy addresses
    // on the same /64 share a LAN scope. The raw address is never in a token.
    if(ip.includes(':'))ip=ip.split(':').slice(0,4).join(':');
    else if(/^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(ip))ip=ip.split('.').slice(0,3).join('.');
    return b64(new Uint8Array(await crypto.subtle.sign('HMAC',this.key,encoder.encode(ip))));
  }
  rate(ip){
    const sql=this.ctx.storage.sql,t=now();
    const previous=[...sql.exec('SELECT tokens,stamp FROM rate WHERE ip=?',ip)][0]||{tokens:40,stamp:t};
    const tokens=Math.min(40,previous.tokens+(t-previous.stamp)*4);
    sql.exec('INSERT INTO rate VALUES (?,?,?) ON CONFLICT(ip) DO UPDATE SET tokens=excluded.tokens,stamp=excluded.stamp',ip,Math.max(0,tokens-1),t);
    if(tokens<1)fail(429,'요청이 너무 많습니다.');
  }
  origins(){return (this.env.ALLOWED_ORIGINS||'https://nukcanon.github.io').split(',');}
  public(r){return {id:r.id,...r.options,players:r.players,phase:r.phase,host_rtt:r.host_rtt,transport:'webrtc',version:this.env.GAME_VERSION};}
  async persist(r){await this.ctx.storage.put('room:'+r.id,r);}
  async sweep(){
    this.hydrate();
    for(const r of [...this.rooms.values()])if(now()-r.updated>45)await this.remove(r,'방 연결이 만료되었습니다.');
  }
  async remove(r,reason){
    this.rooms.delete(r.id);await this.ctx.storage.delete('room:'+r.id);
    for(const ws of this.peers(r.id)){send(ws,{op:'closed',reason});try{ws.close(1000);}catch{}}
  }
  async create(user,value,automatic=false){
    if(this.rooms.size>=Math.min(128,Number(this.env.MAX_ROOMS)||32))fail(503,'로비의 방 정원이 가득 찼습니다.');
    if([...this.rooms.values()].some(r=>r.owner===user.uid))fail(409,'이미 만든 방을 먼저 나가세요.');
    const r={id:random(),owner:user.uid,network:user.network,options:options(value),phase:'starting',updated:now(),players:1,host_rtt:null,next_peer:2,reservations:{},automatic};
    this.rooms.set(r.id,r);await this.persist(r);await this.armAlarm();return r;
  }
  async ice(uid){
    const result=[{urls:['stun:stun.cloudflare.com:3478']}];
    if(this.env.TURN_SECRET&&this.env.TURN_URLS){
      const username=Math.floor(now()+86400)+':'+uid;
      const key=await crypto.subtle.importKey('raw',encoder.encode(this.env.TURN_SECRET),{name:'HMAC',hash:'SHA-1'},false,['sign']);
      const credential=btoa(String.fromCharCode(...new Uint8Array(await crypto.subtle.sign('HMAC',key,encoder.encode(username)))));
      result.push({urls:this.env.TURN_URLS.split(','),username,credential});
    }
    return result;
  }
  async admission(r,user){
    if(r.options.scope==='lan'&&r.network!==user.network)fail(403,'같은 네트워크의 내부망 로비에서만 참가할 수 있습니다.');
    const peers=this.peers(r.id),owner=r.owner===user.uid;
    if(!owner&&!this.host(r.id))fail(409,'방장이 준비 중입니다.');
    if(peers.some(ws=>ws.deserializeAttachment().uid===user.uid))fail(409,'이미 참가한 방입니다.');
    r.reservations=Object.fromEntries(Object.entries(r.reservations).filter(([,v])=>v.exp>now()));
    if(!owner&&peers.length+Object.entries(r.reservations).filter(([uid])=>uid!==user.uid).length>=r.options.capacity)fail(409,'방이 가득 찼습니다.');
    const peer=owner?1:(r.reservations[user.uid]?.peer||r.next_peer++);
    const jti=random(),exp=now()+30;r.reservations[user.uid]={jti,peer,exp};await this.persist(r);
    const ticket=await this.sign({kind:'ticket',room:r.id,uid:user.uid,nick:user.nick,peer,jti,exp});
    return {ticket,room:this.public(r),peer,uid:user.uid,transport:'webrtc',signal_path:'/v1/signal',ice_servers:await this.ice(user.uid),automatic:r.automatic};
  }
  async body(request){
    const reader=request.body?.getReader();let size=0,bytes=[];
    if(!reader)return {};
    while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>4096){await reader.cancel();fail(413,'요청 크기 제한');}bytes.push(...value);}
    try{return object(JSON.parse(new TextDecoder().decode(new Uint8Array(bytes))));}catch(error){if(error.status)throw error;fail(422,'JSON 형식을 확인하세요.');}
  }
  async fetch(request){
    const headers={'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'};
    const origin=request.headers.get('Origin');
    if(origin&&this.origins().includes(origin))Object.assign(headers,{'Access-Control-Allow-Origin':origin,'Vary':'Origin','Access-Control-Allow-Headers':'Authorization, Content-Type','Access-Control-Allow-Methods':'GET, POST, OPTIONS'});
    try{
      if(origin&&!this.origins().includes(origin))fail(403,'허용되지 않은 웹 주소입니다.');
      if(request.method==='OPTIONS')return new Response(null,{status:204,headers});
      this.rate(await this.network(request));await this.sweep();
      const url=new URL(request.url),path=url.pathname;
      if(path==='/v1/signal'&&request.headers.get('Upgrade')?.toLowerCase()==='websocket'){
        if(this.ctx.getWebSockets().length>1100)fail(503,'연결 정원에 도달했습니다.');
        const pair=new WebSocketPair();this.ctx.acceptWebSocket(pair[1]);
        pair[1].serializeAttachment({opened:now(),tokens:150,stamp:now()});await this.armAlarm();
        return new Response(null,{status:101,webSocket:pair[0]});
      }
      if(path==='/health')return new Response(JSON.stringify({status:'ok',version:this.env.GAME_VERSION,role:'directory-only',rooms:this.rooms.size}),{headers});
      const data=request.method==='POST'?await this.body(request):null;
      let result;
      if(path==='/v1/sessions'&&data){
        exact(data,['nick','version']);text(data.nick,20);if(data.version!==this.env.GAME_VERSION)fail(409,'같은 게임 버전이 필요합니다: '+this.env.GAME_VERSION);
        const uid=random(),token=await this.sign({kind:'session',uid,nick:data.nick,network:await this.network(request),exp:now()+21600});
        result={token,uid,transport:'webrtc',ice_servers:await this.ice(uid)};
      }else{
        const auth=request.headers.get('Authorization')||'';if(!auth.startsWith('Bearer '))fail(401,'로비에 연결하세요.');
        const user=await this.verify(auth.slice(7),'session');
        if(path==='/v1/rooms'&&request.method==='GET'){
          const kind=scope(url.searchParams.get('scope')||'internet');
          result={rooms:[...this.rooms.values()].filter(r=>r.options.scope===kind&&(kind!=='lan'||r.network===user.network)).map(r=>this.public(r))};
        }else if(path==='/v1/rooms'&&data){result=this.public(await this.create(user,data));}
        else if(/^\/v1\/rooms\/[a-f0-9]+\/join$/.test(path)&&data){
          const r=this.rooms.get(path.split('/')[3]);if(!r)fail(404,'종료된 방입니다.');result=await this.admission(r,user);
        }else if(path==='/v1/match'&&data){
          exact(data,['mode','scope']);scope(data.scope);if(data.mode!=null)integer(data.mode,0,4);
          for(const r of this.rooms.values()){
            if(r.options.locked||r.options.scope!==(data.scope||'internet')||r.phase==='starting'||(data.mode!=null&&r.options.mode!==data.mode))continue;
            try{result=await this.admission(r,user);break;}catch(error){if(![403,409].includes(error.status))throw error;}
          }
          if(!result){const mode=data.mode??0;result=await this.admission(await this.create(user,{name:user.nick+'의 빠른 매치',mode,map:mode===4?19:13,scope:data.scope||'internet'},true),user);}
        }else fail(404,'지원하지 않는 요청입니다.');
      }
      return new Response(JSON.stringify(result),{headers});
    }catch(error){return new Response(JSON.stringify({detail:error.status?error.message:'서버 오류'}),{status:error.status||500,headers});}
  }
  async webSocketMessage(ws,message){
    let a=ws.deserializeAttachment();
    try{
      if(typeof message!=='string'||message.length>24000)fail(400,'신호 크기 제한');
      a.tokens=Math.min(150,a.tokens+(now()-a.stamp)*40)-1;a.stamp=now();if(a.tokens<0)fail(429,'신호 전송 제한');
      const data=object(JSON.parse(message));
      if(!a.uid){
        if(message.length>1024||now()-a.opened>10)fail(401,'연결 시간이 만료되었습니다.');
        const claim=await this.verify(String(data.ticket||''),'ticket');const r=this.rooms.get(claim.room);
        if(!r||r.reservations[claim.uid]?.jti!==claim.jti||(claim.peer!==1&&!this.host(r.id)))fail(401,'연결 승인이 만료되었습니다.');
        if(this.peers(r.id).some(p=>p.deserializeAttachment().peer===claim.peer))fail(409,'중복 연결');
        delete r.reservations[claim.uid];await this.persist(r);
        a={...a,uid:claim.uid,nick:claim.nick,peer:claim.peer,room:r.id};
        // Tags cannot change after acceptWebSocket: peer queries therefore scan
        // all attachments; at most 32 rooms / 1024 players on this free preset.
        if(a.peer===1){r.updated=now();a.status={updated:r.updated,phase:r.phase,players:1,host_rtt:null,options:r.options};}
        ws.serializeAttachment(a);send(ws,{op:'ready',peer:a.peer});
        if(a.peer!==1)send(this.host(r.id),{op:'peer',peer:a.peer,uid:a.uid,nick:a.nick});return;
      }
      const r=this.rooms.get(a.room);if(!r)fail(404,'종료된 방입니다.');
      if(data.op==='keepalive')send(ws,{op:'alive'});
      else if(data.op==='status'&&a.peer===1){
        if(PHASES.includes(data.phase)&&Number.isInteger(data.players)&&data.players>=1&&data.players<=r.options.capacity&&Number.isInteger(data.map)&&CAPACITIES[data.map]>=r.options.capacity&&(r.options.mode===4)===(data.map>=19)){
          Object.assign(r,{phase:data.phase,players:data.players,updated:now()});r.options.map=data.map;
          a.status={phase:r.phase,players:r.players,updated:r.updated,options:r.options,host_rtt:r.host_rtt};a.nonce=now();send(ws,{op:'ping',nonce:a.nonce});
        }
      }else if(data.op==='pong'&&a.peer===1&&data.nonce===a.nonce){r.host_rtt=Math.round((now()-a.nonce)*1000);a.status.host_rtt=r.host_rtt;}
      else{
        const peers=this.peers(r.id);const payload=relay(data,a.peer,peers.map(p=>p.deserializeAttachment().peer));
        if(payload)send(peers.find(p=>p.deserializeAttachment().peer===data.to),payload);
      }
      ws.serializeAttachment(a);
    }catch{try{ws.close(1008,'Invalid signaling request');}catch{}}
  }
  // Attachments are persisted by the hibernation API, without per-heartbeat KV writes.
  peers(room){return this.ctx.getWebSockets().filter(ws=>{const a=ws.deserializeAttachment();return a?.uid&&a.room===room;});}
  async webSocketClose(ws){
    const a=ws.deserializeAttachment();if(!a?.uid)return;
    const r=this.rooms.get(a.room);if(!r)return;
    if(a.peer===1)await this.remove(r,'방장이 방을 종료했습니다.');
    else send(this.host(r.id),{op:'left',peer:a.peer});
  }
  async webSocketError(ws){await this.webSocketClose(ws);}
  async armAlarm(){if(await this.ctx.storage.getAlarm()===null)await this.ctx.storage.setAlarm(Date.now()+30000);}
  async alarm(){
    await this.sweep();
    for(const ws of this.ctx.getWebSockets()){const a=ws.deserializeAttachment();if(!a.uid&&now()-a.opened>10)try{ws.close(1008);}catch{}}
    this.ctx.storage.sql.exec('DELETE FROM rate WHERE stamp<?',now()-300);
    if(this.rooms.size||this.ctx.getWebSockets().length)await this.ctx.storage.setAlarm(Date.now()+30000);
  }
}
