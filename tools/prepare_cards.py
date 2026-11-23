#!/usr/bin/env python3
"""The user's dinosaur card art (../Assets/Prehistoric Dinosaur Card Collection Preview.png).

The file is a preview: four cards side by side (Raptor, Triceratops,
Spinosaurus, Pterosaur = the Pteranodon) on a textured dark green
background. Each card is cut out of its column, the background removed by a
flood fill from the cut's edge over dark greenish pixels (so the card's own
moss stays), trimmed, and saved as assets/cards/<id>@2x.png (the preview's
pixels) + a half-size <id>.png. cards.json gives each card's size and its
blank parchment box (where the game writes the card's bonus) as fractions of
the card, measured as the biggest light parchment area in its lower part.

The user's card pack ../Assets/Rok_Dinosaur_Cards/cards/<name>.png (21
separate transparent 1024x1536 cards: the four originals, the first 16
expansion species and the T-rex; `pterosaur` is the Pteranodon, `t_rex` the
pursuer) replaces the cut-out: every card there is trimmed to its frame and
scaled to the cut-out cards' height (CARD_H at @2x), so all cards match.

    uv run --no-project --with pillow python tools/prepare_cards.py
then godot --headless --path . --import
"""
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PREVIEW = ROOT.parent / "Assets" / "Prehistoric Dinosaur Card Collection Preview.png"
SEPARATE = ROOT.parent / "Assets" / "Rok_Dinosaur_Cards"
ALIAS = {"pterosaur": "pteranodon", "t_rex": "trex"}   # the pack's file names -> game ids
CARD_H = 766   # @2x height of every card (the preview's cut-out height)
OUT = ROOT / "assets" / "cards"
IDS = ["raptor", "triceratops", "spinosaurus", "pteranodon"]


def is_bg(c) -> bool:
    r, g, b = c[:3]
    return max(r, g, b) < 95 and g >= r - 4 and g >= b


def cut_columns(im: Image.Image) -> list:
    w, h = im.size
    cols = []
    inside = False
    for x in range(w):
        n = sum(0 if is_bg(im.getpixel((x, y))) else 1 for y in range(0, h, 4))
        if n > 40 and not inside:
            start, inside = x, True
        elif n <= 40 and inside:
            cols.append((start, x))
            inside = False
    return cols


def key_out(card: Image.Image) -> Image.Image:
    """Clear the background reachable from the edge (dark greenish pixels)."""
    w, h = card.size
    px = card.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))
    return card.crop(card.getchannel("A").getbbox())


def parchment_box(card: Image.Image) -> list:
    """The blank parchment's box (x0, y0, x1, y1 as fractions): light beige
    pixels below the name plank."""
    w, h = card.size
    px = card.load()
    xs, ys = [], []
    for y in range(int(h * 0.76), h):   # below the name plank (its cream letters are parchment-coloured too)
        for x in range(0, w, 2):
            r, g, b, a = px[x, y]
            if a > 200 and r > 215 and g > 190 and 120 < b < 200 and r - b > 40:
                xs.append(x)
                ys.append(y)
    if not xs:
        return [0.12, 0.77, 0.88, 0.89]
    xs.sort()
    ys.sort()
    lo, hi = len(xs) // 50, len(xs) - 1 - len(xs) // 50   # ignore stray highlights
    return [round(xs[lo] / w, 3), round(ys[lo] / h, 3), round(xs[hi] / w, 3), round(ys[hi] / h, 3)]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cards = {}
    for folder in (SEPARATE / "cards", SEPARATE):
        if folder.exists():
            for f in sorted(folder.glob("*.png")):
                cid = ALIAS.get(f.stem, f.stem)
                if cid in cards:
                    continue
                im = Image.open(f).convert("RGBA")
                im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox())
                cards[cid] = im.resize((round(im.width * CARD_H / im.height), CARD_H), Image.LANCZOS)
    if len(cards) < len(IDS):
        im = Image.open(PREVIEW).convert("RGBA")
        cols = cut_columns(im.convert("RGB"))
        assert len(cols) == len(IDS), cols
        for cid, (x0, x1) in zip(IDS, cols):
            if cid not in cards:
                cards[cid] = key_out(im.crop((max(0, x0 - 4), 0, min(im.width, x1 + 4), im.height)))
    meta = {}
    for cid, card in cards.items():
        card.save(OUT / f"{cid}@2x.png", optimize=True)
        card.resize((card.width // 2, card.height // 2), Image.LANCZOS).save(OUT / f"{cid}.png", optimize=True)
        meta[cid] = {"size": [card.width // 2, card.height // 2], "text_box": parchment_box(card)}
        print(f"{cid:12s} {card.width // 2}x{card.height // 2}  parchment {meta[cid]['text_box']}")
    (OUT / "cards.json").write_text(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
