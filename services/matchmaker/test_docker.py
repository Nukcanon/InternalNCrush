"""Exercise the real Compose gateway/allocator and isolated Godot clients over TLS."""
import contextlib
import json
import os
from pathlib import Path
import ssl
import subprocess
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "validation/docker-v102"
OUT.mkdir(parents=True, exist_ok=True)
COMPOSE = ["docker", "compose", "-p", "inc-ci", "-f", "services/matchmaker/compose.yaml"]
env = dict(os.environ, DOMAIN="localhost", ACME_EMAIL="ci@example.com")
clients = []
logs = []
room = None
tokens = []

def compose(*args, **kwargs):
    return subprocess.run(COMPOSE + list(args), cwd=ROOT, env=env, check=True, **kwargs)

def api(path, data=None, token="", method=None, context=None):
    request = urllib.request.Request("https://localhost" + path,
        data=None if data is None else json.dumps(data).encode(), method=method,
        headers={"Content-Type": "application/json", "Authorization": "Bearer " + token})
    with urllib.request.urlopen(request, context=context, timeout=10) as response:
        return json.load(response)

def client_command(image, name, script, extra):
    mounts = ["-v", f"{OUT / 'root.crt'}:/tmp/test-ca.crt:ro"]
    if "INC_TEST_CA" in extra:
        # Godot reads its default CA bundle during engine startup, before SceneTree._initialize.
        # Mount this only into disposable test clients, never the server image or release.
        mounts += ["-v", f"{OUT / 'override.cfg'}:/app/games/relaystrike/override.cfg:ro"]
    return ["docker", "run", "--rm", "--name", name, "--network", "host", "--cap-drop", "ALL", "--security-opt", "no-new-privileges"] + mounts + [arg for key, value in extra.items() for arg in ["-e", f"{key}={value}"]] + ["--entrypoint", "godot", image, "--headless", "--path", "/app/games/relaystrike", "--script", "res://tests/" + script + ".gd", "--", "--no-save-profile", "--no-update-check"]

try:
    compose("config", "--quiet")
    compose("up", "-d", "--build", "--wait", "--wait-timeout", "180")
    compose("exec", "-T", "gateway", "caddy", "validate", "--config", "/etc/caddy/Caddyfile")
    compose("cp", "gateway:/data/caddy/pki/authorities/local/root.crt", str(OUT / "root.crt"))
    (OUT / "override.cfg").write_text('[network]\ntls/certificate_bundle_override="/tmp/test-ca.crt"\n')
    context = ssl.create_default_context(cafile=str(OUT / "root.crt"))
    for _ in range(30):
        try:
            health = api("/health", context=context);break
        except OSError:
            time.sleep(1)
    else:
        raise RuntimeError("HTTPS API did not start")
    try:
        api("/health")
        raise AssertionError("Untrusted HTTPS certificate was accepted")
    except urllib.error.URLError as error:
        assert isinstance(error.reason, ssl.SSLCertVerificationError), error
    try:
        api("/internal/rooms/fake/heartbeat", {}, context=context)
        raise AssertionError("Internal API exposed")
    except urllib.error.HTTPError as error:
        assert error.code == 404
    tokens = [api("/v1/sessions", {"nick": f"TLS_{i}", "version": health["version"]}, context=context)["token"] for i in range(2)]
    room = api("/v1/rooms", {"map": 13, "capacity": 8}, tokens[0], context=context)
    for _ in range(90):
        listing = api("/v1/rooms", token=tokens[0], context=context)["rooms"]
        if listing and listing[0]["phase"] != "starting":break
        time.sleep(1)
    else:
        raise RuntimeError("Docker Godot did not become ready")
    image = compose("images", "-q", "arena", capture_output=True, text=True).stdout.strip()
    for i, extra in enumerate([{"INC_TEST_URL": "wss://localhost/game/0"}, {"INC_TEST_URL": "wss://127.0.0.1/game/0", "INC_TEST_CA": "/tmp/test-ca.crt"}]):
        result = subprocess.run(client_command(image, f"inc-tls-reject-{i}", "network_tls_reject", extra), capture_output=True, text=True, timeout=30)
        (OUT / f"tls-reject-{i}.log").write_text(result.stdout + result.stderr)
        assert result.returncode == 0 and "TLS_REJECT_PASS" in result.stdout, result.stdout + result.stderr
    for i, token in enumerate(tokens):
        ticket = api(f"/v1/rooms/{room['id']}/join", {}, token, context=context)
        assert ticket["url"].startswith("wss://localhost/")
        log = (OUT / f"client-{i}.log").open("w");logs.append(log)
        name = f"inc-tls-client-{i}"
        command = client_command(image, name, "network_public", {"INC_TEST_JOIN": json.dumps(ticket), "INC_TEST_CA": "/tmp/test-ca.crt"})
        clients.append((name, subprocess.Popen(command, stdout=log, stderr=log)))
    for name, process in clients:
        assert process.wait(timeout=55) == 0, name
    for log in logs:log.flush()
    for i in range(2):
        content = (OUT / f"client-{i}.log").read_text()
        assert "PUBLIC_PASS" in content and "SCRIPT ERROR" not in content and "ERROR:" not in content, content
        print(content.strip())
    print("DOCKER_TLS_PASS HTTPS WSS 2 clients; unknown CA and wrong hostname rejected; internal API blocked")
finally:
    if room and tokens:
        with contextlib.suppress(OSError):api(f"/v1/rooms/{room['id']}", token=tokens[0], method="DELETE", context=context)
    for name, process in clients:
        if process.poll() is None:subprocess.run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for log in logs:log.close()
    with (OUT / "compose.log").open("w") as log:
        subprocess.run(COMPOSE + ["logs", "--no-color"], cwd=ROOT, env=env, stdout=log, stderr=log)
    compose("down", "-v", "--remove-orphans")
