# Combat: attack

The ATTACK action: what it targets, what breaks, the target marker, and the
attack clips for each hero weapon and dinosaur.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `main._attack` / `attack_target` / `_attack_hit` / `attack_breaks` / `attack_clip`, `scripts/attack_marker.gd`, `player.gd` (`attack_play`, `attack_stop`) |
| Button | `Hud.attack_button`, left of SLIDE (`ATTACK_R` / `ATTACK_DEG`); key F on desktop |
| Art | `assets/attacks/<id>/<clip>.png` + `attacks.json` (`tools/prepare_attacks.py`) |
| Cooldown | `ATTACK_COOLDOWN` 1.8 s from the press, shortened by Power (see [attributes](attributes.md)) |

## How an attack works

`_attack` = `attack_target()` + the clip + `_attack_hit(target)`.

1. **Target**: the nearest obstacle or wild dinosaur within `attack_reach()` ahead and at Rok's height (a falling meteor at any height, with extra reach).
2. **Clip**: the form's attack clip plays (below). Bare hands, a dinosaur card, a broken weapon or a species without a clip use a code-drawn lunge and slash instead.
3. **Hit**: instant on the press; the clip is cosmetic.
4. Every connecting hit wears the hero's weapon by 1 (see [weapons-and-armor](weapons-and-armor.md)).
5. The tutorial teaches ATTACK at the first breakable target in reach (see [tutorial](tutorial.md)).

**Reach**: a hero's weapon (`Gear.reach`; bare hands `ATTACK_REACH_HAND`), or `ATTACK_REACH_DINO` for dinosaurs.
**Power**: the form's Power attribute (`attack_power`); a hero's includes gear.

## What breaks

`attack_breaks(o, power)`:

| Target | Breaks when |
|---|---|
| Wild dinosaurs | always (bonked: points, a combo feat, maybe its card) |
| Small rocks, mushrooms, vines | always |
| Logs, thorns | Power ≥ `ATTACK_POWER_WOOD` (4), or the Torch |
| Fences | Power ≥ `ATTACK_POWER_FENCE` (6), or the Torch |
| Boulders, walls | Power ≥ `ATTACK_POWER_ROCK` (7) |
| Anything the form smashes anyway | always |
| Dino gates, ledges, steam | never ("CLANG!") |

A broken obstacle rolls for loot (see [pickups-and-loot](pickups-and-loot.md)).

## Target marker

`attack_marker.gd`, updated every frame by `main._attack_marker_step` from `attack_target()`:
- corner brackets and a bobbing arrow on exactly what ATTACK would hit now;
- green if it would break it, red if it would clang;
- faded during the cooldown, hidden when nothing is in reach;
- follows `attack_reach()`, so long-range weapons show it further out.

## Attack clips

The user's attack pack. `main.attack_clip()` picks:

| Who | Clip |
|---|---|
| A hero holding a whole weapon | `attack_<weapon id>` (Rok, Nira and Boro have all seven) |
| A dinosaur | `attack` (the original four and 16 expansion species) |
| Bare hands, a card, a broken weapon, the 12 balanced-pack species | none: code-drawn lunge and slash |

- `Player.attack_play(clip)` plays it once on `Player.atk`, a sprite with the clip's own canvas and pivot (`SpriteLib.attacks(id)` / `attack_meta(id)`). The body sprite and `GearLayer` hide while it plays (the clip draws the weapon).
- `_attack_step` copies the body sprite's scale and tints.
- `attack_stop` hands back when the clip ends, or on a slide, swim, death, shapeshift or hit reaction.
- Timing: a quick wind-up; the strike (frame 4) shows ~0.17 s after the press, 0.52 s in all.
- The Bow's arrow and the Sling's stone (a code-drawn pebble) leave on the clip's `release` frame (`_shoot_arrow(to, stone)`), aimed where the target was.
- A weapon breaking on the hit stops the clip so its shatter shows in the hand.
- Ankylosaurus, Diplodocus, Kentrosaurus and Stegosaurus strike rearward with their tails (as drawn); Brachiosaurus stomps.

## Open items

- The clips are standing attacks played while running, so they don't blend with the run. Seamless needs running-attack sheets (legs keep the run cycle, frames 0 and 7 match run poses).
- No clip yet for bare hands or the 12 balanced-pack species.
