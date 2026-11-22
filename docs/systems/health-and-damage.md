# Health, damage and hit reactions

Hearts, what each hit costs, what's still instant, hit reactions (trip, dizzy,
snag) and the Power roll on small hazards.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/hearts.gd` (`Hearts`), `main._hurt` / `_stumble` / `_small_hazard` / `_trip` / `_snag` / `_mushroom` / `_crash`, `player.gd` (`react_*`) |
| Config | Heart Container prices `[market]`, unlock scores `[market_score]`; heart pickup odds `config/pickups.cfg` |
| Art | the user's stone heart (`tools/prepare_hearts.py`); per-character hit reactions (`assets/reactions/`, `tools/prepare_reactions.gd`) |
| Tests | `main.roll_override` pins the Power roll (run_tests sets 0.999 = never breaks) |

## Hearts

- Rok has `MAX_HEARTS` (3) hearts plus up to `HEART_CONTAINERS` (3) more from the Market (`main.heart_containers`, saved; `main.max_health()`).
- Each heart is 4 quarters (`Hearts.QUARTERS`); `main.health` counts quarters and refills every run.
- HUD: the first row of Rok's status panel, filled in quarters (`Hud.set_hearts(quarters, max)` grows the row). A lost quarter drains right to left through the art's frames (`Hearts.drain_steps`, ~35 ms each; target fill in each heart's `fill` meta). The hearts pop on a hit (`Hud.hearts_hit`).
- `Hearts.text(q)` reads e.g. "¾ heart".

**Heart Containers** (Market, Other tab)
- `Market.HEART_IDS` heart_1..3, prices 900 / 1800 / 3200 (`[market]`).
- On sale by **best score in one run**, not distance: 6000 / 15000 / 35000 (`[market_score]`), each only once the one before it is owned.
- Crossing a threshold with a new best adds it to the run's Market news.

**Heart pickups**
- Rare reward spots (2.5%, `config/pickups.cfg` `[spots] heart`) and sometimes loot from broken obstacles.
- Heal one heart (`main._heal`), or give `HEART_SCORE` points at full health.
- The Field Guide's Items tab has a Heart card.

## What a hit costs

`main._hurt(kind, cause)` (the user's design):
cost = `HIT[kind]` × (1 − Armor / `ARMOR_DIVISOR` (20)), rounded up, never below 1 quarter.
Armor is that of the form Rok is in (`armor_of`; Rok has attributes too).

| Hit | Base cost (quarters) | At Armor 10 |
|---|---|---|
| Crash (boulder, wall, fence, log, solid ledge) | 4 (1 heart) | ½ heart |
| Wild-dinosaur bump | 2 | |
| Vine snag | 2 | ¼ heart |
| Trip (small rock / twig) | 1 | ¼ |
| Dizzy mushroom | 1 | ¼ |
| Thorns | 1 | ¼ |
| Steam vent | 1 | ¼ |

- A **crash** also shatters the obstacle (no smash points), gives `CRASH_INVULN` and the trip reaction.
- **Shields** (the Spinosaurus's, Armor 10 on a non-Tank) block a crash first. (The Amber Shield power-up is now Primal Amber, an energy refill.)
- At 0 quarters the run ends with that hit's `death_cause`; `_collide` stops checking once the state isn't PLAYING.

**Still instant** (only where instant death makes sense): pits (and canyon/bridge gates), water, lava, quicksand, dino gate walls, being caught.

## Small hazards

Small hazards never end a run on their own:

| Hazard | What happens |
|---|---|
| Small rock or twig (kind `small`) | `_trip()`: "Trip!", the hunter gains, brief invulnerability (one rock can't trip twice) |
| Mushroom (Forest, `Obstacle.mushroom`) | `_mushroom()`: squashed, purple "Dizzy!"; dizzy for `DIZZY_TIME` (3 s): jumps × `DIZZY_JUMP` (0.8, `Player.jump_mult`), wobble, purple tint |
| Forest vine ledge (`Obstacle.vine`) | `_snag()`: green "Snagged!", `STUMBLE_VINE`; the vine then scrolls on as debris (one snag per vine) |

The Desert fossil arch and Volcanic rock ledges are solid: they crash, not snag.

**Power roll** (the user's design, `main._small_hazard`)
- Running into a small rock, mushroom or vine rolls `main._roll()` against `Dinos.break_chance(id, slot)` = (Power − 1) / 9, plus `SMASHER_BREAK_BONUS` (0.3) on the Smasher button.
- Win: it breaks straight through (`_power_break`: "SMASH!" or, for a vine, "SNAP!"). Lose: trip, dizzy or snag as usual.
- No form smashes small hazards for sure (the original Triceratops wins about 74%).

## Hit reactions

The user's art; every character has trip, dizzy and snag.

| Reaction | Clip |
|---|---|
| trip | plays once |
| dizzy | enter → loop for `DIZZY_TIME` − 0.4 s → recover; restarts the loop on landing if Rok jumped while dizzy; only wobbles in the air |
| snag | enter → struggle for `SNAG_HOLD` → recover |

- They play on a second sprite, `Player.react` (`react_play(kind, hold, from_hold)`, `react_stop()`), because each sheet has its own canvas and pivot (`SpriteLib.reactions(id)`, `reaction_pivot(id)`). The main sprite is hidden underneath and keeps running.
- `_react_step` copies scale, rotation and tints each frame.
- Only on the ground: jumping, sliding, swimming, shapeshifting, attacking or dying cancels a reaction.
