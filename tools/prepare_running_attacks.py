#!/usr/bin/env python3
"""The user's seamless running attacks (../Assets/Rok_Running_<Weapon>), at 1x and 2x.

Each pack (validation.json id "<hero>_<weapon>") has, on the hero's run
canvas (4x2, 384x512 cells):
- run.png: the normal run carrying that weapon (the weapon drawn in),
- phases/run_attack_phase_<p>.png: the 8-frame attack for a swing started at
  run phase p. Attack frame i keeps run frame (p+i)%8's legs (pixel-exact
  copies of the hero's run sheet), the hit is frame 4, it plays once at the
  run's own frame clock, and after 8 frames the run carries on at phase p.

The legs are the same pixels as the run sheet the game already uses (Rok's
"Eight-Pose Run Sprite Sheet-3.png"), so every frame is placed with exactly
the offset prepare_form_art.py gives that run frame (its bottom-centre moved
onto the original pack's): attack frame i of phase p gets run frame
(p+i)%8's offset. The result sits on the run's own canvas and pivot, so the
game swaps the sheets frame for frame without any jump.

Writes assets/attacks/<hero>/run_<weapon>.png (the carry run),
assets/attacks/<hero>/run_attack_<weapon>_<p>.png (p = 0..7), each + @2x,
and assets/attacks/running.json:
{hero: {weapon: {"frame": [w, h], "pivot": [x, y], "hit": 4, "phases": 8}}}
(carry_frame = the run canvas; frame/pivot = the attack canvas, the run's
grown by PAD source px on every side, at 1x). Only Rok so far (his run is
the only one these packs are drawn over).

Run after prepare_form_art.py:
    uv run --no-project --with pillow python tools/prepare_running_attacks.py
then godot --headless --path . --import
"""
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_form_art as fa   # noqa: E402  (the run sheet's per-frame placement)

ROOT = fa.ROOT
SRC = fa.SRC
OUT = ROOT / "assets" / "attacks"
WEAPONS = {"club": "club", "axe": "stone_axe", "spear": "flint_spear", "bone_hammer": "bone_hammer",
           "sling": "sling", "torch": "torch", "bow": "bow"}   # pack name -> Gear.ITEMS id
PIVOTS = {"rok": [84.0, 213.5]}   # the hero's run canvas pivot at 1x (Forms ROK)
PAD = 64   # source px added round the attack frames (a swing reaches past the run canvas)


def run_offsets(hero: str) -> list:
    """Per run frame, the (dx, dy) prepare_form_art moves the run sheet's frame by."""
    cfg = fa.FORMS[hero]
    fw, fh = cfg["frame"]
    ref = fa.old_bounds(hero, "run", fw, fh)
    out = []
    for i, f in enumerate(fa.frames(fa.load_new(cfg["sheets"]["run"]), fw, fh)):
        l, t, r, b = fa.body(f)
        ol, ot, or_, ob = ref[i]
        out.append((round((ol + or_) / 2 - (l + r) / 2), ob - b))
    return out


def placed(sheet: Image.Image, offsets: list, fw: int, fh: int, name: str, pad: int = 0) -> Image.Image:
    """Each frame i moved by offsets[i] on the run canvas grown by `pad` source
    px on every side (noting any cropping)."""
    sw, sh = fw, fh
    fw, fh = fw + pad * 2, fh + pad * 2
    out = Image.new("RGBA", (fw * 4, fh * 2))
    for i, f in enumerate(fa.frames(sheet, sw, sh)):
        dx, dy = offsets[i][0] + pad, offsets[i][1] + pad
        cell = Image.new("RGBA", (fw, fh))
        sx, sy = max(-dx, 0), max(-dy, 0)
        w, h = min(f.width - sx, fw - max(dx, 0)), min(f.height - sy, fh - max(dy, 0))
        if w > 0 and h > 0:
            cell.alpha_composite(f.crop((sx, sy, sx + w, sy + h)), (max(dx, 0), max(dy, 0)))
        art = fa.body(f, 8)
        if art and (art[0] + dx < 0 or art[2] + dx > fw or art[1] + dy < 0 or art[3] + dy > fh):
            print(f"  note: {name} frame {i} is cropped at the frame edge")
        out.alpha_composite(cell, (i % 4 * fw, i // 4 * fh))
    return out


def load(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    r, g, b, a = img.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: 0 if v < fa.CLEAR_BELOW else v)))


def main() -> None:
    meta_path = OUT / "running.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    for pack in sorted(SRC.glob("Rok_Running_*")):
        v = json.loads((pack / "validation.json").read_text())
        hero, weapon = v["id"].split("_", 1)
        if hero not in fa.FORMS or hero not in PIVOTS:
            print(f"  skip {pack.name}: no run placement for {hero} yet")
            continue
        wid = WEAPONS.get(weapon, weapon)
        fw, fh = fa.FORMS[hero]["frame"]
        w1, h1 = round(fw * 4 * fa.SCALE), round(fh * 2 * fa.SCALE)
        offs = run_offsets(hero)
        (OUT / hero).mkdir(parents=True, exist_ok=True)
        carry = placed(load(pack / "run.png"), offs, fw, fh, f"{v['id']} run")
        fa.both(carry, f"attacks/{hero}/run_{wid}.png", w1, h1)
        for p in range(v.get("phase_variants", 8)):
            po = [offs[(p + i) % 8] for i in range(8)]   # frame i keeps run frame (p+i)%8's legs
            img = placed(load(pack / "phases" / f"run_attack_phase_{p}.png"), po, fw, fh, f"{v['id']} phase {p}", PAD)
            fa.both(img, f"attacks/{hero}/run_attack_{wid}_{p}.png", round((fw + PAD * 2) * 4 * fa.SCALE), round((fh + PAD * 2) * 2 * fa.SCALE))
        k = PAD * fa.SCALE
        meta.setdefault(hero, {})[wid] = {"carry_frame": [w1 // 4, h1 // 2], "frame": [round((fw + PAD * 2) * fa.SCALE), round((fh + PAD * 2) * fa.SCALE)],
                                          "pivot": [PIVOTS[hero][0] + k, PIVOTS[hero][1] + k],
                                          "hit": v.get("hit_frame_index", 4), "phases": v.get("phase_variants", 8)}
    meta_path.write_text(json.dumps(meta, indent=1))
    print("running.json:", meta)


if __name__ == "__main__":
    main()
