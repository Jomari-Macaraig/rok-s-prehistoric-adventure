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

- [ ] **Cards:** should a dinosaur card add to a weapon instead of replacing it in the weapon slot?
- [ ] **Stomps:** which wild species are stompable, and does a stomp bounce Rok?

## Art (the user)

- [ ] **Zone obstacles** (19 pieces; transparent PNG + `@2x`, each with a 4×2 break sheet):
  - Desert: horned dinosaur skull on its side (2 variants), half-buried fossil spine segment, petrified stone log, row of ribs in the sand, standing rib cage or tall vertebra column, small raptor skull, bone pile, sandstone shard, dry spiky shrub with bleached thorns.
  - Volcanic: cooled lava ridge with glowing cracks, charred stone log, row of short obsidian spikes, hexagonal basalt column, smouldering ember rock, obsidian shard cluster, pumice lump, ash-grey bramble with ember-tipped thorns.
  - Forest: break animations for the small twig and the two mushrooms.
- [ ] **Rok's other attack styles:** Thrust, Throw, Shoot, Fist (empty-handed, with a guide sheet and landmarks JSON each, like `Rok_Swing_Attack`). Then his five running style attacks.
- [ ] **Nira and Boro:** five standing and five running style attacks each, with guide sheets.
- [ ] **Medals:** Point Hunter (`scorer`) and Seasoned (`veteran`), unearned, bronze, silver and gold each (8).
- [ ] **UI:** an Armor stat icon (kit glyph style); "Crafting Bench", "Items" and "DINOSAUR CAMP" title plaques.
- [ ] **Card art** for the 12 balanced-pack dinosaurs (Deinonychus … Dsungaripterus).
- [ ] **Attacks** for those 12 dinosaurs.
- [ ] **Break-by-material sheets:** wood, stone, bone, obsidian, metal, cord.
- [ ] **Long-run items:** the fossil pickup and the bonus-zone portal (drawn in code today).
- [ ] **Body-armor patterns** (Hide Vest, Bone Guards, Scale Mail), once the outfit shader is built.

## Unused art

- The tutorial vine pieces in `Rok_Polished_Assets` (imported, not placed anywhere yet).

## Done recently

- 2026-11-23: chest rarities; bug-proof tutorial; Kora's lines and name plank; Ugo's name plank; Camp meat counter hidden; Rok's Swing pilot (approved); [NEW_ITEM_ART.md](NEW_ITEM_ART.md).
