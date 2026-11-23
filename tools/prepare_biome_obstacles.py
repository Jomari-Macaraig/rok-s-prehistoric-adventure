#!/usr/bin/env python3
"""The user's biome obstacles (../Assets/Rok_Biome_Obstacles, README there).

10 Desert and 8 Volcanic obstacles (the list the user asked for: skulls,
fossil spine, petrified log, ribs, vertebra column, raptor skull, bones,
sandstone shard, dry thorn shrub; lava ridge, charred log, obsidian spikes,
basalt column, ember rock, obsidian shards, pumice, ember bramble), each an
8-frame break sheet (4x2, 256 px cells at 1x, 512 at @2x; frame 0 is the
intact obstacle, 12 fps, plays once), plus 4 Forest break sheets for the
twig and mushrooms (which had none).

Copies every sheet to assets/traps/biome_<id>.png + @2x (SpriteLib.trap
draws the @2x twin) and writes assets/traps/biome.json in traps.json's
format (frame, anchor = the obstacle's base, bounds0 = frame 0's visible
box, duration_ms, loop, events), which SpriteLib.trap_meta merges in (kept
apart so prepare_assets.py, which rewrites traps.json, doesn't drop them).
Course stands each Desert/Volcanic obstacle as its sheet's frame 0 and plays
the rest when it's smashed (Obstacle.setup_anim); the Forest twig and
mushrooms play theirs (Obstacle.BREAKS).

    python3 tools/prepare_biome_obstacles.py
then godot --headless --path . --import
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT.parent / "Assets" / "Rok_Biome_Obstacles"
OUT = ROOT / "assets" / "traps"
MS = [70, 70, 80, 90, 90, 100, 110, 220]   # ~12 fps, holding the last remains a little


def main():
    meta = {}
    for rec in sorted(SRC.glob("*/*.json")):
        if rec.name in ("manifest.json",) or rec.parent == SRC:
            continue
        d = json.loads(rec.read_text())
        if "standard_sheet" not in d:
            continue
        name = "biome_" + d["id"]
        shutil.copyfile(rec.parent / d["standard_sheet"], OUT / f"{name}.png")
        shutil.copyfile(rec.parent / d["hd_sheet"], OUT / f"{name}@2x.png")
        b = d["standard_visible_bounds"][0]
        meta[name] = {"frame": d["standard_cell"], "anchor": d["origin"], "bounds0": b,
                      "duration_ms": MS, "loop": False, "biome": d["biome"].lower(),
                      "events": {"impact_frame": 2, "final_remains_frame": 7}}
    (OUT / "biome.json").write_text(json.dumps(meta, indent=1))
    print(len(meta), "biome break sheets:", ", ".join(sorted(meta)))


if __name__ == "__main__":
    main()
