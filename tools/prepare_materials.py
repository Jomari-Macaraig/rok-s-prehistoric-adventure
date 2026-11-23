#!/usr/bin/env python3
"""The user's crafting material icons (../Assets/Rok_Missing_Material_Assets).

The pack's icons are named "<number>_<material id>.png" (e.g. 04_fern_frond.png)
in icons_512/<rarity>/ and icons_128/<rarity>/: transparent, no frame or text
(the game draws the rarity border and counts). For every icon whose id is a
material in config/crafting.cfg this writes assets/materials/<id>@2x.png
(the 512 export scaled to 256) and <id>.png (the 128 export), which
Crafting.icon picks up (SpriteLib.tex prefers the @2x twin). Icons for ids
not in the config are reported and skipped; materials with no icon keep the
placeholder drawn in code.

    uv run --no-project --with pillow python tools/prepare_materials.py
then godot --headless --path . --import
"""
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PACKS = [ROOT.parent / "Assets" / "Rok_Missing_Material_Assets" / "Rok_Material_Assets"]
OUT = ROOT / "assets" / "materials"


def material_ids() -> set:
    ids = set()
    in_mats = False
    for line in (ROOT / "config" / "crafting.cfg").read_text().splitlines():
        if line.startswith("["):
            in_mats = line.strip() == "[materials]"
        elif in_mats and "=" in line and not line.startswith(";"):
            ids.add(line.split("=", 1)[0].strip())
    return ids


def main() -> None:
    ids = material_ids()
    OUT.mkdir(parents=True, exist_ok=True)
    done, unknown = [], []
    for pack in PACKS:
        for f in sorted((pack / "icons_512").glob("*/*.png")):
            mid = re.sub(r"^\d+_", "", f.stem)
            if mid not in ids:
                unknown.append(mid)
                continue
            big = Image.open(f).convert("RGBA").resize((256, 256), Image.LANCZOS)
            big.save(OUT / f"{mid}@2x.png", optimize=True)
            small = next((pack / "icons_128").glob(f"*/{f.name}"), None)
            (Image.open(small).convert("RGBA") if small else big.resize((128, 128), Image.LANCZOS)).save(OUT / f"{mid}.png", optimize=True)
            done.append(mid)
    print(f"{len(done)} material icons written to {OUT}")
    if unknown:
        print("not in config/crafting.cfg (skipped):", ", ".join(unknown))
    missing = sorted(ids - set(done) - {p.stem for p in OUT.glob('*.png') if '@2x' not in p.stem})
    if missing:
        print("still drawn in code (no icon yet):", ", ".join(missing))


if __name__ == "__main__":
    main()
