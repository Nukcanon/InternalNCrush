"""Run hosting fixtures serially and fail on engine errors, even with exit code zero."""
import os
from pathlib import Path
import re
import subprocess
import sys

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT.parent / "validation/functional-v11"
TESTS = ["rules", "regressions", "ai_aim", "bots", "v04", "v05", "kill_feed", "v06", "v07", "v1", "v101", "vertical_traversal", "v102", "v103", "arena_flow_v103", "network_security", "lobby_menu", "combat_v104", "presentation_v104", "v11", "v111", "abilities_v111", "spawn_exits", "v112", "v113", "turret_replacement", "silhouette_assembly", "ballistics", "cartoon_review", "web_graphics", "render_split", "motion_v115"]

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    failed = []
    for name in TESTS:
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
        (OUT / f"test_{name}.log").write_text(content, encoding="utf-8")
        result = " | ".join(line for line in content.splitlines() if re.search(r"RESULT|FAIL|ERROR|passed", line))
        print(f"{name}: exit={process.returncode} {result}", flush=True)
        if process.returncode or "ERROR" in content or "FAIL" in content:
            failed.append(name)
    print("FUNCTIONAL_FAILED", failed, flush=True)
    return bool(failed)

if __name__ == "__main__":
    sys.exit(main())

