# 1.2.3 validation — in progress, 2026-09-27

Base: origin/main fb6c32a (published 1.2.2); recovery da2424b. Continued on Windows from checkpoint b4efed1. No 1.1.3 source merged.

## Completed local checks

- All 40 legacy functional groups now pass after updating superseded rule expectations and fixing DUET grip/cache errors. Additional gameplay 138/138; resource stress 72,000 tracer requests / 1,800 healing updates bounded.
- Python directory + legacy service tests 19; Worker policy tests 3.
- Real local WebRTC host/client, custom mode options, snapshots and disconnect passed. ICE reported an unavailable interface (10051) but established the local encrypted connection. This is not a remote NAT/TURN test.
- ENet gameplay and complete defusal-series map rotation with early/late clients passed. Lifecycle/capacity and packaged-binary checks still pending.
- Rendered Windows RTX 4080 SUPER: 12 eight-actor defusal cycles and 12 kill replays, no runtime errors. Warm/final resources 536/536, static memory 129.05/129.16 MB, average frame ~16.7 ms. Approximately two minutes, not a long-term crash guarantee.
- Browser WebGL2/ANGLE RTX 4080 SUPER: 36 cycles/replays over about six minutes, no gameplay script errors or freeze. Warm/final resources 480/480, nodes 1182/1218, video memory 40.65/43.47 MB. Mean sample frame 16.91 ms; maximum 355.3 ms. Native static-memory monitor is unavailable in Web release (returns 0).
- That browser run reported a WorkerThreadPool allocator warning during engine shutdown after the fixture completed. Do not describe the run as error-free. A new run with delayed teardown and retained round pools is pending.
- Original gun PCM hashes unchanged. Flash/smoke/explosion use identical PCM. Deployment/equipment use the previous melee-swing PCM.

## Remaining gates

Final Native/Web asset bake and review, audio/touch checks, final rendered repeat test, full network lifecycle/capacity, CI Linux/NAS checks, Windows/Web/NAS exports, packaged EXE execution, exact-source release and Pages deployment.

Physical GTX960/mobile frame rates, mobile Safari memory pressure, multi-PC LAN and external NAT/TURN remain outside these local measurements. No min-FPS/crash-free claim.

## References checked

- [Godot 4.4 3D performance](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html): baked/shared meshes and LODs; reduce repeated uploads/draw calls rather than importing unbounded assets.
- [Godot 4.4 Web export](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html): single-thread/WebGL2 constraints, mobile caveats, audio and browser networking limits.
- [Engine issue 104428](https://github.com/godotengine/godot/issues/104428): separate physics-thread freeze; this project does not enable that option. Not evidence that our reported freeze had the same cause.

Latest continuation: ENet reconnect/restart lifecycle passed with all 8 peers. Touch 40/40. Native audio 21/21 non-silent PCM, but 256px texture allocations report warnings only at driver shutdown; delayed node teardown did not eliminate that warning. Keep this distinct from unbounded in-game growth or a reproduced crash.
