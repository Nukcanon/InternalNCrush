# Web / mobile

Godot 4.4.1 Compatibility, WebGL 2, single-thread export. No SharedArrayBuffer/COOP/COEP requirement; suitable for GitHub Pages. Desktop and mobile texture imports are enabled. Browser files are generated, not committed to this source repository.

```sh
python game/tools/prepare_assets.py
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tools/build_models.gd
godot --headless --path game --script res://tools/build_arenas.gd
godot --headless --path game --editor --import --quit
# Use xvfb-run on a Linux build machine without a display.
godot --path game --script res://tools/build_thumbnails.gd
godot --headless --path game --editor --import --quit
python -m pip install Pillow
python web/prepare_lightweight.py
godot --headless --path web/staging/game --editor --import --quit
godot --headless --path web/staging/game --script res://tools/lightweight_models.gd
# Create web/build first; supply an absolute output path.
godot --headless --path web/staging/game --export-release Web /absolute/path/web/build/index.html
python web/package_web.py
```

This branch is **not yet exported or published**. The website's `play/` binaries remain the previous 1.1.4 build. The user requested replacing the existing 1.1.4 release. The updated main workflow publishes Windows/Web assets only after its engine tests and exports succeed; the website workflow verifies and installs the complete Web archive. Visual/device review is still required to assess actual appearance and performance. See game/docs/MANUAL_UPLOAD.md. `build.json` records file sizes and SHA-256 values. Each file must stay under 100 MiB. CI exports with a commit-specific executable basename and serves the generated HTML as index.html to avoid mixing old cached runtime files. The package also creates a Web ZIP and its source-commit/hash descriptor in out/. Do not copy a source script into the existing compiled PCK or update instructions before replacing the complete build.

The revised Web profile preserves all five modes, all arenas, practice, bots, replay, damage, networking, props and tactical smoke. It uses original low-poly comic operators and texture-free paint shaders, animated deaths instead of ragdolls, no cosmetic rigid-body debris, batched prop visuals, and no background menu battle. Kill replay and its warm-up/capture remain active. Animated fingers and weapon reload sockets remain intact. The build regenerates equipment thumbnails from the new models, so old photographic-looking cards do not survive in the exported menu.

Quality defaults to **Auto**, starting at Medium/100% with fixed cartoon shading and no shadows/MSAA/fog. Low, Medium, High and Custom are also available. Custom controls include lighting, 1024 shadows, MSAA 2×/4×, decoration, fog, 3D sharpness and FPS cap. Manual choices disable automatic changes. The HUD stays at output resolution. Saved Windows resolution settings no longer rescale the Web view.

Auto samples rendered combat frames in 3-second windows after an 8-second warm-up. It ignores menus, replay and background tabs; two sustained slow windows lower effects before resolution, while five healthy windows restore resolution before effects. Changes have an 18-second hold period. Auto never goes below 85%; 70% requires manual selection. No setting changes model/texture quality, bot count or gameplay. Web preserves the complete near-view comic, weapon and architecture base meshes. It adds distance LODs instead of permanently replacing them with the old heavily decimated meshes. Facial marks, hands and nearby silhouettes therefore retain the authored geometry. Final mesh counts, compressed download size and real FPS require a fresh export; old 1.1.4 counts are not measurements of this revision.

Optimization references: [Godot 3D performance](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html). Stock Web exports do not include occlusion culling, so enabling that setting alone is not an optimization.

Left floating stick moves; sprint uses an explicit on/off toggle. Slide starts in the facing direction, including from rest. Drag the right side to look; drag the fire button while firing to aim. ADS and crouch toggle; weapon/ability tiles, reload, jump, use, gear, gadget cooking and placement confirmation have touch buttons. The bomb action appears only in defusal mode and is grey until planting/defusing is possible. Optional aim assist and auto fire are in Settings; auto fire defaults off. Desktop retains keyboard/mouse. Physical-device performance is not inferred from desktop touch simulation.

Browser networking cannot use UDP LAN discovery. Browser LAN and Internet use the WebRTC-compatible room directory; Windows users select the matching lobby. Practice/bot combat works without a directory after the game loads. GitHub Pages cannot itself run that directory. See `nas/` and `services/cloudflare-directory/`.

Desktop pointer capture starts from a click. If an embedded browser denies it, the game keeps keyboard movement, click fire and drag aiming available and displays a short explanation.
