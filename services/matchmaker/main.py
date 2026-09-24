"""Single-host room allocator. Run one worker; Godot owns all combat decisions."""
import asyncio
import base64
import contextlib
import hashlib
import hmac
import json
import os
import secrets
import subprocess
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field, model_validator

ROOT = Path(__file__).resolve().parents[2]
VERSION = "1.0.4"
MAP_CAPACITY = [32, 32, 16, 16, 16, 32, 16, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8] + [8] * 6 + [12] * 6


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class SessionRequest(StrictModel):
    nick: str = Field(min_length=1, max_length=20)
    version: str = Field(min_length=1, max_length=20)


class RoomRequest(StrictModel):
    name: str = Field(default="공개 경기", min_length=1, max_length=40)
    mode: int = Field(default=0, ge=0, le=4)
    map: int = Field(default=13, ge=0, le=30)
    capacity: int = Field(default=8, ge=2, le=32)
    map_random: bool = True
    map_rotation: bool = False
    rounds: int = Field(default=0, ge=0, le=100)
    prep_seconds: int = Field(default=45, ge=30, le=60)

    @model_validator(mode="after")
    def compatible_map(self):
        if self.capacity > MAP_CAPACITY[self.map]:
            raise ValueError("capacity exceeds this map's limit")
        if self.capacity % 2:
            raise ValueError("capacity must be even")
        if (self.mode == 4) != (self.map >= 19) or (self.mode == 4 and self.capacity > 12):
            raise ValueError("defusal requires an 8/12-player defusal map")
        return self


class MatchRequest(StrictModel):
    mode: int | None = Field(default=None, ge=0, le=4)


class Heartbeat(StrictModel):
    players: list[str] = Field(max_length=32)
    phase: str = Field(max_length=20)
    map: int | None = Field(default=None, ge=0, le=30)


@dataclass
class Session:
    uid: str
    nick: str
    expires: float


@dataclass
class Room:
    id: str
    slot: int
    owner: str
    options: RoomRequest
    key: str = field(default_factory=lambda: secrets.token_hex(32))
    created: float = field(default_factory=time.time)
    heartbeat: float = field(default_factory=time.time)
    last_occupied: float = field(default_factory=time.time)
    phase: str = "starting"
    players: list[str] = field(default_factory=list)
    reservations: dict[str, float] = field(default_factory=dict)
    process: subprocess.Popen | None = None
    automatic: bool = False

    def occupants(self):
        return set(self.players) | {uid for uid, expires in self.reservations.items() if expires > time.time()}

    def public(self):
        return {"id": self.id, "name": self.options.name, "map": self.options.map,
                "mode": self.options.mode, "capacity": self.options.capacity,
                "players": len(self.occupants()), "phase": self.phase}


