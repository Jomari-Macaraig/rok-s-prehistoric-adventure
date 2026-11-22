# Combo streak and Primal Frenzy

Clean feats build a combo multiplier and fill the frenzy meter; a full meter
starts Primal Frenzy, a few seconds of smashing through everything.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/combo.gd` (`main.combo`), `scripts/combo_meter.gd` (HUD), `main._combo_step` / `_frenzy_smash` |
| Numbers | `COMBO_*` and `FRENZY_*` in `tuning.gd` |

## Feats

Each adds to `Combo.count`:

| Feat | Weight |
|---|---|
| An obstacle that scrolls past without hitting Rok (not while invulnerable after a hit) | 1 |
| A pit, liquid or quicksand patch crossed | 1 |
| A smash (`_smash`) | 1 |
| A dino gate passed | `COMBO_GATE_WEIGHT` (3) |
| A wild dinosaur the hunter eats | `COMBO_SNACK_WEIGHT` (2) |
| Opening a chest | `CHEST_COMBO_WEIGHT` |

- Pickups only keep the streak alive (`keep_alive`), they don't add to it.
- **The streak ends** on any stumble (`_stumble` → `combo.hit()`) or after `COMBO_WINDOW` (6 s) without a feat.

## Tiers

`COMBO_TIERS`:

| Feats | Multiplier |
|---|---|
| 5 | ×1.5 |
| 12 | ×2 |
| 24 | ×3 |
| 40 | ×4 |
| 60 | ×5 |

- The multiplier applies to every point (`main.points_mult`).
- Each meat pickup gives the multiplier's whole part in meat (`meat_per_pickup()`).

## Primal Frenzy

- Feats also fill `meter` (`FRENZY_FILL`, about 33 feats); a stumble takes `FRENZY_HIT_LOSS`.
- Full meter → **Primal Frenzy** for `FRENZY_TIME` (8 s):
  - every obstacle goes to `_frenzy_smash`: walls, boulders, ledges and dino gate walls smash, wild dinosaurs get bowled over, steam is ignored;
  - the gap to the hunter grows `FRENZY_CHASE_GAIN`/s;
  - meat drops ahead every `FRENZY_MEAT_EVERY` s;
  - Rok glows gold with speed lines; the meter drains.
- Pits, liquids and quicksand still count.
- Afterwards `FRENZY_END_INVULN` of grace.
- No break loot or mid-run events during a frenzy.

## Feedback

- `_on_combo_tier`: "x2 COMBO!" and a rising chime; `_on_combo_broken`; `_on_frenzy_started` / `_ended`.
- The first combo and first frenzy each show a banner once (`seen` "combo" / "frenzy").
- **Combo meter** (HUD, under the meat pill, only during a run): the multiplier in its tier colour, the count, the time left and the gold frenzy meter.
- The summary's news starts with "Best combo: N" and the run's frenzies (`main.frenzies`).
