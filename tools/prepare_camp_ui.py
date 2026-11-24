#!/usr/bin/env python3
"""The user's Camp path nodes and skill card frames ->
assets/ui/camp/<id>.png (+@2x).

Source: ../Assets/Rok_Camp_Path_and_Card_Frames (section 4 of the campaign
art list; manifest.json gives each canvas and its visible bounds).
- Level path nodes (path_dot_*, path_milestone_*, path_evolution_*, lit and
  unlit): all cropped to one shared box (the biggest drawing's bounds) so the
  dot < milestone < evolution sizes stay as drawn, then 96 px (@2x 192).
- Skill card frames (skill_card_learned / learnable / locked): each cropped
  to its own visible bounds and scaled to 300 px wide (@2x 600). The middle
  is transparent; the game draws the card, icon and text under it.

    uv run --no-project --with pillow python tools/prepare_camp_ui.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Camp_Path_and_Card_Frames"
OUT = ROOT / "assets" / "ui" / "camp"
PATH_SIZE = 96
CARD_W = 300


def save(img: Image.Image, name: str, w: int) -> None:
    h = round(img.height * w / img.width)
    img.resize((w * 2, h * 2), Image.LANCZOS).save(OUT / f"{name}@2x.png")
    img.resize((w, h), Image.LANCZOS).save(OUT / f"{name}.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    m = json.loads((SRC / "manifest.json").read_text())
    assets = {a["id"]: a for a in m["assets"]}
    paths = [a for a in assets.values() if a["id"].startswith("path_")]
    box = [min(a["content_bounds_alpha_128"][0] for a in paths), min(a["content_bounds_alpha_128"][1] for a in paths),
           max(a["content_bounds_alpha_128"][2] for a in paths), max(a["content_bounds_alpha_128"][3] for a in paths)]
    side = max(box[2] - box[0], box[3] - box[1])
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    sq = (round(cx - side / 2), round(cy - side / 2), round(cx + side / 2), round(cy + side / 2))
    for a in paths:
        img = Image.open(SRC / a["file"]).convert("RGBA").crop(sq)
        save(img, a["id"], PATH_SIZE)
    for a in assets.values():
        if a["id"].startswith("skill_card_"):
            img = Image.open(SRC / a["file"]).convert("RGBA").crop(tuple(a["content_bounds_alpha_128"]))
            save(img, a["id"], CARD_W)
    print("wrote", sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
