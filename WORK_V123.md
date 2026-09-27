# 1.2.3 recovery and validation ledger

Public baseline: game `fb6c32aafc1bb5a5467ae45346fa87fe51e05472`, site `f320788e6850dafd500d5281e0908ce3fe29abdf` (1.2.2).
Uncommitted previous 1.2.3 work was absent after environment restoration. Previous test results are historical and **do not validate this checkout**. All reconstructed changes require fresh validation.
Work is checkpointed on `work/v1.2.3-stability-20260927`; release remains unchanged until gates pass.

## Stability
- [x] Native and Web repeated combat / round changes: resource counts, allocations and frame-time spikes.
- [x] Reuse bounded tracer nodes/materials and immutable healing ribbon geometry.
- [x] Refresh scoreboard rows only when displayed data changes.
- [x] Bound disconnected-player records; clean round effects, marks, dropped gear and replay.
- [x] Investigate actual native crashes separately from memory-growth suspicions; no unverified crash-free claims.

## Requested gameplay and presentation
- [x] Non-strategic remote audio max 40m; suppress other players' flesh/surface-hit feedback.
- [x] New swing/equip/deploy/throw/bounce/UI sounds; equal flash/smoke/grenade blast; flash 18m, 5s center to 2s edge.
- [x] Door physics origin and mobile autofire/sprint button widths.
- [x] MONOLITH head 150×normal head multiplier, torso 120, limbs 90, hands/feet 80.
- [x] Scope-only passive marker, 10-degree total cone, yellow outline/countdown/reset. Passive/empty items unselectable, empty labels/models.
- [x] Hold/release grenade cook with mouse/touch, including last grenade.
- [x] All classes CHIME/SPARK + DUET dual pistols, matching first/third-person hands/reload; DUET twice SIDE rate/magazine and stronger bloom.
- [x] Native/Web female face proportions informed by supplied reference, softer chin, fitted hair; remove ill-fitting female hats; preserve native detail and Web budget.
- [x] Mode-specific numeric options, irrelevant fields hidden; defaults: TDM/FFA 10min/60 kills, team reserve 60, domination hold 60s, defusal even 4 rounds, prep 30s, round 5min, cash 800, personal respawns 0..10. Non-defusal 0min = unlimited.
- [x] Defusal halftime switch/reset, random-side one-round tiebreak, exact bomb location, close stationary interruptible defuse, stable drops/double-use outside site, smaller back bomb and handling poses.
- [x] Defusal pistol-only start, paid LINK 800, death loses gear, survivors keep gear, auto purchase window each prep, owned-slot/class replacement confirmation, lobby gear hidden.
- [x] Every round clear devices/marks/effects; spawn walls team colors/no text/flicker; louder beeps; each round winner voice, final series lineup only.
- [x] Host moves self/bots only, humans choose themselves, balanced limits, odd count auto hard bot, default next-match rating balance.
- [x] Support score breakdown and room-persistent stats, separate match kills; domination majority at timeout or hold all zones; winner portraits/names above scoreboard.

## Release gates
- [ ] Godot parse + targeted tests + legacy functional/network checks.
- [ ] Native/Web model rendering and gameplay visual review.
- [ ] Long-running stability measurements; real browser check and native runtime check.
- [ ] 1.2.3 Windows/Web/NAS build, exact source/manifest match, site deployment and public download audit.
- [ ] Preserve unchanged homepage images and descriptions.

## Windows recovery continuation — 2026-09-27

Fetched origin and resumed `da2424b` on the recovery branch. No 1.1.3 source was
merged into this work. Reference JPG was found locally and inspected. Native
`HumanModel`/`AuthoredHuman` and Web `CartoonModel` remain separate; game rules
continue to be shared and Web assets generated only in the isolated staging tree.

Implemented after recovery: mode settings across both Python services, Worker
policy and RTC admission; hard fill-bot lifecycle and dedicated-owner controls;
new foley/announcements with existing gun PCM preserved; smaller carried bomb
and handling poses; DUET pose-only muzzle; softer female jaw and fitted hair;
series winner determined by total wins, rotation after the whole series.

Fresh checks so far: recovery import; updated gameplay 65/65; Python services
19 tests; Worker policy 3 tests; 72,000 tracer / 1,800 healing-update resource
stress bounded. Full legacy regression and rendered Windows/browser sessions
are still running. Old tests expecting combat-time defusal purchase queues,
45-second prep, side swaps every round, old MONOLITH/flash values and host moves
of other humans are being updated to the requested rules, not silently ignored.

No 1.2.3 release or site update has been made. Remaining gates include completed
regressions, live network options/state transitions, rendered asset review,
longer browser session, builds and exact-source publication checks.

Current candidate checks and limits supersede the intermediate counts above: see VALIDATION_V123.md. Source preserves separate rendering. Neck atlas-ID interpolation was corrected after final visual inspection; female eyebrows/jaw width adjusted without increasing mesh count.

