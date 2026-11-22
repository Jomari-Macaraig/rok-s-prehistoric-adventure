# Zones, day/night, background and lap twists

The three zones, the day/night cycle, the parallax background and the weather
twist each lap.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/zones.gd`, `scripts/background.gd`, `scripts/weather.gd`, `main._update_environment` / `_lap_step` |
| Art | `assets/bg/` (`tools/prepare_assets.py`), ground strips in `assets/terrain/` |

## Zones

Each zone is `Zones.ZONE_LEN_M` long: **1500 m**, set by `config/progression.cfg` `[zones] length_m` (read in `Progression._load`). It was 1000 m until the user found the zones changed too fast. A lap is 3 zones (4500 m), then they repeat. If you change the length, move the zone-only lessons in `[introductions]` so each still falls inside one of its zone's visits, and update the hard-coded stops in `tests/zone_shots.gd`. The tests read the length from `Zones.ZONE_LEN_M`.

| Zone | From | Look | Course |
|---|---|---|---|
| Forest | 0 m | jungle layers, ferns, seamless forest ground | baseline |
| Desert | 1500 m | the user's mesa backdrop and dunes, sandstone ground | more hills, fewer pits |
| Volcanic Badlands | 3000 m | basalt, ash and lava (recoloured desert art until dedicated art exists) | more pits and drops |

- `Zones.weights()` cross-fades looks over `BLEND_M` (120 m) at each border.
- Entering a zone shows "ZONE: …" (with the lap number after the first lap). The first-ever visit pauses on an info card.
- The HUD shows e.g. "123 m · Desert".
- Each zone has its own hunter, wild dinosaurs, hazard skins, traps and music (see the other system docs).

## Day and night

- Its own cycle, `DAY_CYCLE_M` (3600 m): `daylight()` is day 0–42%, dusk to 52%, night to 90%, then dawn. `sunset()` warms the sky at dusk and dawn.
- First lap: Forest by day, Desert by day into sunset, Volcanic at night; later laps shift.
- Banners: "NIGHT FALLS" / "DAYBREAK".
- `lighting` (a CanvasModulate from `Zones.light()`) tints the world, not the HUD.

## Background

`Background.apply_environment(m)` fades one layer group per zone, sets the sky
gradient (`Zones.sky()`), and fades in stars and the moon at night.

Layers (`Layer` tiles a texture in 4 copies and scrolls at `factor × speed`), back to front:

| Layer | Factor | Notes |
|---|---|---|
| Sky gradient | – | per zone and time of day |
| bg-2 mountains | 0.08 | cropped to the art, overlapped 50 px (no gaps) |
| far jungle (smaller, darker bg-1) | 0.16 | base tucked 18 px below the grass line |
| dark forest-floor band | – | |
| bg-1 jungle | 0.28 | drawn at `GROUND_Y − 586`; higher would show the floor band under the trunks (floating trees) |
| wind-animated trees and bushes | 0.55 | hazy; `make_wind()` is shared with Terrain |
| bg-3 ferns | 1.35 | in front of the player |

bg-1 has fog baked in; the far jungle and floor band behind it make it read as depth.

Ambient particles: fireflies in the Forest at night, desert dust by day, volcanic embers.

## Lap twists

`weather.gd` (`main._lap_step`, `main.lap`; a CanvasLayer under the HUD).

- Every lap past the first (4500 m) brings a twist in turn (`Weather.twist_for_lap`): storm, fog, eclipse, repeat.
- Each lap pays `LAP_BONUS` more points (`main.points_mult`).
- A banner names it `LAP_BANNER_DELAY` s after the zone banner.

| Twist | Effect |
|---|---|
| Storm | zone weather particles: Forest rain, Desert sandstorm, Volcanic ash |
| Fog | a gradient closing in from the right (hazards show late) |
| Eclipse | lighting × `Weather.light_mult()` |
