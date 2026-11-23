#!/usr/bin/env python3
"""The user's polished course art (../Assets/Rok_Polished_Assets).

The pack redraws 69 of the game's own prop and trap images (assets/props/
and assets/traps/: fences, grasses, logs, mushrooms, signs, stones, other
props, every break and collapse sheet, the liquids' left/mid/right pieces,
the steam vent, rolling boulder, Spinosaurus swim, the forest overhead and
desert fossil arch) at exactly the same sizes, frame grids and baselines,
plus three new tutorial vine pieces. This copies each `standard/<name>.png`
over the game file of the same name (checking the size matches), so
hitboxes, frames and anchors (traps.json) are unchanged.

Each also gets an @2x twin from the pack's HD export (hd/<name>_hd.png:
4x for static props, scaled down to 2x here; 2x for animation sheets, used as
is), checked to be exactly twice the standard size. The game draws props and
traps through SpriteLib.tex, which uses the @2x twin at the 1x size, so they
stay sharp on high-DPI screens. The tutorial vine pieces aren't used yet.

Run it AFTER prepare_assets.py (whose props() and traps() write the old art):
    uv run --no-project --with pillow python tools/prepare_polished.py
then godot --headless --path . --import
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT.parent / "Assets" / "Rok_Polished_Assets" / "standard"
HD = PACK.parent / "hd"
OUT = ROOT / "assets"


def main() -> None:
    done, twins, skipped = 0, 0, []
    for f in sorted(PACK.glob("*.png")):
        target = next((OUT / sub / f.name for sub in ("props", "traps") if (OUT / sub / f.name).exists()), None)
        if target is None:
            skipped.append(f.name)
            continue
        new = Image.open(f).convert("RGBA")
        old_size = Image.open(target).size
        if new.size != old_size:
            print(f"SIZE MISMATCH {f.name}: pack {new.size} vs game {old_size} (kept the game's)")
            continue
        new.save(target, optimize=True)
        hd = HD / f"{f.stem}_hd.png"
        if hd.exists():
            big = Image.open(hd).convert("RGBA")
            want = (new.width * 2, new.height * 2)
            if big.size != want:
                big = big.resize(want, Image.LANCZOS)   # 4x props down to 2x
            big.save(target.with_name(f"{target.stem}@2x.png"), optimize=True)
            twins += 1
        done += 1
    print(f"{done} polished images written to assets/props and assets/traps ({twins} with @2x twins)")
    if skipped:
        print("not used yet (no game file of that name):", ", ".join(skipped))


if __name__ == "__main__":
    main()
