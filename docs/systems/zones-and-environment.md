# Zones, day/night, background and lap twists

The three zones, the day/night cycle, the parallax background and the weather
twist each lap.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/zones.gd`, `scripts/background.gd`, `scripts/weather.gd`, `main._update_environment` / `_lap_step` |
| Art | `assets/bg/` (`tools/prepare_assets.py`; the Canyon's from `tools/prepare_canyon.py`), ground strips in `assets/terrain/`, Canyon props in `assets/canyon/` |

## Zones

Each zone is `Zones.ZONE_LEN_M` long: **1500 m**, set by `config/progression.cfg` `[zones] length_m` (read in `Progression._load`). It was 1000 m until the user found the zones changed too fast. A lap is 4 zones (6000 m), then they repeat. If you change the length or add a zone, move the zone-only lessons in `[introductions]` so each still falls inside one of its zone's visits (adding the Canyon moved Steam to 4650, Rolling Boulders to 5250, the Lava Crossing to 5850 and the Flooded Crossing to 6150 m), and update the hard-coded stops in `tests/zone_shots.gd`. The code takes any number of zones (`Zones.weights` and the lookups below). The tests read the length from `Zones.ZONE_LEN_M`.

| Zone | From | Look | Course |
|---|---|---|---|
| Forest | 0 m | jungle layers, ferns, seamless forest ground | baseline |
| Desert | 1500 m | the user's mesa backdrop and dunes, sandstone ground | more hills, fewer pits |
| Canyon | 3000 m | the user's canyon pack: far mesas (painted sky keyed out), mid mesas, near hoodoos, red sandstone strata ground with cliff edges at gaps, dry shrubs, stones and fossil outcrops; rope bridges | more pits, rolling hills |
| Volcanic Badlands | 4500 m | basalt, ash and lava (recoloured desert art until dedicated art exists) | more pits and drops |

- `Zones.weights()` cross-fades looks over `BLEND_M` (120 m) at each border.
- Entering a zone shows "ZONE: …" (with the lap number after the first lap). The first-ever visit pauses on an info card.
- The HUD shows e.g. "123 m · Desert".
- Each zone has its own hunter, wild dinosaurs, hazard skins, traps and music (see the other system docs). A zone with no content of its own borrows its **kin**'s (`Zones.kin`, the zone's `kin` field): the Canyon's kin is the Desert, so it has the Desert's hunter (Carnotaurus), wild dinosaurs, music, sandstorm, material spots fallback and dino-gate art until it gets its own.
- The HUD's distance line starts with a time-of-day icon (the user's `Rok_Day_Night_Badges`: the sun by day, the moon at night, the half-and-half face at dusk and dawn; `Hud.set_daylight`).

## Day and night

- Its own cycle, `DAY_CYCLE_M` (3600 m): `daylight()` is day 0–42%, dusk to 52%, night to 90%, then dawn. `sunset()` warms the sky at dusk and dawn.
- First lap: Forest by day, Desert by day into sunset and night, Canyon from night into the next day, Volcanic by day; later laps shift.
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

**Canyon group** (`prepare_canyon.py`): `canyon_far` (×0.12, its painted sky keyed out so the game's sky and stars show), `canyon_mid` (×0.16) and `canyon_near` (×0.28), each 1536×720 with its bottom near the ground line. The pack is made for **mirrored** repeat, so these layers flip every other copy (`Layer.mirror`; the scroll wraps every two tiles).

Ambient particles: fireflies in the Forest at night, desert and canyon dust by day, volcanic embers.

## Lap twists

`weather.gd` (`main._lap_step`, `main.lap`; a CanvasLayer under the HUD).

- Every lap past the first (4500 m) brings a twist in turn (`Weather.twist_for_lap`): storm, fog, eclipse, repeat.
- Each lap pays `LAP_BONUS` more points (`main.points_mult`).
- A banner names it `LAP_BANNER_DELAY` s after the zone banner.

| Twist | Effect |
|---|---|
| Storm | zone weather particles: Forest rain, Desert and Canyon sandstorm, Volcanic ash |
| Fog | a gradient closing in from the right (hazards show late) |
| Eclipse | lighting × `Weather.light_mult()` |
