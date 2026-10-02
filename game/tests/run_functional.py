"""Run hosting fixtures serially and fail on engine errors, even with exit code zero."""
import os
from pathlib import Path
import re
import subprocess
import sys

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT.parent / "validation/functional-v11"
TESTS = ["rules", "regressions", "ai_aim", "bots", "v04", "v05", "kill_feed", "v06", "v07", "v1", "v101", "vertical_traversal", "v102", "v103", "arena_flow_v103", "network_security", "lobby_menu", "combat_v104", "presentation_v104", "v11", "v111", "abilities_v111", "spawn_exits", "v112", "v113", "turret_replacement", "silhouette_assembly", "ballistics", "cartoon_review", "web_graphics", "render_split", "motion_v115", "details_v116", "details_gameplay_v116", "melee_v117", "support_v118", "update_v119", "selection_v120", "update_v121", "update_v122", "update_v123", "resources_v123", "native_finish_v124", "defusal_v124", "room_routes_v125", "traversal_contacts", "capture_v126", "drops_v127", "practical_lights", "v141", "v142", "v144", "v145", "sight_clearance_v151"]

def run_group(name):
    command = [os.environ.get("GODOT", "godot"), "--headless", "--path", str(PROJECT), "--script", f"res://tests/test_{name}.gd", "--", "--no-save-profile", "--no-update-check"]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    try:
        content, _ = process.communicate(timeout=360)
    except subprocess.TimeoutExpired:
        if os.name == "nt":
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW)
        else:
            process.kill()
        content, _ = process.communicate()
        content += "\nFAIL test timeout\n"
    return process.returncode, content

def main():
    for test in ["optics_v13", "room_weapons_v13", "settings_guard_v13", "combat_refresh", "bot_settings", "dialog_style", "objective_floor_markers", "lobby_v135", "screens_v14", "water_v128", "v146_water", "v146_fall"]:
        if test not in TESTS:TESTS.append(test)
    OUT.mkdir(parents=True, exist_ok=True)
    failed = []
    args = sys.argv[1:]
    selected = TESTS
    # CI runs the groups split across parallel jobs: --shard <index>/<count>.
    if args[:1] == ["--shard"]:
        index, count = (int(value) for value in args[1].split("/"))
        selected = [name for position, name in enumerate(TESTS) if position % count == index]
        args = args[2:]
    if args:
        selected = args
    if any(name not in TESTS for name in selected):
        raise ValueError("Unknown test group")
    print("FUNCTIONAL_GROUPS", len(selected), "of", len(TESTS), flush=True)
    for name in selected:
        # A handful of physics-timing groups (v04's movement spread) are flaky
        # under CPU contention: one immediate retry separates flakes from regressions.
        for attempt in range(2):
            returncode, content = run_group(name)
            (OUT / f"test_{name}.log").write_text(content, encoding="utf-8")
            result = " | ".join(line for line in content.splitlines() if re.search(r"RESULT|FAIL|ERROR|passed", line))
            print(f"{name}: exit={returncode} {result}" + (" (retry)" if attempt else ""), flush=True)
            ok = not (returncode or "ERROR" in content or "FAIL" in content)
            if ok:
                break
        else:
            failed.append(name)
    print("FUNCTIONAL_FAILED", failed, flush=True)
    return bool(failed)

if __name__ == "__main__":
    sys.exit(main())

