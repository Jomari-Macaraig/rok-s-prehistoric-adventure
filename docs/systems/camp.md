# Dinosaur Camp (levelling and gear screen)

Where the player chooses the hero and the dinosaur on each button, compares
them, levels them up, and equips gear. Players see it as the **Dinosaur Camp**
(the user's name: the title is "DINOSAUR CAMP" on the scene kit's blank plaque,
`SceneKit.text_plaque`, because the kit's own plaque has "DINOSAURS" baked in;
the side button's caption is "Dinosaur Camp"). The code still calls it the
Herd, and docs say "Camp" for short.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Opened from | the **Dinosaurs** side button on the main menu (`main.open_herd(cat)`, `Hud.herd_button`); key H on desktop |
| Code | `scripts/herd.gd` (`Herd`) |
| Related | [leveling](leveling.md), [attributes](attributes.md), [weapons-and-armor](weapons-and-armor.md), [dinosaurs](dinosaurs.md), [heroes](heroes.md) |
| Art | drawn in code until `assets/camp/hut.png` exists |

## The screen

- **Scene** (`_draw_camp`): a hide hut, a campfire and a log; title banner DINOSAURS, sign CAMP. Your hero stands at the left; the chosen dinosaur (or another hero) stands by the hut. It plays its real idle loop (`stage_body`, from `assets/characters/<id>/idle.png`) and every few seconds a random move (`_stage_move`, the user's pick):
- its **attack** clip (`stage_atk`, `_stage_attack`; a hero swings its equipped weapon and has no attack without one),
- a **jump** (its jump clip, plus a hop up and back down),
- a **slide** (its slide clip).

Then it idles again (`Tuning.CAMP_ATTACK_FIRST` / `CAMP_ATTACK_EVERY`). Its feet sit at the bottom of the `stage` box, fitted to it and mirrored to face the hero (`_place_stage`, `stage_info`). Without its art it falls back to a still portrait in `stage`. It's a dark silhouette if not owned.
- **Tabs** (`Herd.tabs()`): Heroes first (Rok, Nira, Boro), then one per category with how many of its 8 you own ("Runner 4/8").
- **Shelf** (`list`): a sideways row of tiles (`_row`): picture, name, tier and level, a tag (EQUIPPED / OWNED / MARKET / LOCKED), and `LevelReady`. Members: the button's original first, then the Market dinosaurs in on-sale order (`Herd.members(cat)`).
- **Board** (`board`, `detail` inside the scrolling `dscroll`): the level-up, compare and gear panel.
- Drags scroll whichever panel they start on; a drag isn't taken as a tap. While it's open `main._input` leaves touches to its GUI.

## Comparing

Tap a tile (`select(id)`) to show it on the board:
- its category, tier and trade-off;
- the five attributes as 10-segment bars **against the equipped one**: shared points brown, gains bright green, points you'd give up light red, the difference beside each (`Delta_<attr>`); part-segments for decimals;
- what its attributes add in play (`Dinos.perks`).

Ones you don't own are silhouettes but can still be compared, with how to get them (Market price or `Market.lock_text`). A note says when the category's button is still locked.

## Equipping

- **Equip** (`press_equip`) puts an owned one on the button; on the original it reads "Use the original" (`main.unequip`).
- Heroes: "Play as …" (see [heroes](heroes.md)).

## Levelling

- Levels come by themselves from XP (see [leveling](leveling.md)); nothing is bought here.
- The detail shows "Lv 7" (`Dinos.level_text`) and an XP bar; a note (`LevelNote`) says how many metres to the next level and what it adds ("Lv 4 in 450 m: +0.4 Speed. The Gallimimus levels up by itself as it runs."; heroes grow no attributes by level). The header's meat counter is hidden for now (the user's call: the Camp doesn't need it; `MeatPouch`, `visible = false`).

## Gear (Heroes tab)

- EQUIPMENT rows (`_gear_rows`): weapon and armor by full name ("Epic Stone Axe") with their bonuses and attack reach, and "Durability n/max" (or BROKEN) with its material repair cost and a **Repair** button (two taps, `press_repair`; disabled without the materials).
- **Change** (`press_slot`) turns the shelf into that slot's choices (`_gear_list`: Nothing, owned copies by item then rarest first, in their rarity colour, with any slotted card named); a tap equips (`press_gear`).
- A weapon with a card slot gets a **Card slot** row under it (`_card_row`): its Change (`press_slot("card")`) lists Empty, the slotted card and the free cards (`_card_list`); a tap slots it (`main.slot_card`). Cards can't go in the weapon slot itself.
- The header has **Crafting** (disabled and showing its distance until the bench opens, `bench_button`) and **Items** buttons, opening the [Crafting Bench and Items screens](crafting.md). Those two are their own full screens (Kora's workshop from the Crafting and Items kit); the back button returns to the Camp.

## Red dots

Where something can be done: `gear_ready()` lights the Camp button (`Hud.set_herd`) and the Heroes tab ("●"). Levels no longer need the Camp, so they light nothing.

## The scene kit look

With the user's scene kit (`SceneKit`, see [field-guide](field-guide.md#the-scene-kit-look)) the Camp follows the kit's Dinosaurs concept: the painted camp (fire, tent, forest) as the backdrop with the drawn camp hidden; the stone Back button, the DINOSAURS plaque and the meat on the counter plate; the detail on the parchment stats panel (at least 560 px wide, its rows need ~440 px inside the frame); the hero you play animated on the left (scaled up) and the chosen dinosaur animated beside him by the tent; the wooden roster with kit tabs and cards, a green EQUIPPED / OWNED pill (orange MARKET), a check on the one equipped and a padlock on locked ones; Equip / Play as in the kit's green button and the other actions in brown (`_kit_buttons`). The kit's static presenter cutouts and stat meters aren't used yet (the animated actors and the existing attribute bars stay).
