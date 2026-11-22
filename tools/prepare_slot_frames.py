#!/usr/bin/env python3
"""The user's sandstone slot frames -> assets/ui/slot_<kind>.png (+@2x) and
assets/ui/slot_frames.json.

Three ring frames with a badge on top and a transparent middle:
`Empty sandstone power-up slot-1.png` (powerup: the booster slots),
`Sandstone Dinosaur Slot Frame-2.png` (dino: the four dinosaur buttons) and
`Sandstone hero slot frame-3.png` (hero: the hero / Rok button). Each is
saved at 256 px (+ a 512 px @2x twin). slot_frames.json gives each ring's
centre and its outer and inner radius as fractions of the image side, so
TouchButton.frame can lay the ring's outside on the button's edge and draw
the portrait inside the hole.

    uv run --no-project --with pillow python tools/prepare_slot_frames.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "ui"
FILES = {
    "powerup": "Empty sandstone power-up slot-1.png",
    "dino": "Sandstone Dinosaur Slot Frame-2.png",
    "hero": "Sandstone hero slot frame-3.png",
}
SIZE = 256


def measure(img: Image.Image) -> dict:
    a = img.getchannel("A")
    w, h = img.size
    l, t, r, b = a.point(lambda v: 255 if v > 128 else 0).getbbox()
    ro = (r - l) / 2           # the ring is a circle as wide as the art
    cx, cy = (l + r) / 2, b - ro   # the badge sits on top, so measure from the bottom
    px = a.load()
    # inner radius: from the centre outwards along the horizontal and the bottom, first solid pixel
    hits = []
    for dx, dy in ((1, 0), (-1, 0), (0, 1)):
        for k in range(int(ro)):
            x, y = int(cx + dx * k), int(cy + dy * k)
            if px[x, y] > 128:
                hits.append(k)
                break
    ri = sum(hits) / len(hits)
    return {"center": [cx / w, cy / h], "outer": ro / w, "inner": ri / w}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for kind, name in FILES.items():
        img = Image.open(SRC / name).convert("RGBA")
        meta[kind] = measure(img)
        img.resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"slot_{kind}.png", optimize=True)
        img.resize((SIZE * 2, SIZE * 2), Image.LANCZOS).save(OUT / f"slot_{kind}@2x.png", optimize=True)
        print(f"ui/slot_{kind}.png", {k: [round(x, 3) for x in v] if isinstance(v, list) else round(v, 3) for k, v in meta[kind].items()})
    (OUT / "slot_frames.json").write_text(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
