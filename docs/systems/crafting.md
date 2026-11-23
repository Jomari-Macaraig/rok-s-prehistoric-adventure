# Crafting, materials, rarity and the Items screen

Weapons and armor are never bought (the user's design). They are **crafted** at the **Crafting Bench** from **materials** found in runs, and the basic materials can also be bought in the Market. Each craft rolls a **rarity**. The **Items** screen shows everything you own.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Config | **`config/crafting.cfg`**: when the bench opens, the materials, Market bundles, recipes, rarity odds and multipliers, catalysts, salvage, repair, and every drop table. Read by `Crafting._load()`. `Crafting.DEFAULTS` mirrors the file and is the fallback for anything missing. |
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

## Where materials come from

All drops go straight into the bank (`grant_materials`). Materials found during a run are also counted in `run_materials`, and the summary's news lists them ("Found 3 Wood, 1 Flint"). Materials keep dropping before the bench opens, so you have some ready when it does.

| Source | Code | Config |
|---|---|---|
| Broken obstacles. Logs and fences drop wood. Vines and thorns drop fiber. Rocks drop by zone (Forest stone, Desert flint, Volcanic obsidian). Meteors drop obsidian. Mushrooms drop nothing. | `_smash` → `_break_materials` (`Crafting.break_table`) | `[break_drops]` |
| Bonked or bowled-over wild dinosaurs (land or flyer table) | `_drop_card` callers → `_wild_materials` | `[wild_drops]` |
| Material reward spots. Their contents depend on the zone, and deep in a run some spots roll the `deep` table instead. | `Course._spot_kind` "material" → `_fill` → `m_<id>` pickups (`Pickup` shows `Crafting.icon`) | `[spots]` (rolled after hearts, fossils and power-ups) |
| Milestone chests: a "materials" reward for each chest rarity | `_open_chest` | `[chests]` |
| Rare fossils (each also gives Fossil Shards) | the fossil pickup | `[fossils] shards` |
| The Market: a bundle of a basic material (`mat_<id>`, Gear tab, bought again and again; never on sale before the bench opens) | `Market.items` / `main.buy` | `[materials] price / unlock_m`, `[market] bundle` |

`mat_drop_override` (tests) pins the drop rolls.

## Screens (`Workshop`, one script, two modes)

Both open from the **Camp's header**, which has Crafting and Items buttons (`main.open_bench` / `open_items`). The title screen's side columns have no room for more buttons. Until the bench opens, the Crafting button is disabled and shows "Crafting · 500 m", and the news announces it when it opens. Both screens use the Camp's scene-kit look: the camp painting under a warm shade, the stats-panel board on the right, the roster shelf along the bottom, and the hero on the left.

- **Crafting Bench** (`mode "bench"`).
  - Tabs: Weapons, Armor.
  - Shelf: the recipes in learn order. A locked recipe shows its distance; a craftable one shows "Ready ●".
  - Board, top to bottom:
    - the name, with the **Craft** button beside it (always in view; one tap arms it, the second crafts),
    - the result line ("EPIC STONE AXE! (+3.5 Power)") after a craft,
    - its Common stats,
    - MATERIALS with have/need for each (green when you have enough, red when short),
    - CATALYST choices (None and each catalyst with its count; disabled when you don't have one),
    - the odds for each rarity,
    - the description.
  - The workbench is drawn in code until the user's art arrives (`assets/scenes/crafting_bench.png`).
- **Items** (`mode "items"`).
  - Tabs: Materials (what you have, ×count), Weapons, Armor, Cards.
  - Board for a material: its rarity, count, "Found by", and which recipes use it.
  - Board for gear: rarity, stats, durability, who has it equipped, and for unequipped copies **Salvage** (two taps) with what it returns.
  - Board for a card: its bonus and count.

The Camp still equips gear. Its Change list shows each copy by full name in its rarity colour, sorted by item and then rarest first.

## Art still to come (placeholders drawn in code)
- `assets/scenes/crafting_bench.png`: a stone workbench with tools, transparent, about 420 × 260 px at 1x, in the scene-kit style.
- `assets/materials/<id>.png` for the 12 materials: square, transparent, about 128 px (with `@2x`), in the gear icons' style.
- Rarity frames for tiles (grey, green, blue, purple, gold) as 9-slice. Until then a coloured border is drawn.
- Title plaques for "Crafting Bench" and "Items". Until then the scene kit's blank plaque is used with text.
