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

## Seamless running attacks

The user's running-attack packs (`../Assets/Rok_Running_<weapon>`, imported by `tools/prepare_running_attacks.py` into `assets/attacks/<hero>/` + `running.json`). So far: **Rok with the club**.

- **Carry run**: while Rok holds a whole weapon that has a pack, his `run` animation is that pack's carry run with the weapon drawn in (`SpriteLib.carry_frames`, `Player.set_carry`, set every frame from `main.carry_weapon()`). `GearLayer.baked_run` hides its own weapon during `run` so there's one club. Jump, slide and the rest still use the plain sheets plus `GearLayer`.
- **The swing**: ATTACK while running on the ground (`Player.run_attack_play`, tried before the standing clip in `main._attack`) shows the version made for the current run phase p (`p0`…`p7`, `SpriteLib.running_attack`). It isn't played on its own clock: each time the hidden body sprite's run frame advances (`_run_attack_tick`), the swing advances one frame, so it keeps the run's frame duration, speed and fractional progress. After 8 frames it hands back and the run is at phase p again. The hit pose is frame 4.
- Leaving the ground, a slide, a shapeshift, a hit reaction or a non-`run` animation ends it. In the air the standing clip plays as before.
- The hit itself still lands on the press (as with every clip). The bow and sling would release on frame 4 at the run's clock (`Player.run_attack_wait`).
- Placement: the packs' legs are pixel copies of Rok's run sheet, so attack frame i of phase p gets the exact offset `prepare_form_art.py` gives run frame (p+i)%8. Legs match the in-game run to the pixel. The swing canvas is the run's grown by 64 source px on each side (pivot 112, 241.5 at 1x) so the club isn't cropped.

## Open items

- Running attacks exist only for Rok with the club. The other six weapons, and Nira and Boro, still use the standing clips while running (a new pack in the same format is picked up by `prepare_running_attacks.py`; Nira and Boro would also need their run placement added there).
- No clip yet for bare hands or the 12 balanced-pack species.
