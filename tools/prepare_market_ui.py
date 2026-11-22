#!/usr/bin/env python3
"""The user's Marketplace UI pack (../Assets/Rok_Marketplace_UI) -> assets/market/ui/.

Each piece is saved under the name the Market looks for (Market._ui_box /
_ui_tex): the pack's half-size PNG as <name>.png (the size it's drawn at on
the 1280x720 screen) and its full-size PNG as <name>@2x.png (SpriteLib.tex
draws that at the half size, so it stays sharp on phones). ui.json holds each
9-slice piece's texture and content margins in those half-size units, read
from the pack's own half-size Godot styles (godot/styles_half/*.tres).

The Dino Card Pack icon also goes to assets/gear/card_pack.png (Gear.icon).

Standard library only:
    python3 tools/prepare_market_ui.py
then godot --headless --path . --import
"""
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT.parent / "Assets" / "Rok_Marketplace_UI"
OUT = ROOT / "assets" / "market" / "ui"

# pack name -> game name (the Market's hook names)
NAMES = {
    "shop_panel": "panel_frame",
    "details_strip": "detail_strip",
    "meat_counter_frame": "meat_counter",
    "tab_active": "tab_on",
    "tab_inactive": "tab_off",
    "item_card_normal": "card",
    "item_card_selected": "card_selected",
    "item_card_locked": "card_locked",
    "price_pill": "price_pill",
    "price_pill_insufficient": "price_pill_short",
    "button_buy_normal": "buy_button",
    "button_buy_pressed": "buy_button_pressed",
    "button_buy_disabled": "buy_button_disabled",
    "button_back": "back_button",
    "title_marketplace": "title",
    "badge_check": "check",
    "icon_padlock": "padlock",
    "icon_dino_card_pack": "card_pack",
    "icon_heart_container_full": "heart_full",
    "icon_heart_container_empty": "heart_empty",
}


def style_margins(pack_name: str):
    """(texture margins, content margins) as [l, t, r, b] from the half style."""
    p = PACK / "godot" / "styles_half" / f"{pack_name}.tres"
    if not p.exists():
        return None
    text = p.read_text()

    def side(kind: str) -> list:
        out = []
        for s in ("left", "top", "right", "bottom"):
            m = re.search(rf"^{kind}_margin_{s} = ([\d.]+)", text, re.M)
            out.append(float(m.group(1)) if m else 0.0)
        return out

    return side("texture"), side("content")


def main() -> None:
    meta = json.loads((PACK / "assets.json").read_text())["assets"]
    OUT.mkdir(parents=True, exist_ok=True)
    ui = {}
    for pack_name, name in NAMES.items():
        a = meta[pack_name]
        shutil.copyfile(PACK / a["half_file"], OUT / f"{name}.png")
        shutil.copyfile(PACK / a["file"], OUT / f"{name}@2x.png")
        m = style_margins(pack_name)
        if m:
            ui[name] = {"margin": m[0], "content": m[1]}
            # crop the transparent padding around the art (the tab pills leave
            # 19 px each side, the BUY pill ~22% above and below), so the
            # visible shape fills its control; margins shrink by the crop
            b = a.get("alpha_bounds")
            if b:
                hw, hh = a["size"][0] / 2, a["size"][1] / 2
                l, t, r, btm = b[0] / 2, b[1] / 2, b[2] / 2, b[3] / 2
                crop = [l, t, hw - r, hh - btm]
                ui[name]["region"] = [l, t, r - l, btm - t]
                mg = [max(2.0, m[0][i] - crop[i]) for i in range(4)]
                if name.startswith(("tab_", "price_pill", "buy_button")):   # pills: keep the rounded ends whole
                    cap = (btm - t) * 0.45
                    mg[0], mg[2] = max(mg[0], cap), max(mg[2], cap)
                ui[name]["margin"] = mg
        print(f"{pack_name:28s} -> market/ui/{name}.png (+@2x)")
    (OUT / "ui.json").write_text(json.dumps(ui, indent=1))
    gear = ROOT / "assets" / "gear"
    gear.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(OUT / "card_pack.png", gear / "card_pack.png")
    shutil.copyfile(OUT / "card_pack@2x.png", gear / "card_pack@2x.png")
    print("card pack icon -> gear/card_pack.png (+@2x)")


if __name__ == "__main__":
    main()
