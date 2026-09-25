# Internal N Crush 1.1.5 handoff

## Required behavior

The owner authorized fixing both repositories, validating with Godot, and publishing 1.1.5 and the homepage. Native graphics must retain the detailed original 1.1.4 models/materials with moderate optimization. Web is independently lightweight. Do not flatten native graphics to the Web profile again, simplify audio, or remove game modes, bots, practice or kill replay.

Original 1.1.4 reference: `3e87f868e10cefa98db9723096fcfe4b55f25710`, tag `internal-n-crush-v1.1.4`. The 1.1.5 runtime source is `8f1ca92fd1c2ca3a77c2f330107c5f19bdf1e761`; game code is identical to validated baseline `6cb202107915f61fa74b7a31e362dc25875f6ae6`. Later documentation/publication commits do not change that runtime. Exact publication details are in `PUBLICATION_STATUS.json`.

## Implemented

- Native: original detailed HumanModel and material paths restored. Skin stays painted instead of photographic. The medium preset balances lighting/shadows while preserving geometry and finishes. Native menu shows real bot combat and removes it when starting gameplay.
- Native defaults: current monitor resolution, fullscreen and medium graphics; a one-time 115 profile migration applies these, then saved settings are respected. The restore button says **기본설정으로 복원**.
- Web: isolated staging selects lightweight models/materials via `application/config/web_assets`; it does not mutate native source assets. Fixed grazing-angle ink shading that made distant floors/objects excessively dark, plus minimum lighting brightness. Automatic graphics remains the default and retains user presets/options.
- Web menu: 12 actual 1920×1080 bot-combat captures, shuffled crossfades, two resident textures, no live menu simulation. Capture checks firing recency, opponent distance and unobstructed viewpoints.
- Original audio generation was not simplified. Reserved feedback voices protect hit/hurt/deployment cues from gunfire voice stealing. Deployment events use reliable delivery. Turret damage triggers enemy hit feedback just like character damage.
- Native death physics has selectable quality; authoritative movable props remain pushable/shootable. Both death systems keep exaggerated motion **along bullet travel**, then lie flat with spread limbs. This direction was already intentional, not a bug to reverse.
- Native ragdoll uses whole-chain settling for quiet/wedged persistent contacts, bounded velocities, damping, continuous collision detection and mutual limb collision exceptions. Lightweight Web death uses one collider and animated fall. Narrow-wall and airborne regression cases are included.
- Grounded actors traverse static steps up to 28 cm automatically; higher obstacles, airborne movement, ceilings and movable props do not receive this shortcut.
- Bullet marks: chipped dark core on Web; additional cracks, grain and rim detail on native. These are visual decals, not destructive collision holes.
- First-person hands enlarged 32%; forearm thickness increased about 43%; weapon scale and aim alignment preserved.
- Skill icons centred from real path bounds with shallow embossed shading. Disabled/cooldown state colors preserved.
- Earlier cooldown/turret replacement, deployment, scrolling, touch sprint toggle, slide, aim assistance, kill-feed, UI wording, mild bullet drop and Web clarity changes are retained.

## Validation and deployment

See `VALIDATION_V115.md` for test scope and `PUBLICATION_STATUS.json` for exact results/assets. The build workflow validates native/Web rendering, motion and ragdolls, captures review images, checks actual audio PCM, runs all functional/network/touch tests, then exports Windows/Web/NAS and creates a draft release. The publication workflow verifies the successful build, source SHA and asset hashes before exposing the draft. The site installer verifies archive and individual file hashes, installs hashed runtime filenames, and requests Pages publication.

Hardware limitations: Windows executable interaction on the owner's monitor, low-end GPU frame rates, physical mobile controls/performance and real WAN/NAT multiplayer are not covered by Linux automation. Do not describe these as verified. Do not infer benchmark improvements from export success.

## Maintenance cautions

Both GitHub repositories contain more files than the local partial editing workspace. Always create trees from the current remote base tree and fast-forward refs; never replace a tree from a partial file listing. Fetch the current branch first.

The build workflow refuses to overwrite a published 1.1.5 release. Future runtime changes need an explicit release strategy/version decision. Root documentation commits do not trigger the full game build. The original 1.1.4 source tag remains available for comparison.
