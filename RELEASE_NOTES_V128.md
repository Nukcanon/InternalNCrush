# Internal N Crush 1.2.8 candidate

Not published yet. Release gates and remaining checks are recorded in
VALIDATION_V128_PARTIAL.md.

- Rebuild 21 competitive maps with distinct grounded terraces, stairs and
  circulation. Retain one rectangular and one supported-crossing map per
  supported capacity, plus the practice arena.
- Add 32 original Blender props, curated by map theme, and regional wall/floor
  palettes. Share imported geometry/materials to avoid per-instance duplication.
- Correct mobile map pinch anchoring, fixed-size auto-fire/sprint controls,
  circular touch controls under nonuniform viewport scaling, and slide gestures.
- Restore an explicit forward-slide touch button. Match crouch/jump sizes and
  avoid the equipment button with the smaller mobile killcam bar.
- Keep match score/time hidden when closing equipment during a killcam.

The user's subsequent request is a separate follow-up after this stabilization:
expand the distinct prop catalogue beyond 200; visually distinguish open sea
(fatal immersion) from shallow, safely traversable rivers. These are not claimed
as implemented in this candidate.
