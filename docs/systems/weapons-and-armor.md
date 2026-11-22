# Weapons, armor and dinosaur cards

Hero gear: the weapon and armor slots, what each item adds, durability and
repair, the Torch and Bow, dinosaur cards, and gear drawn on the hero.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/gear.gd` (`Gear.ITEMS`, `bonus`, `reach`, `wear`, `broken`, `repair_cost`), `scripts/gear_layer.gd` (`GearLayer`), `main.equip_gear` / `wear_weapon` / `repair_gear` / `grant_card` / `_drop_card` / `gear_ready` |
| Prices and sale | defaults in `Gear.ITEMS`; `[market]` / `[market_unlocks]` can override |
| Art | icons `assets/gear/<id>.png` + @2x, `gear_art.json` (grips), `sockets.json` (hand/back per frame), `break_<id>.png` (`tools/prepare_gear.py`) |
| Saved | `main.gear_owned`, `gear_equipped`, `cards`, `gear_wear` (`SaveData.load/save_gear`; `_sync_gear` points `Gear`'s statics at them) |

## Slots

Each hero (Rok, Nira, Boro) has a **Weapon** and an **Armor** slot. Bought in
the Market's Gear tab, equipped at the Camp (`main.equip_gear(hero, slot, id)`).
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
- The Torch is 1300 meat from 3400 m; the Bow 2800 meat from 7400 m. Both are held nearly upright (`upright` in gear_art.json).
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
5. **Repair** at the Camp (`Herd.press_repair`, two taps, `main.repair_gear`): cost = price × `REPAIR_SHARE` (0.5) × the worn share. The Camp shows "Durability n/max" (or BROKEN).

Buying a weapon gives full durability; the Market's text says how many hits it lasts.

## Dinosaur cards

- One per dinosaur (the playable four and the 28 species).
- A card in the **weapon** slot adds `CARD_BONUS[tier]` to its category's lean attribute and reaches `CARD_REACH`. It isn't drawn and has no attack clip.
- **Where they come from** (the user's rule; the Market no longer sells a Card Pack):
  - a wild dinosaur Rok bonks with ATTACK or bowls over in a frenzy drops its own species' card: always the first time ever per species (`seen` "card_<id>"), then `CARD_DROP_CHANCE` (25%) (`main._drop_card`; tests pin it with `card_drop_override`);
  - rare/epic milestone chests (`Chest.REWARDS` "card", `Gear.random_card`).
- A dropped card pops out with a sparkle and a banner and is collected at once.
- A card's icon is its dinosaur's portrait.

## Gear on the hero

`gear_layer.gd` (the user's plan: equipment as separate layers, not new hero art).

- A child of the hero's sprite with `hero` set (`Player._apply_form` sets it in human form, "" as a dinosaur; the Camp, Market and Field Guide heroes have one named `Gear`).
- Each frame it puts the weapon's grip on that frame's front-hand socket, tilted by `CLIP_ANGLE` plus the weapon's own angle (the sling hangs straight), and the Shell Plate on the back socket.
- Both draw behind the body (`show_behind_parent`), so the fist covers the handle.
- Hidden outside hero clips (death hop, reactions, attack clips), for cards, and for armor without body art.
- It notices equipment changes itself.

## Open items

- Hide Vest, Scale Mail and Bone Guards need per-frame overlay sheets fitted to each hero's clips (4×2, the hero's canvas and pivot, armor only on transparent).
- The retired Card Pack still has code paths (`Gear.CARD_PACK`).
