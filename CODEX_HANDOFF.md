## Local 1.2.6 work is unfinished

Read `VALIDATION_V126_PARTIAL.md` before continuing. Approved enlarged maps and the map viewer have uncommitted implementation changes. The public release below is still 1.2.5; new-map routing, full regression and performance validation are not complete. Shared movement contact tests passed 13/13 (small-prop pushing, low curbs, safe mantling). Do not report the entire renewal as complete or publish without resolving the recorded failures.

# Internal N Crush 1.2.5 published handoff — 2026-09-27

Runtime source/tag: `7a51e15239cf91c0056629c4bbfcaaea629f14da`, `internal-n-crush-v1.2.5`. [Windows/Web/NAS release](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.2.5) · [live page](https://nukcanon.github.io/nukcanon/internal-n-crush.html). Subsequent main commits are documentation only. Start from current main and preserve `work/v1.2.3-stability-20260927`; never restore 1.1.x files. The previous runtime is 1.2.4 (`8c9e3572ac9e00d387eb6c57f83cdaa7c061942c`). This work continues the recovered 1.2.2/1.2.3 line.

## Latest request and changes

- Free-loadout footer: non-wrapping `장비 선택` / `무료` information box occupies the same region as defusal money. Actions remain 72 logical pixels tall. 29 rendered cases cover free and combat modes, native/Web profiles and viewport settings; the actual exported Web browser footer and combat entry were checked too.
- SERA/MINA: remove the compounded offline elongated-jaw morph before runtime identity shaping; native hair uses the same corrected head surface. Web has a separate lower-chin contour without native skin textures. Still stylized artwork, not photographic-reference-equivalent faces.
- Equipment: folded rectangular carry packs, flaps, webbing, buckles, distinct vented flash and smoke shells. Web uses merged/shared low-detail geometry and no additional dynamic lights. Existing readable weapon thumbnails are preserved.
- Maps: all twelve defusal layouts gain bent, narrower connectors (16–21 graph nodes). General arenas gain staggered halls, covered doglegs and four-room layouts while preserving the requested footprint/level-ground exceptions. These revise existing maps; they are not newly replicated CS maps. All 124 start-to-objective paths pass. An additional eight-room physical traversal regression exposed conservative flat navigation rasterization; that bug was fixed and the regression is now part of CI. Competitive balance still needs human play statistics.

## Verification and remaining limits

Read `VALIDATION_V125.md` and `PUBLICATION_STATUS.json` for exact evidence, CI and live-site hashes. CI 36304456160 passed on its first attempt: all 45 functional groups, 32-client capacity, late-start/lifecycle/props, touch and WebRTC. Directory/Docker/Worker CI 36304456146 passed. The earlier candidate CI 36303663690 was deliberately cancelled before publication to fix room traversal.

The actual release Windows ZIP passed four rendered execution cases, packaged WebRTC loopback and 12 round/killcam cycles. Exact Web files passed hash/source checks, browser startup, equipment footer and bot combat entry with no observed browser errors. Temporary localhost tests are not external WAN tests.

Two short RTX 4080 SUPER / Ryzen 9 7900 benchmark trials are recorded. Intermittent long frames remain in both 1.2.4 and 1.2.5; their cause is not proven by those samples. No Intel 10–11th-gen/GTX960/physical-phone performance guarantee. Existing native GL texture shutdown warnings remain. Earlier 120-cycle Windows/Web soaks belong to the 1.2.4 candidate, not this final release. Historical 1.2.2 c0000005 crash root cause is unknown without its dump. Multi-hour and external NAT/TURN tests remain outstanding.

## Operational rules

Native and Web share rules/networking but have separate baked graphics. Never copy `web/staging/game` models back to native `game/`. Arena cache revision is 125. The public Web JS retains bounded sparse GL handles; no automatic resolution changes. Approved menu photographs/site descriptions remain intact. Reference photographs/map diagrams were not copied into game textures.

The Cloudflare public lobby still requires the owner's Cloudflare login. Keep `game/assets/lobby_defaults.json` empty until a real HTTPS/WSS endpoint is deployed and verified. Docker/NAS/Worker implementations are tested; GitHub Pages is only static game hosting.

Source: `D:\python_workplace\InternalNCrush\InternalNCrush`; site: sibling `site-repository`. Exact package evidence: ignored `validation/public-v125/`, `public-windows-v125/`, `public-webrtc-v125/`, `public-web-v125/`. Fetch both remotes and preserve concurrent changes before continuing. `V124_REQUEST_AUDIT.md`, `PERFORMANCE_V124_KO.md`, and `V123_REQUEST_AUDIT.md` retain earlier request history; do not claim every historical art/performance request fully solved.

Map review handoff: all 32 current maps were exported from runtime collision/walk-surface data for user review. Local deliverables: `output/pdf/InternalNCrush_1.2.5_Floorplans/InternalNCrush_1.2.5_All_32_Maps.pdf` (33 pages), sibling `InternalNCrush_1.2.5_All_Map_Plans.zip` (PDF, 32 individual PNGs, legend, two comparison sheets, local HTML index). These show current geometry, not a proposed redesign. Levels are separate; ceilings/decorative meshes omitted. Source exporter and processing scripts/data remain under ignored `validation/*floorplans*`. Public game runtime is unchanged.
