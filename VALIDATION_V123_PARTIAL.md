# 1.2.3 partial recovery: NOT RELEASE READY

Date: 2026-09-27. Public release remains 1.2.2.
This is a recovery work branch, not a published or fully tested release.

## Environment interruption
The local execution environment disconnected after the dual-pistol code was written.
There is no terminal, filesystem, Godot, or visual test access now.
The changes after checkpoint 3df89dcd377817a0c9f8aa194b3e89ee31fbfa7b were replayed from the exact edit commands in the conversation onto the saved remote files using the GitHub connector.
These recovered bytes have NOT been re-imported or executed. Re-run all relevant gates before release.

## Measurements observed before interruption
- test_resources_v123.gd: 72,000 tracer requests + 1,800 healing updates; 96 tracer objects bounded. Static memory about 24.61 MB, stable resources/nodes; cleanup empty. This validates that earlier isolated batch only.
- test_update_v122.gd previously 49/49 before latest MONOLITH changes. Old expected torso/hands/feet damage values must be updated to the new request; do not use that old pass to validate the current branch.
- Godot 4.4.1 graphical test_stability_v123.gd ran 12 cycles with six demo combatants and real native geometry via Xvfb/Mesa llvmpipe. Initialization guard required six actors. Log had STABILITY_RESULT failures=0. Final cycles:
  - cycle 7: 1,123 nodes; 494 resources; 96,095,023 static bytes; maximum frame 149.956 ms.
  - cycle 8: 1,095 nodes; 494 resources; 95,965,807 static bytes; maximum frame 112.021 ms.
  - cycle 9: 1,080 nodes; 494 resources; 95,903,067 static bytes; maximum frame 106.944 ms.
  - cycle 10: 1,081 nodes; 494 resources; 95,909,723 static bytes; maximum frame 104.236 ms.
  - cycle 11: 1,079 nodes; 494 resources; 95,901,587 static bytes; maximum frame 109.598 ms.
  - Initial cycle maximum frame: 3,191.978 ms, then 473.557 ms next cycle.
  - This used software rendering on Linux, not Windows/GPU hardware and not a browser. It does NOT establish acceptable FPS, absence of crashes, or Windows/Web long-session stability. Demo excludes normal kill-replay workload.
- test_update_v123.gd printed 58/59. The failing check asked for a lethal headshot at 500 m, outside MONOLITH maximum range. Its test distance was corrected to 200 m; the corrected test was NOT rerun. Other tested checks included defusal ownership/death reset/exact planting/close interruptible defuse/stable drops/overtime and team authority/autobot.
- Import through score/lineup additions showed no ERROR lines. Dual pistols were added afterward and were not imported/validated.

## Still incomplete or unverified
- Service mode-option allowlists/defaults (matchmaker Python, directory Python, Cloudflare policy and RTC merge).
- Full defusal buy UI and replacement/class confirmation user interaction, live multiplayer state transitions, all mode victory paths.
- Defusal bomb first/third-person handling animations and smaller carried bomb.
- Team automatic bot lifecycle across joins/leaves and both transports; dedicated owner policy.
- Sound sample changes: old melee whoosh -> equip/deploy, new melee/throw/heavy bounce/UI cues, identical flash/smoke blast. Missing throw/bounce and win_blue/win_orange samples must be generated. Original gun sounds should stay unchanged.
- Female face/hair changes have NOT been made. Reference file ID: file_00000000a2988206970be8a21d6a1e2b. It was inspected: small soft chin, black bangs and tied-back hair. Preserve separate native/Web detail budgets.
- DUET model/handedness/reload/barrel alternation need native and Web visual review; build_pose needs review if called without muzzle geometry.
- First-use native stalls and actual intermittent crashes remain unproven; browser long-run/replay/round-change resource checks still required.
- New model baking, only affected thumbnails (role1/role5/dual_pistols), audio assets, licenses.
- Full regression tests, Godot native/Web builds, network/service tests and manual visual checks.
- Version metadata/workflow/release notes still 1.2.2 deliberately. Do not publish 1.2.3 until complete.
- Site is unchanged. Do not regenerate unrelated images or descriptions.
- Publish game source and artifacts, then pin exact source in site updater and audit Windows ZIP, Web PCK, version manifests and public links before claiming completion.

## Resume
Fetch this branch first; do not overwrite it from an older local checkout.
Read WORK_V123.md and this file, compare retained local files if the environment returns.
Import with Godot, run the corrected tests, finish remaining requirements, and preserve frequent remote checkpoints.

Continuation: see VALIDATION_V123.md for fresh Windows and Web evidence. This original partial report is historical, not the final release verdict.
