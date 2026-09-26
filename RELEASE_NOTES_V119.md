# Internal N Crush 1.1.9

- Compact, centered equipment previews; smaller skill icons; rotation around model center.
- FIX remote repair tool: 30 HP/s at 10m. Connected pistol guards and tool controls.
- Proportionate held-item fingers; two-handed cover and turret carrying; detailed bipod.
- Directional WASD double tap and mobile neutral-return double swipe slide; mobile slide button removed.
- Rocket: direct 60 total (no duplicate splash), splash 15–45 within 9m; no body-part multipliers for rockets or grenades, reduced gravity, unobstructed aiming and rear reload contact.
- Faster, wider first/third-person melee swings; collision-checked forward-jump mantling.
- Skill recharge survives death and transfers elapsed charge across class changes; turret cooldown 30s.
- Medic: initial 30s charge, F then click for six-second self/ally invulnerability with aim tolerance and white selection outline. Slow field radius 15m. Renamed 하드비트센서 scales between 35 and 60m by map size.
- Armor: light/heavy movement penalties 6%/12%; aim preparation penalties 10%/20%. Random four-digit default player names.
- Physical frag/flash/smoke throws, 2.5s fuse, central countdown and rolling motion.
- Select cover to enter placement immediately. Cover construction 2/3.5/5s; heavy cover slows carrying more.
- Turret construction 5s and upgrades 3s; cooldown starts immediately. Construction fades in at full size, remains nonblocking/inactive, takes 50% extra damage, and displays timers to allied engineers only. New builds start at half health; construction fills the other half without erasing damage. Team-colored outlines and aim-sensitive owner/health labels.
- Bullets and explosions pass unfinished structures while damaging both structure and targets behind.
- Web canvas suppresses browser default actions for modified gameplay clicks.

Validation: new gameplay/construction regression suite plus existing Godot/online/build gates. Unchanged site photographs and guide screenshots are reused. Physical-device browser behavior still needs real-device verification.
