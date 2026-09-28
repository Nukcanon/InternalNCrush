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
