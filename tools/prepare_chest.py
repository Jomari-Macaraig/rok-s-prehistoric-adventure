#!/usr/bin/env python3
"""The user's milestone chest art -> assets/items/chest_*.

- `Eight-Chest Treasure Opening Sprite Sheet-3.png`: the lid opening, a 4x2
  grid of 8 frames (non-integer 443.5 px cells; `Rok treasure chest opening
  animation-1.png` is the same clip with background haze and is unused).
- `Open treasure chest sparkle loop-2.png`: the open chest sparkling, a 2x2
  grid of 4 frames drawn larger; scaled so it matches the last opening frame.

Every frame is trimmed and placed bottom-centre on one shared canvas, so the
chest never jumps between clips. Writes chest_anim.png (a 4x3 sheet: frames
0-7 open, 8-11 sparkle) + @2x and chest.json (frame size, clips, frame times),
plus chest_closed.png (frame 0) and chest_open.png (frame 7) as still
fallbacks. The chest is WIDTH px wide at 1x (Pickup draws it at native size).

    uv run --no-project --with pillow python tools/prepare_chest.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "items"
OPEN = "Eight-Chest Treasure Opening Sprite Sheet-3.png"
SPARKLE = "Open treasure chest sparkle loop-2.png"
WIDTH = 96   # the closed chest's width at 1x (about the old drawn chest)


def cells(sheet: Image.Image, cols: int, rows: int) -> list:
    cw, ch = sheet.width / cols, sheet.height / rows
    out = []
    for i in range(cols * rows):
        x0, y0 = round(i % cols * cw), round(i // cols * ch)
        c = sheet.crop((x0 + 2, y0 + 2, round(x0 + cw) - 2, round(y0 + ch) - 2))
        a = c.getchannel("A").point(lambda v: 0 if v < 24 else v)
        c.putalpha(a)
        out.append(c.crop(c.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()))
    return out


def main() -> None:
    opening = cells(Image.open(SRC / OPEN).convert("RGBA"), 4, 2)
    sparkle = cells(Image.open(SRC / SPARKLE).convert("RGBA"), 2, 2)
    k = opening[-1].width / sparkle[0].width
    sparkle = [f.resize((round(f.width * k), round(f.height * k)), Image.LANCZOS) for f in sparkle]
    frames = opening + sparkle
    s = WIDTH * 2 / opening[0].width   # build at 2x
    frames = [f.resize((max(1, round(f.width * s)), max(1, round(f.height * s))), Image.LANCZOS) for f in frames]
    w = max(f.width for f in frames) + 4
    h = max(f.height for f in frames) + 4
    w += w % 2
    h += h % 2   # even, so the 1x sheet is exactly half
    sheet = Image.new("RGBA", (w * 4, h * 3))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i % 4 * w + (w - f.width) // 2, i // 4 * h + h - f.height))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / "chest_anim@2x.png", optimize=True)
    sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(OUT / "chest_anim.png", optimize=True)
    for name, i in (("chest_closed", 0), ("chest_open", 7)):
        cell = sheet.crop((i % 4 * w, i // 4 * h, i % 4 * w + w, i // 4 * h + h))
        cell.save(OUT / f"{name}@2x.png", optimize=True)
        cell.resize((w // 2, h // 2), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)
    meta = {"frame": [w // 2, h // 2], "open": list(range(8)), "open_ms": [70, 70, 80, 90, 90, 90, 100, 140],
            "sparkle": [8, 9, 10, 11], "sparkle_ms": [160, 160, 160, 160]}
    (OUT / "chest.json").write_text(json.dumps(meta, indent=1))
    print(f"items/chest_anim.png {sheet.width // 2}x{sheet.height // 2} (frame {w // 2}x{h // 2}), chest_closed/open.png (+@2x)")


if __name__ == "__main__":
    main()
