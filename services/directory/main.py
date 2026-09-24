"""Lightweight room directory/signaling. No game processes or combat packets.

One ASGI worker owns ephemeral rooms. Restarting the directory removes the room
list and may end admissions/matches during graceful shutdown. Never log tickets.
"""
import asyncio
import base64
import contextlib
import hashlib
import hmac
import ipaddress
import json
import os
import secrets
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, model_validator

VERSION = os.getenv("GAME_VERSION", "1.1.0")
CAPACITIES = [32,32,16,16,16,32,16,6,6,6,6,6,6,8,8,8,8,8,8]+[8]*6+[12]*6

class SessionInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    nick: str = Field(min_length=1, max_length=20)
    version: str = Field(max_length=20)

class RoomInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    name: str = Field(default="공개 경기", min_length=1, max_length=40)
    mode: int = Field(default=0, ge=0, le=4)
    map: int = Field(default=13, ge=0, le=30)
    capacity: int = Field(default=8, ge=2, le=32)
    map_random: bool = True
    map_rotation: bool = False
    rounds: int = Field(default=0, ge=0, le=100)
    prep_seconds: int = Field(default=45, ge=30, le=60)
    scope: str = Field(default="internet", pattern="^(internet|lan)$")
    locked: bool = False

    @model_validator(mode="after")
    def check_map(self):
        if self.capacity % 2 or self.capacity > CAPACITIES[self.map]:
            raise ValueError("맵 정원 이내의 짝수 인원이 필요합니다.")
        if (self.mode == 4) != (self.map >= 19) or (self.mode == 4 and self.capacity > 12):
            raise ValueError("설치·해체는 12인 이하 전용 맵이 필요합니다.")
        return self

class MatchInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    mode: int | None = Field(default=None, ge=0, le=4)
    scope: str = Field(default="internet", pattern="^(internet|lan)$")

def ice_servers(uid):
    servers = [{"urls": ["stun:stun.cloudflare.com:3478"]}]
    urls = [x.strip() for x in os.getenv("TURN_URLS", "").split(",") if x.strip()]
    secret = os.getenv("TURN_SECRET", "")
    if urls and secret:
        username = f"{int(time.time())+86400}:{uid}"
        credential = base64.b64encode(hmac.new(secret.encode(), username.encode(), hashlib.sha1).digest()).decode()
        servers.append({"urls": urls, "username": username, "credential": credential})
    return servers

class Directory:
    def __init__(self):
        self.sessions = {}; self.rooms = {}; self.tickets = {}; self.buckets = {}
        self.limit = min(512, max(1, int(os.getenv("MAX_ROOMS", "128"))))
        self.salt=secrets.token_bytes(32)

    def network(self, request):
        value=request.headers.get("x-real-ip",request.client.host) if os.getenv("TRUST_PROXY")=="1" else request.client.host
        try:
            address=ipaddress.ip_address(value)
            value=str(ipaddress.ip_network(f"{address}/{24 if address.version==4 else 64}",strict=False)) if address.is_private else str(address)
        except ValueError:value=request.client.host
        return hmac.new(self.salt,value.encode(),hashlib.sha256).hexdigest()

    def allow(self, key, rate=4., burst=40.):
        now = time.monotonic(); tokens, before = self.buckets.get(key, (burst, now))
        tokens = min(burst, tokens + (now-before)*rate)
        self.buckets[key] = (max(0.,tokens-1),now)
        return tokens >= 1

    def authenticate(self, request):
        auth = request.headers.get("authorization", "")
        session = self.sessions.get(hashlib.sha256(auth.removeprefix("Bearer ").encode()).hexdigest())
        if not auth.startswith("Bearer ") or not session or session["expires"] < time.time():
            raise HTTPException(401, "로비에 다시 연결하세요.")
        return session

    def create(self, user, options, automatic=False):
        if len(self.rooms) >= self.limit: raise HTTPException(503, "로비의 방 정원이 가득 찼습니다.")
        if any(r["owner"] == user["uid"] for r in self.rooms.values()):
            raise HTTPException(409, "이미 만든 방을 먼저 나가세요.")
        now = time.time(); room_id = secrets.token_hex(12)
        room = {"id":room_id,"owner":user["uid"],"options":options.model_dump(),"phase":"starting",
                "updated":now,"created":now,"peers":{},"reservations":{},"next_peer":2,
                "host_rtt":None,"players":1,"automatic":automatic,"ping_sent":0.,"network":user["network"]}
        self.rooms[room_id] = room
        return room

    def public(self, room):
        return {"id":room["id"], **room["options"], "players":room["players"],"phase":room["phase"],
                "host_rtt":room["host_rtt"],"transport":"webrtc","version":VERSION}

    def admission(self, room, user):
        if room["options"]["scope"]=="lan" and room["network"]!=user["network"]:
            raise HTTPException(403,"같은 네트워크의 내부망 로비에서만 참가할 수 있습니다.")
        owner = room["owner"] == user["uid"]
        if not owner and 1 not in room["peers"]:raise HTTPException(409, "방장이 준비 중입니다.")
        if any(peer["uid"] == user["uid"] for peer in room["peers"].values()):
            raise HTTPException(409, "이미 연결된 참가자입니다.")
        now = time.time()
        occupied = len(room["peers"]) + sum(exp>now for uid,(exp,_) in room["reservations"].items() if uid!=user["uid"])
        if not owner and occupied >= room["options"]["capacity"]:raise HTTPException(409, "방이 가득 찼습니다.")
        peer = 1 if owner else room["reservations"].get(user["uid"], (0,room["next_peer"]))[1]
        if peer == room["next_peer"]:room["next_peer"] += 1
        # Replace any previous unconsumed ticket for this session/room.
        for key,value in list(self.tickets.items()):
            if value["room"]==room["id"] and value["uid"]==user["uid"]:self.tickets.pop(key)
        ticket = secrets.token_hex(32)
        self.tickets[hashlib.sha256(ticket.encode()).hexdigest()] = {"room":room["id"],"uid":user["uid"],"nick":user["nick"],"peer":peer,"expires":now+30}
        room["reservations"][user["uid"]] = (now+30,peer)
        return {"ticket":ticket,"room":self.public(room),"peer":peer,"uid":user["uid"],
                "transport":"webrtc","signal_path":"/v1/signal","ice_servers":ice_servers(user["uid"]),"automatic":room["automatic"]}

    async def close_room(self, room):
        self.rooms.pop(room["id"], None)
        for peer in list(room["peers"].values()):
            with contextlib.suppress(Exception):
                await peer["socket"].send_json({"op":"closed","reason":"방장이 방을 종료했습니다."})
                await peer["socket"].close(code=1000)

    async def sweep(self):
        now=time.time()
        self.sessions={k:v for k,v in self.sessions.items() if v["expires"]>now}
        self.tickets={k:v for k,v in self.tickets.items() if v["expires"]>now}
        self.buckets={k:v for k,v in self.buckets.items() if time.monotonic()-v[1]<300}
        for room in list(self.rooms.values()):
            room["reservations"]={uid:v for uid,v in room["reservations"].items() if v[0]>now}
            if now-room["updated"]>45:await self.close_room(room)

