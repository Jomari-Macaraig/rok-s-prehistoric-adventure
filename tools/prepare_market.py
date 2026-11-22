#!/usr/bin/env python3
"""Imports the user's cave marketplace pack (standard library only):
    python3 tools/prepare_market.py
    godot --headless --path . --import

Source: ../Assets/Rok_Cave_Marketplace (its README, animations.json and
scene_layout.json describe it). Copied to assets/market/:
- cave_marketplace.png (1536 x 1024, the cave room; outside is transparent)
- merchant_counter.png (1774 x 887, drawn in front of the merchant)
- merchant_<idle|buy|goodbye>.png (4 x 2 sheets of 384 x 512 frames, feet
  at 230, 488; idle loops at 5 fps, buy 8 fps and goodbye 7 fps play once)
- market.json: the frame size, foot anchor, clip speeds and the example
  layout (hero and merchant feet, counter bottom centre and width, all on
  the 1536 x 1024 cave canvas), read by MarketScene and Market.
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Cave_Marketplace"
OUT = ROOT / "assets" / "market"


def main():
    if not SRC.is_dir():
        raise SystemExit(f"{SRC} not found")
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ["cave_marketplace", "merchant_counter"]:
        shutil.copyfile(SRC / "assets" / f"{name}.png", OUT / f"{name}.png")
    anim = json.loads((SRC / "animations.json").read_text())
    layout = json.loads((SRC / "scene_layout.json").read_text())
    clips = {}
    for clip, c in anim["clips"].items():
        shutil.copyfile(SRC / c["sheet"], OUT / f"merchant_{clip}.png")
        clips[clip] = {"fps": c["fps"], "loop": c["loop"]}
    meta = {
        "frame": anim["frame_size"],
        "anchor": anim["foot_anchor_px"],
        "clips": clips,
        "cave_size": layout["example_canvas"],
        "hero_feet": layout["example_hero_feet"],
        "merchant_feet": layout["example_merchant_feet"],
        "character_height": layout["example_character_visible_height_px"],
        "counter_bottom_center": layout["example_counter_bottom_center"],
        "counter_width": layout["example_counter_display_width_px"],
    }
    (OUT / "market.json").write_text(json.dumps(meta, indent=1))
    print("cave, counter, %d merchant clips -> assets/market/" % len(clips))


if __name__ == "__main__":
    main()
