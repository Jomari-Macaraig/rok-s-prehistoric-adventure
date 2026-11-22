# Dinosaurs (the expansion roster)

The 28 expansion dinosaurs: categories and tiers, how they go on sale, and how
an owned one replaces a button's dinosaur.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/dinos.gd` (`Dinos`), `forms.gd` (`Forms.equipped`, `get_data`), `main.equip` / `unequip` / `equipped_in` |
| Data and art | `assets/dinos/dinos.json` and `assets/characters/<id>/` (`tools/prepare_dinos.gd`; crouches via `tools/prepare_animation_pack.gd`) |
| Prices and sale | `[market]`, `[market_unlocks]`, `[market_badges]` (defaults in `Progression.DEFAULT_PRICES` / `DEFAULT_MARKET_UNLOCK_M`) |
| Saved | `main.dinos_owned`, equipped per category (`SaveData.load/save_dinos_owned`, `load/save_equipped`) |

## The roster

- 28 creatures (21 dinosaurs, 7 pterosaurs): 16 from the Dinosaur Expansion pack, 12 from the Balanced 32-Form Pack.
- With the four playable originals, each of the four categories has exactly 8 (tested).
- Categories, one per dino button: Runner (Raptor's), Smasher (Triceratops's), Tank (Spinosaurus's), Flyer (Pteranodon's). See [attributes](attributes.md).

## Tiers

Each category's 7 expansion dinosaurs: 2 Starter, 2 Skilled, 2 Expert, 1 Legend
(`Dinos.tier(id)`, `tier_label` e.g. "Expert ★★★", `TIER_NAMES`).

| Tier | On sale when | Character |
|---|---|---|
| Starter | just after their button unlocks: Runner 1700/2000, Smasher 2700/3100, Tank 3700/4100, Flyer 4700/5100 m | forgiving all-rounders (stamina or armor) |
| Skilled | distance + the category badge at Bronze | sharper specialists |
| Expert | + Silver | |
| Legend | + Gold | |

- Category badges (`Dinos.CATEGORY_BADGE`): Runner Swift Feet, Smasher Rock Breaker, Tank Iron Hide, Flyer Sky Rider. Playing a category unlocks more of it.
- The tier comes from `[market_badges]` (no separate data). Prices are the user's ladder, cheapest first in on-sale order.
- One goes on sale every 50–2000 m from 1700 to 8650 m (each category's seven shifted with its button when the buttons moved to 1000 m apart).
- Higher tiers are stronger (bigger attribute budgets).

## Playing one

- An owned dinosaur is equipped on its category's button in the **Camp** (`main.equip(id)`, `unequip(cat)`). The Market only sells; an owned card says OWNED / EQUIPPED and points to the Camp.
- The button still unlocks by distance; an equipped dinosaur waits until then.
- `Forms.equipped` (form → species id) is the live state. `Forms.get_data(form)` returns `Dinos.form_data(form, id)` (cached) for an equipped species, else the original `Forms.DATA`, so gameplay code keeps using the five form ids.

**What `form_data` keeps and changes**
- Keeps the button's abilities: breaks, flies, swims, light, score bonus, gates, and its sounds (`sound_id`).
- Takes the species' art, frame size, pivot and hitboxes measured from its art.
- Shifts the numbers by its attributes **relative to the button's original** (see [attributes](attributes.md)).

**Art**
- `SpriteLib.character/death` load the species' sheets with its own frame times.
- Every species has a real painted crouch for its duck.
- Pterosaurs use their fly loop on the ground; Tanks use their run loop to swim.
- `Hud.refresh_form_icons()` swaps button portraits on equip; the Field Guide page describes the equipped species.

## Market cards

- `Dinos.icon(id)` is the first idle frame; `Dinos.frame(id, i)` / `frame_times(id)` give the card loop (frames cut into cached `ImageTexture`s).
- Cards play the loop once on sale (`Market._anims`, `_animate()` swaps the texture) and show a still silhouette while locked.
- Cards show the category badge (in its button's colour), tier, the five attributes out of 10 with the lean highlighted, and `tradeoff` ("Best: Speed · Weakest: Power").
- **Don't use `AnimatedTexture`** here: it ignores `AtlasTexture` regions, and freeing one (when tabs rebuild cards) broke the shared frames, turning cards into white squares.

## Wild dinosaurs and cards

Some species also run at Rok as wild dinosaurs (see [wild-dinosaurs](wild-dinosaurs.md)); bonking one can drop its card (see [weapons-and-armor](weapons-and-armor.md)).
