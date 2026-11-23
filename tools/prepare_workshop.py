#!/usr/bin/env python3
"""The user's Crafting and Items kit (../Assets/Rok_Crafting_Items_Kit/
Rok_Crafting_Items_Asset_Pack): Kora the Craftkeeper's workshop for the
Crafting Bench and Items screens (scripts/workshop.gd).

Copies into assets/workshop/:
- the jungle workshop background (1672x941) and the props: tool rack,
  firepit base, the workbench's rear and front layers (Kora stands between
  them) and the open storage chest;
- Kora's four registered animation sheets (idle loop, craft, present, wave)
  and the effect sheets (campfire flame loop, craft-success sparkle): 4x2
  grids of 384x512 cells, used as they are;
- the UI pieces at the kit's runtime size (made for its 1536x864 layout):
  parchment and inventory panels, the title sign, rarity card frames
  (common .. legendary + selected), the teal/brown tabs, the green CRAFT and
  amber SALVAGE buttons, the back button, check/lock badges, the durability
  track and fill;
- glyphs: craft, salvage, the stat icons (power, reach, durability) and the
  stone mallet;
and writes workshop.json: each animation's frame times, loop flag, root
(feet) and Kora's craft impact frame, the 9-slice margins of the panels and
card frames, and the kit's layouts (positions on the 1536x864 canvas).
The kit's equipment, material icons and cards aren't copied: the game's own
are used (they come from the same art).

    uv run --no-project --with pillow python tools/prepare_workshop.py
then godot --headless --path . --import
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KIT = ROOT.parent / "Assets" / "Rok_Crafting_Items_Kit" / "Rok_Crafting_Items_Asset_Pack"
OUT = ROOT / "assets" / "workshop"
UI = ["panel_parchment", "panel_inventory", "title_sign", "nameplate", "tab_brown", "tab_teal",
      "card_common", "card_uncommon", "card_rare", "card_epic", "card_legendary", "card_selected",
      "button_craft_green", "button_salvage_amber", "button_back", "badge_check", "badge_lock",
      "durability_track", "durability_fill"]
FILES = {
    "environment/workshop_background.png": "background.png",
    "props/tool_rack.png": "tool_rack.png",
    "props/firepit_base.png": "firepit_base.png",
    "props/workbench_rear.png": "workbench_rear.png",
    "props/workbench_front.png": "workbench_front.png",
    "props/storage_chest_open.png": "storage_chest_open.png",
    "effects/campfire_flame.png": "fire_loop.png",
    "effects/craft_success.png": "craft_success.png",
    "icons/equipment/icon_craft.png": "icon_craft.png",
    "icons/equipment/icon_salvage.png": "icon_salvage.png",
    "icons/equipment/stone_mallet.png": "stone_mallet.png",
    "icons/materials/stat_power.png": "stat_power.png",
    "icons/materials/stat_reach.png": "stat_reach.png",
    "icons/materials/stat_durability.png": "stat_durability.png",
}
NINE = {"panel_parchment": 36, "panel_inventory": 36, "card_common": 21, "card_uncommon": 21, "card_rare": 21,
        "card_epic": 21, "card_legendary": 21, "card_selected": 21}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for src, dst in FILES.items():
        shutil.copyfile(KIT / src, OUT / dst)
    for name in UI:
        shutil.copyfile(KIT / "ui" / "runtime" / f"{name}.png", OUT / f"{name}.png")
    man = json.loads((KIT / "asset_manifest.json").read_text())
    anims = {}
    for clip, a in man["animations"].items():
        src = KIT / a["sheet"]
        dst = f"{clip}.png" if clip.startswith(("fire", "craft_success")) else f"kora_{clip}.png"
        if clip in ("fire_loop", "craft_success"):
            dst = f"{clip}.png"
        else:
            shutil.copyfile(src, OUT / dst)
        anims[clip] = {"sheet": dst, "frame": a["frame_size"], "loop": a["loop"],
                       "times": [round(s * 1000) for s in a["frame_seconds"]],
                       "root": a.get("root"), "impact": a.get("impact_frame_index")}
    layouts = {}
    for f in sorted((KIT / "godot" / "demo" / "layouts").glob("*.json")):
        layouts[f.stem] = json.loads(f.read_text())["commands"]
    meta = {"canvas": [1536, 864], "animations": anims, "nine": NINE,
            "kora_offset": [-206, -499], "success_at": [31, -140], "success_offset": [-192, -270],
            "fire_base_at": [0, -163.5], "fire_at": [0, -165], "fire_offset": [-192, -397],
            "layouts": layouts}
    (OUT / "workshop.json").write_text(json.dumps(meta, indent=1))
    print("workshop kit written to", OUT)


if __name__ == "__main__":
    main()
