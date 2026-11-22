# Dependency tree (requirements)

What needs what before it can happen, set in one config file: e.g. amber only
appears once a dinosaur is unlocked, since it's energy for dinosaur forms (the
user's request).

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Config | **`config/requirements.cfg`** `[requires]`: `thing = [requirement, …]` (its header lists every thing and requirement, and draws the tree) |
| Code | `scripts/requires.gd` (`Requires.ok(thing)`, `met`, `of`, `missing`, `describe`); `main._ready` binds `Requires.game = self` |
| Tests | the dependency-tree checks in `run_tests.gd` (search "requirements") |

## How it works

- A thing with no entry has no requirement. A listed thing happens only when **all** its requirements are met.
- The checks read the live game state (unlocked forms, `seen`, best distance, owned items, open slots), so a requirement met mid-run takes effect at once.
- With no game bound (e.g. a unit test of another class) everything is allowed.
- Unknown requirement words are allowed, with a warning.

## Things (left side)

| Thing | Checked in | Effect when not met |
|---|---|---|
| `pickup.<kind>` (amber, meat, heart, fossil, egg, a power-up id) | `Course._pickup` (every pickup: reward spots, under ledges, gate and sand caches, events, break loot, chests' drops) and `main._break_loot` | it doesn't spawn (a drop counts as nothing) |
| `intro.<key>` (a hazard, terrain feature or gate key from `[introductions]`) | `Progression.available` | it doesn't appear yet |
| `event.<id>` (golden_hour, meteor_shower, amber_storm, stampede_rush) | `RunEvents.pool` | that event isn't picked |
| `power.<id>` | `Course._booster` | that power-up doesn't turn up in spots and drops |
| `market.<id>` | `Market.on_sale` | not on sale; the lock text and Ugo name what's missing (`Requires.missing`, `describe`) |

## Requirements (right side)

| Requirement | Met when | In words (`describe`) |
|---|---|---|
| `dino` | any dinosaur is unlocked | "unlock a dinosaur" |
| `form:<id>` | that dinosaur is unlocked | "unlock the Raptor" |
| `seen:<key>` | that lesson / banner was shown | "meet the pit" |
| `best_m:<n>` | best distance ≥ n | "reach n m in one run" |
| `owns:<id>` | owns that power-up, gear, dinosaur or hero | "own the …" |
| `slots:<n>` | at least n booster slots open | "open n booster slots" |

## The tree today

```
a dinosaur unlocked
  ├── amber (all pickups)
  ├── the Amber Storm event
  └── the Primal Amber power-up (spawning, and on sale in the Market)
```

Before the first dinosaur (1600 m) reward spots that would hold amber are
simply empty, so early runs have fewer pickups: meat, hearts, power-ups and
the starter egg still come. The training run's amber step comes after it lends
the Raptor.

## Adding a rule

1. Add `thing = ["requirement", …]` under `[requires]` in `config/requirements.cfg`.
2. If the thing is a new kind (not one of the five above), call `Requires.ok("<kind>.<id>")` where it happens and add it to this doc and the config header.
