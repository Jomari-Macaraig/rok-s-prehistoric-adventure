#!/usr/bin/env python3
"""The user's loading screen kit (../Assets/Rok_Loading_Screen_Kit) for the
Preloader (scripts/preloader.gd).

Copies into assets/loading/: the clean jungle background (1920x1080), the ROK
logo (downscaled to 1.5x its layout size), the wooden track and gold fill,
the footprint marker, dust puff, contact shadow, transformation ribbon and
leaf motes, and the kit's layout.json as loading.json (positions on its
1920x1080 design canvas). The kit's own run sheets, poses, label and tip PNGs
aren't copied: the screen uses the game's run animations for Rok, the Raptor
and the Triceratops (as the kit suggests), "LOADING..." comes from the label
art, and the tip is live text (config/hints.cfg).

    uv run --no-project --with pillow python tools/prepare_loading.py
then godot --headless --path . --import
"""
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
KIT = ROOT.parent / "Assets" / "Rok_Loading_Screen_Kit"
OUT = ROOT / "assets" / "loading"
COPY = {
    "backgrounds/jungle_loading_1920x1080.png": "background.png",
    "ui/bar_track.png": "bar_track.png",
    "ui/bar_fill.png": "bar_fill.png",
    "ui/loading_label.png": "loading_label.png",
    "fx/footprint_marker.png": "footprint_marker.png",
    "fx/dust_puff.png": "dust_puff.png",
    "fx/contact_shadow.png": "contact_shadow.png",
    "fx/transformation_ribbon.png": "transformation_ribbon.png",
    "fx/leaf_motes.png": "leaf_motes.png",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for src, dst in COPY.items():
        shutil.copyfile(KIT / src, OUT / dst)
    layout = json.loads((KIT / "layout.json").read_text())
    logo = Image.open(KIT / "ui" / "rok_logo.png").convert("RGBA")
    w = round(layout["logo"]["width"] * 1.5)
    logo.resize((w, round(logo.height * w / logo.width)), Image.LANCZOS).save(OUT / "logo.png", optimize=True)
    layout.pop("original_sheets", None)
    (OUT / "loading.json").write_text(json.dumps(layout, indent=1))
    print("loading screen kit written to", OUT)


if __name__ == "__main__":
    main()
