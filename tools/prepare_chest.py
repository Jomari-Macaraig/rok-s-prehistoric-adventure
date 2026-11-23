#!/usr/bin/env python3
"""The user's milestone chests, one per rarity -> assets/items/chest_<tier>_*.

Source: ../Assets/Rok_Chest_Rarities (README there). Four tiers: common (the
original red-brown chest), rare (teal wood, sapphire clasp), ultra_rare
(purple obsidian, amber bands, tusks) and legendary (amber-gold armour,
horns, primal-crystal clasp). Each tier has a 12-frame opening sheet (4x3,
99x102 cells at 1x; frame 0 closed, 7 open, 8-11 open-chest glints), a
closed and an open still, each with an @2x twin. The pack is game-ready, so
the files are copied as they are; the pivot is the cell's bottom centre.

Writes chest.json: the frame size, the tiers, and the clips (open 0-7 once,
sparkle 8-11 looping) with their frame times (about 12 fps, as the README
suggests). Read by Pickup._chest_frames.

    python3 tools/prepare_chest.py
then godot --headless --path . --import
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Chest_Rarities"
OUT = ROOT / "assets" / "items"
TIERS = ["common", "rare", "ultra_rare", "legendary"]
OLD = ["chest_anim", "chest_closed", "chest_open"]   # the single chest before the tiers


def main() -> None:
    for t in TIERS:
        for part in ("anim", "closed", "open"):
            for sfx in ("", "@2x"):
                name = f"chest_{t}_{part}{sfx}.png"
                shutil.copyfile(SRC / t / name, OUT / name)
    for o in OLD:
        for sfx in ("", "@2x"):
            for ext in (".png", ".png.import"):
                (OUT / f"{o}{sfx}{ext}").unlink(missing_ok=True)
    meta = {"frame": [99, 102], "tiers": TIERS,
            "open": list(range(8)), "open_ms": [70, 70, 80, 90, 90, 90, 100, 140],
            "sparkle": [8, 9, 10, 11], "sparkle_ms": [160, 160, 160, 160]}
    (OUT / "chest.json").write_text(json.dumps(meta, indent=1))
    print("items/chest_<tier>_{anim,closed,open}.png (+@2x) for", ", ".join(TIERS))


if __name__ == "__main__":
    main()
