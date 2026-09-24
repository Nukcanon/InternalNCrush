# Web / mobile

Godot 4.4.1 Compatibility, WebGL 2, single-thread export. No SharedArrayBuffer/COOP/COEP requirement; suitable for GitHub Pages. Desktop and mobile texture imports are enabled. Browser files are generated, not committed to this source repository.

```sh
python game/tools/prepare_assets.py
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tools/build_models.gd
godot --headless --path game --script res://tools/build_arenas.gd
godot --headless --path game --editor --import --quit
# Create web/build first.
godot --headless --path game --export-release Web ../web/build/index.html
python web/package_web.py
```

Publish the complete `web/build` directory to the website's `play/` directory. `build.json` records file sizes and SHA-256 values. Every individual file must remain below GitHub's 100 MiB limit. A user gesture starts audio/game loading; fullscreen is optional. WebGL 2 and enough memory for the approximately 110 MB uncompressed download are needed. Mobile controls appear only for mobile/coarse touch devices, in landscape; low graphics are selected on first mobile launch. Smoke and combat signals remain enabled.

Left floating stick moves; its outer edge runs. Drag the right side to look; drag the fire button while firing to aim. ADS and crouch toggle; weapon/ability tiles, reload, jump, use, gear, gadget cooking and placement mode have touch buttons. Desktop retains keyboard/mouse. Physical-device performance is not inferred from desktop touch simulation.

Browser networking cannot use UDP LAN discovery. Browser LAN and Internet use the WebRTC-compatible room directory; Windows users select the matching lobby. Practice/bot combat works without a directory after the game loads. GitHub Pages cannot itself run that directory. See `nas/` and `services/cloudflare-directory/`.
