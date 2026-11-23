#!/usr/bin/env python3
"""Empty-handed attack styles plus their guides (docs/ITEM_ART_PLAN.md).

A style clip is a hero swinging (thrusting, throwing, shooting, punching)
with a closed, empty hand. Its guide marks per frame the grip, the weapon's
direction from it (the magenta stick), the head top, chest and upper back.
The game draws whichever weapon is equipped at the grip, along the stick
(GearLayer), so one clip serves every weapon of that style; Fist has no
stick (bare hands, a dinosaur card or a broken weapon).

Sources: ../Assets/<Hero>_Style_Attacks (Rok, Nira, Boro; README there):
  standing/<style>/<hero>_<style>_attack.png (+ _guide.png, _landmarks.json)
  running/<style>/phases/run_attack_phase_<p>.png (+ _guide, _landmarks)
  source_run/run.png (the run the running sheets were drawn over)
4x2 one-shots, strike/release on frame 4; Rok on 384x512 cells, Nira and
Boro on 576x512; standing feet on y 488. The landmarks JSON is read for the
points (it is exact); a pack without one falls back to reading the guide
PNG's colours.

Fitting to the game's art (1x = 7/16 of the source, like every hero sheet):
- Rok, standing: as drawn (his clips were made at his idle's scale), on
  the 168x224 canvas, pivot 84,213.5.
- Nira and Boro, standing: their style art is drawn ~12% bigger than their
  in-game art, so each clip is scaled so frame 0's height matches the hero's
  idle frame 0 (assets/characters/<id>/idle.png), feet on the ground line,
  centred on the idle's feet; canvas grown by PAD so nothing is cropped.
- Rok, running: his source run is pixel-identical to the run sheet the game
  uses, so each attack frame i of phase p gets exactly the offset
  prepare_form_art.py gives run frame (p+i)%8 (as prepare_running_attacks.py
  does for the club), on the run canvas grown by PAD.
- Nira and Boro, running: their packs were drawn over a different run (about
  10% taller, feet higher), so each attack frame is scaled by the ratio of
  the two runs' heights and its run frame's solid box (bottom centre) moved
  onto the game's matching run frame's.

Writes assets/attacks/<hero>/style_<style>.png + @2x (standing; preloaded
with the hero's other attack sheets), assets/run_styles/<hero>/
run_style_<style>_<p>.png + @2x (running; built only for the equipped
weapon's style) and assets/attacks/styles.json:
  {hero: {"style_<s>": {frame, pivot, times, active, release, direction,
                        grip, angle, head, chest, back, punch},
          "run_style_<s>": {frame, pivot, hit, phases,
                            guides: [{grip, angle, head, chest, back} x8 phases]}}}
grip/head/chest/back: 8 points in 1x frame pixels (null if absent); angle:
degrees clockwise from straight up (null where no weapon shows); punch: the
Fist's punch direction per frame.

    uv run --no-project --with pillow python tools/prepare_styles.py
then godot --headless --path . --import
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_form_art as fa   # noqa: E402  (Rok's run sheet placement)

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "attacks"
RUN_OUT = ROOT / "assets" / "run_styles"
TIMES = [40, 40, 40, 50, 110, 90, 80, 70]   # as prepare_attacks.py: strike ~0.17 s after the press
STYLES = ["swing", "thrust", "throw", "shoot", "fist"]
RELEASE = {"throw": 4, "shoot": 4}
K = 7 / 16
HEROES = {
    "rok": {"pack": "Rok_Style_Attacks", "cell": (384, 512), "pivot": (192, 488)},
    "nira": {"pack": "Nira_Style_Attacks", "cell": (576, 512), "pivot": (288, 488)},
    "boro": {"pack": "Boro_Style_Attacks", "cell": (576, 512), "pivot": (288, 488)},
}
PAD = 48   # source px round the fitted frames (a swing reaches past the canvas)
COLOURS = {"stick": (255, 0, 255), "grip": (0, 255, 0), "head": (0, 255, 255),
           "chest": (255, 255, 0), "back": (255, 128, 0)}


def cells(im, cw, ch):
    return [im.crop((i % 4 * cw, i // 4 * ch, i % 4 * cw + cw, i // 4 * ch + ch)) for i in range(8)]


def solid(im):
    return im.getchannel("A").point(lambda a: 255 if a > 128 else 0).getbbox()


def clear(im):
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: 0 if v < 24 else v)))


def angle(ax):
    return None if ax is None else round(math.degrees(math.atan2(ax[0], -ax[1])), 1)


def marks_from_json(path):
    out = []
    for f in json.loads(path.read_text())["frames"]:
        out.append({"grip": f.get("grip_center"), "head": f.get("head_top"), "chest": f.get("chest_center"),
                    "back": f.get("upper_back_center"), "axis": f.get("weapon_axis_unit"),
                    "punch": f.get("attack_axis_unit")})
    return out


def marks_from_guide(guide, cw, ch):
    out = []
    for c in cells(guide, cw, ch):
        px = c.load()
        found = {k: [] for k in COLOURS}
        for y in range(c.height):
            for x in range(c.width):
                r, g, b, a = px[x, y]
                if a >= 128:
                    for k, col in COLOURS.items():
                        if (r, g, b) == col:
                            found[k].append((x, y))
        m = {k: ((sum(p[0] for p in v) / len(v), sum(p[1] for p in v) / len(v)) if v else None)
             for k, v in found.items() if k != "stick"}
        m["axis"] = None
        if found["stick"] and m["grip"]:
            gx, gy = m["grip"]
            fx, fy = max(found["stick"], key=lambda p: (p[0] - gx) ** 2 + (p[1] - gy) ** 2)
            m["axis"] = (fx - gx, fy - gy)
        m["punch"] = None
        out.append(m)
    return out


def load_marks(base: Path, cw, ch):
    lm = base.with_name(base.stem + "_landmarks.json")
    if lm.exists():
        return marks_from_json(lm)
    return marks_from_guide(Image.open(base.with_name(base.stem + "_guide.png")).convert("RGBA"), cw, ch)


def fit_sheet(frames, places, scale, cw, ch, pad):
    """Each source frame scaled by `scale` (source px) and put at places[i]
    (its top-left on a (cw + 2 pad) x (ch + 2 pad) source-px cell), then the
    sheet saved at 1x and 2x of K. Returns the 1x and 2x images."""
    fw, fh = cw + pad * 2, ch + pad * 2
    sheet = Image.new("RGBA", (fw * 4, fh * 2))
    for i, f in enumerate(frames):
        g = f if scale == 1.0 else f.resize((round(f.width * scale), round(f.height * scale)), Image.LANCZOS)
        cell = Image.new("RGBA", (fw, fh))
        x, y = places[i]
        sx, sy = max(-x, 0), max(-y, 0)
        w, h = min(g.width - sx, fw - max(x, 0)), min(g.height - sy, fh - max(y, 0))
        if w > 0 and h > 0:
            cell.alpha_composite(g.crop((sx, sy, sx + w, sy + h)), (max(x, 0), max(y, 0)))
        sheet.alpha_composite(cell, (i % 4 * fw, i // 4 * fh))
    return sheet, (fw, fh)


def save2(sheet, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    for kk, sfx in ((K, ""), (2 * K, "@2x")):
        sheet.resize((round(sheet.width * kk), round(sheet.height * kk)), Image.LANCZOS) \
            .save(path.with_name(path.stem + sfx + ".png"), optimize=True)


def tr(p, scale, place, k=K):
    """A source point through the frame's scale and placement, to 1x."""
    if p is None:
        return None
    return [round((p[0] * scale + place[0]) * k, 2), round((p[1] * scale + place[1]) * k, 2)]


