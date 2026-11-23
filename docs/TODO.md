# To do

The running list of open work, so nothing gets lost between sessions. **Keep it current:** tick or remove an item when it's done (in the same commit), and add new requests as they come. The detailed art specs live in [tools/CLAUDE.md](../tools/CLAUDE.md) ("Placeholder art"), [NEW_ITEM_ART.md](NEW_ITEM_ART.md) and [ITEM_ART_PLAN.md](ITEM_ART_PLAN.md).

## Code (Claude)

- [ ] **Wild-dinosaur defeats** (the user's design): stomp some wild dinosaurs by landing on top of them, charge through with horns (Triceratops-type Power), and run through them based on damage, all driven by attributes (Power, Armor, Jump, Speed). Today a wild dinosaur trips Rok unless he bonks it with ATTACK or bowls it over in a frenzy ([wild-dinosaurs](systems/wild-dinosaurs.md)). **Waiting on two answers:** which species can be stomped, and whether stomping bounces Rok.
- [ ] **Item system step 0 leftovers** ([ITEM_ART_PLAN.md](ITEM_ART_PLAN.md)): the accessory slot (Camp slot, Items tab, save data) and an armor `kind` setting (body or rigid, plus the anchor for rigid armor: head, chest or back).
- [ ] **Make the remaining stats configurable:** `Forms.DATA`, heroes, critters (wild dinosaurs), power-up timings.
- [ ] **Recipes for the 33 new materials:** waiting on new weapons, armor and accessories to use them.
- [ ] **Sounds:** a "rawr", and an "uh-oh" (must be a real recording from the user).
- [ ] **Wire in art as it arrives** (see the art list below).

## Decisions (the user)

- [ ] **Pet system (future):** the user plans pets; design to come. The eggs' new use (to be described) may tie in.
- [ ] **Eggs:** the user's new idea for the egg art (to be described).
- [ ] **Stomps:** which wild species are stompable, and does a stomp bounce Rok?

## Art (the user)

- [ ] **Rok's Fist and Shoot standing styles, fresh redraws** (the consistency update ships them as the old art scaled to his run's size; same 4×2, 384×512 cells, feet at y 488, guides and landmarks): drop them in `Rok_Animation_Consistency_Update 3/rok/standing/` and rerun `prepare_styles.py`.
- [ ] **Optional: Nira's and Boro's running style attacks redrawn over their in-game run** (`Rok_New_Heroes_Nira_Boro/<hero>/spritesheets/run.png`): their packs used a different, ~10% taller run, so the game fits them; legs only match exactly for Rok.
- [ ] **A Missions scene** (the user's plan): a full screen like the Market and Camp for the daily and weekly missions (a backdrop, a board or scroll for the two lists with room for 3 + 3 missions, progress bars, a reward/streak plaque, a title plaque "MISSIONS"). Today a dark panel in the middle of the main menu stands in (`Hud.missions_panel`).
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

- The Dino Egg power-up art (`assets/powerups/dino_egg*`, `Rok_Powerups`): the Blaze Pepper replaced it as the speed boost (2026-11-23); the user has another idea for eggs.

- The tutorial vine pieces in `Rok_Polished_Assets` (imported, not placed anywhere yet).

## Done recently

- 2026-11-23: Settings (sound and music volumes); armor durability and repair; selling in the Market at 80% (`config/economy.cfg`).
- 2026-11-23: a Missions button with daily and weekly missions (`config/missions.cfg`); one font (Baloo 2) everywhere; the Encyclopedia lists drops (from the config) and how to unlock locked entries; a Crafting tour after the run that opens the bench; Canyon rock drops fixed.
- 2026-11-23: rarer cards and chests (higher tiers rarer, `[cards]`, `[chests] appear`); the Canyon arch's legs in front of Rok; wild dinosaurs follow the ground and hop pits; the main screen resets hearts, energy and cooldowns after a run.
- 2026-11-23: dinosaur cards are slotted into weapons (`[card_slots]`, a slot can stay empty), not equipped.
- 2026-11-23: damage tiers per obstacle (`config/damage.cfg`; pits, liquids, quicksand and gates stay instant); a NEW banner per obstacle look (`config/obstacle_looks.cfg`), two banners at once; PRIMAL energy explained (Field Guide page, first-dino card, tiring banner, tutorial note).
- 2026-11-23: Rok's size made consistent: idle, walk, duck, trip, dizzy, snag and the 5 standing styles from the user's consistency update (redrawn at his run's size), his per-weapon clips and gear sockets refitted.
- 2026-11-23: the Blaze Pepper replaced the Dino Egg as the speed-boost power-up (id `pepper`; old saves renamed on load).
- 2026-11-23: Desert and Volcanic biome obstacles with breaks, Forest twig and mushroom breaks; all five attack styles for Rok, Nira and Boro, standing and running (bare hands = Fist); the Canyon zone (4th, from the user's canyon pack; timeline probe: every zone lesson lands in its zone); Point Hunter and Seasoned medals; day/night icon on the HUD; chest rarities; bug-proof tutorial; Kora's lines and name plank; Ugo's name plank; Camp meat counter hidden; Rok's Swing pilot (approved); [NEW_ITEM_ART.md](NEW_ITEM_ART.md).
