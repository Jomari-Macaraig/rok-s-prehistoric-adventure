# To do

The running list of open work, so nothing gets lost between sessions. **Keep it current:** tick or remove an item when it's done (in the same commit), and add new requests as they come. The detailed art specs live in [tools/CLAUDE.md](../tools/CLAUDE.md) ("Placeholder art"), [NEW_ITEM_ART.md](NEW_ITEM_ART.md) and [ITEM_ART_PLAN.md](ITEM_ART_PLAN.md).

## Code (Claude)

- [ ] **Wild-dinosaur defeats** (the user's design): stomp some wild dinosaurs by landing on top of them, charge through with horns (Triceratops-type Power), and run through them based on damage, all driven by attributes (Power, Armor, Jump, Speed). Today a wild dinosaur trips Rok unless he bonks it with ATTACK or bowls it over in a frenzy ([wild-dinosaurs](systems/wild-dinosaurs.md)). **Waiting on two answers:** which species can be stomped, and whether stomping bounces Rok.
- [ ] **Accessories** (the user's request, 2026-11-23): a third gear slot on each hero for an accessory (necklace, charm, totem, ring...). To build: the slot at the Camp (Change beside Accessory), save data, the Items screen's Accessories tab, recipes at the Crafting Bench from the new materials, durability/repair and selling like other gear (or decide that accessories don't wear), Encyclopedia page and Crafting tour mention, and a small picture on the hero's chest point or none (docs/ITEM_ART_PLAN.md). Needs from the user: the list of accessories and what each does (attributes or a special effect such as more amber, a longer power-up, a magnet), and their icons (square, transparent, like the gear icons).
- [ ] **Item system step 0 leftovers** ([ITEM_ART_PLAN.md](ITEM_ART_PLAN.md)): the accessory slot (Camp slot, Items tab, save data) and an armor `kind` setting (body or rigid, plus the anchor for rigid armor: head, chest or back).
- [ ] **Make the remaining stats configurable:** `Forms.DATA`, heroes, critters (wild dinosaurs), power-up timings.
- [ ] **Recipes for the 33 new materials:** waiting on new weapons, armor and accessories to use them.
- [ ] **Sounds:** a "rawr", and an "uh-oh" (must be a real recording from the user).
- [ ] **Wire in art as it arrives** (see the art list below).

## Decisions (the user)

- [ ] **Campaign mode**: being planned on a wayfinding map, [docs/wayfinder/campaign/MAP.md](wayfinder/campaign/MAP.md) (decide first, then build).

- [ ] **Pet system** (the user's vision, see [GAME_DESIGN.md](GAME_DESIGN.md)): pets hatch from eggs (the Dino Egg art is kept for it), need care, age through stages and die, breed with traits passed to offspring, and fight turn-based card battles (each dinosaur's attack cards come from its traits) against a bot, PVP later. Breeding only within the same species, at most 8 times per dinosaur; more species are coming. Notes only: the user will discuss it later.
- [ ] **Stomps:** which wild species are stompable, and does a stomp bounce Rok?

## Art (the user)

- [ ] **Rok's Fist and Shoot standing styles, fresh redraws** (the consistency update ships them as the old art scaled to his run's size; same 4×2, 384×512 cells, feet at y 488, guides and landmarks): drop them in `Rok_Animation_Consistency_Update 3/rok/standing/` and rerun `prepare_styles.py`.
- [ ] **Optional: Nira's and Boro's running style attacks redrawn over their in-game run** (`Rok_New_Heroes_Nira_Boro/<hero>/spritesheets/run.png`): their packs used a different, ~10% taller run, so the game fits them; legs only match exactly for Rok.
- [ ] **A Missions scene** (the user's plan): a full screen like the Market and Camp for the daily and weekly missions (a backdrop, a board or scroll for the two lists with room for 3 + 3 missions, progress bars, a reward/streak plaque, a title plaque "MISSIONS"). Today a dark panel in the middle of the main menu stands in (`Hud.missions_panel`).
- [ ] **Boss clips** (for campaign boss stages, when they're built; see docs/wayfinder/campaign/01-boss-stages.md): per boss dinosaur a 4x2 sheet each for running ahead of Rok (facing right), a wind-up per attack (kick a rock back, tail sweep, roar shockwave, backward charge), getting hurt, and being defeated; same canvas and pivot as its run. Until then: its existing clips with a flash and shake.
- [ ] **UI: a Crafting button** in the square menu-button style (`Rok_Square_Buttons/png_256/button_crafting_square.png`, a hammer and anvil or Kora's bench); drawn in code until then.
- [ ] **UI: a Settings button** (cog) in the round top-left button style; a cog is drawn in code until then.
- [ ] **UI: a Missions button** in the square menu-button style (`Rok_Square_Buttons/png_256/button_missions_square.png`, a scroll or checklist icon, no text; `prepare_menu_buttons.py` copies it to `assets/ui/square_missions.png`). A scroll is drawn in code until then.
- [ ] **UI:** an Armor stat icon (kit glyph style); "Crafting Bench", "Items" and "DINOSAUR CAMP" title plaques.
- [ ] **Card art** for the 12 balanced-pack dinosaurs (Deinonychus … Dsungaripterus).
- [ ] **Attacks** for those 12 dinosaurs.
- [ ] **Break-by-material sheets:** wood, stone, bone, obsidian, metal, cord.
- [ ] **Optional: a Blaze Pepper idle loop** (it bobs as a still picture today).
- [ ] **Long-run items:** the fossil pickup and the bonus-zone portal (drawn in code today).
- [ ] **Body-armor patterns** (Hide Vest, Bone Guards, Scale Mail), once the outfit shader is built.

## Canyon follow-ups

- [ ] Canyon break animations (its obstacles vanish in a puff today): boulder, wall block, barricade, rock spikes, pillar, cactus, tumble-thorn (4×2, frame 2 the impact).
- [ ] Canyon's own hunter, wild dinosaurs and music (it borrows the Desert's for now).

## Unused art

- The Dino Egg power-up art (`assets/powerups/dino_egg*`, `Rok_Powerups`): the Blaze Pepper replaced it as the speed boost (2026-11-23); eggs are for the pet system (see Decisions).

- The tutorial vine pieces in `Rok_Polished_Assets` (imported, not placed anywhere yet).

## Done recently

- 2026-11-23: REPAIR on Kora's Items screen too.
- 2026-11-23: a Crafting button on the main menu (the tour points at it).
- 2026-11-23: the Encyclopedia's Weapons, Armor and Card Slots pages, and the Crafting tour's equipment step.
- 2026-11-23: Settings (sound and music volumes); armor durability and repair; selling in the Market at 80% (`config/economy.cfg`).
- 2026-11-23: a Missions button with daily and weekly missions (`config/missions.cfg`); one font (Baloo 2) everywhere; the Encyclopedia lists drops (from the config) and how to unlock locked entries; a Crafting tour after the run that opens the bench; Canyon rock drops fixed.
- 2026-11-23: rarer cards and chests (higher tiers rarer, `[cards]`, `[chests] appear`); the Canyon arch's legs in front of Rok; wild dinosaurs follow the ground and hop pits; the main screen resets hearts, energy and cooldowns after a run.
- 2026-11-23: dinosaur cards are slotted into weapons (`[card_slots]`, a slot can stay empty), not equipped.
- 2026-11-23: damage tiers per obstacle (`config/damage.cfg`; pits, liquids, quicksand and gates stay instant); a NEW banner per obstacle look (`config/obstacle_looks.cfg`), two banners at once; PRIMAL energy explained (Field Guide page, first-dino card, tiring banner, tutorial note).
- 2026-11-23: Rok's size made consistent: idle, walk, duck, trip, dizzy, snag and the 5 standing styles from the user's consistency update (redrawn at his run's size), his per-weapon clips and gear sockets refitted.
- 2026-11-23: the Blaze Pepper replaced the Dino Egg as the speed-boost power-up (id `pepper`; old saves renamed on load).
- 2026-11-23: Desert and Volcanic biome obstacles with breaks, Forest twig and mushroom breaks; all five attack styles for Rok, Nira and Boro, standing and running (bare hands = Fist); the Canyon zone (4th, from the user's canyon pack; timeline probe: every zone lesson lands in its zone); Point Hunter and Seasoned medals; day/night icon on the HUD; chest rarities; bug-proof tutorial; Kora's lines and name plank; Ugo's name plank; Camp meat counter hidden; Rok's Swing pilot (approved); [NEW_ITEM_ART.md](NEW_ITEM_ART.md).
