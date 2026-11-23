#!/usr/bin/env python3
"""Imports the badge medals (standard library only):
    python3 tools/prepare_badges.py
    godot --headless --path . --import

Also SIZED packs (Rok_Day_Night_Badges: Point Hunter and Seasoned), whose
sizes/256/badges/<family>/badge_<family>_<state>.png are scaled to 168 px
with macOS sips (locked = unearned).

Source: every ../Assets/Rok_*Medal* folder (e.g. Rok_Badge_Medals_47_of_52 and
the top-up Rok_Missing_5_Medals) plus any ../Assets/Rok_*/medals folder (e.g.
the medals in Rok_Hunters_Crouches_Best_Distance), oldest first so newer art
wins, each with png_168/<id>_<state>.png (ALIASES maps a pack's file names to
the game's badge ids)
(square, transparent; 168 px = 2x the 84 px they're shown at). States map to
the game's tiers: unearned 0, bronze 1, silver 2, gold 3. Output:
assets/badges/<id>_<tier>.png, which Badges.icon() loads; any medal still
missing keeps the medal drawn in code. Prints what's missing per badge id
listed in scripts/badges.gd.
"""
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "badges"
STATES = {"unearned": 0, "bronze": 1, "silver": 2, "gold": 3}
ALIASES = {"swift_feet": "swift", "iron_hide": "ironhide", "point_hunter": "scorer", "seasoned": "veteran"}
# Packs laid out as badges/<family>/badge_<family>_<locked|bronze|silver|gold>.png
# with sizes/256/ copies (Rok_Day_Night_Badges): scaled to 168 px with macOS sips.
SIZED = ["Rok_Day_Night_Badges"]


def main():
    assets = ROOT.parent / "Assets"
    found = list(assets.glob("Rok_*Medal*")) + list(assets.glob("Rok_*/medals"))
    packs = sorted((p for p in found if (p / "png_168").is_dir()), key=lambda p: p.stat().st_mtime)
    if not packs:
        raise SystemExit("No ../Assets/Rok_*Medal* folder with png_168 found")
    OUT.mkdir(parents=True, exist_ok=True)
    copied = 0
    for pack in packs:
        n = 0
        for f in sorted((pack / "png_168").glob("*.png")):
            m = re.fullmatch(r"(.+)_(unearned|bronze|silver|gold)", f.stem)
            if m:
                bid = ALIASES.get(m.group(1), m.group(1))
                shutil.copyfile(f, OUT / f"{bid}_{STATES[m.group(2)]}.png")
                n += 1
        print(f"{n} medals from {pack.relative_to(assets)}")
        copied += n
    for name in SIZED:
        src = assets / name / "sizes" / "256" / "badges"
        n = 0
        for f in sorted(src.glob("*/badge_*.png")):
            m = re.fullmatch(r"badge_(.+)_(locked|bronze|silver|gold)", f.stem)
            if not m:
                continue
            bid = ALIASES.get(m.group(1), m.group(1))
            tier = 0 if m.group(2) == "locked" else STATES[m.group(2)]
            dst = OUT / f"{bid}_{tier}.png"
            subprocess.run(["sips", "-z", "168", "168", str(f), "--out", str(dst)], check=True, capture_output=True)
            n += 1
        print(f"{n} medals from {name} (256 px scaled to 168)")
        copied += n
    ids = re.findall(r'^\t"(\w+)": \{"name"', (ROOT / "scripts" / "badges.gd").read_text(), re.M)
    missing = [f"{i}_{s}" for i in ids for s, t in STATES.items() if not (OUT / f"{i}_{t}.png").exists()]
    print(f"{copied} medal files -> {OUT}")
    if missing:
        print("still drawn in code (no art yet):", ", ".join(missing))


if __name__ == "__main__":
    main()
