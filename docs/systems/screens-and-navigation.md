# Screens and navigation

How the full-screen places (Market, Field Guide, Camp) open and close, the
look they share, and the side buttons on the main menu.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/market_scene.gd` (`MarketScene`, shared scene drawing), `Market.enter` / `backdrop` / `title_banner`, `hud.gd` (side buttons) |
| Art | square buttons `assets/ui/square_<name>.png`, banners `assets/ui/banner_<name>.png` (`tools/prepare_menu_buttons.py`) |
| Flow | see [run-loop](run-loop.md) for states and the summary → main menu step |

## Navigation map

```
main menu (TITLE) ──tap──▶ run ──end──▶ summary card ──tap──▶ main menu
   │  ├─ Encyclopedia ──▶ Field Guide ──Back──┐
   │  ├─ Dinosaurs ─────▶ Camp ─────────Back──┤
   │  └─ Marketplace ───▶ Market ───────Back──┘──▶ main menu
pause ──▶ Encyclopedia (Field Guide) ──Back──▶ pause
```

## Full-screen places

The user wanted scenes, not modals.

- The Market, Field Guide and Camp each fill the whole screen (no frame or margin), with an opaque backdrop behind (`Market.backdrop(art, tint)`).
- Each puts a **Back** button first in its header (node `Back`) and fades in on opening (`Market.enter`).
- They're CanvasLayers over main rather than real scene changes, so the run, save state and main's references survive.
- **Shared look**: `MarketScene` has a `kind` ("market", "elder", "camp") and a `sign_text` for the roadside sign, so all three share the ground, sign and shelf looks. Your current hero stands at the left of each.
- **Titles**: the user's banners (labels baked in): ENCYCLOPEDIA in the Field Guide, DINOSAURS in the Camp; the Market uses the Marketplace UI pack's plaque.

| Place | Doc |
|---|---|
| Market | [marketplace](marketplace.md) |
| Field Guide | [field-guide](field-guide.md) |
| Camp | [camp](camp.md) |

## Side buttons

`Hud`, `SIDE_BUTTON_SIZE`.

- Shown on the main menu (and the Field Guide on the pause screen); hidden during a run and on the summary card.
- Field Guide (Encyclopedia) and Camp (Dinosaurs) on the left edge, Market (Marketplace) on the right, vertically centred above the thumb clusters.
- **Tutorial** (main menu only): a round button with Rok's portrait above the Marketplace (`TUTORIAL_BUTTON_SIZE`, `TUTORIAL_GAP`), its name drawn below (`TouchButton.caption_below`). It replays the training run (`main.replay_tutorial`, key U); see [tutorial](tutorial.md). It switches to the user's square art if `assets/ui/square_tutorial.png` is added.
- The user's square buttons (`TouchButton.set_banner`: tapped anywhere on the rectangle, name drawn below), or drawn round captioned buttons until imported.
- Red dots: new Field Guide entries or badges, gear to equip, something new or affordable in the Market.
- The title panel's help text wraps narrower so they fit beside it.
