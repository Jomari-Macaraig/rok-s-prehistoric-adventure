#!/usr/bin/env python3
"""The user's attack animations (../Assets/Rok_Attack_Animations), at 1x and 2x.

The pack (manifest.json) has 42 one-shot 4x2 sheets: Rok, Nira and Boro with
each of the seven weapons, 20 playable dinosaurs and the T-rex chaser (the
T-rex's isn't used: the pursuer keeps its own bite). Frame 4 is the strike
(and the bow's / sling's release).

Every sheet is drawn at its own size and ground line, so each is fitted to
the character's in-game art (assets/characters/<id>/idle.png, the 1x units
before the form's sprite scale):
- scale: the character's standing height in idle frame 0 over the height of
  attack frame 0 (alpha > 128 box; checked by eye against idle, weapons
  included, for all 41 sheets),
- place: attack frame 0's feet (the centre of the bottom 10% of the art) and
  bottom land on idle frame 0's feet and bottom, measured from the
  character's pivot. Every frame gets the same sideways offset, so lunges
  and tail swings keep their drawn motion; for characters on the ground each
  frame's bottom is also put back on frame 0's (several sheets draw the
  strike frames up to ~25 px higher, which floated them off the grass), while
  the flyers (FLYERS) keep their drawn rise and dip.
Each clip gets its own canvas (the union of its frames around the pivot, so
a spear thrust isn't cropped) and pivot. Alpha below 24 is wiped.

Writes assets/attacks/<id>/<clip>.png + @2x (clip = "attack" for dinosaurs,
"attack_<weapon id>" for heroes) and assets/attacks/attacks.json:
{id: {clip: {frame, pivot, times, active, release, direction}}}.

Run after the character art is final (prepare_form_art.py, prepare_heroes.gd,
prepare_dinos.gd):
    uv run --no-project --with pillow python tools/prepare_attacks.py
then godot --headless --path . --import
"""
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Attack_Animations"
OUT = ROOT / "assets" / "attacks"

SOLID = 128
CLEAR_BELOW = 24
PAD = 2
# ms per frame: a quick wind-up so the strike (frame 4) lands ~0.17 s after
# the press (the hit itself is instant), then the follow-through
TIMES = [40, 40, 40, 50, 110, 90, 80, 70]
# the pack's weapon names -> Gear.ITEMS ids
WEAPONS = {"club": "club", "axe": "stone_axe", "spear": "flint_spear", "bone_hammer": "bone_hammer",
           "sling": "sling", "torch": "torch", "bow": "bow"}
SPECIES = {"pterosaur": "pteranodon"}
FLYERS = {"pteranodon", "dimorphodon", "quetzalcoatlus"}


def mask(im, t=SOLID):
    return im.getchannel("A").point(lambda a: 255 if a > t else 0)


def feet(im):
    """(feet centre x, bottom y, height) of the art in a frame."""
    m = mask(im)
    l, t, r, b = m.getbbox()
    fl = m.crop((0, b - max(4, int((b - t) * 0.1)), im.width, b)).getbbox()
    return (fl[0] + fl[2]) / 2, b, b - t


def cells(im, fw, fh):
    return [im.crop((i % 4 * fw, i // 4 * fh, i % 4 * fw + fw, i // 4 * fh + fh)) for i in range(8)]


def clear(im):
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: 0 if v < CLEAR_BELOW else v)))


def pivot_of(cid):
    """The character's in-game frame size and pivot (1x)."""
    if cid == "rok":
        return (84.0, 213.5)
    if cid in ("nira", "boro"):
        h = json.loads((ROOT / "assets/heroes/heroes.json").read_text())[cid]
        return tuple(h["pivot"])
    if cid in ("raptor", "triceratops", "spinosaurus"):
        return (112.0, 157.5)
    if cid == "pteranodon":
        return (112.0, 213.5)
    return tuple(json.loads((ROOT / "assets/dinos/dinos.json").read_text())["creatures"][cid]["play"]["pivot"])


