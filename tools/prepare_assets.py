#!/usr/bin/env python3
"""Asset pipeline for Rok Runner.

Reads the original art from ../Assets (never modified) and writes game-ready,
pre-scaled copies into ./assets. Pre-scaling keeps the large source art sharp
(Lanczos downsample) instead of relying on the GPU to shrink 2000px images.

Usage (needs Pillow):  python3 tools/prepare_assets.py
"""
import json
import os
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets"
OUT = ROOT / "assets"
ENV = SRC / "Environment Assets"
ROK = SRC / "Rok" / "Rok_Complete_Animation_Pack" / "Rok_Animations"
ROK_ADDON = SRC / "Rok" / "Rok_Duck_Slide_Addon"
TRAPS = SRC / "Rok_Trap_Expansion" / "Rok_Trap_Expansion"
PTERA = SRC / "Rok" / "Pteranodon_Animations" / "pteranodon"
TREX = SRC / "Trex_Chaser_Animations" / "Rok_Enemies" / "trex"
TREX_SCALE = 0.875           # 768x512 -> 672x448: about twice Rok's height
PTERA_ANIMS = ("idle", "walk", "run", "jump", "duck", "slide", "fly", "glide", "takeoff", "land")
WIND = ENV / "Animations" / "Vegetation_Wind_Animation_Pack" / "Vegetation_Wind_Animations"

VIEW_W, VIEW_H = 1280, 720
CHAR_SCALE = 7 / 16          # 384x512 -> 168x224, 512x384 -> 224x168
PROP_SCALE = 0.45
WIND_SCALE = 0.5


def save(img: Image.Image, rel: str) -> None:
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    img.save(p, optimize=True)


def scaled(img: Image.Image, s: float) -> Image.Image:
    w, h = round(img.width * s), round(img.height * s)
    return img.resize((w, h), Image.LANCZOS)


