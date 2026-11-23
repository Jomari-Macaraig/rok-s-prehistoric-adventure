#!/usr/bin/env python3
"""The user's shapeshift burst (../Assets/Rok_Generic_Transformation_FX).

One generic transformation effect for every hero <-> dinosaur change, in
both directions: 8 frames (4x2, 384x512 cells, pivot at the cell centre),
played once at the pack's fps. Frames 3-4 are a solid cream cloud that hides
the sprite swap (the pack swaps on index 4), 5-7 open up to show the new form.

Writes assets/fx/transform_burst@2x.png (the pack's sheet as is: drawn at
half size, sharp on phones), assets/fx/transform_burst.png (half size, the
1x fallback) and assets/fx/transform_burst.json: the 1x cell and pivot, the
fps, the swap and cover frames, and `cover`, the size of the solid cloud on
the cover frames at 1x (alpha > 200, the smaller of the two), which the game
scales to hide both forms.

    uv run --no-project --with pillow python tools/prepare_transform_fx.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Generic_Transformation_FX"
OUT = ROOT / "assets" / "fx"


def main() -> None:
    meta = json.loads((SRC / "animation.json").read_text())
    sheet = Image.open(SRC / meta["image"]).convert("RGBA")
    cw, ch = meta["cell"]
    cols = meta["columns"]
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / "transform_burst@2x.png", optimize=True)
    sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(OUT / "transform_burst.png", optimize=True)
    cover = None
    for i in meta["cover_frame_indices"]:
        cell = sheet.crop((i % cols * cw, i // cols * ch, i % cols * cw + cw, i // cols * ch + ch))
        l, t, r, b = cell.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()
        size = ((r - l) / 2.0, (b - t) / 2.0)   # 1x
        cover = size if cover is None else (min(cover[0], size[0]), min(cover[1], size[1]))
    out = {
        "cell": [cw // 2, ch // 2],
        "pivot": [meta["pivot"][0] / 2.0, meta["pivot"][1] / 2.0],
        "frames": meta["frames"],
        "columns": cols,
        "fps": meta["recommended_fps"],
        "swap": meta["swap_frame_index"],
        "cover_frames": meta["cover_frame_indices"],
        "cover": [round(cover[0], 1), round(cover[1], 1)],
    }
    (OUT / "transform_burst.json").write_text(json.dumps(out, indent=1))
    print("transform_burst:", out)


if __name__ == "__main__":
    main()
