# 1.2.5 verification — 2026-09-27

Status: release candidate; public 1.2.4 is unchanged until package verification and publication.

## Changes and evidence

- Equipment footer: 24 rendered free-mode/profile/viewport-setting combinations plus five in-match mode checks pass. Free indication is a non-wrapping two-line information box, aligned with the defusal balance region. Footer height is 72 logical pixels. Native rendering with the Web asset flag checks shared layout; it is not a physical-phone browser test.
- Female anatomy: the old source vertices included an elongated lower-face morph in addition to the runtime morph. SERA/MINA now restore original face coordinates smoothly before identity shaping, and the fitted native scalp uses that same surface. Front, three-quarter, profile and neck poses were rendered. No new head texture or increase in native head topology.
- Carried equipment: rectangular fabric packs with flaps, webbing and buckles; vented flash grenade and separate smoke shell. Small gadgets remain one merged cached mesh, without new lights. The existing native-finish test passes 237 checks, including shared geometry and bounded caches; render split and cartoon checks pass 5 and 38 checks.
- Maps: 12 defusal layouts now have 16–21 connected graph nodes, narrower bent approaches and original room/site identities. General arenas receive staggered hall partitions; four flat arenas preserve their level ground, with covered doglegs or open four-room layouts. Outer footprint capacity rules are preserved. All 124 team-start-to-site queries across 31 competitive maps reach their destination. Existing physical traversal tests pass 14 checks and preparation exit tests pass 48 checks. This is not evidence of human competitive win-rate balance.
- Native complete geometry and navigation caches were rebuilt at revision 125. Web derives its optimized assets from the same collision/navigation data. There is no automatic resolution change.

## Limits

Full local suite: 44 groups passed. CI and exact exported package verification are pending below. Existing engine-exit warnings about two 349,524-byte GL textures remain reproducible after the rendered equipment fixture. They are not silently classified as solved. Intel 10–11th-gen integrated graphics, GTX960, physical phones, external NAT and multi-hour soak remain unverified. The layout changes are revisions of existing maps, not newly copied Counter-Strike maps or a claim of AAA artwork.

Local evidence: ignored `validation/v125/`, `validation/v125-*.log`. Reproducible tools: `review_gear_v125.gd`, `review_v125.gd`, `review_maps_v125.gd`, `audit_layout_v125.gd`.
