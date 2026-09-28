# 1.2.8 work in progress — not a release

Current branch: `work/v1.2.8-districts-mobile`. Published 1.2.7 is unchanged.

## Completed local checks

- Blender 5.2.2 LTS executable verified at the user-provided installation path.
- 32 original props built reproducibly by `game/tools/build_themed_props.py`:
  market stalls and displays, bookshelves, laboratory equipment, workshop
  machines, dock equipment, garden furniture and utility fixtures. Editable sources are
  under `art_source/district_original`; only GLBs enter the game asset directory.
- All 32 GLBs imported and rendered by Godot 4.4.1 Compatibility on RTX 4080
  SUPER. Each has one material and preserves vertex colour. Total GLB size is
  1,763,088 bytes. No external texture dependencies.
- Theme-specific placement replaces some unrelated cars/tanks. Prop navigation
  bounds now come from actual imported geometry rather than one generic box.
- Mobile input regression: 43/43. Dedicated gesture/aspect-ratio tests pass.
  Map pinch regression passes for stationary
  pinch midpoint, synthetic mouse suppression, corrupt relative drag vectors,
  transition to one finger, and reset.
- Latest layout path check: 508/508 across 31 competitive maps, including
  grounded terraces and the latest prop bounds. 954 static placement anchors
  across 32 maps; one dock anchor is a service cabin instead of a prop instance.
- Native/Web 32-map state and physics signatures match after the final
  landing selection and dock cabin correction.
- Spawn regression 77/77, traversal/levels 319/319, door regression 125/125,
  slide regression 101/101. Updated tests reflect the explicitly requested
  restored slide button and authored terrain instead of universal raised decks.
- Review captures: `validation/v128/authored-props.png` and 24 map views.
  Eight map viewpoints were inspected/captured; this is not an exhaustive
  walkthrough or a substitute for competitive playtesting.

## Work still required before release

- Complete manual map walkthroughs and performance gates. 21 layouts now use
  distinct grounded terrain; five rectangle and five supported-crossing maps
  remain, plus practice. Generated layouts passing path tests do not prove
  competitive balance or visual quality. Regional material palettes and
  theme-specific prop rosters are implemented.
- Character replacement: CC0 Quaternius Universal Base Characters Standard pack
  downloaded and inspected, **not yet installed into the runtime character rig**.
  The free pack contains superhero male/female bodies; regular/teen source files
  are not in this download. Retargeting, clothes, hair, low-detail variants,
  animation and first-person hands still need validation.
- Full latest map route pass, desktop/Web caches, physics parity, runtime tests,
  device-sized UI captures, sustained performance/memory scenarios and release
  build remain. No physical Intel iGPU or phone measurements have been made.
- Publish only after validation; do not describe this branch as shipped 1.2.8.

## External character source

https://quaternius.itch.io/universal-base-characters

Downloaded `Universal Base Characters[Standard].zip`. Included
`License_Standard.txt` specifies CC0 1.0 Universal. Original archive remains in
the user's Downloads folder; extracted source in the workspace sibling `.tools`
directory. Do not vendor paid Source content or entire unused texture packs.
