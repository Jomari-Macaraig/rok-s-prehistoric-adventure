#!/usr/bin/env python3
"""The user's Canyon pack (../Assets/Rok_Canyon_Asset_Pack/Rok_Canyon_Assets,
README there) -> the Canyon zone's art.

- Backgrounds (assets/bg/canyon_{far,mid,near}.png, 1536x720 like the pack,
  bottom on its ground line): the far layer's painted sky is keyed out (the
  game draws its own day/night sky): a pixel's "skyness" is how much bluer
  than red it is, and its colour is un-mixed from the sky's so cloud and
  mesa edges keep no cyan fringe. Mid mesas and near spires are used as
  they are. The pack wants mirrored repeat: Background.Layer flips every
  other copy (`mirror`).
- Ground (assets/terrain/canyon_ground.png + @2x): the strip from 24 source
  px above its running surface (y 130), so its sandy crust sits where the
  other zones' does (12 px above the feet at 1x); its lower strata are
  repeated mirrored down to 840 px (@2x) like the desert strip; the strip is
  joined to its mirror image so ordinary repeat tiles it seamlessly.
  Scale 0.5 (the pack's default).
- Obstacles and decor (assets/canyon/<id>.png + @2x), trimmed to their art,
  at the pack's default scale (1x) and twice that (@2x): sandstone_boulder,
  tall_rock_pillar, cactus_cluster, tumble_thorn, cracked_sandstone_wall,
  wooden_barricade, sandstone_spikes, stone_scatter, dry_shrub,
  fossil_outcrop. Course scales them to the footprint of the obstacle each
  replaces.
- The low arch (assets/canyon/rock_arch.png + @2x): the pack's opening is
  far lower than the game's slide clearance, so its lintel is raised on two
  legs of the pack's cracked sandstone blocks (stacked under each end,
  ARCH_LEGS) to make the opening ARCH_OPEN source px (113 px at 1x, above
  LEDGE_CLEARANCE); canyon.json `arch_lintel` is the lintel's height at 1x
  (the part that collides).
- Island (assets/props/Terrain-variation_03_canyon.png): the raised
  sandstone ledge trimmed and scaled to the forest island's 131 px width,
  with its walkable surface FloatingPlatform.TOP_INSET (14 px) below the top.
- Rope bridge and cliff edges (assets/canyon/), with their surface lines in
  canyon.json.

    uv run --no-project --with pillow python tools/prepare_canyon.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Canyon_Asset_Pack" / "Rok_Canyon_Assets" / "textures"
OUT = ROOT / "assets" / "canyon"
PROPS = {"sandstone_boulder": ("obstacles", 0.28125), "tall_rock_pillar": ("obstacles", 0.3046875),
         "cactus_cluster": ("obstacles", 0.3125), "tumble_thorn": ("obstacles", 0.275),
         "cracked_sandstone_wall": ("obstacles", 0.29166667), "wooden_barricade": ("obstacles", 0.29296875),
         "sandstone_spikes": ("obstacles", 0.33203125), "stone_scatter": ("decor", 0.27604167),
         "dry_shrub": ("decor", 0.275), "fossil_outcrop": ("decor", 0.32142857)}
GROUND_SCALE = 0.5
GROUND_TOP = 130 - 24          # source rows: crust 12 px (1x) above the feet line
ARCH_SCALE = 0.55
ARCH_LINTEL_BOTTOM = 305       # source: the underside of the lintel (measured)
ARCH_GROUND = 369
ARCH_LEGS = [(40, 205), (440, 605)]   # source columns of the two legs under the lintel
ARCH_OPEN = 205                # source px of opening: 205 * 0.55 = 113 > LEDGE_CLEARANCE 110
ISLAND_W = 131
TOP_INSET = 14


def trim(im):
    return im.crop(im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())


def save2(im, path, k):
    """1x at scale k, @2x at 2k."""
    for kk, sfx in ((k, ""), (2 * k, "@2x")):
        im.resize((max(1, round(im.width * kk)), max(1, round(im.height * kk))), Image.LANCZOS) \
            .save(path.with_name(path.stem + sfx + ".png"), optimize=True)


def key_sky(im):
    px = im.load()
    sky = (64, 190, 205)   # the pack's cyan
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            s = max(0.0, min(1.0, (b - r - 20) / 90.0))
            if s <= 0.0:
                continue
            if s >= 0.99:
                px[x, y] = (0, 0, 0, 0)
                continue
            k = 1.0 - s
            un = [max(0, min(255, round((c - s * sc) / k))) for c, sc in zip((r, g, b), sky)]
            px[x, y] = (un[0], un[1], un[2], round(a * k))
    return im


def mirrored(im):
    out = Image.new("RGBA", (im.width * 2, im.height))
    out.paste(im, (0, 0))
    out.paste(ImageOps.mirror(im), (im.width, 0))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    # backgrounds
    far = key_sky(Image.open(SRC / "backgrounds/bg_far_sky.png").convert("RGBA"))
    far.save(ROOT / "assets/bg/canyon_far.png", optimize=True)
    for n, f in (("mid", "bg_mid_mesas"), ("near", "bg_near_spires")):
        Image.open(SRC / f"backgrounds/{f}.png").convert("RGBA").save(ROOT / f"assets/bg/canyon_{n}.png", optimize=True)
    # ground strip
    g = Image.open(SRC / "terrain/canyon_ground.png").convert("RGBA").crop((0, GROUND_TOP, 1536, 512))
    body = g.crop((0, g.height - 220, g.width, g.height))
    tall = Image.new("RGBA", (g.width, round(840 / (2 * GROUND_SCALE))))
    tall.paste(g, (0, 0))
    y, flip = g.height, True
    while y < tall.height:
        tall.paste(ImageOps.flip(body) if flip else body, (0, y))
        y += body.height
        flip = not flip
    save2(mirrored(tall), ROOT / "assets/terrain/canyon_ground.png", GROUND_SCALE)
    # obstacles and decor
    for n, (cat, k) in PROPS.items():
        save2(trim(Image.open(SRC / f"{cat}/{n}.png").convert("RGBA")), OUT / f"{n}.png", k)
    # the arch, legs stacked up to the game's slide clearance
    a = Image.open(SRC / "obstacles/low_rock_arch.png").convert("RGBA")
    lintel = a.crop((0, 0, a.width, ARCH_LINTEL_BOTTOM + 8))
    # legs: the pack's cracked sandstone blocks, stacked under each end of the lintel
    block = trim(Image.open(SRC / "obstacles/cracked_sandstone_wall.png").convert("RGBA"))
    arch = Image.new("RGBA", (a.width, ARCH_LINTEL_BOTTOM + ARCH_OPEN))
    for x0, x1 in ARCH_LEGS:
        w = x1 - x0
        b = block.resize((w, round(block.height * w / block.width)), Image.LANCZOS)
        y = arch.height - b.height
        flip = False
        while y + b.height > ARCH_LINTEL_BOTTOM - 20:
            arch.alpha_composite(ImageOps.mirror(b) if flip else b, (x0, y))
            y -= b.height - 14
            flip = not flip
    arch.alpha_composite(lintel, (0, 0))
    bb = arch.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    arch = arch.crop((bb[0], bb[1], bb[2], arch.height))
    save2(arch, OUT / "rock_arch.png", ARCH_SCALE)
    meta["arch_lintel"] = round((ARCH_LINTEL_BOTTOM - bb[1]) * ARCH_SCALE, 1)
    meta["arch_open"] = round(ARCH_OPEN * ARCH_SCALE, 1)
    # floating island at the forest island's width, surface TOP_INSET below the top
    led = Image.open(SRC / "terrain/floating_sandstone_ledge.png").convert("RGBA")
    lb = led.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    k = ISLAND_W / (lb[2] - lb[0])
    surface = 133
    pad = max(0, round(TOP_INSET / k - (surface - lb[1])))
    cropped = led.crop(lb)
    isl = Image.new("RGBA", (cropped.width, cropped.height + pad))
    isl.paste(cropped, (0, pad))
    isl.resize((ISLAND_W, round(isl.height * k)), Image.LANCZOS).save(ROOT / "assets/props/Terrain-variation_03_canyon.png", optimize=True)
    # rope bridge (surface at y 293) and cliff edges (lip at the pack's pivot), at 0.5
    br = Image.open(SRC / "terrain/rope_bridge.png").convert("RGBA")
    bb = br.getchannel("A").getbbox()
    save2(br.crop(bb), OUT / "rope_bridge.png", 0.5)
    meta["bridge"] = {"surface": round((293 - bb[1]) * 0.5, 1)}
    for side, piv in (("left", (102, 152)), ("right", (389, 165))):
        c = Image.open(SRC / f"terrain/cliff_edge_{side}.png").convert("RGBA")
        save2(c, OUT / f"cliff_{side}.png", 0.5)
        meta[f"cliff_{side}"] = [piv[0] * 0.5, piv[1] * 0.5]
    (OUT / "canyon.json").write_text(json.dumps(meta, indent=1))
    print("canyon:", meta)


if __name__ == "__main__":
    main()
