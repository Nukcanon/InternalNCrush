# 1.2.3 validation — 2026-09-27

Source: `19386e693a45134b2f8a69ecbe4d5b28ea800ae6`, based on published 1.2.2 `fb6c32a` and recovered 1.2.3 `da2424b`. No 1.1.x source restored. Native and Web assets remain separate.

## Functional and network evidence

- Checkpoint CI [36289439256](https://github.com/Nukcanon/InternalNCrush/actions/runs/36289439256) succeeded: 42 functional groups (including 138 new gameplay assertions), 32 simultaneous clients, two 8-peer reconnect/restart runs (105 seconds each), authoritative props, full defusal-series map rotation with early/late clients, touch 40/40 and WebRTC host/client. Exact final-source build/validation/publication CI [36290116158](https://github.com/Nukcanon/InternalNCrush/actions/runs/36290116158) also **succeeded**. Affected local art/render tests pass 38 + 138 + 5 + 1063 assertions.
- Directory CI [36289440984](https://github.com/Nukcanon/InternalNCrush/actions/runs/36289440984) succeeded: Python/NAS tests, Docker non-root HTTPS/WSS with certificate/hostname rejection, real Worker HTTP/WebSocket contract and policy checks. Service runtime is unchanged in the final source.
- Bounded stress: 72,000 tracer requests and 1,800 healing updates; round cleanup retains an invisible bounded tracer pool; leaving fully frees it.
- Native ragdolls 14/14; touch 40/40; real mixed audio PCM 21/21. Existing gun PCM hashes retained; grenade/flash/smoke blast samples match; deployment reuses old melee-swing PCM.

## Real Windows executable

Local final-source ZIP: 113,856,049 bytes; SHA256 `9f8522f2a30cf8b709b8f342f4076e679b80dab449c57e6192bfeb8a4ada35c9`. This is the local build, not an assertion that CI output is byte-identical.

- `windows/verify_build.py` executed the ZIP's own EXE/PCK: practice, bot combat, graphical client to headless host, graphical client to graphical host. All four exit 0, capture screenshots and have no engine errors. Both connection cases show two players in combat.
- `windows/verify_webrtc.py` used the same packed game resources/DLL: two players, encrypted loopback session, mode settings, snapshots and disconnect pass.
- Additional rendered EXE/PCK fixture: 12 rounds and 12 kill replays, failures 0. Warm/final nodes 2024/2059, resources 523/523, video memory 169.64/180.68 MB. Typical frame ~16.7 ms; maximum observed 178.65 ms. Release static-memory monitor returns 0, so no native heap conclusion from this fixture.
- Rendered planting/defusing: first-person hands and bomb visible, exact non-central plant point retained, releasing defuse resets progress, completion succeeds. `validation/v123/packaged-native-plant.png` and `packaged-native-defuse.png` capture this. No gameplay error or reproduced planting crash.
- Native source-debug run before the final pool change also completed 12 rounds: resources 536/536, static memory 129.05/129.16 MB; this is supporting evidence, not the release heap measurement.

### Downloaded public Windows artifact

The actual public ZIP was downloaded after publication and independently verified: 113,852,832 bytes, SHA256 `b228929aa7b86ebe520168545212c96abb40427e69402edf43d318474cfa9ec4`. All four EXE/PCK launch cases passed with exit 0: practice (10 players), bot combat (8), graphical client/headless host (2), graphical client/graphical host (2). The first two cases reported the known driver-exit texture warning; the two network cases did not. Packaged WebRTC also passed (2 players, 7 ms loopback ping, 59 snapshots), including mode settings and disconnect. ICE errno 10051 on an unavailable interface did not prevent the tested connection. Evidence: `validation/public-windows-v123/verification.json`, `validation/v123-public-rtc-console.log`.

## Actual browser

WebGL2/ANGLE on RTX 4080 SUPER, Godot 4.4.1 single-thread export:

- Final retained-pool probe: 36 round/replay cycles (~6 minutes), failures 0. Warm/final resources 454/465, nodes 2011/2191, video memory 43.43/43.99 MB. Pools populate lazily. Average sampled frame 16.78 ms; max 187.5 ms. No in-play freeze or script exception reproduced. Earlier run before round-pool retention averaged 16.91 ms / max 355.3 ms, but these short runs are not a controlled hardware benchmark.
- Actual browser client joined the packaged Windows host through the local Python directory: two players, ping 17 ms, 85 snapshots; all mode options matched. This tests browser/native WebRTC interoperability, not an external NAT route.
- Web production package uses separate lightweight character/world assets, fixed automatic render scale 100%, original approved menu pictures and 1.2.3 source manifest. Explicit manual resolution controls remain.
- Actual public Pages startup was checked through the normal **바로 플레이 → 게임 시작** UI. The rendered menu shows `WEB / v1.2.3`; logs identify `game-19386e693a45.js` and NVIDIA RTX 4080 SUPER via ANGLE/D3D11 with no startup error. This is distinct from the instrumented local repeated-play probe.

## Known limitations and remaining deployment gate

- Godot 4.4.1 emits `WorkerThreadPool::Group` allocator warnings when the Web fixture quits. Delayed teardown did not remove them. Native scripted audio/plant fixtures and two public-ZIP launch cases report 256px texture warnings at driver exit. The local-build launch cases and repeated packed round fixture did not. These are not evidence of an in-game crash, nor proof that all memory issues are resolved.
- Intermittent long frames remain. GTX960, physical Android/iOS, mobile Safari memory pressure, multi-hour sessions and multi-PC external WAN/NAT/TURN are not measured here. No universal FPS or crash-free claim.
- Free public Cloudflare directory was not deployed in 1.2.2 and is still awaiting account login here. `lobby_defaults.json` intentionally has no invented endpoint. Docker/NAS and Worker source/configuration pass tests and can be deployed by the owner.
- Female SERA (role 1) and MINA (role 5) have retracted/softened jaws, fitted bangs/tied hair, no ill-fitting cap, corrected neck atlas seams. Original CC0 anatomical meshes and existing shaders stay baked/cached; no heavy external asset pack was introduced. This is stylized game art, not a photorealistic copy of the reference.

## Publication verification

Published at 2026-09-27 03:20:23 UTC. The public Windows/Web/NAS ZIPs and descriptor/checksums were downloaded and matched their GitHub SHA256 digests. `PUBLICATION_STATUS.json` records sizes, hashes and URLs. Final website commit is `b9b045437fd3297b39d67751804e99b535972bb8`; installer [36291478302](https://github.com/Nukcanon/nukcanon/actions/runs/36291478302), Pages [36291571438](https://github.com/Nukcanon/nukcanon/actions/runs/36291571438), and actual public package/PCK audit [36291571895](https://github.com/Nukcanon/nukcanon/actions/runs/36291571895) all succeeded. The browser confirmed Windows/Web/NAS links all select 1.2.3. The previous audit ran before the NAS link reached Pages; its propagation race was fixed by waiting for all public download links. Installer regression suite: 7/7. Approved guide images and descriptions were preserved.

## Primary references reviewed

- [Godot 4.4 3D performance](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html): shared/baked meshes, LOD, avoiding repeated uploads/draw calls.
- [Godot 4.4 Web export](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html): single-thread/WebGL2, mobile and audio/networking constraints.
- [Godot issue 104428](https://github.com/godotengine/godot/issues/104428): separate physics-thread freeze. This project does not enable that option; it is not the established cause of the reported freezes.
