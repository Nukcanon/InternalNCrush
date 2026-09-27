# 1.2.5 verification — 2026-09-27

Status: verified release 1.2.5; runtime source `7a51e15239cf91c0056629c4bbfcaaea629f14da`. See PUBLICATION_STATUS.json for live-site and package hashes.

## Changes and evidence

- Equipment footer: 24 rendered free-mode/profile/viewport-setting combinations plus five in-match mode checks pass. Free indication is a non-wrapping two-line information box, aligned with the defusal balance region. Footer height is 72 logical pixels. Native rendering with the Web asset flag checks shared layout; it is not a physical-phone browser test.
- Female anatomy: the old source vertices included an elongated lower-face morph in addition to the runtime morph. SERA/MINA now restore original face coordinates smoothly before identity shaping, and the fitted native scalp uses that same surface. Front, three-quarter, profile and neck poses were rendered. No new head texture or increase in native head topology.
- Carried equipment: rectangular fabric packs with flaps, webbing and buckles; vented flash grenade and separate smoke shell. Small gadgets remain one merged cached mesh, without new lights. The existing native-finish test passes 237 checks, including shared geometry and bounded caches; render split and cartoon checks pass 5 and 38 checks.
- Maps: 12 defusal layouts now have 16–21 connected graph nodes, narrower bent approaches and original room/site identities. General arenas receive staggered hall partitions; four flat arenas preserve their level ground, with covered doglegs or open four-room layouts. Outer footprint capacity rules are preserved. All 124 team-start-to-site queries across 31 competitive maps reach their destination. Existing physical traversal tests pass 14 checks and preparation exit tests pass 48 checks. This is not evidence of human competitive win-rate balance.
- Native complete geometry and navigation caches were rebuilt at revision 125. Web derives its optimized assets from the same collision/navigation data. There is no automatic resolution change.

## Limits

Initial local suite: 44 groups passed. Additional physical traversal through eight new rooms passes after correcting flat-map grid rasterization. Final CI 36304456160 passed all 45 groups, 32-client capacity, late-start/lifecycle/prop tests, touch and WebRTC tests on its first attempt. Directory/Docker/Worker CI 36304456146 passed. The exact release ZIP passed four rendered Windows execution cases, packaged WebRTC loopback and 12 rendered round/killcam cycles. The exact Web ZIP passed manifest/hash checks and actual browser startup, free-equipment footer and bot combat entry with no observed browser errors. Existing engine-exit warnings about two 349,524-byte GL textures remain reproducible. They are not silently classified as solved. Intel 10–11th-gen integrated graphics, GTX960, physical phones, external NAT and multi-hour soak remain unverified. The layout changes are revisions of existing maps, not newly copied Counter-Strike maps or a claim of AAA artwork.

Local evidence: ignored `validation/v125/`, `validation/v125-*.log`. Reproducible tools: `review_gear_v125.gd`, `review_v125.gd`, `review_maps_v125.gd`, `audit_layout_v125.gd`.

The first candidate CI run (36303663690) was deliberately cancelled before publication: extra room-interior traversal exposed conservative navigation rasterization. A doorway is now sampled with explicit capsule/turn clearance, rather than rounding both ends out to whole grid cells. Room tests follow traversable floor near each room centre (furniture is not a valid walking target) continuously through all four rooms per map.

## Short performance comparison

RTX 4080 SUPER / Ryzen 9 7900, medium, 1280×720, uncapped, five-second warm-up and twelve-second measurement. Two sequential trials compare the published 1.2.4 executable with the local final-source 1.2.5 export. Live bot combat is not deterministic; draw counts and long frames vary between trials. This is a regression observation, not an Intel/phone benchmark or proof that stalls are fixed.

| Players | Version | Mean ms, trials 1 / 2 | P95 ms, trials 1 / 2 | Maximum ms, trials 1 / 2 |
|---|---|---|---|---|
| 8 | 1.2.4 | 1.254 / 1.321 | 2.934 / 3.186 | 127.421 / 249.207 |
| 8 | 1.2.5 | 1.252 / 1.117 | 2.884 / 2.783 | 231.704 / 4.703 |
| 32 | 1.2.4 | 2.169 / 2.688 | 7.065 / 7.886 | 242.628 / 132.765 |
| 32 | 1.2.5 | 2.122 / 3.047 | 6.928 / 8.378 | 238.208 / 125.922 |

Intermittent long frames remain in both versions. Their cause is not established by these samples. The second 32-player trial is slower on average in 1.2.5, while the first is similar; no low-end performance guarantee is made. Evidence: `validation/v125-performance-comparison.json` and the four benchmark logs.
