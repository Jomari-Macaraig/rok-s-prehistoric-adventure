---
title: What's in each milestone, skill tree, accessory and set
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# What's in each milestone, skill tree, accessory and set

## Question

Now that levels, gear and the Market are settled: what are the actual milestone rewards per dinosaur (tricks, perks, looks at levels 3, 5, 8 and so on), each hero's skill tree (Rok's Runner, Brawler and Survivor branches; Nira the scout; Boro the guardian), the first accessory list (one special effect each), and each boss set's bonus? They mustn't overlap (a perk, a skill and an accessory doing the same thing). Start with the four originals, the three heroes, about six accessories and the four chapter bosses; the rest follows the same pattern.

## Resolution

Decided with the user (2026-11-24). All numbers go in config and are tuned
by the balance bot.

**The four lanes** (stops overlaps; every new item fits exactly one):
- **Dinosaur milestones** change only that dinosaur's form (its moves,
  smashing, shield).
- **Hero skills** change only the hero's own form and how the hero
  handles ATTACK, hearts and dodging.
- **Accessories** change the run around you (pickups, meat, amber/PRIMAL,
  power-ups, torches, chests).
- **Set bonuses**: one big, boss-themed combat effect working in every
  form.
- Close-but-different effects are fine when they belong to different
  forms (Rok's Light Feet and the Raptor's Light Step).

**Milestones**: levels **3, 5, 8, 13, 15, 18**, each a **Trick** (something
new the form can do) or a **Trait** (always on; "perk" stays with badges
and attribute thresholds); evolutions at **10 and 20**. New looks only come
with evolution, so milestones need no art.

| Lv | Raptor (Runner) | Triceratops (Smasher) | Spinosaurus (Tank) | Pteranodon (Flyer) |
|---|---|---|---|---|
| 3 | Trait **Quick Start**: shifting in gives a 1 s burst that gains on the hunter | Trait **Thick Skull**: always breaks small rocks and wood (no Power roll) | Trait **Deep Diver**: swims faster | Trait **Updraft**: glides fall slower |
| 5 | Trick **Double Dash**: ATTACK in the air dashes forward | Trick **Charge**: hold ATTACK, 1.5 s charge breaking everything it can | Trick **Tail Sweep**: ATTACK clears thorns and wild dinosaurs in front and close behind | Trick **Dive**: SLIDE in the air dives steeply |
| 8 | Trait **Light Step**: quicksand and crumbling ledges hold a moment longer | Trait **Wide Horns**: one ATTACK breaks two obstacles in a row | Trait **Regrowing Scales**: the shield returns once, 10 s after breaking | Trait **Soft Landing**: landing from a dive never stumbles |
| 13 | Trick **Pounce**: bonking a wild dinosaur bounces you up like a free jump | Trick **Stomp**: landing from a jump breaks small hazards just ahead | Trick **Sail Brace**: hold SLIDE to brace; the next hit within 1 s is free (cooldown) | Trick **Wing Buffet**: ATTACK in the air knocks flying wild dinosaurs away |
| 15 | Trait **Pack Instinct**: ×2 score becomes ×2.5 | Trait **Unstoppable**: smashing never slows it | Trait **River King**: gains on the hunter while swimming | Trait **Thermal Rider**: climbing costs 20% less energy |
| 18 | Trick **Triple Jump** | Trick **Earthshaker**: Charge also breaks walls | Trick **Double Shield**: each shapeshift starts with 2 shields | Trick **Barrel Roll**: double-tap JUMP rolls through one flying hit |

**Evolution**: Lv 10 gives +1 to every attribute; Lv 20 +1 again and the
best attribute may go 1 past its cap. A glow until the evolved art exists.

**Expansion dinosaurs** (the 28): follow their category's list above; the
Lv 8 milestone is swapped for a **Signature Trick** of their own, written
when that dinosaur gets its Trail.

**Skill trees**: one skill point per level 2-20 (**19 points**); three
branches of **5 skills** costing **1, 1, 2, 2, 3** (9 a branch, 27 for all),
so two branches fill but not three; each skill needs the one below; free
reset. Bottom to top:

