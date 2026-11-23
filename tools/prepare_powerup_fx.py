#!/usr/bin/env python3
"""The user's power-up effects (../Assets/Rok_Powerup_FX_Preview/Rok_Powerup_FX).

Four generic overlays (manifest.json: 4x2 atlases, 512x512 frames, origin at
the centre): pickup (once, 12 fps), activation (once, 16 fps), aura (loop,
12 fps) and expire (once, 12 fps). Each atlas is copied as
assets/fx/powerup_<name>@2x.png (the kit's pixels) plus a half-size 1x, and
assets/fx/powerup_fx.json holds the 1x frame and origin, each animation's
fps and loop flag, and `ring`: the aura ring's diameter at 1x (its alpha
bounds on frame 0), which the game sizes to the character.

    uv run --no-project --with pillow python tools/prepare_powerup_fx.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Powerup_FX_Preview" / "Rok_Powerup_FX"
OUT = ROOT / "assets" / "fx"


def main() -> None:
    man = json.loads((SRC / "manifest.json").read_text())
    fw, fh = man["frame_size"]
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {"frame": [fw // 2, fh // 2], "origin": [man["origin"][0] / 2.0, man["origin"][1] / 2.0], "anims": {}}
    for name, a in man["animations"].items():
        sheet = Image.open(SRC / a["atlas"]).convert("RGBA")
        sheet.save(OUT / f"powerup_{name}@2x.png", optimize=True)
        sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(OUT / f"powerup_{name}.png", optimize=True)
        meta["anims"][name] = {"frames": a["frame_count"], "fps": a["fps"], "loop": a["loop"]}
        if name == "aura":
            l, t, r, b = sheet.crop((0, 0, fw, fh)).getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
            meta["ring"] = round(max(r - l, b - t) / 2.0, 1)
    (OUT / "powerup_fx.json").write_text(json.dumps(meta, indent=1))
    print("powerup_fx:", meta)


if __name__ == "__main__":
    main()
