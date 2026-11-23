# Long-run variety: chests, events and bonus zones

What keeps long runs lively: milestone chests, mid-run events and bonus zones
(switched off for now). Combo and frenzy, lap twists, daily missions and the
escalating pickups are the other parts of this set (the user picked all eight
ideas); they have their own docs.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/chest.gd`, `scripts/run_events.gd` (`main.events`), `scripts/bonus_portal.gd`, `main._chest_step` / `_event_step` / `_bonus_step` |
| Numbers | `CHEST_*`, `EVENT_*`, `BONUS_*`, `METEOR_*`, `STAMPEDE_RUSH_EVERY` in `tuning.gd` |
| Art | chest: `assets/items/chest_anim.png` + `chest.json` (`tools/prepare_chest.py`); bonus portal: drawn in code until `assets/items/bonus_portal.png` exists |

## Milestone chests

**When and where**
- A **starter chest** comes first in every run at `[early] starter_chest_m` (870 m, between the wild-dinosaur preview and the Triceratops; `Progression.STARTER_CHEST_M`; 0 turns it off), counted as milestone 1, so the first 1000 m has a reward. If a run starts past a chest (tests, bots), `_chest_step` moves on to the next milestone.
- Every `CHEST_EVERY_M` (1000 m) of a run, `main._chest_step` puts a chest (`Pickup` kind `chest`, meta `milestone` = n) on flat ground as the milestone comes into view (later if the ground isn't flat; never over a pit or liquid).
- Touching it at any height opens it (`main._open_chest`). It stays, open, as scrolling debris.

**Rarity**: `Chest.rarity(n, roll)`; rare and epic chances grow per milestone up to `CHEST_RARE_MAX` / `CHEST_EPIC_MAX`. Rarer and later chests hold more.

**Rewards** (`Chest.REWARDS[rarity]`), plus `CHEST_SCORE` points and `CHEST_COMBO_WEIGHT` combo feats:
- meat (`CHEST_MEAT` + milestone)
- XP for the form Rok is in (`CHEST_XP`)
- a power-up into a free slot (else meat)
- a heart, or full hearts
- an instant Primal Frenzy

**Art**: closed until opened, then the lid-opening clip once and a sparkle loop (`Pickup._chest_frames`); without it the still `chest_closed/open.png`, else drawn in code.

The first chest ever shows a banner (`seen` "chest"); `main.chests_opened` goes in the run's news.

## Mid-run events

`run_events.gd`: from `EVENT_FROM_M`, every `EVENT_GAP_MIN..MAX` m a random
event runs for its time, with a banner and a countdown on the HUD
(`Hud.set_event`, under the combo meter).

| Event | Effect |
|---|---|
| Golden Hour | meat × `GOLDEN_HOUR_MEAT`; reward spots become meat (`Course.force_meat`) |
| Meteor Shower | a growing shadow, then a small rock falls onto it in `METEOR_FALL` s (`main._meteor`). It can hit Rok while falling; ATTACK smashes it at any height with `ATTACK_METEOR_REACH` extra reach |
| Amber Storm | amber drops ahead |
| Stampede! | the zone's stampede every `STAMPEDE_RUSH_EVERY` s; only once stampedes have been taught (`RunEvents.pool`) |

- No event starts during a frenzy, a hunter charge, a bonus zone or with a portal out; it retries a little later.
- While `Course.holding` (a dino unlock's gate is due), meteors and stampedes drop nothing, so the gate stays the first new obstacle.

## Bonus zones (switched off)

**Switched off for now** (the user's call): `Tuning.BONUS_ENABLED` = false
makes `_bonus_step` do nothing. Setting it true brings them back; the bonus
tests run only then.

How they work when on:
1. From `BONUS_FROM_M`, every `BONUS_GAP_MIN..MAX` m (no frenzy, charge, event, gate hold or gate marker about), a `BonusPortal` stands on flat ground just off-screen (`_place_portal`).
2. The ground past it is dropped and only flat ground follows (`Terrain.calm_from` / `calm`, sharing `_trim_after` with `request_gate`); obstacles behind it are removed and `Course.holding` stops spawns.
3. Rok passes through at any height (`_enter_bonus`): for `BONUS_TIME` s the world takes a violet wash (`main.bonus_tint`) and treasure (amber, meat, big meat) drops in waves every `BONUS_DROP_EVERY` s.
4. `_end_bonus` lifts calm and the hold (unless a dino unlock set its own).

Hunter charges wait while a portal is out or a bonus runs. The first one shows a banner (`seen` "bonus").
