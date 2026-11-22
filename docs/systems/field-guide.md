# Field Guide (Encyclopedia)

The in-game encyclopedia: dinosaurs, hazards and terrain, items, power-ups,
zones and badges, with real-world facts about each animal.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Opened from | the **Encyclopedia** side button on the main menu and pause screen (`codex` action); key C on desktop |
| Code | `scripts/codex.gd` (`Codex`), `scripts/dino_facts.gd` (`DinoFacts`) |
| Entry text | `HAZARDS`, `TERRAIN`, `ITEMS` constants in `codex.gd` (`ITEMS` is a `static var` so it can use tuning numbers); facts in `DinoFacts.FACTS` |
| Art | the Elder and his cave are drawn in code until `assets/encyclopedia/elder.png` exists |
| Hazard pictures | `scripts/hazard_icons.gd` (`HazardIcons`), shared with the info cards |

## The screen

- **Scene** (`_draw_elder_cave`): a rocky hill with cave paintings (a dinosaur, hand prints, hunters), a campfire, and the Elder (a cloaked old man with white hair, a beard, a feather and a staff, blinking). Title banner ENCYCLOPEDIA, sign ELDER. Your hero stands at the left.
- **Shelf** (`grid`): a sideways-scrolling row of tiles in stone niches (`_add_entry`: picture, name, NEW). Each tile keeps its full page inside (the old card, node `Card`, hidden), so card builders (`_card`, `_badge_card`, `Badge_<id>`) are unchanged.
- **Page**: `select(i)` shows the chosen page in the Elder's speech bubble (`page`, compacted to fit by `_compact`) after a line from him ("Ah, the T-rex. Listen…" / "That one you have not seen yet…"). Each tab opens on its first entry.
- Drags scroll the shelf sideways and the bubble up and down (`Codex._input` from `InputEventScreenDrag`, with momentum in `_process`; otherwise cards swallow the drag on mobile).

## Hazard pictures

`HazardIcons.icon(key, zid)` draws a hazard in a zone's look, using the same art and tints as `Course` and `Terrain`. The info cards and the Field Guide both use it. (Before, steam vents and Tougher Combos had no picture, and pits, canyons, lava, water, quicksand, rolling boulders and barricades all showed generic props.)

- `ZONE_ICONS` gives a spec per zone: a prop, a path, a cropped trap frame (`trap:<anim>:<frame>`), a liquid strip (`liquid:<anim>`), a pit cut into the zone's ground (`gap:<zone>[:water|lava]`), or the zone's wild dinosaur (`critter:<kind>`), optionally tinted with `@stone`, `@wood` or `@thorn` (`Course.*_TINT`). A hazard missing a zone shows its first zone. Anything not listed uses its `HAZARDS`/`TERRAIN` icon.
- Info cards show the zone Rok is in (`main._intro_icon`).
- A Field Guide page's main picture is the zone where it's first met (`Progression.intro_m`), and hazards that differ by zone get a "ZoneLooks" row with each zone's version and its name (`Codex._zone_looks`, passed to `_card` as `extra`).
- Built images are cached (`HazardIcons._cache`).

## Tabs and what's revealed

| Tab | Entries | Revealed when |
|---|---|---|
| Dinosaurs | Rok, the four forms (with Speed, Jump, Energy pips, `dino_stats()`), the 28 species, the zone hunters | forms once unlocked; species once bought (`species_owned`); hunters once met |
| Hazards & Terrain | every hazard, trap and gate; terrain (floating islands always known) | once taught (`Progression.taught()`) |
| Items | amber, meat, big meat, rare fossil, milestone chest, heart, combo & Primal Frenzy | once met |
| Power-Ups | every `Boosters.DATA` entry | owned ones normally; others greyed with their Market price and "(on sale from N m)" |
| Zones | each zone, plus Day & Night | once reached |
| Badges | every badge (see [goals](goals.md)) | always, with progress |

- Not yet revealed: a dark silhouette marked "???" with its unlock or discovery distance.
- **NEW**: entries discovered since the guide was last opened. Viewed ids are saved; `has_new()` drives the red dot on the button.

## Real-world facts

`dino_facts.gd`, so the guide doubles as learning material.

- Covers the four forms, Rok, the T-rex and all 28 expansion dinosaurs. The four form cards always describe the original dinosaurs (`Forms.DATA`).
- Each entry (`DinoFacts.FACTS`, keyed by id plus `trex`): `heading`, `what`, `era`, `where`, `size`, `ate`, a longer `fact`, and a one-line `quiz`. `text(id)` formats the basics.
- Shown as a facts panel at the end of unlocked cards (`_facts_box`, node `Facts`); locked cards don't show facts.
- The dino-unlock info card adds the `quiz` line as "Did you know?".
- Figures are typical published estimates. The text points out that the Pteranodon was a pterosaur (not a dinosaur), the real Velociraptor was turkey-sized and feathered, and people never lived alongside dinosaurs.