class Allocator:
    def __init__(self, launch=True):
        self.rooms: dict[str, Room] = {}
        self.sessions: dict[str, Session] = {}
        self.buckets: dict[str, tuple[float, float]] = {}
        self.lock = asyncio.Lock()
        self.launch = launch
        self.limit = min(4, max(1, int(os.getenv("MAX_ROOMS", "4"))))
        self.base = os.getenv("PUBLIC_BASE_URL", "https://localhost").rstrip("/")
        if not self.base.startswith("https://") and not self.base.startswith("http://127.0.0.1:"):
            raise RuntimeError("PUBLIC_BASE_URL must use HTTPS (loopback HTTP only for tests)")
        self.port_base = int(os.getenv("GAME_PORT_BASE", "27900"))

    def allow(self, key, rate=10., burst=80.):
        now = time.monotonic()
        tokens, previous = self.buckets.get(key, (burst, now))
        tokens = min(burst, tokens + (now - previous) * rate)
        self.buckets[key] = (max(0., tokens - 1.), now)
        return tokens >= 1.

    def authenticate(self, authorization):
        if not authorization.startswith("Bearer ") or len(authorization) > 100:
            raise HTTPException(401, "세션을 다시 연결하세요.")
        digest = hashlib.sha256(authorization[7:].encode()).hexdigest()
        session = self.sessions.get(digest)
        if not session or session.expires <= time.time():
            raise HTTPException(401, "세션이 만료되었습니다.")
        return session

    def create(self, session, options, automatic=False):
        if len(self.rooms) >= self.limit:
            raise HTTPException(503, "서버의 방이 모두 사용 중입니다.")
        if any(r.owner == session.uid for r in self.rooms.values()):
            raise HTTPException(409, "이미 만든 방이 있습니다. 방 목록에서 참가하세요.")
        slot = next(i for i in range(self.limit) if all(r.slot != i for r in self.rooms.values()))
        room = Room(secrets.token_hex(16), slot, session.uid, options, automatic=automatic)
        if self.launch:
            config = {"room_id": room.id, "key": room.key, "owner": room.owner,
                      "port": self.port_base + slot, "api": os.getenv("INTERNAL_API_URL", "http://127.0.0.1:8080"),
                      "automatic": automatic, "options": {"room": options.name, "map": options.map,
                      "max_players": options.capacity, "mode": options.mode,
                      "map_random": options.map_random, "map_rotation": options.map_rotation,
                      "map_size": MAP_CAPACITY[options.map], "rounds": options.rounds,
                      "prep_seconds": options.prep_seconds}}
            env = os.environ.copy()
            env["INC_ROOM_CONFIG"] = json.dumps(config)
            command = [os.getenv("GODOT", "godot"), "--headless", "--path", str(ROOT / "game"),
                       "--", "--server", "--public-room", "--no-save-profile", "--no-update-check"]
            try:
                room.process = subprocess.Popen(command, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            except OSError:
                raise HTTPException(503, "게임 프로세스를 시작할 수 없습니다.") from None
        self.rooms[room.id] = room
        return room

    def ticket(self, room, session):
        if room.phase == "starting":
            raise HTTPException(409, "맵을 준비 중입니다. 잠시 후 참가하세요.")
        # One room per guest identity. Reservations count until expiry or heartbeat admission.
        for other in self.rooms.values():
            if other.id != room.id and session.uid in other.players:
                raise HTTPException(409, "현재 경기에서 먼저 나가세요.")
        if session.uid not in room.occupants() and len(room.occupants()) >= room.options.capacity:
            raise HTTPException(409, "방이 가득 찼습니다.")
        for other in self.rooms.values():
            other.reservations.pop(session.uid, None)
        expires = int(time.time()) + 30
        room.reservations[session.uid] = expires
        claims = {"room": room.id, "uid": session.uid, "nick": session.nick,
                  "exp": expires, "nonce": secrets.token_hex(16), "owner": session.uid == room.owner}
        encoded = base64.b64encode(json.dumps(claims, separators=(",", ":"), ensure_ascii=False).encode()).decode()
        signature = hmac.new(room.key.encode(), encoded.encode(), hashlib.sha256).hexdigest()
        url = self.base.replace("https://", "wss://", 1).replace("http://", "ws://", 1) + f"/game/{room.slot}"
        if self.base.startswith("http://127.0.0.1:"):
            url = f"ws://127.0.0.1:{self.port_base + room.slot}"
        return {"room": room.public(), "url": url, "ticket": encoded + "." + signature, "expires": expires}

    def close(self, room):
        if room.process and room.process.poll() is None:
            if os.name == "nt":
                subprocess.run(["taskkill", "/PID", str(room.process.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                room.process.terminate()
            try:
                room.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                room.process.kill()
                room.process.wait(timeout=3)
        self.rooms.pop(room.id, None)

    def maintain(self):
        now = time.time()
        for room in list(self.rooms.values()):
            stale = now - room.heartbeat > (90 if room.phase == "starting" else 20)
            empty = not room.occupants() and now - room.last_occupied > 180
            dead = room.process is not None and room.process.poll() is not None
            if stale or empty or dead:
                self.close(room)
            room.reservations = {k: v for k, v in room.reservations.items() if v > now}
        self.sessions = {k: s for k, s in self.sessions.items() if s.expires > now}
        stamp = time.monotonic()
        self.buckets = {k: v for k, v in self.buckets.items() if stamp - v[1] < 300}


def create_app(allocator=None):
    state = allocator or Allocator()

    @asynccontextmanager
    async def lifespan(_app):
        async def cleanup():
            while True:
                await asyncio.sleep(5)
                async with state.lock:
                    state.maintain()
        task = asyncio.create_task(cleanup())
        yield
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task
        for room in list(state.rooms.values()):
            state.close(room)

    app = FastAPI(title="Internal N Crush lobby", version=VERSION, lifespan=lifespan,
                  docs_url=None, redoc_url=None, openapi_url=None)
    app.state.allocator = state

    @app.middleware("http")
    async def limits(request: Request, call_next):
        # Consume a bounded body, including chunked requests; reject before JSON parsing.
        body = bytearray()
        async for chunk in request.stream():
            body.extend(chunk)
            if len(body) > 4096:
                return JSONResponse({"detail": "요청 크기 제한"}, status_code=413)
        request._body = bytes(body)
        ip = request.client.host if request.client else "unknown"
        if len(state.buckets) >= 10000 and ip not in state.buckets:
            return JSONResponse({"detail": "서버 혼잡"}, status_code=503)
        if not state.allow(ip):
            return JSONResponse({"detail": "요청이 너무 빠릅니다."}, status_code=429, headers={"Retry-After": "1"})
        response = await call_next(request)
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    def guest(request: Request):
        return state.authenticate(request.headers.get("authorization", ""))

    @app.get("/health")
    async def health():
        return {"status": "ok", "version": VERSION}

    @app.post("/v1/sessions")
    async def session(data: SessionRequest, request: Request):
        if data.version != VERSION:
            raise HTTPException(409, "서버와 같은 게임 버전을 사용하세요.")
        ip = request.client.host if request.client else "unknown"
        if not state.allow("session:" + ip, rate=.2, burst=40):
            raise HTTPException(429, "잠시 후 세션을 연결하세요.")
        if len(state.sessions) >= 2000:
            raise HTTPException(503, "세션이 가득 찼습니다.")
        token = secrets.token_urlsafe(32)
        s = Session(secrets.token_hex(16), "".join(c for c in data.nick if c.isprintable()).strip() or "Player", time.time() + 21600)
        state.sessions[hashlib.sha256(token.encode()).hexdigest()] = s
        return {"token": token, "expires": int(s.expires), "player": s.uid}

    @app.get("/v1/rooms")
    async def rooms(_s=Depends(guest)):
        return {"rooms": [r.public() for r in state.rooms.values()]}

    @app.post("/v1/rooms")
    async def create(data: RoomRequest, s=Depends(guest)):
        async with state.lock:
            return state.create(s, data).public()

    @app.post("/v1/rooms/{room_id}/join")
    async def join(room_id: str, s=Depends(guest)):
        async with state.lock:
            if room_id not in state.rooms:
                raise HTTPException(404, "방이 종료되었습니다.")
            return state.ticket(state.rooms[room_id], s)

    @app.delete("/v1/rooms/{room_id}")
    async def close(room_id: str, s=Depends(guest)):
        async with state.lock:
            room = state.rooms.get(room_id)
            if not room or room.owner != s.uid:
                raise HTTPException(403, "방장만 방을 종료할 수 있습니다.")
            state.close(room)
            return {"closed": True}

    @app.post("/v1/match")
    async def match(data: MatchRequest, s=Depends(guest)):
        async with state.lock:
            available = [r for r in state.rooms.values() if (data.mode is None or r.options.mode == data.mode)
                         and (len(r.occupants()) < r.options.capacity or s.uid in r.occupants())]
            # Join the most populated compatible room before allocating another process.
            available.sort(key=lambda r: (r.phase == "starting", -len(r.occupants()), r.created))
            room = available[0] if available else state.create(s, RoomRequest(mode=data.mode or 0, map=19 if data.mode == 4 else 13), automatic=True)
            if room.phase == "starting":
                room.reservations[s.uid] = time.time() + 90
                return {"pending": True, "room": room.public()}
            return state.ticket(room, s)

    @app.post("/internal/rooms/{room_id}/heartbeat")
    async def heartbeat(room_id: str, data: Heartbeat, request: Request):
        async with state.lock:
            room = state.rooms.get(room_id)
            if not room or not hmac.compare_digest(request.headers.get("authorization", ""), "Bearer " + room.key):
                raise HTTPException(403, "invalid server credential")
            if len(data.players) > room.options.capacity or any(len(uid) != 32 for uid in data.players):
                raise HTTPException(422, "invalid player roster")
            if data.map is not None:
                if MAP_CAPACITY[data.map] != MAP_CAPACITY[room.options.map] or ((data.map >= 19) != (room.options.mode == 4)):
                    raise HTTPException(422, "invalid map rotation")
                room.options.map = data.map
            room.players = list(set(data.players));room.phase = data.phase;room.heartbeat = time.time()
            for uid in room.players:
                room.reservations.pop(uid, None)
            if room.occupants():
                room.last_occupied = time.time()
            return {"ok": True}

    return app


app = create_app()
