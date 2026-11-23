# Crafting, materials, rarity and the Items screen

Weapons and armor are never bought (the user's design). They are **crafted** at the **Crafting Bench** from **materials** found in runs, and the basic materials can also be bought in the Market. Each craft rolls a **rarity**. The **Items** screen shows everything you own.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Config | **`config/crafting.cfg`**: when the bench opens, the materials, Market bundles, recipes, rarity odds and multipliers, catalysts, salvage, repair, and every drop table. Read by `Crafting._load()`. `Crafting.DEFAULTS` is the fallback if the file or a section is missing (it holds the original 12 materials; the file's `[materials]`, `[recipes]` and `[catalysts]` replace it whole). |
| Code | `scripts/crafting.gd` (`Crafting`: config, odds, rolls, salvage and repair costs, drop tables, material icons), `scripts/workshop.gd` (`Workshop`: the Bench and Items screens), `main.craft` / `can_craft` / `salvage` / `grant_materials` / `bench_open` / `_break_materials` / `_wild_materials` / `_drop_materials`, `Gear` (copies and rarity) |
| When a recipe is learned | `[unlock] bench_m` (500 m) opens the bench. Each recipe is learned at its item's `[market_unlocks]` distance in `config/progression.cfg`, and never before the bench opens (`Crafting.learn_m`). |
| Saved | in the gear save (`SaveData.save_gear`): `materials`, `rarity` (copy id to rarity), `next` (the next copy number), plus the existing `owned`, `equipped`, `wear` and `cards` |
| Tests | the crafting block in `run_tests.gd` `_feedback_checks` |

## Gear copies and rarity

- Every craft makes its own **copy**. Its id is the item id plus `#n` (`stone_axe#3`), and `Gear.base(id)` gives the item id back. Art, attack clips, running attacks, sockets and recipes all use the base id. Owned lists, equipped slots, wear and rarity use the copy id.
- Gear from old saves has no `#` and counts as Common, so no save migration is needed.
- Rarity runs 0 Common, 1 Uncommon, 2 Rare, 3 Epic, 4 Legendary (`[rarity] names`).
  - `Gear.item_bonus` multiplies the item's **positive** bonuses by `bonus_mult`, rounded to 0.1. Drawbacks such as the Bone Hammer's −0.5 Speed stay the same.
  - `Gear.max_durability` multiplies durability by `durability_mult`.
- `Gear.full_name` gives a name like "Epic Stone Axe". Common items show just their name.
- Tiles and names use the rarity colours (`Crafting.RARITY_COLOR`): grey, green, blue, purple, gold.

## Crafting

`main.can_craft(item, catalyst)` is true when the bench is open, the recipe is learned, and you have its materials plus one of the catalyst.

