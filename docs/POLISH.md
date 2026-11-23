# Polish checklist

One line per system. Tick a system once you've polished it; add notes under it
as you go. Each system's details are in [docs/systems/](systems/README.md).

**Legend**: `[ ]` not started · `[~]` in progress · `[x]` polished

## Core run
- [ ] [Run loop, states, summary and main menu](systems/run-loop.md)
- [ ] [Chase and hunters](systems/chase-and-hunters.md)
- [ ] [Health, damage and hit reactions](systems/health-and-damage.md)
  - [ ] Hit reactions for the redrawn forms still use the old art
- [ ] [Movement and forms](systems/movement-and-forms.md)
- [~] [Tutorial (coach hints)](systems/tutorial.md)
  - [x] Training run: plays once on a fresh save, freezes on each hint, can't be lost, skippable
  - [x] Coach hints for jump, high jump, double jump, slide, attack, power-ups, shapeshift, low energy, Market, Camp
  - [x] Tips on/off switch on the pause screen
  - [x] Tutorial button on the main menu replays the training run
  - [x] Training run explains the HUD (hearts, hunter meter, points, distance, meat, PRIMAL) and ends with a tour of the Marketplace, Camp and Encyclopedia
  - [x] Mockup polish: big top cards with highlighted button names, glowing button with rays, dashed move arcs, Tutorial plaque and Skip
  - [x] The user's tutorial UI kit: card, plaque, pills, focus ring, attention marks, tap pointer, Baloo 2 / Nunito Sans
  - [ ] Square art for the Tutorial button (`assets/ui/square_tutorial.png`, like the Encyclopedia/Marketplace/Dinosaurs buttons)
  - [ ] Playtest the timing (gap, show time, look-ahead) on a phone
- [ ] [Combat](systems/combat.md)
  - [x] Seamless running attack + club-carry run for Rok with the club (`Rok_Running_Club`)
  - [ ] Running attacks for Rok's other six weapons, and for Nira and Boro
  - [ ] Attack clips for bare hands and the 12 balanced-pack species

## World and course
- [ ] [Terrain](systems/terrain.md)
  - [ ] Drop tile seam (only matters if the Forest goes back to tiles)
- [ ] [Zones, day/night, background and lap twists](systems/zones-and-environment.md)
  - [ ] Dedicated Volcanic art (currently recoloured desert art)
  - [x] Zones last longer: 1500 m each (was 1000), set in `[zones] length_m`; zone lessons moved to match
- [ ] [Obstacles, traps and dino gates](systems/obstacles-and-gates.md)
  - [ ] Break animations for twigs and mushrooms
- [~] [Wild dinosaurs](systems/wild-dinosaurs.md)
  - [x] Diving flyers: some swoopers come in high and dive at Rok (own lesson at 4100 m; `DIVE_*` in tuning)
  - [ ] Playtest dive feel (`DIVE_FROM_X`/`DIVE_TO_X`, `DIVE_CHANCE`); a dedicated dive pose would need art
- [ ] [Progression and teaching](systems/progression.md)
  - [x] Dinosaur buttons: Raptor 800, then 2600 / 3600 / 4600 (no amber before the first dinosaur)
  - [x] Lesson slip between the Triceratops and the Pteranodon fixed (spawner starvation, Forest revisit, schedule windows)
  - [x] First 800 m: logs 430, starter chest 450, Low Ledges 590, wild-dinosaur preview 720 (`[early]` in progression.cfg)
  - [ ] Playtest the first 800 m on a phone
- [~] [Dependency tree](systems/requirements.md)
  - [x] config/requirements.cfg; amber and the Amber Storm need a dinosaur
  - [ ] Decide more rules (e.g. hide the PRIMAL bar until the first dinosaur?)

## Rewards and items
- [ ] [Pickups, reward spots and loot](systems/pickups-and-loot.md)
  - [ ] Art for the rare fossil
- [~] [Power-ups](systems/power-ups.md)
  - [x] Amber Shield → Primal Amber (refills PRIMAL energy; needs a dinosaur)
  - [ ] Primal Amber art (icon and idle loop; it borrows the amber pickup)
- [ ] [Combo streak and Primal Frenzy](systems/combo-and-frenzy.md)
- [ ] [Long-run variety: chests, events, bonus zones](systems/long-run-events.md)
  - [ ] Decide on bonus zones (switched off; `BONUS_ENABLED`); portal art if they return
- [ ] [Badges, daily missions and the flag](systems/goals.md)
  - [ ] Medals for Point Hunter and Seasoned

## Characters and growth
- [ ] [Heroes](systems/heroes.md)
  - [ ] Use the pack's hurt, transform and victory clips
- [ ] [Dinosaurs](systems/dinosaurs.md)
- [ ] [Attributes and cooldowns](systems/attributes.md)
  - [ ] Cooldown animation in place of the wedge (art from the user)
- [ ] [Levelling and XP](systems/leveling.md)
- [ ] [Weapons, armor and dinosaur cards](systems/weapons-and-armor.md)
  - [ ] Body overlays for Hide Vest, Scale Mail and Bone Guards (art needed)
  - [ ] Remove the retired Card Pack code
  - [ ] Decide whether chests keep giving cards

## Screens and UI
- [x] [Marketplace](systems/marketplace.md)
  - [x] Shop panel stays on screen on every tab
  - [x] Locked items say what unlocks them, under the name
  - [x] Hero attributes wrap instead of running off the strip
  - [x] Remove the leftover "Looks" code (Rug, Line, the saved Market look)
  - [x] Fill the empty grid on short tabs (empty display spots)
  - [x] Outdoor backdrop: sky above the cave, jungle in the wide-phone gap
  - [ ] Later: remove the retired Card Pack code (see Weapons)
- [ ] [Camp](systems/camp.md)
  - [x] Scene kit: painted camp, stats panel, roster, kit tabs, cards and pills
  - [ ] Use the kit's stat meters for the attribute bars
- [~] [Field Guide](systems/field-guide.md)
  - [x] Hazard pictures fixed (steam vents, Tougher Combos had none; pits, canyons, liquids, quicksand, rolling boulders, barricades were generic) and shown in each zone's look, on info cards and as a per-zone row in the guide (`HazardIcons`)
  - [x] Scene kit: painted archive, Elder Numa, open book, roster, kit tabs and cards
- [ ] [Screens and navigation](systems/screens-and-navigation.md)
- [ ] [HUD and touch controls](systems/hud-and-controls.md)

## Presentation
- [ ] [Audio](systems/audio.md)
  - [ ] Rok's "time to run!" shout (a recording from the user)
- [ ] [Rendering, sprites and effects](systems/rendering-and-fx.md)
