# 1.2.6 map renewal — work in progress, not published

The public baseline remains 1.2.5. Local changes on `work/v1.2.3-stability-20260927` implement the approved enlarged district layouts and map viewer. Do not publish these changes as fully validated yet.

## Deployment readiness check, 2026-09-27

The user authorized publication **after all requested work is complete**. This condition is not yet met; no release/tag/site upload has been made. `git fetch origin` confirms remote main remains `890b614`.

- Rebuilt all 32 native arena caches from current polygon data. Competitive navigation now passes **372/372** route checks (`validation/v126-routes-final.log`), including maps 26 and 28.
- Found a real practice arena defect: its expanded walkable floor was combined with wall/roof and perimeter boundaries from the older, unexpanded polygon. The baker now expands those boundaries together and keeps new decorative props outside the central four-storey practice lanes. Rebuilt arena 31 separately. A follow-up ray test confirmed the obsolete blocking wall was removed; actual bot/character ascent to 4.2, 8.4 and 12.6 metres passed **3/3** (`validation/v126-practice-traversal-fixed.log`). The earlier failed traversal log is preserved as diagnosis, not current evidence.
- Rocket expiration now scales with map diagonal while retaining the existing minimum ten seconds and 36 m/s speed. The old fixed lifetime could not cover the enlarged arenas. Updated the range regression to verify the adaptive lifetime and the unchanged small-map minimum.
- Coordinate-independent mechanics reruns passed: rules 30/30, regressions 63/63, AI aim 38/38, bots 6/6, native finish/range 238/238; the selected rerun ends `FUNCTIONAL_FAILED []` in `validation/v126-recheck.log`. This does not clear the remaining full-suite groups.
- Older full-run failures are still not cleared as a group. New Windows/Web exports, remote-client checks, performance/resource soak verification and final art/indoor-layout review remain outstanding.

## Contact traversal, 2026-09-27

`game/tests/test_traversal_contacts.gd` passed **13/13** in the actual Godot 4.4.1 headless physics engine (`validation/v126-traversal-contacts.log`). This uses real character movement and contacts on an isolated floor, not a simulated prop-force assertion.

- Walking crosses 8, 22 and 28 cm curbs without jumping; a 45 cm ledge stops the actor.
- Walking pushes cones, canisters, crates, tires, barrels and lightweight tables. Each moves more than 25 cm and the actor advances; measured displacement was approximately 2–3.2 m over 150 movement frames.
- Forward plus jump mantles a 1.2 m ledge. A low ceiling prevents climbing, and a 3 m wall cannot be bypassed.
- Existing movable-prop logic applies to `InteractiveProp` objects of at most 15 kg. Buildings, cars, large cover and other static level geometry are not pushable. This distinction must remain consistent between Web and native.

This confirms the shared movement implementation, not every individual placement on the new maps, mobile controls, network synchronization or Intel GPU frame rate. No movement limits were increased by this test.

## Outstanding map renewal verification

### Announcer and control capture update

- Replaced the five Windows SAPI victory/bomb phrases with offline Kokoro-82M `af_heart` female neural speech; added all six Blue/Orange A/B/C capture phrases. Sources, WAV hashes and licensing are recorded under `game/tools/announcer/provenance.json` and `game/SOUND_CREDITS.md`. No inference model is included in game exports.
- Announcements use +10 dB gain, fixed pitch, their own player and a bounded queue (maximum eight), so simultaneous captures do not overlap or get stolen by weapon/UI sound voices. Victory clears queued obsolete announcements. Rendered playback/queue/stop assertions passed.
- Server-authoritative capture rate is 1 / 1.5 / 2 / 2.5 times for one / two / three / four-or-more participants. Opponents contest, dead players do not count, and upstairs actors cannot capture through a ceiling. Ownership and progress/count snapshots are sent to clients; each completed capture triggers a reliable authority announcement to all players.
- Added static glyph textures and a simple billboard shader: letters and arrows fill independently from bottom to top. The ordinary depth test remains enabled. Added compact A/B/C overview bars and a participant HUD with percentage, count, speed and contested status.
- `test_capture_v126.gd`: **28/28 passed**. Rendered 1280×720 review: `validation/v126/capture-half.png` and `capture-full.png`; shader and HUD displayed correctly. Known 349524-byte GL texture shutdown warnings were still emitted and are not declared fixed. Real remote-client/device validation and final exports remain outstanding.

### Map renewal blockers

Follow-up control settings and floor overlay: captured control circles now contain a 17%-opacity team-colored fill. Static sampled meshes follow walkable floors, skip unsupported/abrupt-height triangles and use ordinary depth testing with no shadows. Defusal sites do not expose bomb state through this overlay. Actual rendered mesh/material assertions and the `capture-full.png` review passed.

Added `capture_seconds` (default 5, integer range 1–60) to bot/LAN/internet mode controls, sanitization, network options and all three directory/matchmaker schemas. This is single-player neutral capture time; taking a fully enemy-owned point still requires twice the neutral duration, and participation speed bonuses remain unchanged. Rendered SpinBox change to 12 seconds updates room options. Server tests passed: directory 9, matchmaker 10, Cloudflare policy 3. The packaged WebRTC test now checks the new field but has not yet been rerun. At the user's follow-up request, announcer gain was increased an additional 6 dB (now +10 dB); voice recordings are unchanged and the master limiter remains enabled.

- Regenerate `districts` data after the latest water and practice-preview changes, then rebake all 32 native arenas and the separate Web staging build. Older revision-126 cache files may otherwise mask source changes.
- Recheck all objective and elevation routes, including previously failing maps 26 and 28, with physical character traversal. Do not accept graph connectivity alone.
- Review old functional tests that assume the previous map coordinates and legacy terrace arrays. Four coordinate-based combat tests now use `CombatFixture`; this is not a substitute for testing production maps.
- Current full functional run has failures and is not release evidence. Preserve its logs; rerun after geometry and test-contract corrections.
- Review native theme detail at eye height, shared native/Web collision signatures, map viewer at narrow resolutions, score/map coexistence, and practice layer previews.
- Repeat native and Web performance/resource accumulation tests on the final candidate. Intel 10–11th-gen integrated graphics and physical mobile devices have not been tested. Known native shutdown GL texture warnings remain unresolved.

The actor's irregular-map fall recovery was also corrected to choose the nearest fallback spawn against the original fallen position instead of repeatedly changing its comparison point. This specific change still needs a targeted recovery regression.
