# 1.3.2 hotfix

- Restore missing QUAD/ARC equipment thumbnails; packaging now verifies every weapon thumbnail.
- Sound settings retain three full-width previews at the bottom: pain, gunfire, footsteps. Real touch vertical scrolling works independently of browser touchscreen reporting.
- Navigation confirmation: stay left/green, leave right/red. Dry click menu feedback; non-tonal magazine withdrawal, insertion, bolt and shell foley.
- QUAD reload uses its four tube sockets in sequence; rocket nose points into the breech.
- Bot respawns reset perception/navigation state. Empty/blocked routes participate in stuck recovery; blocked combat strafing no longer cancels forward approach.
- Scope range box uses compact 14px centered text sized for 1000.0 m.
- ARC damage ramps from 60 to 120 DPS, per final user instruction. Repair remains 30 HP/s within 100 m.

Pre-publication: native/Web script imports clean; combat refresh 59 checks, zero failures. Detailed interaction and respawn regression follows publication as requested. No physical Intel iGPU/mobile performance guarantee.

Post-publication: Pages succeeded; critical HTML/JS/PCK/WASM/cache-worker hashes match. Public Web v1.3.2 menu inspected. Mobile/reload 15/15 and bot 12/12 (including three respawns) passed. Hidden sound-tab controls initially had zero layout size in the test; selecting the sound tab before measuring corrected the fixture. Windows 32-player P99: low 10.8 ms / high 11.7 ms on RTX 4080 SUPER. See v132-validation.json.


## Same-version update, 2026-09-28 (source 9e781e5)

- Three sound preview buttons now share one equal-width row at the bottom. Website download/play buttons have equal widths.
- Constrained buttons shrink text to their actual available width. Content-sized buttons retain native sizing; duplicate mobile/dialog fitting callbacks were removed.
- ARC: 60 to 120 DPS, maximum reached at 3 seconds; battery 6 seconds; overheat after 4 seconds. Both overheat and release cooling take 2 seconds from maximum heat to zero.
- ARC deals 30% extra damage to armor only, without boosting HP spillover. Friendly device repair remains 30 HP/s within 100 m.
- Windows and Web assets replaced under version 1.3.2. Pages run 36412681984 succeeded. Additional game tests were intentionally skipped at the user's request; preceding test results describe the earlier build only.


## Approved rocket / gadget update
- QUAD: 1 s firing interval, splash 33–11 in 7 m; direct damage remains 45. COMET: direct 80, splash 70–20 in 9 m, interval remains 1.8 s. Direct damage does not stack splash.
- Light/standard/reinforced covers use yellow/green/charcoal and 0.30/0.55/0.80 m body depth, mirrored by hit bounds.
- Assault plates: three charges, 25 separate durability per plate, one active at a time; consume before armor, with muted purple HUD segment and duplicate-use warning.
- Passive gadgets remain visible with automatic-use labels. Human and bot team entries reserve identical name/control rows. Combat notifications no longer overwrite menu help; command responses still appear in menus.
- Same version, native/Web rebuild; additional gameplay tests omitted as requested.


## Cover and team-menu correction
- Restore the complete original cover assembly, including feet, bolts, latches and trim; vary main paint and depth only.
- Pair human/bot team cells in a two-column grid with explicit single-line name bounds and compact two-row entries.
- Keep armor plus plate gauge maximum at 75.
- Important match/administration announcements remain visible over menus; combat hit/skill chatter stays in HUD. Settings feedback also has a timed menu overlay.
- Same-version native/Web rebuild; no additional gameplay tests requested.

- Participant management uses a narrower dialog and compact action buttons; overflowing names scroll within clipped fixed-width slots.

## Range and shotgun update
- Assault rifles, SMGs, shotguns, medic shotguns/carbines and pistols: falloff start x2; falloff end x1.9. Snipers/DMRs: both x1.1. Machine guns, rockets, ARC and LINK unchanged.
- Shotgun spread and bloom/movement spread values halved; 60% central pellets concentrate around the aim axis with movement penalty retained. Shotgun trace range extended only where required to reach the new falloff endpoint. No playtest-based hit-rate guarantee.
- Conventional gun range label now identifies damage falloff start; rockets display explosion radius.

- Final shotgun override (including MENDER): falloff start x3 and falloff end x2.5 relative to pre-update values; replaces x2/x1.9 above.

- Final machine-gun override: ANCHOR/BASTION also receive x2 falloff start and x1.9 falloff end; trace range reaches the new endpoint. ARC, rockets and LINK remain unchanged.

- Final machine-gun cap: falloff ends at 180 m for both ANCHOR and BASTION (start 80/90 m); maximum trace distance remains the original 220 m. Overrides x1.9 above.

- Approved final machine-gun distances: ANCHOR 75→160 m; BASTION 85→180 m. All earlier proposed machine-gun distances are superseded.

- Native focus return restores pointer mode from current UI state. Open gear/menu/map/dialog prevents capture, including respawn callbacks while unfocused.

## Approved roster, voting and reload update
- Ammo pips include actual chambered rounds; magazine-fed weapons retain chamber rounds (excluding shell/break, CHIME, rocket and laser).
- PULSE: 5 shells, 0.7 s each, 90 RPM. FOLD: 2 shells, 1 s each. Single-shell load cycles can be interrupted to fire loaded ammunition, with per-shell animation.
- Results and team menus share paired team rows: human details span two rows; bot settings occupy the second row; team move spans both on the right. Result map removed; detailed score opens separately.
- Host can manage both humans and bots, exchange when a team is full, add/remove bots within capacity. Manual management prevents auto-balancing from undoing decisions.
- Kick vote: one active vote, 15 s, 9 yes / 0 no, equal green/right and red/left buttons, thin countdown bar, unanswered votes do not count as yes. Join/leave/kick notices distinguish events.
- Mobile pause menu opens map via a button. World surfaces use stable floor/wall/ceiling color contrast without additional texture fetches.
- Native/Web export and same-version publication; extra gameplay tests omitted by request.

## Roster readability and automatic salvage
- Center participant rows and use alternating dark-gray cards in participant, team and result lists; widen bot difficulty controls.
- Let result records use remaining vertical space, retaining scrolling only for overflowing rosters.
- PULSE/FOLD require 0.3 seconds to settle after reload completion/interruption; existing shot cooldown is preserved and incomplete shells are not granted.
- Automatically collect nearby dropped guns as ammunition salvage with line-of-sight checking. Each consumed drop gives one 10% chance to restore one owned consumable gadget charge, capped at loadout capacity.
- Same-version native/web publication; no additional gameplay tests requested.