- **Rok**
  - **Runner**: Quick Feet (shorter slide cooldown), Air Step (a third
    jump as the hero), Slipstream (each clean dodge gains a little on the
    hunter), Light Feet (no sinking in quicksand), **Second Wind** (once a
    run, a speed burst when the hunter is about to catch you).
  - **Brawler**: Heavy Swing (+20% ATTACK damage), Quick Hands (ATTACK
    cooldown −20%), Rock Breaker (ATTACK always breaks small hazards),
    Combo Strike (every third boss hit in a row does double), **Ground
    Pound** (SLIDE + ATTACK slams, breaking every small hazard around).
  - **Survivor**: Tough Hide (the first hit of each run or stage is free),
    Shake It Off (stumbles let the hunter close in less), Iron Will (at 1
    heart or less, hits cost half), Patch Up (a quarter heart back every
    500 m without a hit), **Last Stand** (once a run, a run-ending hit
    leaves a quarter heart; pits still end it).
- **Nira** (scout)
  - **Pathfinder**: Keen Eyes (warnings earlier), Scout's Hint (puzzle
    hints after 2 tries instead of 3), Shortcut Sense (forks show the safer
    path), Light Feet, **Foresight** (time slows briefly the first time a
    new hazard appears in a run).
  - **Acrobat**: Spring Step (higher jumps), Air Step, Roll (sliding
    through a low hit dodges it), Wall Hop (bounce off a wall's face
    instead of crashing, once per wall), **Featherfall** (hold JUMP to
    glide slowly).
  - **Tracker**: Weak Spot (bosses show a weak spot, +50% when hit), Quick
    Hands, Bonk Master (a bonked wild dinosaur knocks over the next one),
    Hunter's Sense (hunter charges warned 2 s earlier), **Mark** (ATTACK
    marks a boss: the next 3 hits do double).
- **Boro** (guardian)
  - **Bulwark**: Tough Hide, Thick Hide (medium crashes cost a quarter
    less), Brace (hold SLIDE standing still to block one hit), Iron Will,
    **Fortress** (+1 heart in boss stages).
  - **Crusher**: Heavy Swing, Rock Breaker, Shoulder Barge (ATTACK also
    breaks logs, medium obstacles), Combo Strike, **Quake** (ATTACK on
    landing stuns a boss for 1 s).
  - **Protector**: Shake It Off, Steady (each shapeshift gives a short
    moment where hits are free), Rally (+10% team XP share; the one
    accepted bend of the hero lane), Patch Up, **Guardian Spirit** (once a
    run, a fatal hit while a dinosaur turns you back into Boro with 1
    heart).
- Shared skills (Light Feet, Air Step, Quick Hands, Heavy Swing, ...) are
  on purpose so each hero feels whole.

**Accessories**: crafted at Kora's bench; **rarity** sets the effect's size
(about Common +10% to Legendary +30%), each **upgrade** adds about +2%,
**worn out** halves it. The first six, each needing a zone's materials:
- **Amber Pendant** (Forest): amber gives more PRIMAL.
- **Meat Hook** (Forest): more meat from pickups.
- **Lodestone** (Desert): a small always-on magnet (the Fossil Magnet
  power-up stays the strong 7 s pull).
- **Sun Bead** (Desert): power-ups last longer.
- **Torch Totem** (Canyon): a chance to get the torch back on a failed
  stage (clears are already free).
- **Lucky Fossil** (Volcanic): better odds of rarer milestone chests.

**Bosses and sets**: the Canyon boss is the **Utahraptor** (fast and small,
existing art; Quetzalcoatlus may return as a boss variant). Sets are
**3 pieces only**; each piece is the best of its slot, the full set adds
one **Set Bonus**:
- **T-rex** (Forest, T-rex tooth): **Tyrant's Roar**, ATTACK knocks small
  wild dinosaurs away.
- **Carnotaurus** (Desert, Carnotaurus horn): **Bull Rush**, after each
  shapeshift, 1 s of smashing through small hazards.
- **Utahraptor** (Canyon, Utahraptor quill): **Killing Claw**, a hit resets
  the ATTACK cooldown.
- **Allosaurus** (Volcanic, Allosaurus claw): **Molten Hide**, crashing
  into a small obstacle breaks it instead of costing hearts.

Glossary: Milestone updated; Trick, Trait and Set Bonus added.

Feeds: the destination spec (`docs/systems/campaign.md`, `leveling.md`,
`weapons-and-armor.md`, `crafting.md`), the boss stages (Utahraptor), the
TODO art list (milestone icons, skill card art, accessory icons, boss set
art for four bosses), and balance (all numbers bot-checked).
