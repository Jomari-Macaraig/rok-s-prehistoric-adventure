#!/usr/bin/env python3
"""Empty-handed attack styles plus their guide sheets (docs/ITEM_ART_PLAN.md).

A style clip is a hero swinging (thrusting, throwing...) with a closed, empty
hand; its guide sheet, aligned pixel for pixel, marks per frame:
  magenta #FF00FF stick  the weapon's direction from the grip
  green   #00FF00 dot    the grip (centre of the closed hand)
  cyan    #00FFFF dot    top of the head
  yellow  #FFFF00 dot    chest centre
  orange  #FF8000 dot    upper-back centre
The game draws whichever weapon is equipped at the grip, along the stick
(GearLayer), so one clip serves every weapon of that style.

Sources (STYLES): ../Assets/Rok_Swing_Attack (Rok, Swing; 4x2 of 384x512
cells, the floor at y 488 like Rok's other sheets; strike on frame 4).

The guide reader finds each colour's pixels per cell: a dot is the centroid
of its colour, the stick's direction runs from the grip to the farthest
magenta pixel. Results are checked against the pack's landmarks JSON when
there is one (a warning past 3 px / 4 degrees).

Writes, at Rok's scale (7/16, frame 168x224, pivot 84,213.5):
  assets/attacks/<hero>/style_<style>.png + @2x (the sheet as it is)
  assets/attacks/styles.json: {hero: {"style_<style>": {frame, pivot, times,
    active, release, direction, grip: [[x, y] x8], angle: [deg x8, clockwise
    from pointing straight up], head, chest, back: [[x, y] x8]}}} in 1x frame
    pixels (SpriteLib.attack_meta merges it into the hero's attack clips).

    uv run --no-project --with pillow python tools/prepare_styles.py
then godot --headless --path . --import
"""
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "attacks"
TIMES = [40, 40, 40, 50, 110, 90, 80, 70]   # as prepare_attacks.py: strike ~0.17 s after the press
STYLES = [
    {"hero": "rok", "style": "swing", "dir": "Rok_Swing_Attack", "sheet": "rok_swing_attack.png",
     "guide": "rok_swing_attack_guide.png", "landmarks": "rok_swing_attack_landmarks.json",
     "cell": (384, 512), "pivot": (192, 488), "scale": 7 / 16, "active": 4, "release": None},
]
COLOURS = {"stick": (255, 0, 255), "grip": (0, 255, 0), "head": (0, 255, 255),
           "chest": (255, 255, 0), "back": (255, 128, 0)}


def read_guide(cell: Image.Image) -> dict:
    px = cell.load()
    found = {k: [] for k in COLOURS}
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            for k, c in COLOURS.items():
                if (r, g, b) == c:
                    found[k].append((x, y))
    out = {}
    for k in ("grip", "head", "chest", "back"):
        pts = found[k]
        out[k] = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)) if pts else None
    gx, gy = out["grip"]
    if found["stick"]:
        fx, fy = max(found["stick"], key=lambda p: (p[0] - gx) ** 2 + (p[1] - gy) ** 2)
        out["axis"] = (fx - gx, fy - gy)
    else:
        out["axis"] = None   # no weapon on this frame (after a throw)
    return out


def main() -> None:
    meta = json.loads((OUT / "styles.json").read_text()) if (OUT / "styles.json").exists() else {}
    for st in STYLES:
        src = ASSETS / st["dir"]
        sheet = Image.open(src / st["sheet"]).convert("RGBA")
        guide = Image.open(src / st["guide"]).convert("RGBA")
        cw, ch = st["cell"]
        k = st["scale"]
        marks = [read_guide(guide.crop((i % 4 * cw, i // 4 * ch, i % 4 * cw + cw, i // 4 * ch + ch))) for i in range(8)]
        lm = src / st["landmarks"]
        if lm.exists():
            ref = json.loads(lm.read_text())["frames"]
            for i, (m, r) in enumerate(zip(marks, ref)):
                d = math.dist(m["grip"], r["grip_center"])
                ang = math.degrees(math.atan2(m["axis"][1], m["axis"][0]) - math.atan2(r["weapon_axis_unit"][1], r["weapon_axis_unit"][0]))
                ang = (ang + 180) % 360 - 180
                if d > 3 or abs(ang) > 4:
                    print(f"  warning: {st['hero']} {st['style']} frame {i}: grip off by {d:.1f} px, angle by {ang:.1f} deg")
        OUT.joinpath(st["hero"]).mkdir(parents=True, exist_ok=True)
        clip = "style_" + st["style"]
        for kk, sfx in ((1, ""), (2, "@2x")):
            w, h = round(sheet.width * k * kk), round(sheet.height * k * kk)
            sheet.resize((w, h), Image.LANCZOS).save(OUT / st["hero"] / f"{clip}{sfx}.png", optimize=True)

        def pt(p):
            return None if p is None else [round(p[0] * k, 2), round(p[1] * k, 2)]

        def angle(a):   # clockwise from straight up, degrees
            return None if a is None else round(math.degrees(math.atan2(a[0], -a[1])), 1)

        meta.setdefault(st["hero"], {})[clip] = {
            "frame": [round(cw * k), round(ch * k)], "pivot": [st["pivot"][0] * k, st["pivot"][1] * k],
            "times": TIMES, "active": st["active"], "release": st["release"], "direction": "forward",
            "grip": [pt(m["grip"]) for m in marks], "angle": [angle(m["axis"]) for m in marks],
            "head": [pt(m["head"]) for m in marks], "chest": [pt(m["chest"]) for m in marks],
            "back": [pt(m["back"]) for m in marks]}
        print(f"{st['hero']} {clip}: angles {meta[st['hero']][clip]['angle']}")
    (OUT / "styles.json").write_text(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
