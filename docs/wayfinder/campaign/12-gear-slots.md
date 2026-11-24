---
title: Weapons, armor and accessories: what gear is for
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# Weapons, armor and accessories: what gear is for

## Question

What should gear do and how should the player get it? Today: a weapon and an armor slot per hero, crafted at the Crafting Bench with a rolled rarity, a weapon's card slot, no accessories yet (docs/systems/weapons-and-armor.md, crafting.md). Which slots exist (add the accessory slot?), what each slot gives (attributes, special effects, attack styles), where gear comes from (crafting, Market, campaign drops, bosses), and how gear upgrades over time.

## Resolution

Decided with the user (2026-11-24):
- **Three slots per hero**: weapon, armor, **accessory** (new). Dinosaurs
  don't wear gear (they grow through levels, milestones and evolution;
  cards slot into weapons).
- **One clear job per slot**:
  - weapon = attack (ATTACK strength, reach, style) plus its card slot;
  - armor = defence (softer hits; better pieces add a **bonus heart**);
  - accessory = **one special effect**, no plain attribute points (for
    example amber gives more PRIMAL, longer power-ups, a small magnet, a
    torch back on a boss clear, more meat).
- **Where gear comes from**: crafting at Kora's bench stays the main way;
  each boss drops its **boss material** (a T-rex tooth, an Allosaurus
  claw) for **boss gear**, the best of each slot. **The Market sells no
  gear.**
- **Boss sets**: each chapter boss has a 3-piece set (weapon, armor,
  accessory) from its boss material; wearing all three gives a **set
  bonus** (for example the T-rex set: ATTACK knocks small wild dinosaurs
  away).
- **Upgrades +1 to +10** at Kora's bench for materials; rarity still sets
  the starting strength.
  - +1 to +6 always succeed.
  - +7 to +10 can **fail** (odds in config, for example 75%, 55%, 40%,
    25%): a failure costs the materials and **drops the item one level**;
    from **+8 up** a small chance (about 10%) it **breaks** for good.
  - A rare **protection charm** ("Kora's Blessing": chests, bosses, or a
    pricey Market item) used on an upgrade stops it breaking or dropping.

Feeds: "Durability and repair" (how upgrades and wear fit together), "What
the Market is for" (no gear, but charms; selling upgraded gear), "What
stages pay" (boss materials, charms), "How recommended strength is worked
out" (gear and upgrade levels), and the content fog (the accessory list and
set bonuses).
