# Levelling and XP

Characters earn XP by running and **level up by themselves** the moment they
have it, from 1 to 20: no meat, no trip to the Camp (campaign build ticket
[03](../wayfinder/campaign-build/03-automatic-levels.md)). A dinosaur's level
grows its attributes, mostly its best one; a hero's level will give skill
points ([08](../wayfinder/campaign-build/08-rok-skill-tree.md), not built yet).

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Config | **`config/leveling.cfg`**: `[xp]` max_level, first_level_m, step_m, team_share; `[growth]` pattern. Missing keys fall back to `Dinos.DEFAULT_*`. |
| Code | `scripts/dinos.gd` (`xp`, `xp_for`, `level_for_xp`, `level`, `xp_progress`, `_pts_at`, `next_growth`, `level_text`), `main.add_xp(id, amount)`, `main.team_ids()`, `main._migrate_levels()`, `herd.gd` (the Camp shows it), `summary.gd` (the XP table) |
| Saved | only XP: `main.dino_xp` (`SaveData.load/save_dino_xp`, at each run's end). The level and the attribute points are worked out from it. |
| Who levels | every hero and dinosaur that runs (originals included) |

## Earning XP

- **1 XP per metre** Rok runs as that character (heroes earn it on foot), in
  `main._badge_run_step`, through `main.add_xp`.
- **Team share**: the other equipped dinosaurs (the species on each unlocked
  dino button, `main.team_ids()`) get `team_share` (10%) of every metre's XP.
- Multiplied by the run's rank and the Seasoned badge perk (see
  [run-loop](run-loop.md), [goals](goals.md)); the rank's bonus is added at
  the run's end (`_apply_rank`), also through `add_xp`.
- Chests can give XP to the form Rok is in.

**XP needed**: reaching level L takes, in total,
`first_level_m × (L−1) + step_m × (L−1)(L−2)/2` (`Dinos.xp_for`):

| Level | Total XP (= metres) |
|---|---|
| 2 | 300 |
| 3 | 750 |
| 5 | 2,100 |
| 10 | 8,100 |
| 20 | 31,350 |

## Levelling up

`main.add_xp` adds the XP and compares the level before and after. On a new
level (mid-run if playing):
- a floating **"LEVEL UP! Raptor Lv 3"**, a sparkle, a short golden glow on
  Rok and the unlock sound; play doesn't stop;
- `Forms.clear_cache()` so the new attributes apply at once, and the form
  buttons refresh;
- the run's news gets "<name> reached Lv N", and `main.run_levelups` (id ->
  level) gives the summary a **LEVEL UP! LV N** chip in place of "N to Lv N+1".

## How a dinosaur grows

Each level from 2 up raises **one attribute** by about half a point, less the
higher it already is:

| Attribute now | Gain |
|---|---|
| below 5 | +0.5 |
| below 7 | +0.4 |
| below 9 | +0.3 |
| 9 and up | +0.2 (`GAIN_TOP`) |

**Which attribute**: the `[growth] pattern` of ranks repeats, 1 = the
dinosaur's best attribute by base value (ties in `Dinos.ATTRS` order), 2 = its
second best... The default `[1, 2, 1, 3]` gives the best attribute half the
levels. A capped attribute passes its turn to the next rank.

**Evolution** at levels 10 and 20 adds +1 to every attribute on top (see [dinosaurs](dinosaurs.md#milestones)).

**Caps**: the lean can't pass `LEVEL_LEAN_MAX` (6 / 8 / 8 / 10 / 10 by tier:
one below the next tier's base); no attribute passes 10.

The points are worked out from the level (`Dinos._pts_at(id, level)`, cached),
so nothing but XP is saved. **Heroes** grow no attributes by level.

## Data and display

- `Dinos.stat` returns a float with levels (and a hero's gear) included;
  `trained_stat` is base + levels; `base_stat` the roster value.
- `level_text(id)`: "Lv 7", "Lv 20 MAX" (Camp rows and detail panel).
- `next_growth(id)`: what the next level adds ({attr: points}); the Camp's
  note reads "Lv 4 in 450 m: +0.4 Speed. The Gallimimus levels up by
  itself as it runs."
- A levelled original gets `form_data` (its numbers shifted).
  `Dinos.has_levels` is true once levels changed its attributes.

## Old saves

`main._migrate_levels()` runs once on load when the save still has bought
levels (`progress/dino_levels`): it refunds the meat they cost
(`OLD_LEVEL_COST[tier]` × each level, as before), raises each character's XP
to what its level needs now (so every level is kept), and clears the bought
points (attributes come from the new growth). The next run's news says
"Levels now come by themselves: N meat refunded".
