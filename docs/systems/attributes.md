# Attributes and cooldowns

The five attributes every character has, how categories and tiers shape them,
what each one changes in play, and the cooldowns they shorten.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/dinos.gd` (`stat`, `base_stat`, `cooldown_mult`, `perks`, `form_data`, `CATEGORIES`, `ROSTER`, `TIER_BUDGET`), `forms.gd` |
| Scale | 10 points (`ATTR_MAX`); decimals allowed once levelled (`fmt()` shows "7" / "7.4") |
| Tests | budgets, caps and trade-offs are checked; keep them when editing the roster |

## The five attributes

`Dinos.ATTRS`:

| Attribute | In play (per point, relative to the button's original) |
|---|---|
| Speed | chase rate ±5 px/s (gains or loses on the hunter); shortens the slide cooldown |
| Jump | jump height ±3% |
| Stamina | energy drain ∓7.5% (for Rok: +7.5% amber energy, `amber_mult`) |
| Power | small-hazard break chance ((Power − 1) / 9); what ATTACK breaks; shortens the attack cooldown |
| Armor | stumble cost ±5% (`stumble_mult`); fewer quarters lost per hit |

`form_data` applies **differences from the button's original**, so the originals
play exactly as before (a Legend Utahraptor at Speed 9 is +20 px/s on the
Raptor's 5).

**Thresholds** (`Dinos.perks` lists them; levelling can unlock them)

| At | You get |
|---|---|
| Armor 6+ | a crash costs half a heart (`Hearts.HALF_COST_ARMOR`) |
| Armor 10 (non-Tank) | a shield per transformation (`ARMOR_SHIELD`) |
| Power 10 on a Smasher | also smashes fences (`POWER_FENCE`) |
| Power 8+ (Rok) | smashes small hazards |

## Categories

Every dinosaur, the four originals included, is in one category, one per dino
button (`Dinos.CATEGORIES`). Its **lean** attribute is always its best.

| Category | Button | Lean |
|---|---|---|
| Runner | Raptor | Speed |
| Smasher | Triceratops | Power |
| Tank | Spinosaurus | Armor |
| Flyer | Pteranodon | Jump |

## Tiers and budgets

The user's rule: buying dinosaurs must pay off, and the base Raptor's Speed isn't max.

| Tier | Budget (sum of 5) | Lean cap (base) | Lean cap (levelled, `LEVEL_LEAN_MAX`) |
|---|---|---|---|
| Original | 17 | 5 | 6 |
| Starter | 19 | 7 | 8 |
| Skilled | 21 | 7 | 8 |
| Expert | 25 | 9 | 10 |
| Legend | 29 | 9 | 10 |

- **Base values are low on purpose** (lowered by 1 once levelling existed): nothing starts at 10; only Experts and Legends can level their lean to 10.
- Within a tier they're trade-offs: same budget, none at least as good as another at everything, no two share a profile.
- Tiers show as coloured names (`tier_label`, `tier_color`); **stars mean levels**.

## Rok and the heroes

- Rok: Speed 4, Jump 5, Stamina 4, Power 2, Armor 2 (`Dinos.ROK_STATS`); Nira and Boro in `HERO_STATS` (see [heroes](heroes.md)).
- `Dinos.known(id)` is true for them; `category_of` is "rok", no tier ("Hero"), cap 10 in everything.
- A levelled hero gets `form_data` (slot ROK): Speed above 4 slowly gains on the hunter, Stamina boosts amber, Armor softens hits. His drain stays 0.
- Gear and equipped dinosaur cards add to a hero's attributes (see [weapons-and-armor](weapons-and-armor.md)).

**Speed labels** (`Dinos.speed_label`): Slow / Steady / Quick / Fast / Blazing. `Forms.DATA` speed matches the roster (Rok 4 = the hunter's pace, Raptor 5, Triceratops 3, Spinosaurus 1, Pteranodon 5). The Field Guide shows form cards on 5 pips, species pages on 10.

## Cooldowns

The user's rules: cooldowns count **from the press**, and attributes shorten them.

| Action | Base | Shortened by |
|---|---|---|
| ATTACK | `ATTACK_COOLDOWN` 1.8 s | Power |
| Slide | `SLIDE_COOLDOWN` 2.2 s (the slide itself takes ~1 s) | Speed |
| Jump | none (`JUMP_COOLDOWN` 0, the user's call) | Jump (if ever above 0) |

- `cooldown_mult` = 1 − `COOLDOWN_CUT_PER_POINT` (0.04) × the attribute: 40% off at 10, never below half. Levels, gear and cards all shorten them. `Dinos.perks` lists both times.
- The jump hook stays: above 0, a ground jump would wait that long × `cooldown_mult(id, "jump")` after landing (`Player.jump_cd`), keeping the tap in the jump buffer.
- **Display**: every action button shows its wait (`TouchButton.cooldown` share and `cooldown_left`): a dark wedge unwinding clockwise from 12 o'clock with a timer ("0.6") in the middle.

## Open items

- The user plans to supply a cooldown animation: play it stretched to each cooldown's length (`*_cd_max`) in place of the wedge, keeping the timer.
