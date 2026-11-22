#!/usr/bin/env python3
"""Gear art: the user's equipment sheet -> icons, held-weapon data and the
heroes' hand/back sockets.

1. ../Assets/Rok_Equipment_Sprite_Sheet.png is a 3x3 grid of 512 px cells:
   club, stone_axe, flint_spear / bone_hammer, sling, hide_vest /
   bone_guards, scale_mail, shell_plate. Each cell is trimmed and saved as
   assets/gear/<id>.png (fitted in ICON px) plus an @2x twin (Gear.icon, the
   Market and the Camp; the same picture is the weapon a hero holds).
2. assets/gear/gear_art.json: per item its grip point (weapons) or mount
   point (the shell) in the 1x icon's pixels, how long it's drawn on a hero
   (px, for Rok's 168 px standing height) and its base angle.
3. assets/gear/sockets.json: per hero (rok, nira, boro) and clip, per frame,
   the front hand [x, y] and a back point [x, y] in that clip's 1x frame
   pixels (origin top-left), measured from the art: the hand is the
   rightmost solid point of the arm band (they all face right), the back is
   left of the torso's middle. GearLayer moves the held weapon and the shell
   with them, frame by frame (weapons as separate layers, so any weapon fits
   any hero without new hero art).

Run after prepare_form_art.py and prepare_heroes.gd:
    uv run --no-project --with pillow python tools/prepare_gear.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Equipment_Sprite_Sheet.png"
OUT = ROOT / "assets"
CELL = 512
ICON = 160   # 1x icon box (the @2x twin is twice that)

ORDER = ["club", "stone_axe", "flint_spear", "bone_hammer", "sling", "hide_vest",
         "bone_guards", "scale_mail", "shell_plate"]
# weapons: where the hand grips (fraction of the art's height from the top,
# the middle of its wrapped handle), drawn length on Rok and base tilt (deg,
# clockwise from upright). The shell mounts at its middle.
HELD = {
    "club": {"grip": 0.82, "length": 72, "angle": 0},
    "stone_axe": {"grip": 0.78, "length": 74, "angle": 0},
    "flint_spear": {"grip": 0.80, "length": 120, "angle": 10},
    "bone_hammer": {"grip": 0.80, "length": 80, "angle": 0},
    "sling": {"grip": 0.06, "length": 60, "angle": 0, "hang": True},   # hangs from the hand by its loop
}
WORN = {"shell_plate": {"mount": 0.5, "length": 84, "angle": 0}}

# The weapons animation pack (../Assets/Rok_Weapons_Animation_Pack, 512 px
# frames): two new weapons held upright (the torch burns in the hand with its
# 8-frame loop), the arrow the bow fires, and a one-shot break effect for each
# older weapon (frame 0 is the intact weapon, drawn like its icon).
PACK = ROOT.parent / "Assets" / "Rok_Weapons_Animation_Pack"
NEW_HELD = {
    "bow": {"src": "sprites/bow.png", "grip": 0.5, "length": 92, "angle": 0, "upright": True},
    "torch": {"src": "sprites/torch_lit.png", "grip": 0.8, "length": 80, "angle": 0, "upright": True,
              "anim": "spritesheets/torch_burning.png"},
}
BREAKS = {"club": "wooden_club_break", "stone_axe": "stone_axe_break", "flint_spear": "flint_spear_break",
          "bone_hammer": "bone_hammer_break", "sling": "sling_break"}
FRAME_MS = 83   # the pack's 12 FPS

HEROES = {"rok": (168, 224), "nira": (252, 224), "boro": (252, 224)}
CLIPS = ["idle", "walk", "run", "jump", "duck", "slide", "celebrate"]


def trimmed(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
    return img.crop(bbox) if bbox else img


def icons() -> dict:
    sheet = Image.open(SRC).convert("RGBA")
    art = {}
    gear = OUT / "gear"
    gear.mkdir(parents=True, exist_ok=True)
    for i, gid in enumerate(ORDER):
        cell = trimmed(sheet.crop((i % 3 * CELL, i // 3 * CELL, i % 3 * CELL + CELL, i // 3 * CELL + CELL)))
        s = ICON / max(cell.size)
        w1, h1 = max(1, round(cell.width * s)), max(1, round(cell.height * s))
        cell.resize((w1, h1), Image.LANCZOS).save(gear / f"{gid}.png", optimize=True)
        cell.resize((w1 * 2, h1 * 2), Image.LANCZOS).save(gear / f"{gid}@2x.png", optimize=True)
        info = HELD.get(gid) or WORN.get(gid)
        if info:
            frac = info.get("grip", info.get("mount"))
            y = round(h1 * frac)
            # x: the middle of the solid pixels on that row of the 1x icon
            small = cell.resize((w1, h1), Image.LANCZOS)
            xs = [x for x in range(w1) if small.getpixel((x, min(y, h1 - 1)))[3] > 128]
            x = (xs[0] + xs[-1]) / 2 if xs else w1 / 2
            art[gid] = {"point": [x, y], "size": [w1, h1], "length": info["length"],
                        "angle": info["angle"], "held": gid in HELD, "hang": info.get("hang", False)}
        print(f"gear/{gid}.png {w1}x{h1}")
    weapons_pack(art)
    (gear / "gear_art.json").write_text(json.dumps(art, indent=1))
    return art


def _bbox(img: Image.Image, thr: int = 16):
    return img.getchannel("A").point(lambda a: 255 if a > thr else 0).getbbox()


def _grip(icon: Image.Image, frac: float) -> list:
    y = round(icon.height * frac)
    xs = [x for x in range(icon.width) if icon.getpixel((x, min(y, icon.height - 1)))[3] > 128]
    return [(xs[0] + xs[-1]) / 2 if xs else icon.width / 2, y]


def _cells(sheet: Image.Image) -> list:
    return [sheet.crop((i % 4 * CELL, i // 4 * CELL, i % 4 * CELL + CELL, i // 4 * CELL + CELL)) for i in range(8)]


def _anim(frames: list, ref, s: float, name: str) -> dict:
    """Crop 8 frames by their shared bounds, scale by s (1x) and 2s (@2x), save
    a 4x2 sheet; returns its frame size and where the reference box's corner
    (the icon's origin) sits inside a frame."""
    u = [min(b[i] for b in map(_bbox, frames) if b) if i < 2 else max(b[i] for b in map(_bbox, frames) if b) for i in range(4)]
    w1, h1 = round((u[2] - u[0]) * s), round((u[3] - u[1]) * s)
    for k, suffix in ((1, ""), (2, "@2x")):
        sheet = Image.new("RGBA", (w1 * k * 4, h1 * k * 2))
        for i, f in enumerate(frames):
            c = f.crop(tuple(u)).resize((w1 * k, h1 * k), Image.LANCZOS)
            sheet.alpha_composite(c, (i % 4 * w1 * k, i // 4 * h1 * k))
        sheet.save(OUT / "gear" / f"{name}{suffix}.png", optimize=True)
    print(f"gear/{name}.png {w1 * 4}x{h1 * 2} (+@2x)")
    return {"frame": [w1, h1], "origin": [round((ref[0] - u[0]) * s, 2), round((ref[1] - u[1]) * s, 2)], "ms": FRAME_MS}


def weapons_pack(art: dict) -> None:
    if not PACK.exists():
        return
    gear = OUT / "gear"
    for gid, info in NEW_HELD.items():
        src = Image.open(PACK / info["src"]).convert("RGBA")
        box = _bbox(src)
        cell = src.crop(box)
        s = ICON / max(cell.size)
        w1, h1 = max(1, round(cell.width * s)), max(1, round(cell.height * s))
        small = cell.resize((w1, h1), Image.LANCZOS)
        small.save(gear / f"{gid}.png", optimize=True)
        cell.resize((w1 * 2, h1 * 2), Image.LANCZOS).save(gear / f"{gid}@2x.png", optimize=True)
        art[gid] = {"point": _grip(small, info["grip"]), "size": [w1, h1], "length": info["length"],
                    "angle": info["angle"], "held": True, "hang": False, "upright": True}
        if "anim" in info:   # the burning loop, registered to the icon
            art[gid]["anim"] = _anim(_cells(Image.open(PACK / info["anim"]).convert("RGBA")), box, h1 / cell.height, f"{gid}_anim")
        print(f"gear/{gid}.png {w1}x{h1}")
    arrow = Image.open(PACK / "sprites" / "arrow.png").convert("RGBA")
    arrow = arrow.crop(_bbox(arrow))
    s = ICON / arrow.width
    a1 = (round(arrow.width * s), max(1, round(arrow.height * s)))
    arrow.resize(a1, Image.LANCZOS).save(gear / "arrow.png", optimize=True)
    arrow.resize((a1[0] * 2, a1[1] * 2), Image.LANCZOS).save(gear / "arrow@2x.png", optimize=True)
    for gid, name in BREAKS.items():   # registered so frame 0 lies over the held weapon
        if gid not in art:
            continue
        frames = _cells(Image.open(PACK / "spritesheets" / f"{name}.png").convert("RGBA"))
        f0 = _bbox(frames[0])
        art[gid]["break"] = _anim(frames, f0, float(art[gid]["size"][1]) / (f0[3] - f0[1]), f"break_{gid}")


def sockets() -> None:
    out = {}
    for hero, (fw, fh) in HEROES.items():
        out[hero] = {}
        for clip in CLIPS:
            p2 = OUT / "characters" / hero / f"{clip}@2x.png"
            p1 = OUT / "characters" / hero / f"{clip}.png"
            if p2.exists():
                sheet, k = Image.open(p2).convert("RGBA"), 2
            elif p1.exists():
                sheet, k = Image.open(p1).convert("RGBA"), 1
            else:
                continue
            frames = []
            for i in range(8):
                f = sheet.crop((i % 4 * fw * k, i // 4 * fh * k, (i % 4 + 1) * fw * k, (i // 4 + 1) * fh * k))
                frames.append(_measure(f, k))
            out[hero][clip] = frames
    (OUT / "gear" / "sockets.json").write_text(json.dumps(out))
    print("gear/sockets.json:", ", ".join(f"{h} {len(c)} clips" for h, c in out.items()))


def _measure(f: Image.Image, k: int) -> list:
    """[hand x, hand y, back x, back y] in 1x frame px."""
    a = f.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    l, t, r, b = a.getbbox()
    h = b - t
    px = a.load()
    # the arm band: from the shoulders to the hips
    y0, y1 = t + int(h * 0.30), t + int(h * 0.62)
    best_x, ys = -1, []
    for x in range(r - 1, l, -1):
        col = [y for y in range(y0, y1) if px[x, y]]
        if col:
            best_x = x
            break
    # the fist: solid pixels in the last few columns of the band
    for x in range(best_x - 10 * k, best_x + 1):
        ys += [y for y in range(y0, y1) if px[x, y]]
    hx = best_x - 7 * k
    hy = sum(ys) / len(ys) if ys else (y0 + y1) / 2
    # the back: the torso's middle at chest height, moved toward the back
    cy = t + int(h * 0.42)
    row = [x for x in range(l, r) if px[x, cy]]
    mid = (row[0] + row[-1]) / 2 if row else (l + r) / 2
    bx = mid - (r - l) * 0.22
    return [round(hx / k, 1), round(hy / k, 1), round(bx / k, 1), round(cy / k, 1)]


if __name__ == "__main__":
    icons()
    sockets()
