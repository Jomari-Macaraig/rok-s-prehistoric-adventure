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

## Milestones

Levels change how a form plays (campaign build ticket
[04](../wayfinder/campaign-build/04-milestones-evolution-raptor.md)). At levels
**3, 5, 8, 13, 15 and 18** a dinosaur learns a **Trick** (something new its form
can do) or a **Trait** (always on); at **10 and 20** it **evolves**.

| | |
|---|---|
| Config | **`config/milestones.cfg`**: `[levels] milestones / evolutions`, `[species.<id>]` level = milestone id, `[milestone.<id>]` name, kind (trick/trait), text, `value` |
| Code | `scripts/milestones.gd` (`Milestones.of`, `knows`, `gained`, `stage_at`/`stage`, `value`), effects in `main.gd` and `Dinos.form_data` |
| Saved | nothing: it all comes from the level (XP) |

**Evolution** (`Dinos._pts_at`): at level 10, +1 to every attribute (within its
caps); at 20, +1 again and the best attribute may go 1 past its cap (the
Raptor's Speed reaches 7). Heroes don't evolve. Until evolved art exists the
form glows (`Player.evo_tint`: gold after the first, violet after the second;
hit flashes and the level-up burst fade back to it).

All four originals are built (tickets 04–06), and the expansion dinosaurs inherit theirs.

**Expansion dinosaurs** (`Milestones.of`): each follows its category's original
(Runner = Raptor, Smasher = Triceratops, Tank = Spinosaurus, Flyer =
Pteranodon), except level 8, its own **Signature Trick**, written when that
dinosaur gets its Trail (`config/milestones.cfg` `[signature]` <id> = milestone
id, plus its `[milestone.*]` and code). Until then it has no level 8 milestone.
The effects check the species running (`player.data().id`), so an equipped
Gallimimus at level 5 gets Double Dash.

**The Raptor**:

| Lv | Milestone | In the game |
|---|---|---|
| 3 | Trait **Quick Start** | shifting in starts a 1 s burst gaining 60 px/s on the hunter (`_shift`, `_milestone_step`) |
| 5 | Trick **Double Dash** | ATTACK in the air: +30 px chase gap and the fall stops, once a jump (recharges on landing) |
| 8 | Trait **Light Step** | quicksand sinks it at half the rate (`_check_quicksand`). The spec's "crumbling ledges" part doesn't apply: the Raptor is light and never crumbles bridges |
| 13 | Trick **Pounce** | an ATTACK bonk on a wild dinosaur bounces it up like a free jump (`_attack_hit`) |
| 15 | Trait **Pack Instinct** | its ×2 score becomes ×2.5 (`form_data` `score_mult`) |
| 18 | Trick **Triple Jump** | +1 air jump (`form_data` `air_jumps`) |

**The Triceratops** (ticket 05):

| Lv | Milestone | In the game |
|---|---|---|
| 3 | Trait **Thick Skull** | small rocks always break on contact, no Power roll (`_collide`); logs are in its breaks already |
| 5 | Trick **Charge** | hold ATTACK 0.35 s: 1.5 s smashing through everything its ATTACK could break (not tall fences), 6 s cooldown (`_milestone_step`, `start_charge`, `_collide`) |
| 8 | Trait **Wide Horns** | a successful ATTACK also breaks the next obstacle within 220 px behind the target (`_wide_horns`) |
| 13 | Trick **Stomp** | landing breaks small hazards up to 180 px ahead (`_stomp`) |
| 15 | Trait **Unstoppable** | each smash adds 5 px of chase gap. (The spec said "smashing never slows it", but smashing never slowed anyone, so it gains instead.) |
| 18 | Trick **Earthshaker** | Charge also breaks tall fences. (The spec said walls, but the Triceratops already crumbles walls by running into them.) |

**The Spinosaurus** (ticket 05):

| Lv | Milestone | In the game |
|---|---|---|
| 3 | Trait **Deep Diver** | world pace × 1.12 while swimming |
| 5 | Trick **Tail Sweep** | ATTACK also clears thorns and wild dinosaurs from 140 px behind to just past its reach (`_tail_sweep`) |
| 8 | Trait **Regrowing Scales** | a broken shield comes back 10 s later, once per shapeshift |
| 13 | Trick **Sail Brace** | pressing SLIDE braces: the next hit within 1 s is free, 6 s cooldown (`_press_slide`) |
| 15 | Trait **River King** | +40 px/s of chase gap while swimming |
| 18 | Trick **Double Shield** | each shapeshift starts with 2 shields (`form_data` `armor`) |

**The Pteranodon** (ticket 06):

| Lv | Milestone | In the game |
|---|---|---|
| 3 | Trait **Updraft** | glides fall at 0.7× `GLIDE_FALL` (`Player._fly`) |
| 5 | Trick **Dive** | SLIDE in the air dives at 1.35× fast-fall and gains 20 px on the hunter (`_press_slide`). (Every form already slams down on SLIDE in the air; the gain and steeper angle are what's new.) |
| 8 | Trait **Soft Landing** | landing from a dive gives 0.6 s of invulnerability, so it can't stumble (`player.landed`) |
| 13 | Trick **Wing Buffet** | ATTACK in the air knocks flying wild dinosaurs (swoopers) within 320 px away (`_wing_buffet`) |
| 15 | Trait **Thermal Rider** | PRIMAL drains at 0.8× while climbing |
| 18 | Trick **Barrel Roll** | a double tap of JUMP in the air: 0.6 s when swoopers pass through, 4 s cooldown (`_press_jump`, `start_roll`, `_collide`) |

**Shown**: a new milestone or evolution floats "NEW: Raptor learned Double
Dash" mid-run, is run news, and gets a green **NEW** card on the summary
(`main.run_milestones`, `RunSummary` `MilestoneCard`). The Camp's **Level Path** shows them all ([camp](camp.md#level-path-dinosaur-tabs)).

## Market cards

- `Dinos.icon(id)` is the first idle frame; `Dinos.frame(id, i)` / `frame_times(id)` give the card loop (frames cut into cached `ImageTexture`s).
- Cards play the loop once on sale (`Market._anims`, `_animate()` swaps the texture) and show a still silhouette while locked.
- Cards show the category badge (in its button's colour), tier, the five attributes out of 10 with the lean highlighted, and `tradeoff` ("Best: Speed · Weakest: Power").
- **Don't use `AnimatedTexture`** here: it ignores `AtlasTexture` regions, and freeing one (when tabs rebuild cards) broke the shared frames, turning cards into white squares.

## Wild dinosaurs and cards

Some species also run at Rok as wild dinosaurs (see [wild-dinosaurs](wild-dinosaurs.md)); bonking one can drop its card (see [weapons-and-armor](weapons-and-armor.md)).