def trimmed(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    return img.crop(bbox) if bbox else img


def backgrounds() -> None:
    for i in (1, 2, 3):
        img = Image.open(SRC / f"bg-{i}.png").convert("RGBA")
        img = img.resize((VIEW_W, VIEW_H), Image.LANCZOS)
        if i == 2:
            # mountains do not span the full width; crop to the art so the
            # layer can tile edge-to-edge without empty gaps
            l, _, r, _ = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
            img = img.crop((l, 0, r, VIEW_H))
        save(img, f"bg/bg_{i}.png")


def characters() -> None:
    for form in ("rok", "raptor", "triceratops", "spinosaurus"):
        for anim in ("idle", "walk", "run", "jump"):
            img = Image.open(ROK / form / "spritesheets" / f"{anim}.png").convert("RGBA")
            save(scaled(img, CHAR_SCALE), f"characters/{form}/{anim}.png")
        for anim in ("duck", "slide"):
            img = Image.open(ROK_ADDON / form / "spritesheets" / f"{anim}.png").convert("RGBA")
            save(scaled(img, CHAR_SCALE), f"characters/{form}/{anim}.png")
    swim = Image.open(TRAPS / "player" / "spinosaurus_swim" / "spinosaurus_swim.png").convert("RGBA")
    save(scaled(swim, CHAR_SCALE), "characters/spinosaurus/swim.png")
    # Pteranodon (512x512 canvas -> 224x224) has its own pack incl. flight
    for anim in PTERA_ANIMS:
        img = Image.open(PTERA / "spritesheets" / f"{anim}.png").convert("RGBA")
        save(scaled(img, CHAR_SCALE), f"characters/pteranodon/{anim}.png")

    # the T-rex pursuer
    for anim in ("idle", "run", "roar", "bite"):
        img = Image.open(TREX / "spritesheets" / f"{anim}.png").convert("RGBA")
        save(scaled(img, TREX_SCALE), f"characters/trex/{anim}.png")
    sheet = Image.open(TREX / "spritesheets" / "idle.png").convert("RGBA")
    img = trimmed(sheet.crop((0, 0, sheet.width // 4, sheet.height // 2)))
    img.thumbnail((140, 120), Image.LANCZOS)
    save(img, "portraits/trex.png")

    # HUD icons: first idle frame of each form (the big character renders
    # have opaque white backgrounds, the animation frames are transparent)
    for form in ("rok", "raptor", "triceratops", "spinosaurus", "pteranodon"):
        src = PTERA if form == "pteranodon" else ROK / form
        sheet = Image.open(src / "spritesheets" / "idle.png").convert("RGBA")
        fw, fh = sheet.width // 4, sheet.height // 2
        img = trimmed(sheet.crop((0, 0, fw, fh)))
        img.thumbnail((140, 120), Image.LANCZOS)
        save(img, f"portraits/{form}.png")


TERRAIN_SCALE = 0.55
# (source file, crop box in source px). Crops trim the dark outline on edges
# that join a neighbour so tiles butt together without seams; outer edges
# (cap ends, slope ends) keep their outline.
TERRAIN_PIECES = {
    # crops go past the outline *and* the darker shading just inside it,
    # so neighbouring blocks read as one continuous strip of ground
    "mid_a": ("Terrain Tiles/Terrain-tiles_02.png", (31, 52, 181, 252)),
    "mid_b": ("Terrain Tiles/Terrain-tiles_03.png", (34, 52, 183, 252)),
    "cap_left": ("Terrain Tiles/Terrain-tiles_01.png", (46, 52, 203, 252)),
    "cap_right": ("Terrain Tiles/Terrain-tiles_04.png", (31, 52, 183, 252)),
    "slope_up": ("Terrain Variations/Terrain-variation_01.png", (46, 18, 266, 190)),
    "slope_down": ("Terrain Variations/Terrain-variation_02.png", (26, 18, 250, 190)),
    "drop": ("Terrain Tiles/Terrain-tiles_10.png", (30, 46, 205, 252)),
}


def _grass_top(img: Image.Image, x0: int, x1: int) -> float:
    """Median first-opaque row across columns x0..x1 (the grass tips)."""
    a = img.getchannel("A")
    tops = []
    for x in range(max(0, x0), min(img.width, x1)):
        for y in range(img.height):
            if a.getpixel((x, y)) > 128:
                tops.append(y)
                break
    tops.sort()
    return float(tops[len(tops) // 2]) if tops else 0.0


def terrain() -> None:
    """Ground tiles from the Terrain Tiles / Terrain Variations packs."""
    meta = {}
    imgs = {}
    for name, (f, box) in TERRAIN_PIECES.items():
        imgs[name] = Image.open(ENV / f).convert("RGBA").crop(box)
    # the slope's rise defines one terrain level; scale the step tile so its
    # drop matches exactly
    up = imgs["slope_up"]
    rise_src = _grass_top(up, 2, 12) - _grass_top(up, up.width - 30, up.width - 4)
    drop = imgs["drop"]
    drop_src = _grass_top(drop, drop.width - 50, drop.width - 4) - _grass_top(drop, 14, 40)
    step = rise_src * TERRAIN_SCALE
    for name, img in imgs.items():
        sc = step / drop_src if name == "drop" else TERRAIN_SCALE
        out = scaled(img, sc)
        save(out, f"terrain/{name}.png")
        w = out.width
        meta[name] = {
            "size": [out.width, out.height],
            # grass-tip line (px from the piece top) at its left / right end
            "left": _grass_top(out, 2, 8 if name != "cap_left" else w // 2),
            "right": _grass_top(out, w - 8 if name != "cap_right" else w // 2, w - 2),
            "mid": _grass_top(out, w // 3, 2 * w // 3),
            # smoothed grass line along the piece, for physics on slopes/steps
            "profile": [[x, _grass_top(out, x - 5, x + 6)] for x in range(0, w + 1, max(1, w // 10))],
        }
    dirt = Image.open(ENV / "Seamless Tileable Textures/Seamless-tileable-textures_02.png").convert("RGBA")
    dirt = scaled(dirt.crop((35, 46, 291, 302)), TERRAIN_SCALE)
    save(dirt, "terrain/dirt.png")
    # cobblestone fill for the Rocky Canyon zone
    cob = Image.open(ENV / "Seamless Tileable Textures/Seamless-tileable-textures_03.png").convert("RGBA")
    save(scaled(cob.crop((33, 46, 295, 302)), TERRAIN_SCALE), "terrain/cobble.png")
    meta["level_step"] = meta["slope_up"]["left"] - meta["slope_up"]["right"]
    (OUT / "terrain" / "terrain.json").write_text(json.dumps(meta, indent=1))


def props() -> None:
    for folder in ("Stones", "Logs", "Fences", "Mushrooms", "Other", "Signs",
                   "Grasses", "Terrain Variations", "Other Tiles", "Trees"):
        for f in sorted((ENV / folder).glob("*.png")):
            img = trimmed(Image.open(f).convert("RGBA"))
            save(scaled(img, PROP_SCALE), f"props/{f.name}")


def wind() -> None:
    meta = json.loads((WIND / "animations.json").read_text())
    out = {}
    for name, a in meta["assets"].items():
        img = Image.open(WIND / a["sheet"]).convert("RGBA")
        save(scaled(img, WIND_SCALE), f"wind/{name}.png")
        out[name] = {
            "category": a["category"],
            "frame": [a["frame_size"][0] * WIND_SCALE, a["frame_size"][1] * WIND_SCALE],
            "pivot": [a["root_pivot_px"][0] * WIND_SCALE, a["root_pivot_px"][1] * WIND_SCALE],
            "frame_ms": a["frame_duration_ms"],
        }
    (OUT / "wind" / "wind.json").write_text(json.dumps(out, indent=1))


def _tall_ground(strip: Image.Image, crop_body_from: int, height: int = 420) -> Image.Image:
    """Ground strip on top, its body repeated (shifted + cross-faded) below."""
    body = strip.crop((0, crop_body_from, strip.width, strip.height))
    fade = 20
    tall = Image.new("RGBA", (strip.width, height))
    tall.alpha_composite(strip, (0, 0))
    y, shift = strip.height - fade, 0
    mask = Image.new("L", body.size, 255)
    for r in range(fade):
        mask.paste(int(255 * r / fade), (0, r, body.width, r + 1))
    while y < height:
        shift = (shift + 517) % strip.width
        piece = Image.new("RGBA", body.size)
        piece.paste(body.crop((shift, 0, body.width, body.height)), (0, 0))
        piece.paste(body.crop((0, 0, shift, body.height)), (body.width - shift, 0))
        tall.paste(piece, (0, y), mask)
        y += body.height - fade
    return tall


def _recolor(img: Image.Image, dark, light, gamma=1.0) -> Image.Image:
    """Map luminance onto a dark->light ramp, keeping alpha."""
    import numpy as np
    a = np.asarray(img.convert("RGBA")).astype(float)
    lum = (a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11) / 255.0
    lum = lum ** gamma
    out = a.copy()
    for c in range(3):
        out[..., c] = dark[c] + (light[c] - dark[c]) * lum
    return Image.fromarray(out.clip(0, 255).astype("uint8"), "RGBA")


def zones() -> None:
    """Desert art (supplied) and volcanic badlands (recoloured from it until
    dedicated art exists): far backdrop, mid dunes and a ground strip each."""
    import numpy as np
    import random
    random.seed(4)
    mesa = Image.open(SRC / "Distant Desert Mesa Backdrop-2.png").convert("RGBA").resize((VIEW_W, VIEW_H), Image.LANCZOS)
    # key out the baked-in sky so the game's sky (day/night) shows through
    a = np.asarray(mesa).astype(int)
    sky = a[8, 8, :3]
    dist = np.abs(a[..., :3] - sky).sum(axis=2)
    rows = np.arange(VIEW_H)[:, None]
    alpha = np.where((dist < 40) & (rows < VIEW_H * 0.8), 0, 255)
    edge = np.where((dist < 70) & (dist >= 40) & (rows < VIEW_H * 0.8), 140, alpha)
    a[..., 3] = edge
    mesa = Image.fromarray(a.astype("uint8"), "RGBA")
    save(mesa, "bg/desert_far.png")
    dunes = Image.open(SRC / "Rolling golden desert dunes-3.png").convert("RGBA").resize((VIEW_W, VIEW_H), Image.LANCZOS)
    save(dunes, "bg/desert_dunes.png")
    strip = Image.open(SRC / "Golden Sandstone Desert Ground Strip-1.png").convert("RGBA")
    strip = strip.crop((0, 766, strip.width, strip.height))
    strip = strip.resize((VIEW_W, round(strip.height * VIEW_W / 1672)), Image.LANCZOS)
    save(_tall_ground(strip, 40), "terrain/desert_ground.png")

    # volcanic badlands: supplied far / mid / ground layers (Rok_Trap_Expansion)
    vb = TRAPS / "volcanic_biome"
    far = Image.open(vb / "volcanic_bg_far.png").convert("RGBA").resize((VIEW_W, VIEW_H), Image.LANCZOS)
    a = np.asarray(far).astype(int)
    sky = a[8, 8, :3]
    dist = np.abs(a[..., :3] - sky).sum(axis=2)
    rows = np.arange(VIEW_H)[:, None]
    alpha = np.where((dist < 36) & (rows < VIEW_H * 0.8), 0, 255)
    a[..., 3] = np.where((dist < 64) & (dist >= 36) & (rows < VIEW_H * 0.8), 150, alpha)
    save(Image.fromarray(a.astype("uint8"), "RGBA"), "bg/volcanic_far.png")
    mid = Image.open(vb / "volcanic_bg_mid.png").convert("RGBA").resize((VIEW_W, VIEW_H), Image.LANCZOS)
    save(mid, "bg/volcanic_dunes.png")
    g = Image.open(vb / "volcanic_ground.png").convert("RGBA")
    g = g.crop((0, 764, g.width, g.height))
    g = g.resize((VIEW_W, round(g.height * VIEW_W / 1672)), Image.LANCZOS)
    save(_tall_ground(g, 40), "terrain/volcanic_ground.png")


TRAP_SCALE = 7 / 16          # 512 px trap frames -> 224 (same scale as Rok)
BREAK_SCALE = PROP_SCALE     # existing-prop break frames hold props at native size


def _sheet_frames(img: Image.Image, fw: int, fh: int) -> list:
    return [img.crop(((i % 4) * fw, (i // 4) * fh, (i % 4 + 1) * fw, (i // 4 + 1) * fh)) for i in range(8)]


def _pack(frames: list) -> Image.Image:
    fw, fh = frames[0].size
    out = Image.new("RGBA", (fw * 4, fh * 2))
    for i, f in enumerate(frames):
        out.paste(f, ((i % 4) * fw, (i // 4) * fh))
    return out


def traps() -> None:
    """Trap / destruction animations from Rok_Trap_Expansion, pre-scaled.
    Liquids are split into left bank, repeatable centre and right bank so
    crossings can be any width. Writes traps/traps.json with frame sizes,
    anchors and durations."""
    man = json.loads((TRAPS / "trap_manifest.json").read_text())
    meta = {}
    for name, a in man["animations"].items():
        sheet = Image.open(TRAPS / a["sheet"]).convert("RGBA")
        fw, fh = a["frame_size"]
        sc = BREAK_SCALE if name.startswith("existing_") else TRAP_SCALE
        frames = _sheet_frames(sheet, fw, fh)
        info = {"duration_ms": a["duration_ms"], "loop": a["loop"], "events": a.get("events", {})}
        if "optional_liquid_center_crop_px" in a:
            cx, _, cw, _ = a["optional_liquid_center_crop_px"]
            parts = {"left": (0, cx), "mid": (cx, cx + cw), "right": (cx + cw, fw)}
            for part, (x0, x1) in parts.items():
                fr = [scaled(f.crop((x0, 0, x1, fh)), sc) for f in frames]
                save(_pack(fr), f"traps/{name}_{part}.png")
                info[part] = list(fr[0].size)
            info["anchor"] = [0, a["anchor_px"][1] * sc]   # surface line (y)
            info["surface_y"] = a["anchor_px"][1] * sc
        else:
            fr = [scaled(f, sc) for f in frames]
            save(_pack(fr), f"traps/{name}.png")
            info["frame"] = list(fr[0].size)
            info["anchor"] = [a["anchor_px"][0] * sc, a["anchor_px"][1] * sc]
            vb = a.get("visual_bounds_px")
            if vb:
                info["bounds0"] = [v * sc for v in vb[0]]
        meta[name] = info
    for name, st in man["statics"].items():
        img = trimmed(Image.open(TRAPS / st["file"]).convert("RGBA"))
        img = scaled(img, 0.62)
        save(img, f"traps/{name}.png")
        meta[name] = {"size": list(img.size)}
    (OUT / "traps").mkdir(parents=True, exist_ok=True)
    (OUT / "traps" / "traps.json").write_text(json.dumps(meta, indent=1))


# Death-hop sheets (4x2, non-integer cells): file per form and the form's
# visible standing height in the game (px), used to scale the art to match.
DEATHS = {
    "rok": ("Rok's stunned death-hop sprite sheet-1.png", 168),
    "pteranodon": ("Rok’s Orange Pteranodon Death-Hop Sprite Sheet-2.png", 124),
    "triceratops": ("Rok’s Triceratops Stun-Hop Sprite Sheet-3.png", 136),
    "raptor": ("Rok's Raptor Stunned Hop Sprite Sheet-4.png", 112),
    "spinosaurus": ("Rok’s Spinosaurus death-hop sprite sheet-5.png", 152),
}


def deaths() -> None:
    """Cut each death sheet into 8 frames, trim them, scale the form to its
    in-game height (frame 0 = standing hit pose) and pack them on a shared
    canvas aligned bottom-centre (the feet). Writes characters/<form>/die.png
    and characters/die.json (frame size + pivot per form)."""
    meta = {}
    for form, (fname, target_h) in DEATHS.items():
        sheet = Image.open(SRC / "Rok" / fname).convert("RGBA")
        cw, ch = sheet.width / 4.0, sheet.height / 2.0
        frames = []
        for i in range(8):
            x0, y0 = round((i % 4) * cw), round((i // 4) * ch)
            cell = sheet.crop((x0 + 2, y0 + 2, round(x0 + cw) - 2, round(y0 + ch) - 2))
            frames.append(trimmed(cell))
        sc = target_h / frames[0].height
        frames = [scaled(f, sc) for f in frames]
        w = max(f.width for f in frames) + 4
        h = max(f.height for f in frames) + 4
        out = Image.new("RGBA", (w * 4, h * 2))
        for i, f in enumerate(frames):
            cx, cy = (i % 4) * w, (i // 4) * h
            out.alpha_composite(f, (cx + (w - f.width) // 2, cy + h - f.height))
        save(out, f"characters/{form}/die.png")
        meta[form] = {"frame": [w, h], "pivot": [w / 2.0, h - 2.0]}
    (OUT / "characters" / "die.json").write_text(json.dumps(meta, indent=1))


POWERUPS = SRC / "Rok_Powerups"
POWERUP_IDS = ("dino_egg", "amber_shield", "fossil_magnet", "time_crystal", "primal_berry", "golden_fossil")


def powerups() -> None:
    """Power-up pickups (Rok_Powerups): the 128 px idle loop sheets (4x2,
    160 ms per frame) and static 128 px icons, copied as-is."""
    for pid in POWERUP_IDS:
        sheet = Image.open(POWERUPS / "animations" / "128" / pid / f"{pid}_idle.png").convert("RGBA")
        save(sheet, f"powerups/{pid}_idle.png")
        save(Image.open(POWERUPS / "png" / "128" / f"{pid}.png").convert("RGBA"), f"powerups/{pid}.png")


BLAZE_PEPPER = SRC / "Golden-flame blaze pepper.png"


def blaze_pepper() -> None:
    """The Blaze Pepper power-up (the speed boost; it replaced the Dino Egg):
    one still picture, trimmed and fitted to 104 px on a 128 px canvas like the
    other power-up icons. Until it has an idle loop, the 4x2 idle sheet is that
    same picture eight times (the pickup still bobs in code)."""
    img = trimmed(Image.open(BLAZE_PEPPER).convert("RGBA"))
    img.thumbnail((104, 104), Image.LANCZOS)
    icon = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    icon.alpha_composite(img, ((128 - img.width) // 2, (128 - img.height) // 2))
    save(icon, "powerups/blaze_pepper.png")
    sheet = Image.new("RGBA", (512, 256), (0, 0, 0, 0))
    for i in range(8):
        sheet.alpha_composite(icon, ((i % 4) * 128, (i // 4) * 128))
    save(sheet, "powerups/blaze_pepper_idle.png")


MEAT_ART = SRC / "Rok_Meat_Currency" / "meat_128.png"   # the real art (tools/prepare_meat.gd does the same without Pillow)
MEAT_IDLE = SRC / "Rok_Meat_Currency" / "animations" / "128" / "spritesheets" / "meat_idle.png"


def meat() -> None:
    """The Market currency pickup: items/meat.png (96 px). Uses MEAT_ART when
    it exists; until then draws a placeholder meat-on-the-bone."""
    if MEAT_ART.exists():
        img = trimmed(Image.open(MEAT_ART).convert("RGBA"))
        img.thumbnail((96, 96), Image.LANCZOS)
        canvas = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        canvas.alpha_composite(img, ((96 - img.width) // 2, (96 - img.height) // 2))
        save(canvas, "items/meat.png")
        if MEAT_IDLE.exists():
            save(Image.open(MEAT_IDLE).convert("RGBA"), "items/meat_idle.png")   # 4x2 pickup loop, 128 px
        return
    from PIL import ImageDraw
    s = 4   # draw big, then shrink for smooth edges
    img = Image.new("RGBA", (96 * s, 96 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ink = (70, 32, 14, 255)
    bone, bone_hi = (246, 236, 214, 255), (255, 252, 240, 255)
    # bone sticking out to the lower right, with two knobs
    d.line([(52 * s, 52 * s), (78 * s, 78 * s)], fill=ink, width=16 * s)
    d.line([(52 * s, 52 * s), (78 * s, 78 * s)], fill=bone, width=10 * s)
    for cx, cy in ((80, 72), (72, 82)):
        d.ellipse([(cx - 8) * s, (cy - 8) * s, (cx + 8) * s, (cy + 8) * s], fill=ink)
        d.ellipse([(cx - 5.5) * s, (cy - 5.5) * s, (cx + 5.5) * s, (cy + 5.5) * s], fill=bone)
    d.ellipse([77 * s, 69 * s, 81 * s, 73 * s], fill=bone_hi)
    # the meat: a fat rounded chunk, darker rim, glossy highlight
    d.ellipse([8 * s, 10 * s, 64 * s, 62 * s], fill=ink)
    d.ellipse([12 * s, 14 * s, 60 * s, 58 * s], fill=(176, 72, 40, 255))
    d.ellipse([16 * s, 16 * s, 56 * s, 50 * s], fill=(206, 98, 54, 255))
    d.ellipse([22 * s, 20 * s, 40 * s, 32 * s], fill=(240, 160, 110, 255))
    d.ellipse([26 * s, 22 * s, 33 * s, 27 * s], fill=(255, 220, 190, 255))
    for x0, y0 in ((40, 38), (28, 44), (46, 26)):   # grill marks
        d.line([(x0 * s, y0 * s), ((x0 + 6) * s, (y0 - 6) * s)], fill=(130, 50, 26, 255), width=3 * s)
    img = img.resize((96, 96), Image.LANCZOS)
    save(img, "items/meat.png")


def icon() -> None:
    # the user's app icon (Rok, Nira and Boro; 1024 px, opaque as iOS needs):
    # copied as the iOS export icon and scaled to 256 px for the project icon
    app = SRC / "Rok_Group_App_Icon_1024.png"
    if app.exists():
        img = Image.open(app).convert("RGB")
        img.save(OUT / "icon_1024.png")
        img.resize((256, 256), Image.LANCZOS).save(ROOT / "icon.png")
        return
    img = trimmed(Image.open(SRC / "Rok" / "01_Rok_Front.png").convert("RGBA"))
    img.thumbnail((256, 256), Image.LANCZOS)
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((256 - img.width) // 2, (256 - img.height) // 2))
    canvas.save(ROOT / "icon.png")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    backgrounds()
    characters()
    terrain()
    zones()
    traps()
    deaths()
    powerups()
    blaze_pepper()
    meat()
    props()
    wind()
    icon()
    print("assets written to", OUT)
