# Pickups, reward spots and loot

Amber, meat, big meat, fossils and hearts on the course: what a reward spot
holds, where it's placed, how it gets richer deeper into a run, and what
broken obstacles drop.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Config | **`config/pickups.cfg`**: every chance, count and placement number (its header explains the rules) |
| Code | `scripts/loot.gd` (reads the config), `scripts/pickup.gd`, `course.gd` (`_rewards`, `_spot_kind`, `_spot_count`, `_fill`, `_booster`, `big_meat_chance`, `fossil_chance`), `main._break_loot` |
| Tests | `main.loot_override` pins the break-loot dice; `Loot.set_value` / `reload` set config values in a check |

## Pickups

| Pickup | Gives | Art |
|---|---|---|
| Amber | energy (15 as Rok, 7 as a dino) and points; **only once a dinosaur is unlocked** ([dependency tree](requirements.md)) | `Other_07`, static with its own bob |
| Meat | Market currency (×combo multiplier) | the user's meat icon and 8-frame loop |
| Big meat | `BIG_MEAT_VALUE` (3) meat | the meat art drawn at `BIG_MEAT_SCALE` (the user wanted bigger, not gold) |
| Rare fossil | `FOSSIL_MEAT` (8) meat + `FOSSIL_SCORE` | drawn in code until art exists (`Pickup.ART`) |
| Heart | heals one heart (points at full health) | stone heart |
| Power-up | goes into a free slot ([power-ups](power-ups.md)) | its animated idle loop (`Boosters.frames`, scale 0.62) |
| Chest | a milestone reward ([long-run-events](long-run-events.md)) | the user's animated chest |

## Reward spots

After most hazard patterns the course may place a reward spot.

**1. Where** (`[placement]`, tried in order)

| Placement | Chance | Shape |
|---|---|---|
| Sky trail | `sky_trail` 0.12 (once "sky_trail" is introduced) | a high wavy trail ~290 px up, 4–7 pickups; easiest flying |
| Floating islands | `islands` 0.22 | only over simple hazards (small, thorn bush, log, boulder, fence). A staircase of 2–3 islands (`staircase` share, from `staircase_from_m`), prize on the top step; else one island holding up to `island_max` (3) |
| Arc | `arc` 0.45 | an arc over the hazard (rewards the jump) |

Other fixed rewards: amber under a low ledge (1–3), 4 amber before every dino gate.

**2. What** (`[spots]`, checked top to bottom)

| Kind | Chance | Holds |
|---|---|---|
| heart | 0.025 | one heart |
| fossil | rises from 0.03 to 0.08 (see below) | one fossil |
| power | 0.1 | one power-up |
| meat | 0.1, or always once `meat_due_m` (400 m) passed without meat | all meat |
| mixed | 0.06 | amber and meat together |
| amber | the rest | all amber |

- Single things (heart, power, fossil) sit at the spot's best place: the far end of a trail, the top island, the middle of an arc.
- **How many** (`[counts] weights`): amber, meat and mixed spots hold 1–4, chances 0.35 / 0.3 / 0.2 / 0.15 (average ~2.2).

**3. Deeper into a run** (`[escalation]`)
- **Big meat**: from `big_meat_from_m` (2000 m) a share of meat comes as big meat, rising to `big_meat_max` (0.4) at `big_meat_full_m` (6000 m).
- **Fossils**: none before `fossil_from_m` (4000 m), then `fossil_min` (0.03) of spots rising to `fossil_max` (0.08) at `fossil_full_m` (9000 m).
- The combo's meat multiplier applies on top.

## Break loot

The user's rule. `main._break_loot`, called from `_smash`, so attacks, dinosaur
smashes, Power breaks and crash-throughs all roll.

| Setting (`[break_loot]`) | Value |
|---|---|
| `chance` a broken obstacle drops something | 0.12 |
| `heart` share (amber instead at full health) | 0.15 |
| `power` share (an owned power-up) | 0.2 |
| the rest: amber, `amber_count` pieces | 3 |
| `in_frenzy` (also during Primal Frenzy) | false |

Loot drops where the obstacle stood.

## Which power-up

`[power_ups]`: the Blaze Pepper `pepper_share` (0.5) of the time, otherwise one of
the other owned power-ups by weight (unlisted ones weigh 1). Used by reward
spots, break loot and chests (`Course._booster()`).
