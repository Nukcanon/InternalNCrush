"""Download official engine binaries and verify their published SHA-512 manifest."""
import hashlib
import io
from pathlib import Path
import sys
import urllib.request
import zipfile

arch = {"amd64": "x86_64", "arm64": "arm64"}[sys.argv[1]]
base = "https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/"
name = f"Godot_v4.4.1-stable_linux.{arch}.zip"
manifest = urllib.request.urlopen(base + "SHA512-SUMS.txt", timeout=60).read().decode()
expected = next(line.split()[0] for line in manifest.splitlines() if line.split()[-1].lstrip("*") == name)
archive = urllib.request.urlopen(base + name, timeout=120).read()
if hashlib.sha512(archive).hexdigest() != expected:
    raise RuntimeError("Godot archive checksum mismatch")
with zipfile.ZipFile(io.BytesIO(archive)) as source:
    content = source.read(f"Godot_v4.4.1-stable_linux.{arch}")
target = Path("/usr/local/bin/godot")
target.write_bytes(content)
target.chmod(0o755)
