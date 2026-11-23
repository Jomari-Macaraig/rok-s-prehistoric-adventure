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

## The scene kit look

With the user's Encyclopedia / Dinosaurs scene kit (`../Assets/Rok_Scene_Polish_Assets`, imported by `tools/prepare_scene_kit.py` into `assets/scenes/`; shared helpers in `scripts/scene_kit.gd`, `SceneKit`) the screen follows the kit's concept:

- the painted archive cave as the backdrop (still named `Backdrop`), Elder Numa standing at the left with her name plate (the drawn cave, Elder and the hero are hidden);
- **Elder Numa speaks** (the user's request; her animations come later): a speech bubble above her head (`numa_bubble`, `_place_numa`: sized to the line, she stands a little shorter so it never covers her) with a line from `Codex.NUMA_LINES`. She greets you on opening, has her own words for each tab (`tab_0`..`tab_6`), and a line for a NEW entry, a discovered one ("Ah, the %s. Listen...") and a locked one. Each pool has at least five lines and never repeats the last. She is **animated** with the user's clips (`../Assets/Rok_Elder_Nuna_Animations`, imported by `tools/prepare_elder.py` into `assets/scenes/elder/`): the idle loop plays all the time, `wave` when she greets you and `explain` for every other line (`numa_act`), and each one-shot hands back to idle. The animation (`numa_anim`) replaces the still cut-out and is fitted into her spot (`elder` stays as the box; `_place_numa_anim`). The loading screen builds her frames (`Codex.numa_frames`). She murmurs with Ugo's mumble sounds pitched up and softer (`Tuning.NUMA_PITCH`, `NUMA_DB`). Her character: the cave's warm, slightly mischievous old storyteller, fond of proverbs and the old days;
- the stone Back button (icon only, still the header's first node), the ENCYCLOPEDIA plaque (`TitleBanner`), the discovered count on the counter plate;
- the open book in place of the speech bubble, kept to its shape and right-aligned: the left page (`LeftPage`) has the entry's name (Baloo 2), a big picture and a DISCOVERED / NOT YET FOUND pill; the right page is the page scroll as before, headed "Field Notes" (the `Says` label), with the entry's page minus its own picture, name row and frame, every label wrapped to the page (`_wrap_to_page`; a row's leading labels keep their word). Arrows on the book step to the previous / next entry;
- the wooden roster frame behind the shelf, the kit's tabs (teal when chosen), the kit's cards (normal / selected / locked) with the orange NEW badge top right, the check top left on the chosen card and a padlock on locked ones; arrows at the roster's ends scroll it.

Layout (`_layout_kit`): the kit's 1920×1080 reference scaled by the screen height; the book and roster anchored right and bottom, so a wide phone gets more room in the middle. Without the kit everything falls back to the drawn cave.

## Cards tab

The seventh tab lists every dinosaur card: the four originals, then the 28 expansion species (`Codex._cards_tab`, tiles `Card_<id>`). A card is found once you've had one (`Gear.cards` or `seen` "card_<id>"; they drop from wild dinosaurs and come in rare/epic chests, see [weapons-and-armor](weapons-and-armor.md)). A found card shows on the book's left page as the card itself (`CardView`): the user's card art (`assets/cards/<id>`, `tools/prepare_cards.py`; so far Raptor, Triceratops, Spinosaurus and Pterosaur = Pteranodon) with what it gives a weapon (`Gear.bonus_text`) written on its blank parchment (`cards.json` `text_box`), or for a dinosaur without art yet its portrait on the kit's card with the bonus below. The right page says what it gives the weapon, how many you have and where they come from. A card not found is "???" with where to look. Cards don't count toward "Discovered".
