# Combat/audio refresh — published 1.3.1

Published 2026-09-28 as **1.3.1**, source `0bb5ccec86301a1250e91b36cb808d6c3d25b7be`. Windows, Web and NAS packages are public. See `PUBLICATION_STATUS.json` for immutable asset hashes and the verified website.

## Implemented locally

- Stable nearest-target marker: 1.5 s acquisition, retains a target inside the cone, excludes active marks, resets on exit.
- ANCHOR 90 / 450 RPM, BASTION 120 / 400 RPM; smaller BASTION sight obstruction. Rocket reload 20% faster. QUAD four-round launcher, individual reload interruption. ARC continuous laser heat/battery, purple beam, heat gauge, range damage, repair within 100 m and enemy-device damage.
- Tactical chamber preservation and bolt-free tactical reload cues/animation; excluded non-magazine weapon types. Gender-aware replay hurt audio.
- Rebuilt 95 sample-based cues, including 30 weapon mixes, dry menu click, reload/impact/door/explosion/rocket/laser cues. Web category sharing and ADPCM compaction. Subjective audio review still needed.
- Larger native texture-family atlases and compact Web asset pipeline; versioned browser asset cache worker.
- Defusal majority victory / tied regulation decider; wins in HUD; personal respawn budget persists across the match; host-only team changes during match and hard-bot departure replacement. Surviving equipment retained; purchases restricted to own spawn and buy time.
- Immediate-redeploy penalty confirmation and 15 s non-practice cooldown; unavailable at zero remaining defusal lives. Notices queue separately from bomb hints.
- Equal-size, ordered confirmation buttons; removed practice AI paragraph.
- Per-bot role and difficulty in lobby/team controls and records. Server validates host permissions; difficulty immediate, active-bot class change on next spawn. Defaults hard. Host/practice records toggle with Tab, close button, mobile outside touch; modal priority and input blocking.
- Scoped rangefinder, one decimal, infinity beyond 9999 m. ARC now uses its own low-magnification optical overlay, with the range display inside the lens and a visible heat bar. Objective ring segment height checks and no shadow casting. Facade depth/anchor and unsupported waterfront fixture corrections; arena cache revision 141.
- Offline textured map plans for 32 maps / three layers; separate 256px thumbnail images, no second runtime 3D viewport. Preview JSON cache bounded to eight and excludes full 3D groups.

## Verified in this workspace

- `test_combat_refresh.gd`: 57 checks, zero failures before the additional ARC overlay assertion.
- `test_bot_settings.gd`: 15 desktop checks; 18 touch/render checks, zero failures. `validation/bot-settings-mobile.png` inspected at 960×540.
- `test_rules.gd`: 30/30 (latest rerun).
- Earlier this work: defusal 52/52, v112 154/154, v113 102/102, AI aim 38/38, dialog style 8/8.
- Numeric surface audit: all 32 maps, zero duplicate/degenerate/tile-leak findings. This is not a full visual inspection of every map.
- Models regenerated (12 operators, 33 weapons). Audio regenerated. Textured plans generated. Native arena rebake completed for all 32 maps (`validation/build-arenas-latest.log`).
- Touch regression updated for the requested persistent records behavior, then passed 44/44. `git diff --check` passed.
- Web audio/cache tests passed earlier; staged Web build and actual browser refresh/performance checks are still required after the latest edits.

## Approved voice sample

The user approved ElevenLabs Sound Effects history `TJhwz5568ylTvAm4uaUt`, candidate #4, but requested a single utterance. User supplied `C:/Users/119hw/Desktop/A woman enthusiastically performs two vocal gunsho.opus` after in-app download did not yield an accessible file.

The first candidate supplies the pistol's single utterance. The user rejected the subsequent loud `American_woman_shout_#1` take, then supplied and approved `American_woman_yelli_#3-1790581855008.mp3` (6 seconds). Its five isolated utterances supply SMG/rifle/MG/sniper/shotgun; ARC/LINK share the MG utterance. No TTS or pitch shifting. Seven mono 44.1 kHz clips are installed, with source cuts/hashes in `game/assets/vocal_audio_provenance.json`; source copies are retained under `game/tools/vocal_sources`. The gunfire-reduction option persists and defaults off. Non-gun healing/menus/explosions retain their ordinary sounds. Same-category nearby vocal overlap is capped at two, using the existing audio pool. Free-plan attribution/noncommercial limitations are recorded in `game/SOUND_CREDITS.md`.

