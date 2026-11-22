#!/usr/bin/env python3
"""The user's stone heart (../Assets/Stone heart health drain animation.png: a
4x3 grid of 12 frames, the red draining right to left) -> assets/items/.

Frames are cut on one shared crop (so they never jump) and the red share of
each is measured. heart_<full|three|half|quarter|empty>.png (+@2x) are the
frames closest to 4/4, 3/4, 2/4, 1/4 red; the sheet never reaches empty (its
last frame keeps a sliver), so the empty heart is that frame with the red
repainted in the stone interior's dark brown. heart_drain.png (+@2x) is all
13 frames (12 + empty) in a row and heart_drain.json their red shares, so the
HUD can drain a heart smoothly when Rok is hurt (Hud.set_hearts).

    uv run --no-project --with pillow python tools/prepare_hearts.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Stone heart health drain animation.png"
OUT = ROOT / "assets" / "items"
SIZE = 64   # 1x heart (shown at 34 px on the HUD, ~54 as a pickup); @2x is 128


def is_red(p) -> bool:
    r, g, b, a = p
    return a > 128 and r > 140 and g < 90 and b < 90


def main() -> None:
    sheet = Image.open(SRC).convert("RGBA")
    cw, ch = sheet.width / 4, sheet.height / 3
    cells = []
    for i in range(12):
        x0, y0 = round(i % 4 * cw), round(i // 4 * ch)
        c = sheet.crop((x0, y0, round(x0 + cw), round(y0 + ch)))
        a = c.getchannel("A").point(lambda v: 0 if v < 24 else v)
        c.putalpha(a)
        cells.append(c)
    boxes = [c.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox() for c in cells]
    u = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    side = max(u[2] - u[0], u[3] - u[1])
    frames = []
    for c in cells:
        sq = Image.new("RGBA", (side, side))
        crop = c.crop(u)
        sq.alpha_composite(crop, ((side - crop.width) // 2, (side - crop.height) // 2))
        frames.append(sq)
    def red_count(f: Image.Image) -> int:
        b = f.tobytes()
        return sum(1 for i in range(0, len(b), 4) if is_red((b[i], b[i + 1], b[i + 2], b[i + 3])))

    reds = [red_count(f) for f in frames]
    full = reds[0]
    # the empty heart: the last frame with its red sliver painted dark
    last = frames[-1].copy()
    px = last.load()
    dark = None
    for y in range(side):   # sample the drained interior next to the red
        for x in range(side - 1, -1, -1):
            p = px[x, y]
            if p[3] > 200 and p[0] < 110 and abs(p[0] - p[1]) < 40 and p[0] > 40:
                dark = p
                break
        if dark:
            break
    dark = dark or (70, 52, 48, 255)
    for y in range(side):
        for x in range(side):
            p = px[x, y]
            if is_red(p):
                k = (p[0] / 255.0) * 0.9 + 0.1
                px[x, y] = (int(dark[0] * k + 8), int(dark[1] * k + 6), int(dark[2] * k + 6), p[3])
    frames.append(last)
    shares = [round(r / full, 3) for r in reds] + [0.0]
    OUT.mkdir(parents=True, exist_ok=True)
    for name, target in (("full", 1.0), ("three", 0.75), ("half", 0.5), ("quarter", 0.25), ("empty", 0.0)):
        i = min(range(len(shares)), key=lambda j: abs(shares[j] - target))
        frames[i].resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"heart_{name}.png", optimize=True)
        frames[i].resize((SIZE * 2, SIZE * 2), Image.LANCZOS).save(OUT / f"heart_{name}@2x.png", optimize=True)
        print(f"items/heart_{name}.png <- frame {i} ({shares[i]:.2f} red)")
    for k, suffix in ((1, ""), (2, "@2x")):
        strip = Image.new("RGBA", (SIZE * k * len(frames), SIZE * k))
        for i, f in enumerate(frames):
            strip.alpha_composite(f.resize((SIZE * k, SIZE * k), Image.LANCZOS), (i * SIZE * k, 0))
        strip.save(OUT / f"heart_drain{suffix}.png", optimize=True)
    (OUT / "heart_drain.json").write_text(json.dumps({"size": SIZE, "shares": shares}, indent=1))
    print("items/heart_drain.png", len(frames), "frames, shares", shares)


if __name__ == "__main__":
    main()
