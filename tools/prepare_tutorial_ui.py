#!/usr/bin/env python3
"""The user's tutorial UI kit (../Assets/Rok_Tutorial_UI_Kit) for the training run.

Each piece is trimmed to its art (alpha > 16) and saved at the size it's
drawn at 1280x720 (`HEIGHT`, 1x) plus an @2x twin (SpriteLib.tex prefers it),
into assets/ui/tutorial/:
  card.png     the ivory instruction card (CoachMarker cards; stretched only
               in its straight middle, see `margins` in tutorial_ui.json)
  plaque.png   the wood-and-bone "Tutorial" plaque
  pill.png     the brown pill (Skip, and the notes' Back / Next)
  hand.png     the tap pointer (fingertip at the top left)
  ring.png     the focus ring behind the target
  marks.png    the orange attention marks off the card's corner
  chevrons.png the Skip chevrons
The kit's two variable fonts go to assets/fonts/ with their licences (Baloo 2
for headings, Nunito Sans for text; Hud.tutorial_fonts picks the weights).
tutorial_ui.json holds each piece's 1x size and the card's 9-slice margins.
The kit's HUD pieces (hearts, pause, counter, PRIMAL bar), slot frames and
action buttons aren't imported (the game keeps its own).

    uv run --no-project --with pillow python tools/prepare_tutorial_ui.py
then godot --headless --path . --import
"""
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Tutorial_UI_Kit"
OUT = ROOT / "assets" / "ui" / "tutorial"
FONTS = ROOT / "assets" / "fonts"

# name -> (source, height at 1x)
PIECES = {
    "card": ("ui/panels/tutorial_panel.png", 150),
    "plaque": ("ui/panels/tutorial_plaque.png", 54),
    "pill": ("ui/buttons/pill_button.png", 44),
    "hand": ("ui/effects/tap_hand.png", 92),
    "ring": ("ui/effects/focus_ring.png", 128),
    "marks": ("ui/effects/accent_burst.png", 40),
    "chevrons": ("ui/icons/skip_chevrons.png", 20),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for name, (src, h1) in PIECES.items():
        img = Image.open(SRC / src).convert("RGBA")
        img = img.crop(img.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox())
        w1 = round(img.width * h1 / img.height)
        img.resize((w1, h1), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)
        img.resize((w1 * 2, h1 * 2), Image.LANCZOS).save(OUT / f"{name}@2x.png", optimize=True)
        meta[name] = {"size": [w1, h1]}
        print(f"{name:9s} {w1}x{h1} (+@2x)")
    # the card and pills stretch only in their straight middle: the rounded
    # ends (about half the height each side) and a band top and bottom stay
    for name in ("card", "pill", "plaque"):
        w, h = meta[name]["size"]
        meta[name]["margins"] = [round(h * 0.5), round(h * 0.3), round(h * 0.5), round(h * 0.3)]   # left, top, right, bottom
    (OUT / "tutorial_ui.json").write_text(json.dumps(meta, indent=1))
    FONTS.mkdir(parents=True, exist_ok=True)
    for f in ("Baloo2-Variable.ttf", "Baloo2-OFL.txt", "NunitoSans-Variable.ttf", "NunitoSans-OFL.txt"):
        shutil.copy2(SRC / "fonts" / f, FONTS / f)
    print("fonts -> assets/fonts/")


if __name__ == "__main__":
    main()
