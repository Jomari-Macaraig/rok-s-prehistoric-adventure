---
title: Rethink hero and dinosaur levels
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# Rethink hero and dinosaur levels

## Question

How should heroes and dinosaurs level up so it feels intuitive and fun? Today: 1 XP per metre run as that character, levels 1-10 (450 m for level 2, about 20,000 m for level 10), then meat at the Camp, and each level adds about half a point to one attribute the player picks (docs/systems/leveling.md). What earns XP, how fast levels come, what a level gives (bigger visible jumps, new moves or perks, looks), whether the player chooses anything, how a level-up is celebrated, and how levels show the player's strength for the campaign. Note: "When the campaign opens" chose "the played hero at level 3"; revisit that number once levels are redesigned.

## Resolution

Decided with the user (2026-11-24):
- **Levels come by themselves**: the moment a character has the XP it
  levels up, during the run, with a "LEVEL UP!" burst, sound and glow (play
  doesn't stop). **No meat, no trip to the Camp.** The summary fills each
  character's XP bar; a milestone shows a card there ("NEW: Raptor learned
  Double Dash!").
- **Pace**: quick early levels (level 2 within a first good run, about
  300 m), slowing gently; the cap rises to **20**.
- **XP** from metres run as that character, plus campaign stage clears and
  stars, bosses, chests, and a small **team share** for the other equipped
  dinosaurs.
- **Dinosaurs grow automatically** (mostly their best attributes) and get
  **milestone rewards** at set levels (for example 3, 5, 8, 10): a new
  trick, a perk or a new look. Set per species in config.
- **Evolution**: runner dinosaurs **evolve at levels 10 and 20** (a new look
  and a jump in strength). The art is shared with pets' grown-up looks;
  until it exists, an evolved dinosaur gets the strength jump and a glow or
  tint. (Pets grow by age in the pet system's plan.)
- **Heroes level differently**: each hero level gives a **skill point** for
  that hero's own **skill tree** (Rok all-rounder: Runner, Brawler,
  Survivor branches; Nira the scout; Boro the guardian), with a **free
  reset**. Skills and numbers in config.
- **The level path**: at the Camp each character shows its path from level
  1 to 20, with milestones (or a hero's tree) as icons, unlocked ones lit
  and the next one highlighted.
- **Gone**: the per-attribute "+" buttons and the meat cost of levels.
- **Old saves**: levels are kept, attributes recalculated with the new
  growth, and the meat spent on levels refunded.
- **Revisit**: "When the campaign opens" asked for hero level 3; with faster
  early levels it may become a higher level.

Feeds: "How recommended strength is worked out", "What the Market is for"
(meat no longer buys levels), "What stages pay" (XP), the screens (level
path, skill tree), and the pet system (shared grown-up art).
