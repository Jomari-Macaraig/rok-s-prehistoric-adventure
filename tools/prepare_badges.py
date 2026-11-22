#!/usr/bin/env python3
"""Imports the badge medals (standard library only):
    python3 tools/prepare_badges.py
    godot --headless --path . --import

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
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "badges"
STATES = {"unearned": 0, "bronze": 1, "silver": 2, "gold": 3}
ALIASES = {"swift_feet": "swift", "iron_hide": "ironhide"}


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
    ids = re.findall(r'^\t"(\w+)": \{"name"', (ROOT / "scripts" / "badges.gd").read_text(), re.M)
    missing = [f"{i}_{s}" for i in ids for s, t in STATES.items() if not (OUT / f"{i}_{t}.png").exists()]
    print(f"{copied} medal files -> {OUT}")
    if missing:
        print("still drawn in code (no art yet):", ", ".join(missing))


if __name__ == "__main__":
    main()
