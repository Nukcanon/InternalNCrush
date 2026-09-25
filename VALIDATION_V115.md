# 1.1.5 validation

Runtime source: `8f1ca92fd1c2ca3a77c2f330107c5f19bdf1e761`. Game sources are byte-identical to validated baseline `6cb202107915f61fa74b7a31e362dc25875f6ae6`; only packaging workflow files differ.

Regression run: https://github.com/Nukcanon/InternalNCrush/actions/runs/36133628094

The 32 functional suites passed **3818/3818** checks; touch passed **35/35**. The 32-client capacity test, independent clients, restart/reconnect lifecycle (normal and late startup), authoritative movable props, rotation synchronization and actual host/client WebRTC snapshots all passed. That run later stopped only because the redundant Web photo capture did not find a clear active fight in its time limit. Packaging run https://github.com/Nukcanon/InternalNCrush/actions/runs/36136057333 reuses the already reviewed native combat photographs for the Web slideshow, checks that every runtime input directory is identical, and verifies every reused validation step succeeded before packaging. It does not treat the earlier overall run as successful.

## Changes verified in Godot 4.4.1

- Native/Web rendering paths are independent. Native retains detailed HumanModel geometry and original surface finishes; Web staging uses its own simplified geometry and materials.
- Motion regression: 22/22 checks. Low steps at 8 cm and 22 cm are traversable without jumping; a 45 cm obstacle is blocked. Lightweight deaths travel along the bullet direction, lie flat and contact the floor in four directions. A native corpse wedged between narrow static walls freezes as a complete chain, with finite positions and no continuing joint jitter.
- Native ragdoll regression: 14/14 checks. Head, torso and leg impacts travel an exaggerated 1–3 m, finish lying flat, retain the original struck limb and stay above the floor. A corpse dropped from height reaches the floor before settling.
- Audio feedback regression: 13/13 checks. Original generated sound assets remain unchanged; important hit, hurt and deployment cues have reserved voices and produce non-silent PCM.
- Visual review: larger first-person hands and thicker arms retain sight alignment; ready/disabled/cooldown skill badges are centred and legible; native bullet holes have additional cracks and grain; both death systems end with spread limbs on the floor.
- Menu image capture uses actual bot combat and verifies 12 JPEGs at 1920×1080. Web runs a randomized two-texture crossfade instead of a live menu simulation; native retains live bots and removes the menu world on entering a match.

## Anti-jitter behavior

Native bodies have continuous collision detection, mutual collision exclusions, bounded velocities and damping. Grounded quiet or wedged bodies settle together; persistent ground contact also bounds the active joint simulation. Every body is frozen and its velocities cleared in one operation. Airborne bodies continue falling. This avoids indefinite solver vibration without reversing the requested bullet-direction launch. The lightweight Web death uses one collider and animation, so it does not have an articulated joint chain to oscillate.

## Scope

Validation uses Linux Godot automation, rendered frames, independent network processes and exported Windows/Web packages. It does not substitute for running the Windows executable on the owner's monitor or benchmarking an actual low-end GPU or phone. No hardware FPS improvement or universal geometry guarantee is claimed. The supplied narrow-wall, floor and airborne regressions cover the reported persistent vibration mechanism.

Exact published assets, hashes and deployment commits are recorded in `PUBLICATION_STATUS.json`.

## Published result

Packaging run 36136057333 and publication run 36136902187 succeeded. Release tag `internal-n-crush-v1.1.5` points to the exact packaged source. Site installer run 36137008744 and Pages run 36137051752 succeeded, deploying site commit `376525a824a95fdf214912a5543bd0d9e2ad5d52`. The public homepage was opened and its 1.1.5 label and exact Windows/play links were confirmed. The remote browser reports missing WebGL2, so actual public Web gameplay and menu animation could not be interactively confirmed in that environment. Godot-rendered frames and build validation are separate evidence, not a claim of browser gameplay verification.
