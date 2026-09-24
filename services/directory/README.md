# Lightweight room directory

FastAPI implementation of the room discovery / session / one-use admission / WebRTC signaling protocol. No Godot subprocesses and no combat relay. Deploy with [nas/](../../nas/README.md), or use the matching [Cloudflare Workers implementation](../cloudflare-directory/README.md).

Run one uvicorn worker: rooms, tickets and connections are in-memory. Multiple workers require a shared state/connection coordinator and are not supported by this configuration. Restarting clears rooms. `main.py` is the implementation, `test_directory.py` covers the service contract, `check_live.py` tests actual HTTP and WebSocket connections, and `test_docker.py` builds the production Compose configuration with a disposable test CA.
