# 1.1.0 candidate — in progress

Stable publication remains 1.0.4 until artifact and public-site verification finishes.

Implemented: native-resolution menu text, compact common actions, practice confirmation, blood default off, movement 3.2/6.2 m/s before equipment modifiers, ragdoll collision separation/settling, CC0 UV skin textures and generated microdetail atlas, sloping/narrower shoulders and fitted headgear, wrist/arm and magazine-specific reload adjustments, closed weapon loft ends, per-bone anatomical hit tests, rotated coplanar face cleanup, shadow cascade blending, mobile multitouch HUD, single-thread Web export, host-authoritative WebRTC, searchable room directory, NAS Docker wizard and Cloudflare free-tier directory.

Current local evidence: 338 anatomical/material/weapon/directory regression checks; 17 touch checks including concurrent movement/fire/aim and reload/ADS/crouch; 2 displays × 3 output modes; 14/14 bot vertical traversal (including 4-level practice); Python service/setup 10 tests; Worker policy and live HTTP/WS contracts; two native processes via Python and Worker; browser client + Windows native host combat with 3 ms local game ping. These are local tests, not WAN or physical mobile evidence.

Fixes discovered during validation: continuous surface entry for stair-side navigation; test fixture Godot root name matches production Game RPC path; physical time scale in traversal test; Compatibility sRGB microdetail atlas conversion; no transient RPC to closed RTC channels; menu-demo multiplayer API cleanup retained.

Pending: final functional/CI, production Docker TLS, actual release ZIP, public Pages byte/launch checks, account-based Cloudflare deployment. No public lobby URL is claimed. Known preexisting Compatibility shutdown-only texture leaks remain in two menu-demo textures. Browser automation has a Chromium pointer-lock UnknownError on entering combat, while the game itself renders/receives snapshots; check real browser behavior separately.
