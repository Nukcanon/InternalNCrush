#!/usr/bin/env bash
# Shared CI preparation for every job: Godot 4.4.1, the export templates
# (build job only, WITH_TEMPLATES=1), CC0 asset preparation, the project
# import and the model / door / arena bakes the tests and exports rely on.
set -euo pipefail
GODOT_URL=https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable
GODOT=/tmp/godot/Godot_v4.4.1-stable_linux.x86_64
curl -fL --retry 3 -o /tmp/godot.zip "$GODOT_URL/Godot_v4.4.1-stable_linux.x86_64.zip"
unzip -q /tmp/godot.zip -d /tmp/godot
chmod +x "$GODOT"
if [ "${WITH_TEMPLATES:-0}" = "1" ]; then
  curl -fL --retry 3 -o /tmp/templates.tpz "$GODOT_URL/Godot_v4.4.1-stable_export_templates.tpz"
  mkdir -p ~/.local/share/godot/export_templates/4.4.1.stable
  for template in windows_release_x86_64.exe windows_debug_x86_64.exe web_nothreads_release.zip web_nothreads_debug.zip; do
    unzip -p /tmp/templates.tpz "templates/$template" > ~/.local/share/godot/export_templates/4.4.1.stable/$template
  done
fi
pip install -q Pillow
python3 game/tools/prepare_assets.py
"$GODOT" --headless --path game --editor --import --quit
timeout 300 "$GODOT" --headless --path game --script res://tools/build_models.gd
"$GODOT" --headless --path game --script res://tools/build_door_leaves.gd
"$GODOT" --headless --path game --script res://tools/build_arenas.gd
"$GODOT" --headless --path game --editor --import --quit
