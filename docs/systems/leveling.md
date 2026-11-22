# Levelling and XP

Characters earn XP by running, then level up (1–10) at the Camp with meat,
raising one attribute a little each time.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/dinos.gd` (`levels`, `xp`, `gain`, `level_cost`, `xp_for`, `xp_ok`, `can_level`, `can_raise`), `main.level_up(id, attr)`, `herd.gd` (the Camp UI) |
| Saved | `main.dino_levels` (`SaveData.load/save_dino_levels`), `main.dino_xp` (`load/save_dino_xp`, at each run's end) |
| Who levels | every owned dinosaur (originals included), Rok, Nira and Boro |

## Earning XP

- **1 XP per metre** Rok runs as that character (heroes earn it on foot). Counted in `_badge_run_step`.
- Multiplied by the run's rank and the Seasoned badge perk (see [run-loop](run-loop.md), [goals](goals.md)).
- Chests can give XP to the form Rok is in.
- The moment one qualifies for a level, the run's news gets "<name> ready for Lv N", and the summary shows READY FOR LV N!

**XP needed**: reaching level L takes `xp_for(L)` = `XP_STEP` (450) × (1 + … + (L−1)) XP in total.

| Level | Total XP (= metres) |
|---|---|
| 2 | 450 |
| 3 | 1350 |
| 5 | 4500 |
| 10 | 20250 |

## Levelling up

At the Camp: pick a character and an attribute, then confirm (`main.level_up(id, attr)`).

**Needs**
- enough XP (`xp_ok`, `xp_progress`), and
- meat: `LEVEL_COST[tier]` × the new level. Base by tier (Original/Starter/Skilled/Expert/Legend): 30 / 45 / 60 / 80 / 100 (far less than a new dinosaur).

**Gain** (the user's rule: about half a point, less the higher it already is; `gain()`):

| Attribute now | Gain |
|---|---|
| below 5 | +0.5 |
| below 7 | +0.4 |
| below 9 | +0.3 |
| 9 and up | +0.2 (`GAIN_TOP`) |

**Caps**
- Levels go 1 → `MAX_LEVEL` (10).
- The lean can't pass `LEVEL_LEAN_MAX` (6 / 8 / 8 / 10 / 10: one below the next tier's base); no attribute passes 10 (a gain is clipped).
- Gear and cards never block levelling.

## Data and display

- Entries: `{"lv": level, "pts": {attr: points added}}`. Older `{attr: points}` saves are read as one level per point (`level_entry`).
- `Dinos.stat` returns a float with levels included; `base_stat` is the roster value.
- `level(id)`, `level_stars` (one star per level): rows and cards show "Lv 4★", the Camp's detail panel the full bar.
- A levelled original gets `form_data` too (its numbers shifted). `Forms.clear_cache()` runs after every level-up.
- A ready level-up puts a red dot on the Camp button.
