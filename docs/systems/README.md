# System docs

One file per gameplay system, so each can be read and polished on its own. Progress is tracked in the [polish checklist](../POLISH.md). Each lists its key files, then the details. Config files: `config/progression.cfg` (when things appear) and `config/pickups.cfg` (pickup odds and placement). The asset pipeline is in [tools/CLAUDE.md](../../tools/CLAUDE.md) and the tests in [tests/CLAUDE.md](../../tests/CLAUDE.md).

## Core run
- [Run loop, states, summary and main menu](run-loop.md): How a run starts, plays, ends and hands back to the main menu: game states, the intro, death, Stop, the summary card and save data.
- [Chase and hunters](chase-and-hunters.md): The pursuer behind Rok: the chase gap, each zone's hunter, and timed charges.
- [Health, damage and hit reactions](health-and-damage.md): Hearts, what each hit costs, what's still instant, hit reactions (trip, dizzy, snag) and the Power roll on small hazards.
- [Movement and forms](movement-and-forms.md): Running, jumping, sliding and flying, and the five shapeshift forms' rules.
- [Combat: attack](combat.md): The ATTACK action: targeting and its marker, what breaks, the attack clips per hero weapon and dinosaur.
- [Tutorial (coach hints)](tutorial.md): teaches the controls at the moment they are useful, without pausing or nagging.

## World and course
- [Terrain](terrain.md): The scrolling ground: flats, hills, drops, pits, the dirt fill and the height queries physics uses.
- [Zones, day/night, background and lap twists](zones-and-environment.md): Forest, Desert and Volcanic Badlands, the day/night cycle, parallax backgrounds and the weather twist each lap.
- [Obstacles, traps and dino gates](obstacles-and-gates.md): What gets spawned in front of Rok: course patterns, obstacles and their zone skins, traps, liquids and quicksand, dino gates, floating islands and break effects.
- [Wild dinosaurs](wild-dinosaurs.md): The stampedes and swoopers that run at Rok in each zone, and what happens when he dodges or bonks them.
- [Progression and teaching](progression.md): The curriculum: when each hazard, dinosaur, zone and slot first appears, how new things are taught (info cards, marination) and the first-sight rule. Distances live in `config/progression.cfg`.
- [Dependency tree (requirements)](requirements.md): what needs what before it happens (e.g. amber needs a dinosaur), all in config/requirements.cfg.

## Rewards and items
- [Pickups, reward spots and loot](pickups-and-loot.md): Amber, meat, big meat, fossils and hearts on the course: what a reward spot holds, where it's placed, escalation deep in a run, and loot from broken obstacles. Odds live in `config/pickups.cfg`.
- [Power-ups (boosters)](power-ups.md): The six power-ups, the kart-style slots, their effects and how they spawn.
- [Combo streak and Primal Frenzy](combo-and-frenzy.md): Clean feats build a combo multiplier and fill the frenzy meter; Primal Frenzy smashes through everything.
- [Long-run variety: chests, events and bonus zones](long-run-events.md): What keeps long runs lively: milestone chests, mid-run events and (switched off for now) bonus zones.
- [Badges, daily missions and the best-distance flag](goals.md): Long-term and daily goals: tiered badges (and what they unlock), three daily missions, and the flag marking your best distance.

## Characters and growth
- [Heroes](heroes.md): Rok, Nira and Boro: buying and playing a hero, and the new-best celebration jump.
- [Dinosaurs (the expansion roster)](dinosaurs.md): The 28 expansion dinosaurs: their tiers, how they're sold, equipped on a button and played.
- [Attributes and cooldowns](attributes.md): The five attributes (Speed, Jump, Stamina, Power, Armor), categories and leans, tier budgets, Rok's stats, and the cooldowns they shorten.
- [Levelling and XP](leveling.md): XP earned by metres, levels 1-10, level-up costs and what each level adds.
- [Crafting, materials, rarity and the Items screen](crafting.md): gear is crafted at the Crafting Bench from materials found in runs (or basic ones from the Market); each craft rolls a rarity; the Items screen lists what you own. All in `config/crafting.cfg`.
- [Weapons, armor and dinosaur cards](weapons-and-armor.md): Hero gear: the weapon and armor slots, bonuses, reach, durability and repair, breaks, the Torch and Bow, dinosaur cards, and gear drawn on the hero.

## Screens and UI
- [Marketplace](marketplace.md): The Market screen: what's sold and when, buying, the cave scene and Ugo the merchant, the UI art and layout.
- [Camp (levelling and gear screen)](camp.md): The Camp screen (code name Herd): pick a hero or dinosaur per button, compare, level up, and equip gear.
- [Field Guide (Encyclopedia)](field-guide.md): The encyclopedia of dinosaurs, hazards, items and badges, with real-world facts.
- [Screens and navigation](screens-and-navigation.md): How the full-screen places (Market, Field Guide, Camp) open and close, the shared scene look, and the side buttons on the main menu.
- [HUD and touch controls](hud-and-controls.md): The on-screen layout: thumb clusters, touch buttons, cooldown display, button glow and the touch-first text rule.

## Presentation
- [Audio](audio.md): Sound effects, per-form and per-surface sounds, the T-rex's voice and the zone music.
- [Rendering, sprites and effects](rendering-and-fx.md): How character art is loaded (1x/@2x), SpriteFrames are built, and particles and floating text are drawn.
