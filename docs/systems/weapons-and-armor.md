# Weapons, armor and dinosaur cards

Hero gear: the weapon and armor slots, what each item adds, durability and
repair, the Torch and Bow, dinosaur cards, and gear drawn on the hero.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/gear.gd` (`Gear.ITEMS`, `bonus`, `reach`, `wear`, `broken`, `repair_cost`), `scripts/gear_layer.gd` (`GearLayer`), `main.equip_gear` / `wear_weapon` / `repair_gear` / `grant_card` / `_drop_card` / `gear_ready` |
| Getting gear | **crafted, not bought**: recipes, rarity and materials in `config/crafting.cfg`; recipes learned at `[market_unlocks]` (see [crafting](crafting.md)) |
| Art | icons `assets/gear/<id>.png` + @2x, `gear_art.json` (grips), `sockets.json` (hand/back per frame), `break_<id>.png` (`tools/prepare_gear.py`) |
| Saved | `main.gear_owned` (copy ids like `stone_axe#3`), `gear_equipped`, `cards`, `gear_wear`, `gear_rarity`, `gear_next`, `materials` (`SaveData.load/save_gear`; `_sync_gear` points `Gear`'s and `Crafting`'s statics at them) |

## Slots

Each hero (Rok, Nira, Boro) has a **Weapon** and an **Armor** slot. Gear is
**crafted** at the Crafting Bench (each craft is its own copy with a rolled
rarity that multiplies its bonuses and durability; see [crafting](crafting.md)),
and equipped at the Camp (`main.equip_gear(hero, slot, copy_id)`). The tables
below are the Common stats.
A red dot on the Camp button means an owned hero has an empty slot it has gear
for (`gear_ready()`).

## Weapons

| Weapon | Bonus | Reach | Hits | Special |
|---|---|---|---|---|
| Wooden Club | Power +1 | 165 | 30 | |
| Stone Axe | Power +2 | 175 | 40 | |
| Flint Spear | Power +1.5, Speed +1 | 250 | 50 | |
| Bone Hammer | Power +3.5, Speed −0.5 | 170 | 60 | |
| Sling | Power +1, Jump +1 | 340 | 80 | fires a stone |
| Torch | Power +1 | 185 | 45 | **burns** logs, fences, thorns and vines whatever the Power; burns in the hand (8-frame loop) |
| Bow | Power +2 | 460 (longest) | 70 | **ranged**: fires a flint arrow |

- Bare hands: `ATTACK_REACH_HAND`. See [combat](combat.md) for what Power breaks.
- The Torch's recipe is learned at 3400 m, the Bow's at 7400 m. Both are held nearly upright (`upright` in gear_art.json).
- Arrows and stones are cosmetic; the hit is instant.

## Armor

| Armor | Bonus | Shown on the hero |
|---|---|---|
| Hide Vest | Armor +1 | not yet |
| Bone Guards | Armor +2 | not yet |
| Scale Mail | Armor +2.5, Stamina +0.5 | not yet |
| Shell Plate | Armor +3.5, Speed −0.5 | yes (back socket) |

## How bonuses apply

- `Gear.bonus(hero, attr)` feeds `Dinos.stat` for heroes (clamped to 10), so perks, `form_data` and attacks all see it.
- Levelling uses `Dinos.trained_stat` (base + levels), so gear never blocks a level-up.
- Gear shows only in human form; it stays equipped through shapeshifts.

## Durability and repair

The user's design. Armor and cards don't wear.