`main.craft(item, catalyst, roll)` then:
1. spends the recipe and the catalyst,
2. rolls the rarity (`Crafting.roll_rarity`: the `[rarity] chances` weights, or the catalyst's own weights from `[catalysts]`),
3. adds the new copy. Tests pass `roll` to pin the rarity.

## Salvage and repair

- **Salvage** (`main.salvage`): break down an unequipped copy for `[salvage] share` of its recipe (rounded down), plus `[salvage] bonus[rarity]` (a catalyst for Rare and better).
- **Repair** (`main.repair_gear`): costs materials instead of meat. `Gear.repair_cost` returns a materials dictionary: `[repair] share` of the recipe, scaled by how worn the weapon is, and at least 1 of the recipe's first material.

## The 45 materials
The 12 used by recipes today (Wood, Stone, Fiber, Flint, Hide, Bone, Resin, Dino Scale, Obsidian, Shell, Fossil Shard, Primal Crystal) plus 33 added for the coming weapons, armor and accessories. No recipe uses the added ones yet; they're found and kept.
- **Common:** Fern Frond, Mushroom Cap, Moss, Sandstone, Cactus Spine, Basalt, Ash, Feather.
- **Uncommon:** Clay, Wild Berries, Ochre, Sulfur, Ember Coal, Sinew, Claw, Eggshell, Stampede Dust.
- **Rare:** Bleached Skull, Horn, Back Plate, Tail Club Knob, Wing Membrane, Golden Dust, Storm Glass, Fog Pearl.
- **Epic:** Fire Opal, T-rex Tooth, Carnotaurus Horn, Allosaurus Claw, Meteorite Iron, Eclipse Shard.
- **Legendary:** Insect in Amber, Star Metal.

Each one's `from` text (shown on the Items screen) says where it drops. The tests check that every material has at least one source.

## Where materials come from

All drops go straight into the bank (`grant_materials`). Materials found during a run are also counted in `run_materials`, and the summary's news lists them ("Found 3 Wood, 1 Flint"). Materials keep dropping before the bench opens, so you have some ready when it does.

| Source | Code | Config |
|---|---|---|
| Broken obstacles: logs and fences (wood), vines and thorns (fiber; Forest adds fern fronds, Desert gives cactus spines), mushrooms (mushroom caps), rocks by zone (Forest stone and flint, Desert sandstone and flint, Volcanic basalt, obsidian and sulfur), meteors (obsidian, Meteorite Iron, a little Star Metal). A `<kind>_<zone>` table is used when it exists. | `_smash` → `_break_materials` (`Crafting.break_table`) | `[break_drops]` |
| Bonked or bowled-over wild dinosaurs: the land or flyer table plus the species' own parts (Gallimimus feathers, Kentrosaurus back plates, pterosaur wing membranes) | `_drop_card` callers → `_wild_materials` (`Crafting.wild_table`) | `[wild_drops]` (`species`) |
| Escaping a hunter's charge: its trophy (T-rex Tooth, Carnotaurus Horn, Allosaurus Claw), by chance | `_charge_step` → `_charge_trophy` | `[trophies]` |
| Events and lap twists: while one runs, material spots can roll its table (Golden Hour → Golden Dust, Meteor Shower → Meteorite Iron, Amber Storm → Resin and a rare Insect in Amber, Stampede → Stampede Dust, storm/fog/eclipse laps → Storm Glass, Fog Pearl, Eclipse Shard) | main sets `course.specials` each frame → `Crafting.spot_table` | `[spots]` `special_chance` + one table per event/twist |
| Material reward spots. Their contents depend on the zone, and deep in a run some spots roll the `deep` table instead. | `Course._spot_kind` "material" → `_fill` → `m_<id>` pickups (`Pickup` shows `Crafting.icon`) | `[spots]` (rolled after hearts, fossils and power-ups) |
| Milestone chests: a "materials" reward for each chest rarity | `_open_chest` | `[chests]` |
| Rare fossils (each also gives Fossil Shards) | the fossil pickup | `[fossils] shards` |
| The Market: a bundle of a basic material (`mat_<id>`, Gear tab, bought again and again; never on sale before the bench opens) | `Market.items` / `main.buy` | `[materials] price / unlock_m`, `[market] bundle` |

Run drops are **rare** (the user's rule): low chances (a broken obstacle 15%, a wild dinosaur 30%, 5% of reward spots), and every drop table is weighted by **drop rarity** (`[drop_rarity] weights` by the material's rarity, default 1 / 0.45 / 0.15 / 0.05 / 0.015 for Common .. Legendary; `Crafting.drop_pick` / `rarity_weighted`), so rare materials turn up far less often than common ones in the same table. Chests use it too.

`mat_drop_override` (tests) pins the drop rolls.

## Screens (`Workshop`, one script, two modes)

Both open from the **Camp's header**, which has Crafting and Items buttons (`main.open_bench` / `open_items`). The title screen's side columns have no room for more buttons. Until the bench opens, the Crafting button is disabled and shows "Crafting · 500 m", and the news announces it when it opens.

Both screens are the user's **Crafting and Items kit** (`../Assets/Rok_Crafting_Items_Kit/Rok_Crafting_Items_Asset_Pack`, imported by `tools/prepare_workshop.py` into `assets/workshop/`), laid out as in the user's approved references (`references/crafting_approved.png` and `items_approved.png` in the kit). Everything is placed on the kit's **1536 × 864 design canvas** (`Workshop.canvas`), which `_layout` scales to fit the screen and centres (a wide phone shows the jungle background either side). The scene: Kora the Craftkeeper (idle loop; craft, present and wave one-shots; the craft-success sparkle bursts on her craft clip's impact frame, `workshop.json`), the campfire (animated flame on the firepit base), the tool rack, and the workbench (rear and front layers, Kora between them) on the Bench or the open storage chest on Items. UI pieces are the kit's: parchment and inventory panels (9-slice), the title sign, teal (selected) and brown tabs, rarity card frames (Common … Legendary, plus a gold "selected" frame drawn behind the rarity frame), the green CRAFT and amber SALVAGE buttons, the stat icons (power, reach, durability) and the durability track and fill.

- **Crafting Bench** (`mode "bench"`).
  - Tabs: Weapons, Armor, under the bench.
  - Shelf (bottom): the recipes in learn order. A locked recipe shows a padlock and its distance; a craftable one shows "● Ready", otherwise "Need materials".
  - Parchment (top right): the picture, name and COMMON pill, the stat row, the description, MATERIALS (have/need per material card, green with a check when you have enough, red when short), CATALYST · BETTER ODDS (None and each catalyst with its count; disabled without one), the odds for each rarity in its colour, and **CRAFT** (one tap arms it as "SURE?", the second crafts). After a craft Kora swings her mallet and the result line ("UNCOMMON STONE AXE!") shows in the rarity colour.
- **Items** (`mode "items"`).
  - Tabs: Materials (×count), Weapons, Armor, Cards. The grid scrolls in the inventory panel; tiles use the rarity frame of the material or copy.
  - Parchment for a material: name, picture, rarity pill, "You have N", "Found by" and "Used for" (which recipes use it, or that it's a catalyst).
  - For gear: full name and rarity, picture, bonus, reach and durability with a bar, the description, who has it equipped, and for unequipped copies **SALVAGE** (two taps) with what it RETURNS.
  - For a card: the card art, its bonus, reach and count, and where it drops.
- **Kora talks** (the user's request, like Ugo and Elder Numa): a cream speech bubble in the free space beside her head, its tail at her face (`kora_say`, `KORA_LINES`: a pool per situation, at least five lines each, never the same line twice in a row, with the shared mumble at `Tuning.KORA_PITCH`). She greets you (bench, items, or an empty chest), comments on what you pick (ready to craft, short of materials, not learned yet with the distance, a material, gear, a card), cheers a craft (louder for Rare and up, astonished for a Legendary) and a salvage. Her name is on the scene kit's wooden plank (`kora_plate`, the same wood as Numa's and Ugo's); the bench's and chest's plaque just says "Craftkeeper".
- Text on the parchment wraps inside its inner area (`Workshop._para` turns wrapping on before it sets the size, so a label can't grow into one long line); the test "a material's details stay inside the parchment" checks it.

The Camp still equips gear. Its Change list shows each copy by full name in its rarity colour, sorted by item and then rarest first.

## Art still to come
- Material icons: all 45 are the user's art (`tools/prepare_materials.py` → `assets/materials/`); a material without one falls back to a code-drawn lump on a rarity ring (`Crafting.icon`).
- An Armor stat icon in the kit's style (armor uses the power icon today).
- Title plaques with "Crafting Bench" and "Items" baked in (the kit's blank title sign with text is used).
