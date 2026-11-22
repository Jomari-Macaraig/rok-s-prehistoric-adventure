#!/usr/bin/env python3
"""The user's seamless terrain (../Assets/Rok_Seamless_Terrain) -> assets/terrain/.

The pack is the game's terrain set rebuilt to join seamlessly: `standard/`
at the game's sizes, `hd/` at 4x (the grass pieces, dirt and cobble) or 2x
(the 1280x420 ground strips). Each file goes to assets/terrain/<name>.png
(standard) with a <name>@2x.png twin made from the HD art (SpriteLib.tex
draws it at the standard size, sharp on phones).

terrain.json is rebuilt from the pack's join rows (tiles.json `connectors`):
the grass pieces meet pixel-exactly at those rows (flats at y 8, the slopes'
low ends at 61, the drop's at 56), so each piece's `left`/`right` grass line
is its join row minus JOIN_TO_TIP (the grass tips stand 3 px above the join,
keeping Tuning.FEET_BELOW_GRASS's meaning). One level is the slope's rise
(53 px). The drop falls only 48 px, so it's scaled up by 53/48 to fall
exactly one level (as the old pipeline did). `mid` and the physics `profile`
are measured from the art as before.

Standard library + Pillow:
    uv run --no-project --with pillow python tools/prepare_terrain.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT.parent / "Assets" / "Rok_Seamless_Terrain"
OUT = ROOT / "assets" / "terrain"
PIECES = ["mid_a", "mid_b", "cap_left", "cap_right", "slope_up", "slope_down", "drop"]
FILLS = ["dirt", "cobble", "desert_ground", "volcanic_ground", "forest_ground"]
JOIN_TO_TIP = 3


def grass_top(img: Image.Image, x0: int, x1: int) -> float:
    """Median first-opaque row across columns x0..x1 (the grass tips)."""
    a = img.getchannel("A")
    tops = []
    for x in range(max(0, x0), min(img.width, x1)):
        for y in range(img.height):
            if a.getpixel((x, y)) > 128:
                tops.append(y)
                break
    tops.sort()
    return float(tops[len(tops) // 2]) if tops else 0.0


def save_pair(std: Image.Image, hd: Image.Image, name: str, size: tuple) -> Image.Image:
    """Save the 1x file at `size` and the @2x twin at exactly twice it."""
    w, h = size
    one = std if std.size == (w, h) else std.resize((w, h), Image.LANCZOS)
    one.save(OUT / f"{name}.png", optimize=True)
    hd.resize((w * 2, h * 2), Image.LANCZOS).save(OUT / f"{name}@2x.png", optimize=True)
    print(f"terrain/{name}.png {w}x{h} (+@2x)")
    return one


def main() -> None:
    tiles = json.loads((PACK / "tiles.json").read_text())["assets"]
    OUT.mkdir(parents=True, exist_ok=True)
    slope = tiles["slope_up"]["standard"]["connectors"]
    step = slope["left"][1] - slope["right"][1]   # 53
    meta = {}
    for name in PIECES:
        std = Image.open(PACK / "standard" / f"{name}.png").convert("RGBA")
        hd = Image.open(PACK / "hd" / f"{name}.png").convert("RGBA")
        con = tiles[name]["standard"].get("connectors", {})
        k = 1.0
        if name == "drop":
            k = step / (con["right"][1] - con["left"][1])   # 53 / 48
        size = (round(std.width * k), round(std.height * k))
        img = save_pair(std, hd, name, size)
        w = img.width
        sy = img.height / std.height
        # grass line at each end: the join row (scaled) minus the tip offset;
        # a cap's outside end is its measured rounded edge
        left = con["left"][1] * sy - JOIN_TO_TIP if "left" in con else grass_top(img, 2, w // 2)
        right = con["right"][1] * sy - JOIN_TO_TIP if "right" in con else grass_top(img, w // 2, w - 2)
        meta[name] = {
            "size": [w, img.height],
            "left": round(left, 2),
            "right": round(right, 2),
            "mid": grass_top(img, w // 3, 2 * w // 3),
            "profile": [[x, grass_top(img, x - 5, x + 6)] for x in range(0, w + 1, max(1, w // 10))],
        }
    for name in FILLS:
        std = Image.open(PACK / "standard" / f"{name}.png").convert("RGBA")
        hd = Image.open(PACK / "hd" / f"{name}.png").convert("RGBA")
        save_pair(std, hd, name, std.size)
    meta["level_step"] = meta["slope_up"]["left"] - meta["slope_up"]["right"]
    (OUT / "terrain.json").write_text(json.dumps(meta, indent=1))
    print("level_step", meta["level_step"])


if __name__ == "__main__":
    main()
