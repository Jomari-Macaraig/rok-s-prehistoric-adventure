#!/usr/bin/env python3
"""Elder Numa's animations (../Assets/Rok_Elder_Nuna_Animations; the pack calls
her Nuna). animation.json lists, per clip (idle loop, explain and wave
one-shots), eight frames picked from three 4x2 sheets of 384x512 cells, each
with its own duration and a baseline fix (crop N transparent rows off the top
and pad N at the bottom, i.e. move the drawing up N px, so every frame's feet
line up). This builds one aligned 4x2 sheet per clip:
assets/scenes/elder/<clip>@2x.png (the pack's pixels) and a half-size
<clip>.png, plus elder.json (1x frame size, the feet pivot (bottom centre,
the pack's offset 192,486 halved), each clip's frame times in ms and loop
flag, and the drawing's visible box in frame 0 for fitting).

    uv run --no-project --with pillow python tools/prepare_elder.py
then godot --headless --path . --import
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT.parent / "Assets" / "Rok_Elder_Nuna_Animations"
OUT = ROOT / "assets" / "scenes" / "elder"
FW, FH = 384, 512
PIVOT = (192, 486)


def main() -> None:
    meta = json.loads((PACK / "animation.json").read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = {}
    out = {"frame": [FW // 2, FH // 2], "pivot": [PIVOT[0] / 2, PIVOT[1] / 2], "clips": {}}
    for clip, c in meta["animations"].items():
        sheet = Image.new("RGBA", (FW * 4, FH * 2), (0, 0, 0, 0))
        times = []
        for i, f in enumerate(c["frames"]):
            src = sheets.setdefault(f["sheet"], Image.open(PACK / f["sheet"]).convert("RGBA"))
            k = f["index"]
            cell = src.crop(((k % 4) * FW, (k // 4) * FH, (k % 4 + 1) * FW, (k // 4 + 1) * FH))
            up = int(f.get("crop_top_transparent_pixels", 0))
            if up:
                cell = cell.crop((0, up, FW, FH))   # the drawing moves up; the bottom stays transparent
            sheet.paste(cell, ((i % 4) * FW, (i // 4) * FH))
            times.append(round(float(f["duration_seconds"]) * 1000))
        sheet.save(OUT / f"{clip}@2x.png", optimize=True)
        sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(OUT / f"{clip}.png", optimize=True)
        out["clips"][clip] = {"times": times, "loop": bool(c["loop"])}
        if clip == "idle":
            box = sheet.crop((0, 0, FW, FH)).getchannel("A").point(lambda a: 255 if a > 128 else 0).getbbox()
            out["visible"] = [v / 2 for v in box]
        print(f"{clip:8s} {len(times)} frames, {sum(times)} ms, loop={c['loop']}")
    (OUT / "elder.json").write_text(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
