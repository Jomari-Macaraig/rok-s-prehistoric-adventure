# Progression and teaching

The curriculum: when each hazard, dinosaur, zone and booster slot first
appears, how new things are taught, and the rules that space them out.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/progression.gd`, `main._on_introduced` / `queue_info` / `_can_introduce` / `_first_sight_step` |
| Config | `config/progression.cfg`: the whole schedule is in its header; `[dinos]`, `[introductions]`, `[pacing]`, `[boosters]`, `[trex]` |
| Check changes | `tests/timeline_probe.gd` (see [tests/CLAUDE.md](../../tests/CLAUDE.md)) |
| Units | metres (`PX_PER_M` = 40 px) |

## The schedule

- Dinosaur buttons unlock by best distance (`UNLOCKS`): Raptor 800 (the user wanted the first dinosaur early; it was 1600), Triceratops 2600, Spinosaurus 3600, Pteranodon 4600 m. No amber appears before the first dinosaur (`pickup.amber = ["dino"]` in `config/requirements.cfg`). The Gallimimus, the first Runner Starter, goes on sale at 900 m.
- Anything can also need something else first (e.g. amber needs a dinosaur): the [dependency tree](requirements.md).
- New hazards and terrain arrive every 130–250 m, each zone with its own lessons, up to ~9400 m.
- `ZONE_LESSONS`: lessons that only happen in one zone (quicksand, steam vents, rolling boulders). Their distances have to fall inside one of their zone's visits, which depend on `[zones] length_m` (1500 m: Desert 1500–2999, Volcanic 3000–4499, then every 4500 m). When the zones went from 1000 to 1500 m: quicksand 1300→1750, steam 2300→3150, rolling boulders 5150→4250, Flooded Crossing 6000→5000 (a Forest visit); stampedes 2720→2250 and swoopers 2900→2760 so they aren't held behind the first Volcanic visit; boulders 3480→3340.
- **The four dinosaur buttons** come early and evenly (the user's call, 2026-11-23): Raptor 450, Triceratops 1000, Spinosaurus 1600, Pteranodon 2200 m, each with its dino trap right after. To fit, the early lessons moved up: rocks from 0 m, logs 160, hills 240, Low Ledges (SLIDE) 300 (so slide is still known before the Raptor), the Raptor at 450, the pepper 600, a slow wild-dinosaur preview 720 and a starter chest 870. Boulders moved to 1900 (after Quicksand, clear of the Pteranodon), and Stampedes to 2340 and hazard combos to 2480 (after it). Low Ledges must sit between `log + marinate_m` and `raptor − big_clearance_m`. The chest and preview are set in `[early]` and add no lesson card. The Desert's first visit (1500) and the Spinosaurus (1600) are 100 m apart.
- **Lesson slip between the Triceratops and the Pteranodon (fixed).** Lessons there used to arrive 500–1500 m late. There were three causes:
  1. Spawner starvation: a due lesson that needs a long flat (the first combo in the hilly Desert) kept its turn and nothing spawned for hundreds of metres. Now a pattern with no room for `WANT_WAIT_MAX` px is skipped for `Course.NO_ROOM_SKIP_M` (`_no_room`).
  2. The Forest a lap later counted as a first visit (runs start there without marking it seen), which showed a NEW ZONE card and reset marination at 4500 m. `start_run` now marks the first zone seen.
  3. Crowding: each big moment blocks lessons ~100 m before and `MARINATE_M` after, so the lessons were moved into the free windows (2730–2900, 3130–3500, 3890–4500): boulders 2050 (before the Triceratops), swoopers 2740, rolling boulders 3900, diving flyers 4100.
  With `timeline_probe` all of them now arrive before the Pteranodon. Swoopers still miss the short 2730–2900 window in about half the runs and come at ~3900–4200 m.
- `INTRO_TEXT`: each key's banner title, hint, and the dino tip shown once that dino is unlocked. `INTROS` pairs it with the configured distance (sorted at load).

## Pacing rules

All set from `[pacing]`:

| Setting | Meaning |
|---|---|
| `MARINATE_M` (130 m) | a not-yet-taught hazard waits this long after the last new thing (`last_new_m`) |
| `BIG_CLEARANCE_M` (100 m) | kept clear before a big moment (next dino unlock, first visit to a zone, second booster slot, first hunter charge; `main.next_big_m`) |
| `INTRO_SOLO_SPAWNS` | a new hazard is spawned alone this many times |
| `FAMILIAR_AFTER_M` | a hazard is "familiar" this far after its intro; only familiar hazards go into combos |
| `GATE_SPACING_M` | distance between dino gates |
| `ZONE_SHOWCASE_M` | |
| `RAMP_START_M` / `RAMP_FULL_M` | `pressure()` ramps 0 → 1 between them |

- While you're in a zone with its own lesson still to learn, other new hazards wait for it.
- Course (`introduce_ok`, a key's first spawn in a run) and Terrain (`introduce_ok` in `_generate`) both ask `main._can_introduce()`.
- Features without a lesson, and anything already taught, are never held back.
- An introduction distance is the *earliest* point; these rules can push it later.

## Teaching new things

**Info cards** (`State.INFO`, `queue_info`, `Hud.show_info`)
- Pause the game for: an untaught hazard's first appearance, a dino unlock, the first-ever visit to a zone, the first hunter charge.
- They queue, can't be dismissed for `INFO_MIN_TIME` (0.6 s, so a jump tap doesn't skip one), and close with a tap or JUMP.
- `pause_for_info` = false falls back to banners (tests use that).
- A hazard card's picture is `main._intro_icon(key)` = `HazardIcons.icon(key, zone Rok is in)`, so it shows that zone's version (Desert sandstone rocks, the fossil arch, a lava channel…). See [field-guide](field-guide.md#hazard-pictures).

**Already taught** (`Progression.taught`): no hint if its banner was shown before, or the best distance is `TAUGHT_MARGIN_M` (60 m) past it. The pacing and solo spawns still happen every run.

**First sight** (the user's rule: nothing new appears before it's been mentioned)
- `main._first_sight_step` introduces big meat, rare fossils, milestone chests, the bonus portal and any power-up besides the starter pepper the first time one comes on screen (`FIRST_SIGHT`, `_introduce_thing`): an info card, and the `seen` key (`power_<kind>`) reveals its Field Guide card.
- **Obstacle looks** (the user's rule, 2026-11-23: rocks and mushrooms aren't grouped, and a zone's look-alikes mustn't surprise): `main._looks_step` gives each look of a hazard its own NEW banner (not a card) the first time one is on screen, `seen` key `look_<id>`. The looks are in **`config/obstacle_looks.cfg`** (`ObstacleLooks`: per look its art names, banner name and hint, and an optional `lesson` whose own banner already teaches it, so rocks ride on the "small" lesson, now titled "Rocks"). Today: rocks, mushrooms, twigs, the Canyon's loose stones, the Desert's raptor skulls, bone piles and sandstone shards, the Volcanic ember rocks, obsidian shards and pumice lumps. `Obstacle.art` is the first part's file name or its animation; any hazard's look can be added the same way.
- Hazards already work this way (Course `introduced`).

## Unlock news

- `main.new_this_run`: every new hazard, dino, zone and slot met in a run.
- `main.new_market`: Market items that went on sale (crossing their distance past the best).
- Market news never interrupts a run; the summary lists it all.
- The Market tags unseen on-sale items NEW (`main.market_new()`); opening it marks them seen (`main.market_seen`, saved).
- The Marketplace button's red dot: `main.market_badge()` (something new on sale, or affordable).
