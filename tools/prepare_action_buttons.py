#!/usr/bin/env python3
"""The user's action buttons (../Assets/Rok Prehistoric Action Button Trio.png:
jump, slide, attack side by side, icons baked in) -> assets/ui/button_<name>.png
(trimmed to the round badge, squared, 200 px) + an @2x twin (400 px), drawn
by TouchButton.art at the button's diameter through SpriteLib.tex.

    uv run --no-project --with pillow python tools/prepare_action_buttons.py
then godot --headless --path . --import
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok Prehistoric Action Button Trio.png"
OUT = ROOT / "assets" / "ui"
NAMES = ["jump", "slide", "attack"]
SIZE = 200


def main() -> None:
    sheet = Image.open(SRC).convert("RGBA")
    w = sheet.width // 3
    OUT.mkdir(parents=True, exist_ok=True)
    for i, name in enumerate(NAMES):
        cell = sheet.crop((i * w, 0, (i + 1) * w, sheet.height))
        bbox = cell.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
        cell = cell.crop(bbox)
        side = max(cell.size)
        sq = Image.new("RGBA", (side, side))
        sq.alpha_composite(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
        sq.resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"button_{name}.png", optimize=True)
        sq.resize((SIZE * 2, SIZE * 2), Image.LANCZOS).save(OUT / f"button_{name}@2x.png", optimize=True)
        print(f"ui/button_{name}.png {SIZE}x{SIZE} (+@2x)")


if __name__ == "__main__":
    main()
