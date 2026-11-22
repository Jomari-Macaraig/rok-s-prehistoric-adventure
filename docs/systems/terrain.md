# Terrain

The scrolling ground: flats, hills, drops and pits, the dirt fill, and the
height queries physics uses.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/terrain.gd` |
| Art and data | `assets/terrain/*.png` + `terrain.json` (`tools/prepare_terrain.py`, the user's seamless pack) |
| When features appear | `config/progression.cfg` `[introductions]` (pits, hills, big hills, drops…) |
| Zone look | each zone's `ground` style in `zones.gd` (see [zones-and-environment](zones-and-environment.md)) |

## How the ground is built

- Two lists in local coordinates (the node scrolls left):
  - `segs`: physics segments (`x0, x1, y0, y1, pit`; y is the feet line);
  - `features`: what was generated: flat, slope_up, slope_down, drop or pit.
- A feature's sprites are built only once the next feature exists, so a flat knows whether it needs an end cap beside a pit.
- Ground is generated at least `LOOK_AHEAD` (1400 px) past the screen edge, so combos spawned just off-screen find flat ground.
- Each feature takes the zone of the spot where it's generated (`Terrain.gen_zone()`), so new ground appears ahead before you reach it.

**Drawing styles**
- **Strips** (all three zones now): `_build_strip()` wraps the zone's tall ground texture over the surface in 16 px quads and outlines pit edges. The Forest uses the seamless `forest_ground` strip (`Zones` forest `ground: "forest"`).
- **Tiles** (`"tiles"`, kept but unused): rows of grass-top blocks (tiles 02/03) with rounded caps (01/04) beside pits, slope pieces (Terrain-variation_01/02) and the curved step tile (10) for drops.
- The seamless dirt fills down to the screen bottom: a `Polygon2D` with world-mapped UVs (continuous across features), moved to the front of the child list so it draws behind the tiles (a negative `z_index` would put it behind the background).
- Pit walls get a dark `Line2D` continuing the outline; grass tufts are moved in front of the tiles.

## Levels and slopes

- One level is the slope's rise from `terrain.json`: **53 px** with the seamless pack (it was 47 with the old tiles). Base feet line 560.
- Physics on slopes and steps follows each piece's measured grass profile, ends pinned to the level lines and kept monotonic.
- Rok runs down slopes and falls off the steep part of a drop.

## Features

| Feature | Rules |
|---|---|
| Flat | the default; obstacles need long flat ground |
| Hill | slope up, 1–3 blocks (`HILL_TOP_TILES_*`), slope down; sometimes twice in a row |
| Large hill | taught at 5680 m, ground level only (`LARGE_HILL_CHANCE`): climbs `LARGE_HILL_STEPS` (3) levels with short ledges, a plateau, then one long descent built for sliding. The only feature above level 2. No obstacles on it. |
| Drop | a step down one level |
| Pit | widens with pressure; the first emits `introduced("pit")` |

- Which features can appear is gated by `Progression` and `metres`.
- A terrain lesson that's due (pit, quicksand, big hill) is built at the first chance instead of waiting on a random roll (`due` in `_generate`), so it lands on schedule.
- Each zone scales pit, hill, large-hill and drop chances.

## Queries (world x)

| Function | Returns |
|---|---|
| `height_at(x)` | feet-line height, or `PIT` inside a pit |
| `flat_y(x0, x1)` | the height if the range is one flat solid run, else −1 |
| `next_pit(x)` | the next pit ahead |
| `slope_at(x)` | the slope (climbing < 0) |