def idle_ref(cid):
    """Idle frame 0's feet x, bottom and height relative to the pivot, in 1x units."""
    hi = ROOT / f"assets/characters/{cid}/idle@2x.png"
    k = 2 if hi.exists() else 1
    im = Image.open(hi if k == 2 else ROOT / f"assets/characters/{cid}/idle.png").convert("RGBA")
    fx, b, h = feet(cells(im, im.width // 4, im.height // 2)[0])
    px, py = pivot_of(cid)
    return fx / k - px, b / k - py, h / k


def build(sheet, cid):
    fw, fh = sheet["frame_px"]
    fr = [clear(c) for c in cells(Image.open(SRC / sheet["file"]).convert("RGBA"), fw, fh)]
    rx, rb, rh = idle_ref(cid)
    fx, b, h = feet(fr[0])
    s = rh / h                     # source px -> 1x game px
    # source point (fx, b) lands at pivot-relative (rx, rb)
    ox, oy = rx - fx * s, rb - b * s   # top-left of a source cell, pivot-relative
    # per-frame drop (source px) that puts its bottom back on frame 0's
    drop = [0 if cid in FLYERS else b - feet(f)[1] for f in fr]
    boxes = [f.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox() for f in fr]
    x0 = min(ox + bx[0] * s for bx in boxes) - PAD
    y0 = min(oy + (bx[1] + d) * s for bx, d in zip(boxes, drop)) - PAD
    x1 = max(ox + bx[2] * s for bx in boxes) + PAD
    y1 = max(oy + (bx[3] + d) * s for bx, d in zip(boxes, drop)) + PAD
    x0, y0 = math.floor(min(x0, -PAD)), math.floor(min(y0, -PAD))
    x1, y1 = math.ceil(max(x1, PAD)), math.ceil(max(y1, PAD))
    w, hgt = x1 - x0, y1 - y0
    pivot = (-x0, -y0)
    for k, suffix in ((1, ""), (2, "@2x")):
        out = Image.new("RGBA", (w * 4 * k, hgt * 2 * k))
        sw, sh = round(fw * s * k), round(fh * s * k)
        for i, f in enumerate(fr):
            g = f.resize((sw, sh), Image.LANCZOS)
            dx, dy = round((ox - x0) * k), round((oy + drop[i] * s - y0) * k)
            # the cell's transparent margins can hang off the canvas: crop them
            g = g.crop((max(-dx, 0), max(-dy, 0), min(sw, w * k - dx), min(sh, hgt * k - dy)))
            cell = Image.new("RGBA", (w * k, hgt * k))
            cell.alpha_composite(g, (max(dx, 0), max(dy, 0)))
            out.alpha_composite(cell, (i % 4 * w * k, i // 4 * hgt * k))
        yield k, suffix, out
    build.meta = {"frame": [w, hgt], "pivot": [pivot[0], pivot[1]], "scale": round(s, 4)}


def main():
    man = json.loads((SRC / "manifest.json").read_text())
    meta = {}
    for sh in man["sheets"]:
        if sh["type"] == "enemy":
            continue
        if sh["type"] == "hero":
            cid, clip = sh["hero"], "attack_" + WEAPONS[sh["weapon"]]
        else:
            cid = sh["file"].split("/")[1]
            cid, clip = SPECIES.get(cid, cid), "attack"
        if not (ROOT / f"assets/characters/{cid}/idle.png").exists():
            print(f"  skip {sh['id']}: no character {cid}")
            continue
        OUT.joinpath(cid).mkdir(parents=True, exist_ok=True)
        for k, suffix, img in build(sh, cid):
            img.save(OUT / cid / f"{clip}{suffix}.png", optimize=True)
        m = build.meta
        m.update({"times": TIMES, "active": sh["active_frame_index"],
                  "release": sh["projectile_release_frame_index"], "direction": sh["direction"]})
        meta.setdefault(cid, {})[clip] = m
        print(f"{cid:20s} {clip:20s} frame {m['frame']} pivot {m['pivot']} scale {m['scale']}")
    (OUT / "attacks.json").write_text(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
