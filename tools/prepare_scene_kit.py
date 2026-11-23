#!/usr/bin/env python3
"""The user's Encyclopedia and Dinosaurs (Camp) scene kit (../Assets/Rok_Scene_Polish_Assets).

The kit is drawn for a 1920x1080 screen; the game's is 1280x720 (2/3 of
it). Every piece is copied as its @2x twin (the kit's pixels; SpriteLib.tex
draws it at half size) plus a half-size 1x fallback, into assets/scenes/:
backgrounds (encyclopedia_archive, dinosaur_camp), characters (elder_numa,
rok_presenter, raptor_presenter), panels (open_book, stats_panel,
roster_panel), controls (tabs, buttons, cards, title_blank, counter_plate,
badges, lock, page arrows, stone_back), icons, meters and the two titles.
scene_kit.json holds the 9-slice margins of the stretchable pieces (from the
kit's nine_patch_presets.json, halved to 1x units) and the kit's layout
reference (1920x1080 areas and the book's page fractions).

    uv run --no-project --with pillow python tools/prepare_scene_kit.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Scene_Polish_Assets"
OUT = ROOT / "assets" / "scenes"

FOLDERS = ["backgrounds", "characters", "ui/panels", "ui/controls", "ui/icons", "ui/meters", "ui/titles"]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for folder in FOLDERS:
        for f in sorted((SRC / folder).glob("*.png")):
            img = Image.open(f)
            img = img.convert("RGBA") if img.mode != "RGB" else img
            img.save(OUT / f"{f.stem}@2x.png", optimize=True)
            img.resize((max(1, img.width // 2), max(1, img.height // 2)), Image.LANCZOS).save(OUT / f"{f.stem}.png", optimize=True)
            n += 1
    presets = json.loads((SRC / "godot" / "nine_patch_presets.json").read_text())
    boxes = {}
    for name, p in presets.items():
        boxes[Path(p["texture"]).stem] = {
            "texture": [round(v / 2) for v in p["texture_margins_ltrb"]],
            "content": [round(v / 2) for v in p["content_margins_ltrb"]],
        }
    meta = {"boxes": boxes, "layout": json.loads((SRC / "docs" / "layout_reference.json").read_text())}
    (OUT / "scene_kit.json").write_text(json.dumps(meta, indent=1))
    print(f"{n} pieces -> assets/scenes/ ; 9-slices: {sorted(boxes)}")


if __name__ == "__main__":
    main()