1. Every ATTACK that connects (smash, bonk or CLANG) costs 1 hit (`_attack_hit` → `wear_weapon`, after that hit's Power is counted).
2. At `WEAR_WARN` (5) hits left, a banner warns.
3. At 0 the weapon is **broken** (`Gear.broken`): its own 8-frame shatter plays in the hand (`GearLayer.play_break`; frame 0 is the intact weapon), the `weapon_break` sound, "SNAP!", a banner and a news line. Any attack clip stops so the shatter shows.
4. Broken: no bonus, bare-hand reach, not drawn, no attack clip. It stays owned and equipped.
5. **Repair** at the Camp (`Herd.press_repair`, two taps, `main.repair_gear`): costs **materials**, `[repair] share` of the recipe × the worn share (`Crafting.repair_cost`). The Camp shows "Durability n/max" (or BROKEN) and the repair cost.

A crafted weapon starts at full durability (its rarity's `durability_mult` × the base hits).

## Dinosaur cards

- One per dinosaur (the playable four and the 28 species).
- **Cards aren't equipped; they're slotted into a weapon** (the user's rule, 2026-11-23). Each weapon has a card slot or not: `config/crafting.cfg` `[card_slots]` (per weapon, `default` for unlisted ones; 0 = none; every weapon has 1 today). A slot can stay empty.
- A slotted card adds `CARD_BONUS[tier]` to its dinosaur's category lean attribute, on top of the weapon's own bonuses, while that weapon is equipped and not broken (`Gear.bonus`). It doesn't change reach and isn't drawn.
- `main.gear_sockets` (saved in the gear save as `sockets`; `Gear.sockets`) maps a weapon copy to its card's dinosaur. A card in a weapon is used up until it's taken out (`Gear.free_cards`, `card_choices`); the card stays in the weapon when the weapon is unequipped, and salvaging the weapon gives the card back.
- `main.slot_card(weapon, dino)` slots one ("" takes it out). `equip_gear` refuses card ids. Old saves with a card in the weapon slot have it taken out on load (back to the pile).
- Camp: under the weapon row a **Card slot** row (`Herd._card_row`) with Change, which lists Empty, the slotted card and every dinosaur with a free card (`_card_list`). An equipped weapon with an empty card slot and a free card lights the red dot (`gear_ready`). The Items screen's Cards tab lists every card with how many are free.
- **Where they come from** (the user's rule; the Market no longer sells a Card Pack):
  - a wild dinosaur Rok bonks with ATTACK or bowls over in a frenzy **may** drop its own species' card (`main.card_chance`): `config/pickups.cfg` `[cards]` `first_drop_chance` (0.5) the first time ever per species (`seen` "card_<id>"), `drop_chance` (0.08) after that, both × the dinosaur tier's `tier_mult` (the user's rule 2026-11-23: rare, and the higher the tier the lower the chance; `main._drop_card`, tests pin it with `card_drop_override`);
  - rare and better milestone chests, picked by `[chests] reward_weights` (card 0.35 against 1 for the rest); which dinosaur is by `[cards] chest_tier_weights` per tier (higher tiers less often; rare chests only up to Skilled; `Gear.random_card`).
- A dropped card pops out with a sparkle and a banner and is collected at once.
- A card's icon is its dinosaur's portrait.

## Gear on the hero

`gear_layer.gd` (the user's plan: equipment as separate layers, not new hero art).

- A child of the hero's sprite with `hero` set (`Player._apply_form` sets it in human form, "" as a dinosaur; the Camp, Market and Field Guide heroes have one named `Gear`).
- Each frame it puts the weapon's grip on that frame's front-hand socket, tilted by `CLIP_ANGLE` plus the weapon's own angle (the sling hangs straight), and the Shell Plate on the back socket.
- Both draw behind the body (`show_behind_parent`), so the fist covers the handle.
- Hidden outside hero clips (death hop, reactions, attack clips), for cards, and for armor without body art.
- It notices equipment changes itself.

### Attack styles (all heroes, all five styles)
The plan in [ITEM_ART_PLAN.md](../ITEM_ART_PLAN.md): a hero is drawn once per **attack style** with an empty, closed hand, plus a **guide sheet** (grip dot, weapon stick, head, chest and back dots), and the game draws whichever weapon is equipped.
- Each weapon's style is in **`config/crafting.cfg` `[weapon_styles]`** (`Gear.style`): Club, Stone Axe, Bone Hammer and Torch swing; the Spear thrusts, the Sling throws, the Bow shoots. `use_styles` switches the system off, `scale` (and `<id>_scale`) sets how big a weapon is drawn in a style clip (`Gear.style_scale`).
- `Gear.style_clip(hero, weapon)` is `"style_<style>"` when that hero has the clip (`SpriteLib.attack_meta` merges `assets/attacks/styles.json`), else "" and the old clip with the weapon drawn in plays. **Rok, Nira and Boro have all five styles** (Swing, Thrust, Throw, Shoot, Fist), standing and running (`tools/prepare_styles.py`, the user's `<Hero>_Style_Attacks` packs).
- **Bare hands** (no weapon or a broken weapon) is the **Fist** style (`Gear.fist_clip`): a punch, no weapon drawn. The code-drawn lunge and slash only stand in with styles off.
- `main.attack_clip()` returns the style clip. On the ground while running, the **running style** plays (`Player.run_style_play`: the phase sheet for the current run frame, stepped by the run's own frames, legs matching the run; `SpriteLib.running_style`, built only for the equipped weapon's style, the loading screen prepares it). In the air the running style's phase 0 plays on its own clock: the standing clips' upright pose is ~25% taller than the running pose, so swapping to it mid-run looked like Rok grew (the user's report). Standing still, the standing clip plays.
- Throw and Shoot release on frame 4 (the stone or arrow leaves then, `_shoot_arrow`); the guide has no stick after that, so the sling or bow stays in the hand at its last angle.
- `Player.atk_gear` is a `GearLayer` on the attack sprite with `front = true`; Player gives it the guide of the clip showing (`clip_meta`: a standing clip's entry or the running phase's guide). In a style clip (`_place_style`) the weapon's grip sits on the guide's grip point, pointing along the stick (its angle, clockwise from up, plus the weapon's own tilt), drawn **in front** of the body with a small patch of the same frame (`_fist`, `FIST_R` around the grip) redrawn on top, so the fist still wraps the handle. The shell rides the guide's back point, behind the body. A frame without a stick shows no weapon.
- A weapon that breaks mid-swing shatters in that hand (`Player.weapon_break`).

## Open items

- Hide Vest, Scale Mail and Bone Guards need per-frame overlay sheets fitted to each hero's clips (4×2, the hero's canvas and pivot, armor only on transparent).
- The retired Card Pack still has code paths (`Gear.CARD_PACK`).
