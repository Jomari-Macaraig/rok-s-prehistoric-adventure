# Power-ups (boosters)

The six power-ups, the kart-style slots that hold them, what each does, and
how they spawn.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/boosters.gd` (`Boosters.DATA`), `main.collect_booster` / `use_slot` / `activate_booster` / `booster_ready` / `_power_step` |
| Art | `assets/powerups/` (`icon(kind)`, `frames(kind)`: 4×2 idle loop) |
| Prices and sale | `[market]`, `[market_unlocks]`, `[market_badges]` (see [marketplace](marketplace.md)) |
| Spawn odds | `config/pickups.cfg` (`[spots] power`, `[power_ups]`) |
| Slot 2 distance | `[boosters] slot_2` |

## The power-ups

Numbers in `tuning.gd`. Timed ones live in `main.power_t` (`power_on(kind)`),
can't stack (`booster_ready`), tint Rok while running, and a new run clears them.

| Power-up | Effect | How you get it |
|---|---|---|
| Dino Egg | 2.5 s speed boost that pulls away from the hunter | owned from the start; every run offers one at 140 m |
| Primal Amber (id `amber_shield`; it was the Amber Shield) | refills PRIMAL energy to full; usable only when it isn't full. Pictured as the amber pickup until it has its own art (`Boosters.DATA` `still`) | Market, from 0 m **once a dinosaur is unlocked** ([dependency tree](requirements.md)); it doesn't spawn before one either |
| Fossil Magnet | 7 s: pickups within `MAGNET_RADIUS` fly to Rok (`Pickup.pull_toward`) | Market, 1800 m + Amber Hoarder Bronze |
| Time Crystal | 4 s: world pace × `SLOW_PACE`, the gap grows `SLOW_CHASE_GAIN` | Market, 3000 m (before the first charge) |
| Primal Berry | 8 s free shapeshifting: no energy needed or drained, no cooldown | Market, 5000 m + Primal Spirit Bronze |
| Golden Fossil | 10 s ×2 points (`points_mult`) | Market, 6600 m + Untouchable Silver |

**Only owned power-ups exist in a run** (`main.boosters_owned`, saved). The
others show greyed in the Field Guide with their Market price, and
`collect_booster` refuses them. Each non-starter power-up is introduced on an
info card the first time one appears.

## Slots

| Slot | Opens |
|---|---|
| 1 | from the start (`START_SLOTS`) |
| 2 | the first time a run reaches `SLOT_UNLOCK_M` (3760 m, before the first charge at 5400 m), with a "NEW BOOSTER SLOT!" card; saved |
| 3 (`MARKET_SLOT`) | bought in the Market only |

- `main.slots` always has 3 entries; `main.slot_count` how many are open (saved).
- **Pickup rule** (the user's): a power-up goes into any free open slot, even if another slot holds the same type. Only when every open slot is full is it just points. It always gives its points.
- Slot buttons arc above SLIDE. Locked ones show a padlock with the slot-2 distance or "Market"; tapping one shows a popup.
- `use_slot(i)` runs `activate_booster(kind)` if `booster_ready(kind)`. Keys B / N / comma on desktop.

## Spawning

- Power-ups come in their own reward spots (`[spots] power`), never mixed with amber or meat, at the spot's best place.
- Also from break loot and chests.
- Which one: the egg `egg_share` (half) of the time, else another owned power-up by weight (`Course._booster()`).

## Adding a power-up

1. A `Boosters.DATA` entry (art id, name, effect text, points; `starter` if owned from the start).
2. A case in `main.activate_booster` (and `booster_ready` if it can't always be used).
3. A price in `[market]` (it's then sold) and optionally `[market_unlocks]` / `[market_badges]`.
