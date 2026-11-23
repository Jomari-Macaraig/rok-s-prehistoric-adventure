# Chase and hunters

The pursuer behind Rok: the chase gap, each zone's hunter, and timed charges.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/trex.gd` (the pursuer node), `scripts/hunters.gd` (per-zone hunters), `scripts/chase_meter.gd`, `main._update_chase` / `_charge_step` / `_hunter_step` |
| Config | `config/progression.cfg` `[trex]` (`charge_m`, `charge_every_m`) |
| Art | T-rex: `assets/characters/trex/`; Carnotaurus and Allosaurus: `assets/hunters/<id>/` + `hunters.json` (`tools/prepare_animation_pack.gd`) |

## The chase gap

- `main.chase_gap`: px between the hunter's snout and Rok. `Trex.SNOUT` = 272 px ahead of its feet; `Trex.follow()` places it so its body and tail run off the left edge.
- A run starts at `CHASE_GAP_START` = `CHASE_GAP_MAX` (250: only the head shows).
- A closed gap = caught (`_caught()`): the bite animation, "CAUGHT!", `death_cause` "caught"; the world freezes with the hunter mid-bite.
- Below `CHASE_DANGER` the HUD pulses red on the left edge, and the hunter's footsteps (`stomped` signal) get louder as it closes in.
- **The chase meter** (`chase_meter.gd`, row 3 of Rok's status panel under PRIMAL): the hunter icon trails Rok's on a track that turns red as it closes in.

## What moves the gap

**Rules (the user's)**
- Rok runs at exactly the hunter's pace (`CHASE_RECOVER` = 0): on foot the gap holds, and stumbles are never won back by running.
- **Any lead is kept**: nothing fades a gap back down. Turning back into Rok after a Raptor sprint keeps the distance.
- Hills cost Rok ground.
- No hunter creeps closer on its own.

| Cause | Effect |
|---|---|
| Form `chase_rate` | Raptor +40/s, Pteranodon +25/s; the hunter gains 8/s on the Triceratops, 14/s on the Spinosaurus |
| Climbing (`Terrain.slope_at()` < 0) | − `UPHILL_LOSS` (not for `fast` forms: the Raptor); pace × `UPHILL_PACE` |
| Sliding downhill | + `SLIDE_DOWNHILL_GAIN`; pace × `DOWNHILL_SLIDE_PACE` |
| Blaze Pepper | + `PEPPER_CHASE_GAIN` (90/s) for `PEPPER_BOOST_TIME` (2.5 s), world speed × `PEPPER_BOOST_PACE`, streaks and glow |
| Time Crystal | builds a lead (see [power-ups](power-ups.md)) |
| Stumbles | thorn bush `STUMBLE_THORN`, shield hit `STUMBLE_SHIELD`, small rock `STUMBLE_ROCK`, mushroom `STUMBLE_MUSHROOM` |
| A charge | − the hunter's `charge_rate` while it lasts |

A lead can grow up to `CHASE_GAP_FAR` (480: hunter off-screen) and stays until a stumble, a climb or a charge eats it.

## Hunters per zone

`Hunters.DATA`; `main.hunter_id` is the current one.

| Zone | Hunter | Style | Charge |
|---|---|---|---|
| Forest | T-rex | steady | 4 s at +45/s |
| Desert | Carnotaurus | sprinter | 3 s at +65/s |
| Volcanic Badlands | Allosaurus | relentless | 5 s at +40/s (the longest) |

- `_hunter_step` swaps the hunter at zone borders (`Trex.set_hunter`: art, pivot, snout). The first time ever: roar, shake and "NEW HUNTER: …" (`seen` "hunter_<id>"); after that "THE … TAKES UP THE HUNT!".
- The pursuer node is still called `Trex`.
- Snouts: Carnotaurus 184, Allosaurus 197 px. A hunter without art would wear the T-rex's sheets with its own `tint`.
- The Field Guide has a card per hunter (with real facts), revealed once met.
- No species is both hunter and prey (the Volcanic stampede is the Kentrosaurus).
- The Allosaurus once had a `pace` creep; it was removed.

## Charges

`main._charge_step`; distances `[trex]` `charge_m` (5400, 7800), then every `charge_every_m` (2400) (`Progression.next_charge_m`).

1. A roar, a shake, Rok's shout (`rok_alarm`, `CHARGE_ALARM_DELAY` 0.45 s after the roar on a pausable timer) and a "THE T-REX CHARGES!" banner. The first charge ever pauses on an info card (`seen` "trex_charge"); lessons keep `BIG_CLEARANCE_M` clear of it.
2. `CHARGE_WARN` (1.5 s) of warning.
3. For `CHARGE_TIME` the hunter gains its `CHARGE_RATE` extra (T-rex: 4 s at 45/s).
4. Surviving shows "Escaped!" and counts for the Escape Artist badge.

Balance: as Rok with no stumbles the gap drops from 250 to about 70; a Runner roughly holds it; a pepper or a downhill slide escapes.
