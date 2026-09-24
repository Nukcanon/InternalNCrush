# Web / mobile

Godot 4.4.1 Compatibility, WebGL 2, single-thread export. No SharedArrayBuffer/COOP/COEP requirement; suitable for GitHub Pages. Desktop and mobile texture imports are enabled. Browser files are generated, not committed to this source repository.

```sh
python game/tools/prepare_assets.py
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tools/build_models.gd
godot --headless --path game --script res://tools/build_arenas.gd
godot --headless --path game --editor --import --quit
python -m pip install Pillow
python web/prepare_lightweight.py
godot --headless --path web/staging/game --editor --import --quit
godot --headless --path web/staging/game --script res://tools/lightweight_models.gd
# Create web/build first; supply an absolute output path.
godot --headless --path web/staging/game --export-release Web /absolute/path/web/build/index.html
python web/package_web.py
```

Publish the complete `web/build` directory to the website's `play/` directory. `build.json` records file sizes and SHA-256 values. Every individual file must remain below GitHub's 100 MiB limit. A user gesture starts audio/game loading; fullscreen is optional. WebGL 2 and enough memory for the approximately 74 MB uncompressed download are needed. Mobile controls appear only for mobile/coarse touch devices, in landscape. Web uses simplified materials, textures capped at 256 px, reduced visual meshes, and no extra lights, shadows or anti-aliasing. Smoke and combat signals remain enabled.

The shared 3D world renders into a separate adaptive viewport, capped at 540 pixels high on desktop and 432 on touch devices, with a 288-pixel lower bound. UI renders at the original resolution. The menu battle background uses reduced resolution and a 15 FPS update rate. Browser and OS settings still determine the GPU; GTX960 and physical-mobile performance have not been measured.

Left floating stick moves; its outer edge runs. Drag the right side to look; drag the fire button while firing to aim. ADS and crouch toggle; weapon/ability tiles, reload, jump, use, gear, gadget cooking and placement mode have touch buttons. Desktop retains keyboard/mouse. Physical-device performance is not inferred from desktop touch simulation.

Browser networking cannot use UDP LAN discovery. Browser LAN and Internet use the WebRTC-compatible room directory; Windows users select the matching lobby. Practice/bot combat works without a directory after the game loads. GitHub Pages cannot itself run that directory. See `nas/` and `services/cloudflare-directory/`.

Desktop pointer capture starts from a click. If an embedded browser denies it, the game keeps keyboard movement, click fire and drag aiming available and displays a short explanation.
