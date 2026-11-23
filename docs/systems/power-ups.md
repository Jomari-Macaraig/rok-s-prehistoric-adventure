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
| Blaze Pepper | 2.5 s speed boost that pulls away from the hunter | owned from the start; every run offers one at `[introductions] pepper` (600 m). It replaced the Dino Egg (the user's change, 2026-11-23; id `pepper`, old saves' `egg` is renamed on load by `SaveData._renamed`); the egg art stays in `assets/powerups/dino_egg*` for another idea. Art: the user's still picture (`tools/prepare_assets.py` `blaze_pepper()`), no idle loop yet |
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
- Which one: the pepper `pepper_share` (half) of the time, else another owned power-up by weight (`Course._booster()`).

## Adding a power-up

1. A `Boosters.DATA` entry (art id, name, effect text, points; `starter` if owned from the start).
2. A case in `main.activate_booster` (and `booster_ready` if it can't always be used).
3. A price in `[market]` (it's then sold) and optionally `[market_unlocks]` / `[market_badges]`.

## Effects

The user's power-up effects (`../Assets/Rok_Powerup_FX_Preview/Rok_Powerup_FX`, imported by `tools/prepare_powerup_fx.py` into `assets/fx/powerup_*` + `powerup_fx.json`): gold rings around the player, sized to the current form (`POWERUP_FX_SIZE` of its drawn frame's bigger side, against the aura ring's measured diameter) and centred on it.

| Effect | When | Where |
|---|---|---|
| pickup | a power-up goes into a slot (`collect_booster`) | `Player.pfx_once`, over the body |
| activation | a slot is used (`activate_booster`) | `pfx_once` |
| aura (loop) | while any power-up runs: the pepper's boost or a timed one (`_power_step` → `Player.set_power_aura`) | `Player.pfx_aura`, behind the body (follows a shapeshift's size) |
| expire | when the last one ends | `pfx_once` |

A new run clears them.

### Sounds
Each effect has a synthesised sound (`make_sounds.py` `powerup_sounds()`; `make_sounds.py powerups` writes just these):
`powerup_pickup` (a rising pentatonic sparkle) in `collect_booster`; `powerup_activate` (a rising whoosh into a major chord) in `activate_booster`, pitched per power-up by `Tuning.POWERUP_SOUND_PITCH`; `powerup_expire` (a falling chime and fizzle) in `_power_step` when the aura turns off. The pepper boost still adds its own `shift` whoosh.