directory=Directory()
@asynccontextmanager
async def lifespan(app):
    async def maintenance():
        while True:await asyncio.sleep(10);await directory.sweep()
    task=asyncio.create_task(maintenance())
    yield
    task.cancel()
    with contextlib.suppress(asyncio.CancelledError):await task
    for room in list(directory.rooms.values()):await directory.close_room(room)

app=FastAPI(title="Internal N Crush Room Directory",lifespan=lifespan)
origins=os.getenv("ALLOWED_ORIGINS","https://nukcanon.github.io,http://127.0.0.1:8088,http://localhost:8088").split(",")
app.add_middleware(CORSMiddleware,allow_origins=origins,allow_methods=["GET","POST","OPTIONS"],allow_headers=["Authorization","Content-Type"])

@app.middleware("http")
async def limits(request:Request,call_next):
    from fastapi.responses import JSONResponse
    # The trusted reverse proxy overwrites X-Real-IP; direct deployments use socket IP.
    ip=request.headers.get("x-real-ip",request.client.host) if os.getenv("TRUST_PROXY")=="1" else request.client.host
    if not directory.allow("ip:"+ip):return JSONResponse({"detail":"요청이 너무 많습니다."},status_code=429)
    if request.method=="POST":
        chunks=[];length=0
        async for chunk in request.stream():
            length+=len(chunk)
            if length>4096:return JSONResponse({"detail":"요청 크기 제한"},status_code=413)
            chunks.append(chunk)
        request._body=b"".join(chunks)
    response=await call_next(request);response.headers["Cache-Control"]="no-store";return response

@app.get("/health")
async def health():return {"status":"ok","version":VERSION,"role":"directory-only","rooms":len(directory.rooms)}

@app.post("/v1/sessions")
async def session(request:Request,value:SessionInput):
    if value.version!=VERSION:raise HTTPException(409,"같은 게임 버전이 필요합니다: "+VERSION)
    if len(directory.sessions)>=4096:raise HTTPException(503,"로비 연결 정원에 도달했습니다.")
    token=secrets.token_hex(32);uid=secrets.token_hex(16)
    directory.sessions[hashlib.sha256(token.encode()).hexdigest()]={"uid":uid,"nick":value.nick,"expires":time.time()+21600,"network":directory.network(request)}
    return {"token":token,"uid":uid,"transport":"webrtc","ice_servers":ice_servers(uid)}

@app.get("/v1/rooms")
async def rooms(request:Request,scope:str="internet"):
    user=directory.authenticate(request)
    return {"rooms":[directory.public(r) for r in directory.rooms.values() if r["options"]["scope"]==scope and time.time()-r["updated"]<45 and (scope!="lan" or r["network"]==user["network"])]}

@app.post("/v1/rooms")
async def create(request:Request,value:RoomInput):
    return directory.public(directory.create(directory.authenticate(request),value))

