#!/usr/bin/env python3
"""The user's Missions scene art -> assets/ui/missions/ (+@2x).

Sources in ../Assets (the user's Missions scene pack, 2026-11-24):
- `Woodland Mission UI Asset Atlas-5.png`: a transparent 4x4 atlas (1254 px)
  of the UI pieces, cut cell by cell and trimmed to each piece's visible
  bounds (alpha > 96, so stray specks are dropped):
  row 0 board (wood frame), card (parchment), title (banner with a scroll),
  bubble (speech bubble); row 1 tab_on (teal), tab_off (brown), nameplate,
  back; row 2 button_claim (glowing green), button_done (dark green),
  button_wait (grey), check; row 3 bar_track, bar_fill, pill, dot.
  Each is saved at its drawn size as @2x and half that as 1x.
  (`Woodland parchment mission UI atlas-6.png` is the same art on a painted
  background, and `470fb063-....png` the user's mockup of the screen: not
  imported.)
- Tala the Trail Scout: `Tala's Idle Mapkeeper Animation Sheet-8.png` (idle),
  `Tala's trail scout talk animation-2.png` (talk), `Tala's eight-frame
  greeting wave-1.png` (wave), `Tala's Thumbs-Up Celebration Sprite Sheet-9.png`
  (thumbs), `Scout's quiet mission presentation sprite sheet-3.png` (present):
  4x2 sheets of 384x512 cells, copied as @2x and halved for 1x (192x256).
  Alpha below 24 is wiped (the sheets carry coloured pixels at alpha 0).
- The amber reward bursts (-4, -7) aren't used: missions pay meat.

    uv run --no-project --with pillow python tools/prepare_missions_ui.py
then godot --headless --path . --import
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "ui" / "missions"
ATLAS = "Woodland Mission UI Asset Atlas-5.png"
CELLS = [
    ["board", "card", "title", "bubble"],
    ["tab_on", "tab_off", "nameplate", "back"],
    ["button_claim", "button_done", "button_wait", "check"],
    ["bar_track", "bar_fill", "pill", "dot"],
]
TALA = {
    "idle": "Tala's Idle Mapkeeper Animation Sheet-8.png",
    "talk": "Tala's trail scout talk animation-2.png",
    "wave": "Tala's eight-frame greeting wave-1.png",
    "thumbs": "Tala's Thumbs-Up Celebration Sprite Sheet-9.png",
    "present": "Scout’s quiet mission presentation sprite sheet-3.png",
}


def save(img: Image.Image, name: str) -> None:
    img.save(OUT / f"{name}@2x.png")
    img.resize((max(1, img.width // 2), max(1, img.height // 2)), Image.LANCZOS).save(OUT / f"{name}.png")


def clean(img: Image.Image) -> Image.Image:
    a = img.getchannel("A").point(lambda v: 0 if v < 24 else v)
    img.putalpha(a)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.open(SRC / ATLAS).convert("RGBA")
    cw, ch = atlas.width / 4.0, atlas.height / 4.0
    for r, row in enumerate(CELLS):
        for c, name in enumerate(row):
            cell = atlas.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))
            box = cell.getchannel("A").point(lambda v: 255 if v > 96 else 0).getbbox()
            if box is None:
                print("empty cell:", name)
                continue
            pad = 2
            box = (max(0, box[0] - pad), max(0, box[1] - pad), min(cell.width, box[2] + pad), min(cell.height, box[3] + pad))
            save(clean(cell.crop(box)), name)
    for clip, f in TALA.items():
        p = SRC / f
        if not p.exists():
            print("missing:", f)
            continue
        save(clean(Image.open(p).convert("RGBA")), f"tala_{clip}")
    print("wrote", len(list(OUT.glob("*@2x.png"))), "pieces to", OUT)


if __name__ == "__main__":
    main()