def idle_ref(hero, cw, ch):
    """The hero's in-game idle frame 0: solid height, feet centre x, bottom
    (source px on the 4x2 source canvas, from the 1x/2x sheet)."""
    hi = ROOT / f"assets/characters/{hero}/idle@2x.png"
    im = Image.open(hi if hi.exists() else hi.with_name("idle.png")).convert("RGBA")
    s = im.width / 4 / cw   # sheet px per source px
    b = solid(cells(im, im.width // 4, im.height // 2)[0])
    return (b[3] - b[1]) / s, (b[0] + b[2]) / 2 / s, b[3] / s


def game_run_boxes(hero, cw, ch):
    hi = ROOT / f"assets/characters/{hero}/run@2x.png"
    im = Image.open(hi if hi.exists() else hi.with_name("run.png")).convert("RGBA")
    s = im.width / 4 / cw
    return [tuple(v / s for v in solid(c)) for c in cells(im, im.width // 4, im.height // 2)]


def rok_run_offsets():
    cfg = fa.FORMS["rok"]
    fw, fh = cfg["frame"]
    ref = fa.old_bounds("rok", "run", fw, fh)
    out = []
    for i, f in enumerate(fa.frames(fa.load_new(cfg["sheets"]["run"]), fw, fh)):
        l, t, r, b = fa.body(f)
        ol, ot, or_, ob = ref[i]
        out.append((round((ol + or_) / 2 - (l + r) / 2), ob - b))
    return out


def clip_meta(marks, scales, places, frame, pivot, extra):
    m = {"frame": frame, "pivot": pivot}
    m.update(extra)
    for key in ("grip", "head", "chest", "back"):
        m[key] = [tr(mk[key], scales[i], places[i]) for i, mk in enumerate(marks)]
    m["angle"] = [angle(mk["axis"]) for mk in marks]
    if any(mk.get("punch") for mk in marks):
        m["punch"] = [mk.get("punch") for mk in marks]
    return m


def main():
    meta = {}
    for hero, h in HEROES.items():
        pack = ASSETS / h["pack"]
        if not pack.is_dir():
            print(f"  skip {hero}: no {h['pack']}")
            continue
        cw, ch = h["cell"]
        px, py = h["pivot"]
        meta[hero] = {}
        # ---- standing
        for st in STYLES:
            base = pack / "standing" / st / f"{hero}_{st}_attack.png"
            if not base.exists():
                continue
            frames = [clear(c) for c in cells(Image.open(base).convert("RGBA"), cw, ch)]
            marks = load_marks(base, cw, ch)
            if hero == "rok":
                s, pad = 1.0, 0
                place = (0, 0)
            else:
                ih, icx, ib = idle_ref(hero, cw, ch)
                b = solid(frames[0])
                s = ih / (b[3] - b[1])
                pad = PAD
                # frame 0's feet (bottom centre) onto the idle's, on the padded canvas
                place = (round(icx - (b[0] + b[2]) / 2 * s) + pad, round(ib - b[3] * s) + pad)
            sheet, (fw, fh) = fit_sheet(frames, [place] * 8, s, cw, ch, pad)
            save2(sheet, OUT / hero / f"style_{st}.png")
            meta[hero][f"style_{st}"] = clip_meta(marks, [s] * 8, [place] * 8, [round(fw * K), round(fh * K)],
                                                  [(px + pad) * K, (py + pad) * K],
                                                  {"times": TIMES, "active": 4, "release": RELEASE.get(st),
                                                   "direction": "forward", "scale": round(s, 4)})
        # ---- running
        if hero == "rok":
            offs = rok_run_offsets()
        else:
            src_run = [solid(c) for c in cells(Image.open(pack / "source_run/run.png").convert("RGBA"), cw, ch)]
            game_run = game_run_boxes(hero, cw, ch)
            rs = sum(g[3] - g[1] for g in game_run) / sum(r[3] - r[1] for r in src_run)
        for st in STYLES:
            phases_dir = pack / "running" / st / "phases"
            if not phases_dir.is_dir():
                continue
            guides = []
            for p in range(8):
                base = phases_dir / f"run_attack_phase_{p}.png"
                frames = [clear(c) for c in cells(Image.open(base).convert("RGBA"), cw, ch)]
                marks = load_marks(base, cw, ch)
                if hero == "rok":
                    scales = [1.0] * 8
                    places = [(offs[(p + i) % 8][0] + PAD, offs[(p + i) % 8][1] + PAD) for i in range(8)]
                    sheet, (fw, fh) = fit_sheet(frames, places, 1.0, cw, ch, PAD)
                else:
                    scales = [rs] * 8
                    places = []
                    for i in range(8):
                        j = (p + i) % 8
                        sb, gb = src_run[j], game_run[j]
                        places.append((round((gb[0] + gb[2]) / 2 - (sb[0] + sb[2]) / 2 * rs) + PAD,
                                       round(gb[3] - sb[3] * rs) + PAD))
                    # each frame its own placement: fit one by one
                    fw, fh = cw + PAD * 2, ch + PAD * 2
                    sheet = Image.new("RGBA", (fw * 4, fh * 2))
                    for i, f in enumerate(frames):
                        one, _ = fit_sheet([f], [places[i]], rs, cw, ch, PAD)
                        sheet.alpha_composite(one.crop((0, 0, fw, fh)), (i % 4 * fw, i // 4 * fh))
                save2(sheet, RUN_OUT / hero / f"run_style_{st}_{p}.png")
                g = clip_meta(marks, scales, places, None, None, {})
                guides.append({k: g[k] for k in ("grip", "angle", "head", "chest", "back")})
            meta[hero][f"run_style_{st}"] = {"frame": [round(fw * K), round(fh * K)],
                                             "pivot": [(px + PAD) * K, (py + PAD) * K],
                                             "hit": 4, "release": RELEASE.get(st), "phases": 8, "guides": guides}
        print(f"{hero}: " + ", ".join(sorted(meta[hero])))
    (OUT / "styles.json").write_text(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
