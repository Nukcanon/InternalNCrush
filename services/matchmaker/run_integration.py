"""Real API -> allocated headless Godot -> two independent WebSocket clients.

Loopback HTTP/WS intentionally tests the runtime separately from the TLS gateway.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.error
import urllib.request

from services.matchmaker.main import ROOT, VERSION

out = ROOT / "validation/public-lobby"
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env.update(PUBLIC_BASE_URL="http://127.0.0.1:28080", INTERNAL_API_URL="http://127.0.0.1:28080")
engine = env["GODOT"]
processes = []
logs = []
room = None
tokens = []


def api(path, body=None, token=""):
    request = urllib.request.Request("http://127.0.0.1:28080" + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "Authorization": "Bearer " + token})
    with urllib.request.urlopen(request, timeout=8) as response:
        return json.load(response)


try:
    log = (out / "service.log").open("w", encoding="utf-8");logs.append(log)
    backend = subprocess.Popen([sys.executable, "-m", "uvicorn", "services.matchmaker.main:app", "--host", "127.0.0.1", "--port", "28080", "--no-access-log"], cwd=ROOT, env=env, stdout=log, stderr=log, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    processes.append(backend)
    for _ in range(50):
        try:
            api("/health");break
        except OSError:
            time.sleep(.2)
    tokens = [api("/v1/sessions", {"nick": f"PUBLIC_{i}", "version": VERSION})["token"] for i in range(2)]
    room = api("/v1/rooms", {"map": 13, "capacity": 8, "mode": 0}, tokens[0])
    for _ in range(60):
        listing = api("/v1/rooms", token=tokens[0])["rooms"]
        if listing and listing[0]["phase"] != "starting":
            break
        time.sleep(1)
    else:
        raise RuntimeError("Dedicated room did not become ready")
    for i, token in enumerate(tokens):
        ticket = api(f"/v1/rooms/{room['id']}/join", {}, token)
        client_env = env.copy();client_env["INC_TEST_JOIN"] = json.dumps(ticket)
        log = (out / f"client-{i}.log").open("w", encoding="utf-8");logs.append(log)
        process = subprocess.Popen([engine, "--headless", "--path", str(ROOT / "games/relaystrike"), "--script", "res://tests/network_public.gd", "--", "--no-save-profile", "--no-update-check"], env=client_env, stdout=log, stderr=log, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        processes.append(process)
    for process in processes[1:]:
        if process.wait(timeout=45) != 0:
            raise RuntimeError("Public client failed; inspect validation/public-lobby")
    for log in logs:
        log.flush()
    for i in range(2):
        content = (out / f"client-{i}.log").read_text(encoding="utf-8")
        if "PUBLIC_PASS" not in content or "SCRIPT ERROR" in content or "ERROR:" in content:
            raise RuntimeError(content)
        print(content.strip())
    print("PUBLIC_LOBBY_INTEGRATION_PASS")
finally:
    if room and tokens:
        with __import__("contextlib").suppress(OSError):
            request = urllib.request.Request("http://127.0.0.1:28080/v1/rooms/" + room["id"], method="DELETE", headers={"Authorization": "Bearer " + tokens[0]})
            urllib.request.urlopen(request, timeout=8).close()
    for process in reversed(processes):
        if process.poll() is None:
            if os.name == "nt":
                subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                process.terminate()
            try: process.wait(timeout=8)
            except subprocess.TimeoutExpired: process.kill();process.wait()
    for log in logs: log.close()
