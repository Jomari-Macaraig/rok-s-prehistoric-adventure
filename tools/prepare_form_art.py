#!/usr/bin/env python3
"""The user's polished sheets for Rok and the original forms, at 1x and 2x.

Reads the user's new sheets in ../Assets (4x2 grids on the same canvas as the
original pack: Rok 384x512 frames, the Raptor 512x384) and writes every file
the game draws for that form, each at 1x (7/16, as before) and as a
<name>@2x.png twin (7/8, exactly twice the pixels; SpriteLib.tex() loads it
and draws it at the 1x size):

- characters/<form>/{idle,walk,run,jump,duck,slide}.png (+ celebrate for Rok)
- characters/<form>/die.png (+ its entry in characters/die.json)
- portraits/<form>.png
- reactions/<form>/{trip,dizzy,snag}.png (no new art yet: the hit-reaction
  pack's sheets, with 2x twins)

The new sheets don't keep one ground line (rows and sheets sit at different
heights), so each frame is moved so its art's bottom and centre land exactly
where the original pack's frame had them. Pivots, hitboxes and the game's
frame sizes stay as they were. A sheet that's missing falls back to the
original pack's art. Faint background haze (alpha below CLEAR_BELOW, which
some generated sheets carry over the whole canvas) is wiped.

Run after prepare_assets.py, prepare_reactions.gd and prepare_animation_pack.gd
(they write the old art over these files):
    uv run --no-project --with pillow python tools/prepare_form_art.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets"
OUT = ROOT / "assets"
PACK = SRC / "Rok" / "Rok_Complete_Animation_Pack" / "Rok_Animations"
ADDON = SRC / "Rok" / "Rok_Duck_Slide_Addon"
OLD_CELEBRATE = SRC / "Rok_Hunters_Crouches_Best_Distance" / "celebrations" / "rok" / "spritesheets" / "celebrate_jump.png"
REACTIONS = SRC / "Rok_Dinosaur_Expansion" / "Rok_Hit_Reactions"

SCALE = 7 / 16             # 1x game scale
SOLID = 128                # alpha that counts as the art's body when aligning
CLEAR_BELOW = 24           # alpha below this is background haze

# Per form: its frame in the source sheets, the user's new sheet for each
# clip, the defeat (death hop) sheet, and the height frame 0 of the death hop
# stands at 1x (prepare_assets.py's DEATHS).
FORMS = {
    "rok": {
        "frame": (384, 512),
        "sheets": {
            "idle": "Rok's Eight-Pose Idle Sprite Sheet-1.png",
            "walk": "Rok's Eight-Pose Walking Sprite Sheet-2.png",
            "run": "Rok’s Eight-Pose Run Sprite Sheet-3.png",
            "jump": "Rok's Eight-Pose Jump Sprite Sheet-4.png",
            "duck": "Rok's polished eight-frame crouch sheet-5.png",
            "slide": "Rok's eight-pose sliding sprite sheet-6.png",
            "celebrate": "Rok’s Celebration Jump Sprite Sheet-7.png",
        },
        "defeat": "Rok Caveman Defeat Sprite Sheet-8.png",
        "old_death": "Rok's stunned death-hop sprite sheet-1.png",
        "die_height": 168,
    },
    "raptor": {
        "frame": (512, 384),
        "sheets": {
            "idle": "Rok's Feathered Raptor Idle Frames-1.png",
            "walk": "Rok's Feathered Raptor Walk Cycle-2.png",
            "run": "Rok’s eight-frame feathered raptor run-3.png",
            "jump": "Orange raptor jump sprite sheet-4.png",
            "duck": "Rok's crouching raptor sprite sheet-5.png",
            "slide": "Feathered Raptor Slide Sprite Sheet-6.png",
        },
        "defeat": "Feathered raptor defeat sprite sheet-7.png",
        "old_death": "Rok's Raptor Stunned Hop Sprite Sheet-4.png",
        "die_height": 112,
    },
    # The pack also has 1774x887 idle (-1) and walk (-3) exports of the same
    # clips; these are the ones on the game's 512x384 grid.
    "triceratops": {
        "frame": (512, 384),
        "sheets": {
            "idle": "Eight-frame Triceratops idle sprite sheet-2.png",
            "walk": "Eight-Frame Triceratops Walk Cycle-9.png",
            "run": "Rok’s Triceratops Charge Sprite Sheet-4.png",
            "jump": "Polished triceratops jump sprite sheet-5.png",
            "duck": "Triceratops Crouch Sprite Sheet-6.png",
            "slide": "Rok's Triceratops slide animation sheet-7.png",
        },
        "defeat": "Rok's Triceratops hit-and-defeat sprites-8.png",
        "old_death": "Rok’s Triceratops Stun-Hop Sprite Sheet-3.png",
        "die_height": 136,
    },
    # Also a 1774x887 idle (-1) export; -2 is the one on the game's grid.
    "spinosaurus": {
        "frame": (512, 384),
        "sheets": {
            "idle": "Wide eight-frame Spinosaurus idle sheet-2.png",
            "walk": "Polished Spinosaurus Walk Cycle Sprite Sheet-3.png",
            "run": "Polished Spinosaurus Run Cycle Sheet-4.png",
            "jump": "Polished Spinosaurus jump sprite sheet-5.png",
            "duck": "Crouching Spinosaurus eight-pose sprite sheet-6.png",
            "slide": "Rok’s Spinosaurus slide transformation sheet-7.png",
            "swim": "Rok's Spinosaurus Swim Sprite Sheet-9.png",
        },
        "defeat": "Rok's Spinosaurus Hit-Defeat Sprite Sheet-8.png",
        "old_death": "Rok’s Spinosaurus death-hop sprite sheet-5.png",
        "die_height": 152,
    },
    # The pterosaur pack is on 384x512 frames (the original Pteranodon's are
    # 512x512) and drawn ~17% smaller, so each frame is scaled x1.2 before it's
    # placed. Its jump sheet carries a strong haze (alpha up to ~63). The pack's
    # second takeoff (-12) draws it smaller than the rest and is unused.
    "pteranodon": {
        "frame": (512, 512),
        "new_frame": (384, 512),
        "scale": 1.2,
        "clear": {"jump": 72},
        "sheets": {
            "idle": "Rok's pterosaur idle sprite sheet-1.png",
            "walk": "Rok's Pterosaur Walk Sprite Sheet-2.png",
            "run": "Rok’s Pterosaur Run Sprite Sheet-3.png",
            "jump": "Rok’s Pterosaur Jump Sprite Sheet-4.png",
            "duck": "Rok's crouching pterosaur sprite sheet-5.png",
            "slide": "Rok’s pterosaur slide sprite sheet-6.png",
            "takeoff": "Rok’s Pterosaur Takeoff Animation-8.png",
            "fly": "Rok’s Eight-Pose Pterosaur Flight Loop-9.png",
            "glide": "Rok’s Pterosaur Glide Sprite Sheet-10.png",
            "land": "Rok's Pterosaur Landing Sprite Sheet-11.png",
        },
        "defeat": "Rok’s Pterosaur Defeat Sprite Sheet-7.png",
        "old_death": "Rok’s Orange Pteranodon Death-Hop Sprite Sheet-2.png",
        "die_height": 124,
    },
}


def save(img: Image.Image, rel: str) -> None:
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    img.save(p, optimize=True)
    print(f"{rel:44s} {img.width}x{img.height}")


def both(img: Image.Image, rel: str, w1: int, h1: int) -> None:
    """Save img at w1 x h1 and its @2x twin at exactly twice that."""
    save(img.resize((w1, h1), Image.LANCZOS), rel)
    save(img.resize((w1 * 2, h1 * 2), Image.LANCZOS), rel.replace(".png", "@2x.png"))


def load_new(name: str, clear: int = CLEAR_BELOW) -> Image.Image:
    img = Image.open(SRC / name).convert("RGBA")
    r, g, b, a = img.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: 0 if v < clear else v)))


def frames(sheet: Image.Image, fw: int, fh: int) -> list:
    return [sheet.crop((i % 4 * fw, i // 4 * fh, i % 4 * fw + fw, i // 4 * fh + fh)) for i in range(8)]


def body(img: Image.Image, thr: int = SOLID):
    return img.getchannel("A").point(lambda a: 255 if a > thr else 0).getbbox()


def trimmed(img: Image.Image) -> Image.Image:
    bbox = body(img, 8)
    return img.crop(bbox) if bbox else img


def old_sheet(form: str, anim: str) -> Path:
    if anim == "swim":   # the trap expansion's Spinosaurus swim
        return SRC / "Rok_Trap_Expansion" / "Rok_Trap_Expansion" / "player" / "spinosaurus_swim" / "spinosaurus_swim.png"
    if form == "pteranodon":   # its own pack (all ten clips)
        return SRC / "Rok" / "Pteranodon_Animations" / "pteranodon" / "spritesheets" / f"{anim}.png"
    if anim in ("duck", "slide"):
        return ADDON / form / "spritesheets" / f"{anim}.png"
    return PACK / form / "spritesheets" / f"{anim}.png"


def old_bounds(form: str, anim: str, fw: int, fh: int) -> list:
    """Each original frame's body box in the form's frame space."""
    if anim == "celebrate":   # Rok only: a 576-wide canvas with the feet at x 288
        dx = 288 - fw // 2
        out = []
        for f in frames(Image.open(OLD_CELEBRATE).convert("RGBA"), 576, 512):
            l, t, r, b = body(f)
            out.append((l - dx, t, r - dx, b))
        return out
    return [body(f) for f in frames(Image.open(old_sheet(form, anim)).convert("RGBA"), fw, fh)]


def aligned_sheet(form: str, anim: str, name: str, fw: int, fh: int, cfg: dict) -> Image.Image:
    """The new sheet with every frame (cut at the pack's own frame size and
    scaled by its `scale`) moved onto the original's bottom-centre, on the
    original's fw x fh canvas."""
    nfw, nfh = cfg.get("new_frame", (fw, fh))
    k = cfg.get("scale", 1.0)
    out = Image.new("RGBA", (fw * 4, fh * 2))
    ref = old_bounds(form, anim, fw, fh)
    clear = cfg.get("clear", {}).get(anim, CLEAR_BELOW)
    for i, f in enumerate(frames(load_new(name, clear), nfw, nfh)):
        if k != 1.0:
            f = f.resize((round(nfw * k), round(nfh * k)), Image.LANCZOS)
        l, t, r, b = body(f)
        ol, ot, or_, ob = ref[i]
        dx = round((ol + or_) / 2 - (l + r) / 2)
        dy = ob - b
        cell = Image.new("RGBA", (fw, fh))
        # paste f at (dx, dy), clipped to the cell
        sx, sy = max(-dx, 0), max(-dy, 0)
        w, h = min(f.width - sx, fw - max(dx, 0)), min(f.height - sy, fh - max(dy, 0))
        if w > 0 and h > 0:
            cell.alpha_composite(f.crop((sx, sy, sx + w, sy + h)), (max(dx, 0), max(dy, 0)))
        art = body(f, 8)
        if art and (art[0] + dx < 0 or art[2] + dx > fw or art[1] + dy < 0 or art[3] + dy > fh):
            print(f"  note: {form} {anim} frame {i} is cropped at the frame edge")
        out.alpha_composite(cell, (i % 4 * fw, i // 4 * fh))
    return out


def sheets(form: str, cfg: dict) -> None:
    fw, fh = cfg["frame"]
    w1, h1 = round(fw * 4 * SCALE), round(fh * 2 * SCALE)
    for anim, name in cfg["sheets"].items():
        if (SRC / name).exists():
            img = aligned_sheet(form, anim, name, fw, fh, cfg)
        elif anim != "celebrate":
            print(f"  {name} not found: using the original {form} {anim}")
            img = Image.open(old_sheet(form, anim)).convert("RGBA")
        else:
            continue   # celebrate stays as prepare_animation_pack.gd made it
        both(img, f"characters/{form}/{anim}.png", w1, h1)


def die(form: str, cfg: dict) -> None:
    """The death hop (like prepare_assets.py's deaths()): eight trimmed frames,
    frame 0 scaled to die_height, packed bottom-centre. The 2x twin is built
    from the same layout at twice the size so it is exactly double."""
    fw, fh = cfg.get("new_frame", cfg["frame"])
    if (SRC / cfg["defeat"]).exists():
        fr = [trimmed(f) for f in frames(load_new(cfg["defeat"]), fw, fh)]
    else:
        sheet = Image.open(SRC / "Rok" / cfg["old_death"]).convert("RGBA")
        cw, ch = sheet.width / 4.0, sheet.height / 2.0
        fr = []
        for i in range(8):
            x0, y0 = round((i % 4) * cw), round((i // 4) * ch)
            fr.append(trimmed(sheet.crop((x0 + 2, y0 + 2, round(x0 + cw) - 2, round(y0 + ch) - 2))))
    sc = cfg["die_height"] / fr[0].height
    sizes = [(round(f.width * sc), round(f.height * sc)) for f in fr]
    w = max(s[0] for s in sizes) + 4
    h = max(s[1] for s in sizes) + 4
    for k, rel in ((1, f"characters/{form}/die.png"), (2, f"characters/{form}/die@2x.png")):
        out = Image.new("RGBA", (w * 4 * k, h * 2 * k))
        for i, f in enumerate(fr):
            sw, sh = sizes[i]
            f = f.resize((sw * k, sh * k), Image.LANCZOS)
            cx, cy = (i % 4) * w, (i // 4) * h
            out.alpha_composite(f, ((cx + (w - sw) // 2) * k, (cy + h - sh) * k))
        save(out, rel)
    meta_path = OUT / "characters" / "die.json"
    meta = json.loads(meta_path.read_text())
    meta[form] = {"frame": [w, h], "pivot": [w / 2.0, h - 2.0]}
    meta_path.write_text(json.dumps(meta, indent=1))


def portrait(form: str) -> None:
    """HUD icon: the first idle frame, trimmed, fitted in 140x120 (and 2x)."""
    sheet = Image.open(OUT / "characters" / form / "idle@2x.png").convert("RGBA")
    img = trimmed(sheet.crop((0, 0, sheet.width // 4, sheet.height // 2)))
    small = img.copy()
    small.thumbnail((140, 120), Image.LANCZOS)
    both(img, f"portraits/{form}.png", small.width, small.height)


def reactions(form: str) -> None:
    """Trip, dizzy and snag: no new art yet, so the hit-reaction pack's sheets
    at the sizes prepare_reactions.gd gave them, plus 2x twins."""
    meta = json.loads((REACTIONS / "hit_reactions.json").read_text())
    if form not in meta["characters"]:
        return
    done = set()
    for a in meta["characters"][form]["animations"].values():
        if a["sheet"] in done:
            continue
        done.add(a["sheet"])
        rel = f"reactions/{form}/{Path(a['sheet']).stem}.png"
        w1, h1 = Image.open(OUT / rel).size
        both(Image.open(REACTIONS / a["sheet"]).convert("RGBA"), rel, w1, h1)


if __name__ == "__main__":
    for form, cfg in FORMS.items():
        sheets(form, cfg)
        die(form, cfg)
        portrait(form)
        reactions(form)
