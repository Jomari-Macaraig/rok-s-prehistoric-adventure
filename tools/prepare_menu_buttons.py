#!/usr/bin/env python3
"""Imports the user's menu art (standard library only):
    python3 tools/prepare_menu_buttons.py
    godot --headless --path . --import

- Square buttons (icon only): ../Assets/Rok_Square_Buttons/png_256/
  button_<name>_square.png (256 x 256) -> assets/ui/square_<name>.png, the
  Encyclopedia, Marketplace and Dinosaurs side buttons on the title, pause
  and game-over screens (Hud; shown at Tuning.SIDE_BUTTON_SIZE, name below).
- Banners (label baked in): ../Assets/Rok_Menu_Buttons (Banner)/png_384/
  button_<name>.png (384 x 128) -> assets/ui/banner_<name>.png, the titles in
  the headers of the Field Guide (encyclopedia), the Market (marketplace)
  and the Camp (dinosaurs) (Market.title_banner).
<name> is encyclopedia, marketplace or dinosaurs.
"""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT.parent / "Assets"
OUT = ROOT / "assets" / "ui"
NAMES = ["encyclopedia", "marketplace", "dinosaurs", "missions"]   # missions: when the user supplies it (skipped while missing)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name in NAMES:
        sq = ASSETS / "Rok_Square_Buttons" / "png_256" / f"button_{name}_square.png"
        bn = ASSETS / "Rok_Menu_Buttons (Banner)" / "png_384" / f"button_{name}.png"
        for src, dst in [(sq, f"square_{name}.png"), (bn, f"banner_{name}.png")]:
            if src.exists():
                shutil.copyfile(src, OUT / dst)
                print(f"{src.parent.parent.name}/{src.name} -> assets/ui/{dst}")
            else:
                print(f"missing: {src}")


if __name__ == "__main__":
    main()
