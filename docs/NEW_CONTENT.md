# Adding new content: what each kind of thing needs

The user's checklist for adding a **dinosaur**, **hero**, **weapon**, **armor** or **obstacle**. For each one it lists the art to make, the config and code entries, and the checks.

**Keep this file current:** whenever a system starts needing something new (a new animation, a new config entry), add it here.

Art conventions shared by everything:
- Sprite sheets are **4×2 grids, 8 frames**. One-shot clips put the strike or impact on frame 4.
- Transparent PNG with no baked-in background.
- A ground pivot (feet at the bottom centre).
- Drawn at the pack's size. The import scripts in `tools/` scale and align it ([tools/CLAUDE.md](../tools/CLAUDE.md)).
- Run `godot --headless --path . --import` after adding PNGs.

---

## Dinosaur (playable species, a Market expansion dinosaur)

### Art (one folder per species, like `../Assets/Rok_Balanced_32_Form_Pack/<id>/`)

| Clip | Needed for | Notes |
|---|---|---|
| idle | Market card loop, Camp, button portrait | the card loop and portrait are cut from it |
| walk | menu and screens | |
| run | running | |
| jump | jumping | |
| slide | sliding under ledges | enter 0–1, loop 2–5, exit 6–7 |
| duck (crouch) | ducking | its own painted loop (otherwise it's built from the slide) |
| die | death hop | |
| attack | ATTACK | 4×2 one-shot, strike on frame 4, like `Rok_Attack_Animations` |
| trip, dizzy, snag | hit reactions | dizzy and snag: enter 0–1, hold 2–5, recover 6–7 |
| **Flyers:** fly, glide, takeoff, land | flight | registered at the same point as the other clips |
| **Tanks:** swim | Flooded Crossing gate | floats at the waterline |
| **Card art** | the dinosaur card (Field Guide Cards tab, a weapon's card slot) | transparent PNG at `../Assets/Rok_Dinosaur_Cards/cards/<id>.png` (1024×1536, name painted on the plank, blank parchment below), like the 21 in the pack; `prepare_cards.py` trims and sizes it |

### Data and config
- **Metadata** (`characters` / `role` in the pack): name, category (Runner, Smasher, Tank, Flyer), tier, blurb → `tools/prepare_dinos.gd` writes `assets/dinos/dinos.json`.
- **Attributes** (Speed, Jump, Stamina, Power, Armor) within its tier's budget and cap. The tests check the rules: no two dinosaurs share a profile, and none is at least as good as another at everything. See [attributes](systems/attributes.md).
- **Market:**
  - price in `config/progression.cfg [market]`,
  - on-sale distance in `[market_unlocks]`,
  - a badge in `[market_badges]` for Skilled and higher tiers.
- **Real-world facts** in `scripts/dino_facts.gd`: when, where, size, food and a fun fact.
- **Wild version** (optional): a zone's stampede or swooper in `scripts/critters.gd`, with its own attributes. It drops its card and materials.
- **Card bonus:** automatic, from its tier (`Gear.CARD_BONUS`).
- **Milestones:** expansion dinosaurs follow their category's list in `config/milestones.cfg` (ticket 06); a new original species gets its own `[species.<id>]` with six milestones and their code ([dinosaurs](systems/dinosaurs.md#milestones)).
- **Dinosaur Camp stage:** automatic: it idles with its idle clip and shows off its attack clip now and then.

### Import and check
1. Run `tools/prepare_dinos.gd`, then `prepare_reactions.gd`, then `prepare_animation_pack.gd` (crouches). Then `prepare_attacks.py`, `prepare_cards.py` and `--import`.
2. The tests' species checks cover every animation its button needs, slide and duck boxes that fit under a ledge, attributes, and equipping.

---

## Hero (like Nira and Boro)

### Art (like `../Assets/Rok_New_Heroes_Nira_Boro`, on the heroes' shared 576×512 canvas)

| Clip | Needed for | Notes |
|---|---|---|
| idle, walk, run, jump, duck, slide, die | running and screens | slide: enter 0–1, glide 2–4, recover 5–7 |
| celebrate | the new-best celebration jump | launch and land frames marked |
| trip, dizzy, snag | hit reactions | |
| **attack × every weapon** | ATTACK with each weapon | 7 today: club, stone_axe, flint_spear, bone_hammer, sling, torch, bow. Hand position matches the weapon icon's grip |
| **bare-hand attack** | ATTACK with no weapon or a broken weapon | still missing for all heroes |
| **running attack × every weapon** | ATTACK while running (seamless) | a pack like `Rok_Running_Club`: `run.png` carrying the weapon, `phases/run_attack_phase_0..7.png`, `validation.json` |
| **armor overlays** (Hide Vest, Bone Guards, Scale Mail) | armor drawn on the body | 4×2 per clip, on the hero's canvas and pivot, armor only (transparent elsewhere). Shell Plate uses the back socket |
| portrait | Camp tile, Market card | cut from idle |

### Data and config
- **Stats** (`scripts/heroes.gd` `INFO`): name, role, blurb, attributes on the originals' budget.
- **Skill tree** (`config/skills.cfg`): a `[tree.<hero>]` with three `[branch.*]` of five `[skill.*]` each (name, text, value), plus the code for any new skill effect ([heroes](systems/heroes.md#skill-trees)). Skill icons and branch banners are art to ask for.
- **Market:** price and on-sale distance in `config/progression.cfg` (`[market]`, `[market_unlocks]`).
- **Gear sockets:** `tools/prepare_gear.py` measures the front hand and back point for every frame. Rerun it after any hero art changes.

### Import and check
1. Run `tools/prepare_heroes.gd` (after `prepare_reactions.gd`), then `prepare_animation_pack.gd` (celebrate), `prepare_attacks.py`, `prepare_gear.py` (sockets) and `--import`.
2. `prepare_running_attacks.py` handles Rok only today. A new hero's running placement has to be added to it (as it does for Nira's packs).
3. The tests' hero checks cover owning and playing the hero, its own animations, sliding under ledges and earning XP.

---

## Weapon

> **What art to generate** for a new weapon, armor or accessory: [NEW_ITEM_ART.md](NEW_ITEM_ART.md).

> Moving to **attack styles** (heroes drawn empty-handed once per style, with weapons placed by guide sheets), so a new weapon will need only its icon, a `[weapon_styles]` entry and a `[card_slots]` count (0 = no card slot; unlisted weapons use `default`) in `config/crafting.cfg`. See [ITEM_ART_PLAN.md](ITEM_ART_PLAN.md). Rok's **Swing** is in (the pilot, approved): a new swing weapon already needs no attack clip for Rok. Until every hero has every style, the list below is what a weapon needs.

### Art

| Piece | Needed for | Notes |
|---|---|---|
| **Icon** | Market, Camp, Items, crafting, the weapon in the hero's hand | transparent, at least 512 px. Today a cell of `Rok_Equipment_Sprite_Sheet.png` or a sprite in `Rok_Weapons_Animation_Pack` |
| **Grip point** | holding it right | where the hand wraps the handle; `prepare_gear.py` writes it to `gear_art.json` (with length, tilt, `upright`, `hang`) |
| **Break animation** | the weapon snapping at 0 durability | 4×2 sheet, frame 0 the intact weapon (`spritesheets/<weapon>_break.png`) |
| **Attack clip × every hero** | ATTACK | 4×2 one-shot per hero (Rok, Nira, Boro), strike on frame 4, named `attack_<weapon id>` |
| **Running attack × every hero** | ATTACK while running | a `Rok_Running_<Weapon>` pack per hero |
| **Animated version** (optional) | e.g. the Torch's burning loop | registered to the icon |
| **Projectile** (ranged only) | e.g. the Bow's arrow | |

### Data and config
- **Stats** in `scripts/gear.gd` `ITEMS`:
  - `name`, `slot: "weapon"`,
  - `bonus` (attributes),
  - `reach`, `durability`,
  - optional flags `burns` / `ranged`,
  - `desc`.

  These are the Common stats; rarity multiplies them.
- **Recipe** in `config/crafting.cfg [recipes]` (materials and counts).
- **Distance that learns the recipe:** `config/progression.cfg [market_unlocks]`.
- New materials, if any: `[materials]`, plus where they drop (`[break_drops]`, `[wild_drops]`, `[spots]`, `[chests]`).

### Import and check
1. Run `prepare_gear.py`, `prepare_attacks.py` and `prepare_running_attacks.py`, then `--import`.
2. The tests check that every hero has a clip per weapon, and that every recipe uses real materials.

---

## Armor

### Art

| Piece | Needed for | Notes |
|---|---|---|
| **Icon** | Market, Camp, Items, crafting | transparent, at least 512 px |
| **Body overlay × every hero × every clip** | armor drawn on the hero | 4×2 per clip (idle, walk, run, jump, duck, slide, celebrate, attack…) on that hero's canvas and pivot, armor only. None of the current armor has these yet |
| **Back mount** (rigid armor only, like the Shell Plate) | drawn on the back socket | a mount point in `gear_art.json` |

### Data and config
- **Stats** in `scripts/gear.gd` `ITEMS`: `slot: "armor"`, `bonus` (usually Armor, maybe a drawback), `desc`.
- **Recipe** in `config/crafting.cfg [recipes]`.
- **Distance that learns the recipe:** `config/progression.cfg [market_unlocks]`.

---

## Obstacle (hazard)

### Art

| Piece | Needed for | Notes |
|---|---|---|
| **Prop picture per zone** | the obstacle on the course | Forest, Desert and Volcanic looks (or a tint rule). Transparent. Its size sets the hitbox |
| **Break animation** | ATTACK, smashing, frenzy | 4×2, frame 2 the impact, in the trap-expansion break format. Still missing for the twig and mushrooms |
| **Field Guide picture** | the Hazards tab and the info card | drawn from the prop (`scripts/hazard_icons.gd`), one per zone |
| Animated version (optional) | e.g. a steam vent, rolling boulder | 4×2 loop |

### Data and config
- **Spawning:** a pattern in `scripts/course.gd` (`PATTERN_KEYS` in `progression.gd`) and its zone skins.
- **When it's introduced:** `config/progression.cfg [introductions]`. Its banner and card text go in `Progression.INTRO_TEXT`.
- **What it needs first** (optional): `config/requirements.cfg`.
- **What it does on contact:**
  - a crash costs a heart, a trip a quarter, a snag half ([health-and-damage](systems/health-and-damage.md)),
  - whether Power can break it ([combat](systems/combat.md)).
- **Break sound:** wood or rock class in `main.break_sound`.
- **Break materials:** which `[break_drops]` table it uses (`Crafting.break_table`: wood, fiber, rock by zone, meteor) in `config/crafting.cfg`.
- **Break loot** (amber, hearts, power-ups) is shared: `config/pickups.cfg [break_loot]`.

### Check
- Run `tests/timeline_probe.gd` to see when it appears in a fresh player's runs.
- Use `trap_shots.gd` or `zone_shots.gd` screenshots to see it in each zone.
