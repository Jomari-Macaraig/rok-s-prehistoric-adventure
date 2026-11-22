# Obstacles, traps and dino gates

What gets spawned in front of Rok: course patterns, obstacles and their zone
skins, traps (liquids, quicksand, steam, rolling boulders), dino gates,
floating islands and break effects.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/course.gd` (spawning), `scripts/obstacle.gd`, `scripts/platform.gd`, `terrain.gd` (liquids, quicksand, canyon and bridge gates), `main.break_sound` |
| When each appears | `config/progression.cfg` `[introductions]` (distances below are the current config) |
| Art | props `assets/props/`, traps and break animations `assets/traps/` (`SpriteLib.trap()` / `trap_sprite()`), islands `tools/prepare_islands.gd` |
| Reward spots | see [pickups-and-loot](pickups-and-loot.md) |

## How the course picks what's next

`Course._next_key()`:
1. **New hazard**: spawned alone for its first `INTRO_SOLO_SPAWNS` (3) appearances, with `INTRO_GAP_MULT` (×1.6) space. Emits `introduced` on the first spawn.
2. **Order**: lessons in distance order, but the current zone's own hazards (`ZONE_ONLY`) first; the first combo and first tough combo take their turn too.
3. **Otherwise**: a weighted pick among hazards already met (recent ones a little more often).

**Combos**: 2 familiar hazards spaced `_combo_spacing()` apart (enough to land and jump again). **Tough combos**: 2–3 hazards that can include walls and tall fences.

**Placement rules**
- Only where `terrain.flat_y()` reports flat ground from 340 px before to `_pattern_length()` after; otherwise retry 60 px later.
- A combo needs flat ground for its first two parts; a third is added only where the ground allows.
- Long patterns (`LONG_KEYS`: combos, ledges) keep their turn for up to `WANT_WAIT_MAX` (2400 px) instead of being re-rolled; a due lesson still goes first.
- Gap between patterns: a random travel time (`GAP_EARLY` → `GAP_LATE` as pressure rises) × speed.
- `skip_intros_before(m)` marks earlier hazards as met (tests starting part-way).

## Obstacles

| Pattern | Notes |
|---|---|
| Small rock / twig / mushroom (`small`) | trips, dizzies; a Power roll may break it ([health-and-damage](health-and-damage.md)) |
| Log (`wood`) | |
| Boulder (`rock`) | taught as "smash them" |
| Fence / tall fence (`fence`) | |
| Rock wall | 2–3 stacked tiles |
| Thorn bush | jumpable; brushing it is a stumble, not a crash; the Spinosaurus tramples it (6680 m) |
| Low ledge (`overhead`) | `LEDGE_CLEARANCE` (110 px) up, amber underneath, a one-way platform on top; spawned 220 px further out for run-up (840 m) |
| Combos, tough combos | see above |

**Obstacle node** (`obstacle.gd`): stacked Sprite2D parts. Hitbox = visual size × `shrink`. `setup_ledge()` builds the Volcanic ledge from 2–3 floating-island pieces; `setup_thorns()` builds thorn bushes and bramble walls.

**Floating islands** (`platform.gd`): one-way; `position.y` is the walkable top. `island_texture(zone)` uses the zone's island art (`Terrain-variation_03_<zone>.png`), falling back to the forest one. Only over simple single hazards (small, thorn bush, log, boulder, fence), never beside ledges, walls, gates or combos; island groups stay `PLATFORM_GROUP_GAP` (600 px) apart.

## Zone skins

`Course.small/log_/boulder/rock_wall/fence/thorn_bush` check `zone_at_x()`. Tints sit on the obstacle node, so rubble keeps them.

| | Forest | Desert | Volcanic |
|---|---|---|---|
| Rocks | as drawn, plus mushrooms | sandstone tint, no mushrooms | basalt tint |
| Wood (logs, fences) | as drawn | sun-bleached (`WOOD_TINT`) | charred |
| Boulders, walls | as drawn | desert barricade art (`_zone_rock`) | basalt chunks and walls |
| Thorn bushes | yes | dry tumble-thorns | none (a rock instead) |
| Low ledge | vine branch (snags) | fossil arch | floating rock |

Desert and Volcanic walls use `ZONE_WALL_PIECE_H` pieces so a wall of height h matches the Forest's.

## Traps

**Liquids** (`Terrain._build_liquid`: left bank, repeated centre, right bank, drawn in front of Rok)
- Forest water: the Spinosaurus gate there. Forms with `swims` float at `liquid_surface()` with the swim clip (`Player.set_swimming`); others fall in.
- Volcanic lava: the Pteranodon gate there.
- Deaths are recorded as "water" or "lava", with a splash.

**Quicksand** (Desert, from 1300 m, `QUICKSAND_*`)
- A soft flat that obstacles avoid. Standing on it fills `main.sink` (`SINK_RATE`; Raptor `SINK_RATE_FAST`, heavy dinos `SINK_RATE_HEAVY`) and lowers Rok. Off it, the meter drains (`SINK_RECOVER`). At 1 he's swallowed.
- **Deep quicksand** (once the Raptor is unlocked; `Terrain.runner_ready` marks it `deep`):
  - wider than Rok's longest bound (`Forms.air_time`) plus one gripped escape hop, × `QUICKSAND_DEEP`, at the current speed (never narrower than `QUICKSAND_MIN/MAX`);
  - landing on it adds `QUICKSAND_PLUNGE` (scaled by sink rate), and `Player.sand_grip` (`QUICKSAND_GRIP`) weakens jumps off it (no air jump);
  - the sink doesn't drain while airborne over the sand, so two landings swallow Rok;
  - the Raptor runs across, the Pteranodon flies over;
  - it gets an amber cache before it and a floating Raptor marker (meta `sand`: glows the Raptor button, doesn't count as a gate for badges).
- Before the Raptor it's capped at `QUICKSAND_SAFE` of Rok's bound, so it's always clearable.
- Every feature is followed by ≥ `FLAT_MIN` ground, so there's time to switch to a gate dino after the sand.

**Volcanic only** (`Progression.ZONE_ONLY`)
- Steam vents come in pairs; only blast frames (3–5) have a hitbox; a blast is a stumble (`STUMBLE_STEAM`).
- Rolling boulders move `ROLL_SPEED` faster than the ground and count as rock (jump, or smash as Triceratops).

**Other variations** (no transformation needed): sturdy `Logs_03/04` bridges over normal pits (30% of pits after 850 m), narrow pits, small boulders, short walls.

## Dino gates

Only one dinosaur gets through each (`Obstacle.gate_form`); a Spinosaurus shield doesn't help.

| Gate | Dinosaur | From | Build |
|---|---|---|---|
| Crumbling Bridge | Raptor | 1600 m | twigs over a gate-wide gap; collapses under any form without `light` (Raptor and Pteranodon are light). Desert: a sandstone bridge with a collapse animation |
| Boulder Wall | Triceratops | 2600 m | stacked past the top of the screen: log barricade (Forest), cracked sandstone (Desert), basalt (Volcanic) (`setup_anim_stack`) |
| Bramble Wall | Spinosaurus | 3600 m | wind-animated thorn bushes, full height |
| Flooded Crossing | Spinosaurus | 6000 m | Forest water |
| Wide Canyon | Pteranodon | 4600 m | `Terrain.gate_width()` = speed × 1.6 + 160 px, wider than any jump |
| Lava Channel | Pteranodon | 8000 m | Volcanic lava |

**Spacing**
- Gates come every `gate_spacing_min..max` (200–340 m) once a dino is unlocked and its gate's distance is reached.
- Each zone favours its **signature** gates (`Progression.ZONE_GATES`: Forest water and log barricade, Desert sandstone bridge and wall, Volcanic lava and basalt barricade), rotating within a visit; entering a zone brings one within `ZONE_SHOWCASE_M` (100 m).
- A never-seen gate variant (e.g. `gate_water`) also waits for `introduce_ok`. Names come from `Terrain.gate_variant()`.

**Every gate gets** a NEW banner on first meeting, a cache of 4 amber before it, and a floating marker with the needed dino's portrait (`Course.markers`; `Course.gate_x0(m)`). The matching button glows (see [hud-and-controls](hud-and-controls.md)).

**When a dino unlocks mid-run its gate comes next** (`Course.force_gate()`)
- Hazards spawned but still off-screen are removed; the gate is forced even before its normal distance; regular spawns hold (`holding`) until Rok is past.
- Wall gates spawn 720 px off-screen. Canyon and bridge gates are built by Terrain (`request_gate()` → `gate_built`), which trims the ground beyond `view + 720` px.
- Banners queue so the unlock and gate banners don't overwrite each other.

## Breaking

- `Course.shatter_obstacle()` removes collision; `Obstacle.shatter()` plays each part's break animation (`Obstacle.BREAKS` maps props to the stone, boulder, fence and log breaks; barricades play their own). Rubble scrolls on in `Course.debris`.
- Small rocks and meteors crumble with the boulder break at their own size (`BREAK_SCALE`); a meteor smashed mid-air drops its rubble while crumbling.
- Twigs and mushrooms have no break art (a puff).
- **Sounds** (`main.break_sound(o)`): `break_wood` for logs, fences, thorns, vines, crumbling bridges; `break_rock` for rocks, small rocks, meteors; mushrooms keep the squishy `smash`.
- A broken obstacle may drop loot ([pickups-and-loot](pickups-and-loot.md)).
