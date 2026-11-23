# Wild dinosaurs

The stampedes and swoopers that run at Rok in each zone, and what happens when
he dodges, bumps or bonks them.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/critters.gd` (`Critters.DATA`), `course.gd` (`_spawn_key`), `obstacle.gd` (`setup_critter`, `place_critter`), `main._bump` / `_eat_critters` / `_drop_card` |
| When they appear | `[introductions]` `stampede` (2250 m), `swooper` (2760 m) and `diver` (diving flyers, 4100 m); how often: `CRITTER_WEIGHT`, `DIVE_CHANCE` |
| Art | the species' own sheets (expansion dinosaurs), mirrored to face Rok |

## Species per zone

| Zone | Stampede (jump it) | Swooper (slide under it) |
|---|---|---|
| Forest | Pachycephalosaurus | Dimorphodon |
| Desert | Gallimimus | Pteranodon |
| Volcanic | Kentrosaurus | Quetzalcoatlus |

A swooper flies at head height; the Raptor fits under it standing.

## Diving flyers

The user asked for flyers that dive at Rok. A diver is a swooper of the zone's species with `Obstacle.make_diver()` applied. It is its own lesson (`diver` in `[introductions]`, `INTRO_TEXT`, a Field Guide hazard card).

- It comes in high (underside `DIVE_START_H` px up, out of reach) and `DIVE_SPEED_MULT` faster, with no bob.
- The dive follows its distance ahead of Rok, not time, so it lines up at any speed (`Obstacle.dive_progress`). It starts `DIVE_FROM_X` px ahead, where `main._eat_critters` plays a screech (`form_pteranodon`, pitched up) once. It bottoms out `DIVE_TO_X` px ahead at its species' normal `height` plus `DIVE_DIP`, so a slide gets under it. It tips nose-down mid-dive (`DIVE_TILT`).
- Answers: slide under it, or ATTACK it once it's low (`attack_target` only reaches things at Rok's height). Jumping into the dive gets you hit.
- Spawning (`Course._wants_dive`): once `diver` is due and may be introduced (`_diver_due`), its lesson's `INTRO_SOLO_SPAWNS` swoopers all dive, and `_next_key` sends swoopers until they're done. After that a swooper dives with `DIVE_CHANCE`. `skip_intros_before` counts its lesson as done too.
- All `DIVE_*` numbers are in `tuning.gd`.

**Attributes** (per species): `speed` (closes in on top of the scroll), `scale`,
`bump` (gap the hunter gains if Rok runs into it), `snack` (gap won back when
the hunter eats it), and for flyers `height` and `bob`.

## Spawning

- Pattern keys `stampede` / `swooper`; `Course._spawn_key` picks the zone's species (`Critters.for_zone`).
- `Obstacle.setup_critter`: its run or fly loop, mirrored, moving at `roll_speed`; hitbox `custom_box` measured from the art (`Critters.art_bounds`). `place_critter` lifts swoopers; `make_diver` turns one into a diving flyer. A running one follows the ground under it every frame (`Obstacle.follow_ground`, from `Course.scroll`): it stands on slopes and steps instead of keeping its spawn height, and hops over a pit or liquid (`CRITTER_HOP_V`) instead of running in it (the user's report, 2026-11-23).

## What can happen

| Rok… | Result |
|---|---|
| runs into it | `main._bump`: a stumble of its own strength, the trip reaction, costs hearts; `Obstacle.bumped` so it hits only once |
| bonks it with ATTACK (or a frenzy) | points, a combo feat, maybe its dinosaur card (see [weapons-and-armor](weapons-and-armor.md)) |
| dodges it | the hunter eats it when it reaches the snout (`_eat_critters`, `Trex.eat()`): "CHOMP!", the gap grows by `snack`, counts for the Bait badge |

## Early preview

Until the Stampede lesson is taught, every run gets one slow wild dinosaur from the zone at `[early] stampede_preview_m` (720 m, just before the Raptor). `main._preview_step` calls `Course.wild_preview`, which spawns it on flat ground at `stampede_preview_speed` × its speed with meta `preview`, keeps the next pattern clear, and shows a "WILD DINOSAUR!" banner. It's a banner, not a card, so it doesn't hold lessons back (no `last_new_m`). Jumping it and watching the hunter eat it is the payoff. If no flat ground comes within 200 m, it's skipped for that run.

## Teaching

- The lesson's info card covers the first species.
- Any other species met for the first time gets a NEW banner (`seen` "critter_<id>").
