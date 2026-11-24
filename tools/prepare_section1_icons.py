#!/usr/bin/env python3
"""The user's campaign section 1 icons (../Assets/Rok_Section1_Icons) ->
assets/ui/icons/<name>.png (+@2x), standard library only.

Copies the pack's `icons/` (torch_lit, torch_spent, strength, kora_blessing,
star_gold, star_empty; `accessories/*` and `boss_materials/*` keep their
file names) and the two animated loops in `animations/` (kora_blessing_glow,
torch_flicker: 4x2 sheets with their JSON). The pack already ships each at
1x and @2x, so files are copied as they are. Used so far: kora_blessing (the
Market's Kora's Blessing and the Items screen). The rest wait for their
tickets (torches 17, Strength 14, accessories 12, boss materials 22-23,
stars 18).

    python3 tools/prepare_section1_icons.py
then godot --headless --path . --import
"""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Section1_Icons"
OUT = ROOT / "assets" / "ui" / "icons"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted((SRC / "icons").rglob("*.png")):
        shutil.copyfile(f, OUT / f.name)
        n += 1
    for f in sorted((SRC / "animations").glob("*")):
        if f.is_file() and f.suffix in (".png", ".json"):
            shutil.copyfile(f, OUT / f.name)
            n += 1
    print("copied", n, "files to", OUT)


if __name__ == "__main__":
    main()