## Latest completion checks

- Full regression first pass exposed 11 groups needing investigation. Corrected old purchase fixtures to use legal defusal maps/own spawn, notification assertions to use the separate toast queue, and recoil assertions for the intentionally straight laser. Fixed actual ARC pose-only socket mismatch and the exact 28 cm step collision-margin failure. Affected groups have passed reruns; a final complete suite is still required after asset regeneration.
- All 32 source maps passed the updated numeric surface audit. Whole-width facade support found 11 sloped-wall cases; lowering anchors to the minimum wall-base height fixed them. Exact window-extents audit now reports zero unsupported facades across all maps.
- Captured 32 front/side/layout views from regenerated source geometry. Corrected window glazing burial with a 2 mm back-face clearance. The capture camera now stays in the corridor instead of penetrating an opposite wall. Front/side contact sheets inspected; this samples each map, not every camera position.
- Rendered sniper/DMR/ARC HUDs and rangefinder placement inspected. Training-map preview generation now includes the actual added gallery/stair surfaces.
- `test_vocal_audio.gd`: rendered Dummy-audio test, zero failures, verifies default normal gunfire, voice mapping, overlap bound, unaffected menu/healing skills, and stopped voices on exit.
- `run_network_bot_settings.py`: two real ENet peers passed host-choice replication and rejection of a guest bot-edit request.
- Web compact audio passes: 6,695,036 source WAV bytes to 2,932,652 staged WAV bytes, with vocal clips retained and downsampled. This is not final exported package size.
- Shutdown warning isolated to a fixture that creates and immediately destroys a menu viewport before rendering it. Empty/shader/menu/arena/actor cases had no warnings; allowing the newly returned menu to render before shutdown yields a clean `render-shutdown-menu-frame.log`. This does not replace repeated-session memory measurements.

- Latest rendered audio feedback 30/30, vocal playback zero failures, mobile settings guard passed, mobile bot controls 18/18. Tests now allow the initial menu viewport to render before replacing it; shutdown is clean.
- Nine real map/menu cycles with vocal gunfire: after warmup nodes 162, objects 3369, resources 983, texture bytes 197,060,135 stayed constant. Static allocation was approximately 116.9 MB. This is bounded local sampling, not a claim of zero leaks for all workloads.
- Additional visual inspection found steep-pavement window burial: facade groups are now omitted where terrain varies by more than 0.60 m across their width. All 32 wall support audits remain clear.
- Full regression found an empty objective-ring mesh error: ring generation now waits for collision registration and skips empty surfaces. Spawn exits rerun passed 48/48; all 12 defusal maps produced nonempty finite objective rings.
- Fresh Web headless GLB import emits dummy-renderer texture errors; render-backed import completed cleanly; staged Web combat/render/marker checks passed, and all 32 collision signatures match native.

- The full 55-group suite passed after the two affected groups were corrected and rerun. The intermittent combat fixture used map 23 options with a map 0 Arena, allowing random non-spawn respawns; aligning the fixture map made three consecutive combat refresh runs pass.
- Native and Web source assets regenerated; latest mobile interactions and resource checks passed. Implementation/error gates are complete; release export may proceed.

## Publication verification

- Windows/Web release exports and packages passed; actual Windows release launched with eight players and all seven vocal clips.
- Published Windows binary: eight measured quality/map scenarios at 1280×720, 7/31 bots. See `v131-performance.json`. The 32-player P99 frame time was 10.2–11.3 ms on RTX 4080 SUPER.
- Public Web menu and bot combat inspected. Critical public file hashes match packaged HTML/JS/PCK/WASM/cache worker. Same-version reload reused PCK/WASM with no second server request. No Intel iGPU or physical mobile measurement exists.
- GitHub Pages commit `e5b7228` preserves exact generated bytes, avoiding Git newline conversion changing manifest hashes. Public download sizes/digests match local packages. The 12-round instrumented Web/killcam soak passed; see v131-performance.json for transient frame spikes and measurement limits.

Unrelated untracked `output/` and `game/tools/inspect_character_source.py` predate these edits; preserve them. `Universal Base Characters[Standard].zip` is a character-source candidate with a Blender inspection script, not a verified integrated runtime asset.

Latest 1.3.2 supersedes the above weapon balance: ARC 60→120 DPS. See V132_HOTFIX.md for publication and focused follow-up checks.