@app.post("/v1/rooms/{room_id}/join")
async def join(request:Request,room_id:str):
    user=directory.authenticate(request);room=directory.rooms.get(room_id)
    if not room:raise HTTPException(404,"종료된 방입니다.")
    return directory.admission(room,user)

@app.post("/v1/match")
async def match(request:Request,value:MatchInput):
    user=directory.authenticate(request)
    for room in directory.rooms.values():
        if room["options"]["locked"] or room["options"]["scope"]!=value.scope:continue
        if value.mode is not None and room["options"]["mode"]!=value.mode:continue
        if room["phase"]=="starting":continue
        try:return directory.admission(room,user)
        except HTTPException:continue
    mode=value.mode if value.mode is not None else 0
    room=directory.create(user,RoomInput(name=user["nick"]+"의 빠른 매치",mode=mode,map=19 if mode==4 else 13,scope=value.scope),True)
    return directory.admission(room,user)

@app.websocket("/v1/signal")
async def signal(ws:WebSocket):
    origin=ws.headers.get("origin")
    if origin and origin not in origins:await ws.close(code=1008);return
    await ws.accept();room=None;peer_id=0
    try:
        raw=await asyncio.wait_for(ws.receive_text(),10)
        if len(raw)>1024:await ws.close(code=1009);return
        first=json.loads(raw)
        if not isinstance(first,dict):await ws.close(code=1008);return
        ticket=str(first.get("ticket",""))
        claims=directory.tickets.pop(hashlib.sha256(ticket.encode()).hexdigest(),None)
        if not claims or claims["expires"]<time.time():await ws.close(code=1008);return
        room=directory.rooms.get(claims["room"]);peer_id=claims["peer"]
        if not room or peer_id in room["peers"]:await ws.close(code=1008);return
        if peer_id!=1 and 1 not in room["peers"]:await ws.close(code=1008);return
        room["peers"][peer_id]={"socket":ws,"uid":claims["uid"],"nick":claims["nick"]}
        room["reservations"].pop(claims["uid"],None)
        if peer_id==1:room["updated"]=time.time()
        await ws.send_json({"op":"ready","peer":peer_id})
        if peer_id!=1:
            await room["peers"][1]["socket"].send_json({"op":"peer","peer":peer_id,"uid":claims["uid"],"nick":claims["nick"]})
        while True:
            raw=await asyncio.wait_for(ws.receive_text(),45)
            if len(raw)>24000 or not directory.allow("ws:"+claims["uid"],40,150):await ws.close(code=1008);break
            data=json.loads(raw)
            if not isinstance(data,dict):await ws.close(code=1008);break
            op=data.get("op")
            if op=="keepalive":await ws.send_json({"op":"alive"});continue
            if op=="status" and peer_id==1:
                phase=data.get("phase");count=data.get("players");map_id=data.get("map")
                if phase not in ["lobby","buy","combat","round_end","result"] or type(count)!=int or not 1<=count<=room["options"]["capacity"]:continue
                if type(map_id)!=int or not 0<=map_id<len(CAPACITIES) or CAPACITIES[map_id]<room["options"]["capacity"] or (room["options"]["mode"]==4)!=(map_id>=19):continue
                room["phase"]=phase;room["players"]=count;room["options"]["map"]=map_id;room["updated"]=time.time()
                room["ping_sent"]=time.monotonic();await ws.send_json({"op":"ping","nonce":room["ping_sent"]});continue
            if op=="pong" and peer_id==1 and data.get("nonce")==room["ping_sent"]:
                room["host_rtt"]=round((time.monotonic()-room["ping_sent"])*1000);continue
            if op not in ["sdp","ice"]:continue
            target=data.get("to")
            if type(target)!=int or target==peer_id or (peer_id!=1 and target!=1) or target not in room["peers"]:continue
            if op=="sdp":
                if data.get("type") not in ["offer","answer"] or not isinstance(data.get("sdp"),str) or len(data["sdp"])>20000:continue
                payload={"op":op,"from":peer_id,"type":data["type"],"sdp":data["sdp"]}
            else:
                if not isinstance(data.get("candidate"),str) or len(data["candidate"])>3000 or not isinstance(data.get("mid"),str) or len(data["mid"])>64 or type(data.get("index"))!=int or not 0<=data["index"]<=16:continue
                payload={"op":op,"from":peer_id,"candidate":data["candidate"],"mid":data["mid"],"index":data["index"]}
            await room["peers"][target]["socket"].send_json(payload)
    except (WebSocketDisconnect,asyncio.TimeoutError,json.JSONDecodeError,RuntimeError):pass
    finally:
        if room and peer_id in room["peers"] and room["peers"][peer_id]["socket"] is ws:
            room["peers"].pop(peer_id,None)
            if peer_id==1:await directory.close_room(room)
            elif 1 in room["peers"]:
                with contextlib.suppress(Exception):await room["peers"][1]["socket"].send_json({"op":"left","peer":peer_id})
