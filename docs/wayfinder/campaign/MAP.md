---
title: Campaign
label: wayfinder:map
---

# Campaign

How this works: this map lists what's been decided about the campaign and
where it's headed. Each open question is its own file in this folder
(`wayfinder:<type>` says how it's resolved; `blocked_by` lists the questions
that must be answered first; `assignee` is set when a session takes it on).
Answers are written into the question's file, and the question is closed.

## Destination

A build-ready spec of the Campaign mode in `docs/systems/campaign.md`: its
layout, what stages ask of the player, what they cost and pay, how the
campaign cycles with endless runs, and its screens; **plus the progression it
runs on**, redesigned to be intuitive and fun: hero and dinosaur levels,
gear (weapons, armor, accessories), durability and repair, and the Market
and **how each stage loads** (memory-efficient preloading behind a loading
screen like the main one)
(widened by the user, 2026-11-24; the changes go into those systems' docs).
Decide everything first; build afterwards.

## Notes

- Domain: the game Rok Runner (Godot 4.7, GDScript). Words in
  [GLOSSARY.md](../../../GLOSSARY.md): Campaign, Chapter, Stage, Endless Run,
  Level, Mission.
- Every grilling session also calls the `grilling` and `domain-modeling`
  skills; update the glossary as terms settle.
- The user's rules: everything tunable lives in config files; art is never
  generated (ask the user for it with a short spec); UI must fit at
  1280x720 and 1560x720.
- Explain in plain words: the user prefers concrete examples to jargon.
- Big picture: [docs/GAME_DESIGN.md](../../GAME_DESIGN.md) (the core loop).

## Decisions so far

- [Campaign basics](00-campaign-basics.md): a stage is a run with a finish
  line (some with a boss, some puzzle-like); 4 chapters by zone of about 10
  stages, a boss at the end, growing later with every species; recommended
  strength, not locks; opens at a distance and level; costs energy/tickets
  (ads later); big first-clear reward; 3 stars; stages from config.
- [How other mobile games charge for levels](07-runner-energy-research.md):
  lives (pay only on failure) or stamina (about a day's refill); the fair
  trend is charging on success, never on failure; ads refill one life or
  some energy; runners usually charge nothing.
- [What a boss stage is](01-boss-stages.md): the boss runs ahead and Rok
  wears its health down with ATTACK (Power and gear matter); warned attacks
  answered by jump/slide/shapeshift; enrages at half health; beating it
  clears the stage; lose on hearts or if it escapes; any species, set in
  config; no hunter during the fight.
- [What a puzzle stage is](02-puzzle-stages.md): right-dinosaur chains,
  switches and forks, and coloured gems for doors; slower, no hunter;
  checkpoints (a mistake costs a heart and sends you back); pieces listed in
  order in config with energy and amber; locked until its dinosaurs are
  unlocked; a hint after 3 tries.
- [What a stage costs to play](03-play-cost.md): Torches, lives-style: only
  a failed (or quit) stage costs one, clears are free; 5 max, one back per
  30 minutes on the real clock; meat refills, reward torches up to 10, ads
  later; endless runs stay free.
- [When the campaign opens](04-campaign-opens.md): best distance 1,000 m and
  the played hero at level 3 (config); a locked Campaign button shows what's
  needed; a one-time tour when it opens.
- [The list of star goals](05-star-goals.md): star 1 is clearing; two more
  from a set list (collecting, skill, fighting, dinosaurs, plus boss-only
  and puzzle-only goals; no time limits); stars add up across tries; shown
  in the briefing and a run tracker; stars never lock, star totals open
  bonus chests.
- [What settings define a stage](06-stage-settings.md): the same course
  every try; `config/campaign.cfg` for general settings and bosses, one file
  per chapter for stages; per stage: kind, zone, length, difficulty,
  hazards, wild dinosaurs and hunter, suggested dinosaurs, two star goals,
  rewards, recommended strength; boss and puzzle extras.
- [How the campaign grows with more species](10-campaign-growth.md): zone
  chapters as the main path (new zones add chapters and join endless runs)
  plus a 3-stage Trail per species in its home zone, opened by clearing
  that chapter; a Trail pays one random reward from its pool (card, XP,
  Market discount, egg), each once; stages set time and weather (night and
  rain matter a little), and endless runs get random weather too.
- [Rethink hero and dinosaur levels](11-levels-rethink.md): instant
  automatic level-ups (no meat, no Camp trip) up to 20, XP from runs,
  stages, bosses, chests and a team share; dinosaurs grow automatically with
  milestone rewards and evolve at 10 and 20; heroes spend skill points in
  their own skill tree (free reset); a level path at the Camp; old meat
  refunded.
- [Weapons, armor and accessories: what gear is for](12-gear-slots.md):
  three slots (weapon = attack, armor = defence and bonus hearts, accessory
  = one special effect); crafting plus boss materials for boss gear sets
  with set bonuses; no gear in the Market; upgrades +1 to +10, risky from
  +7 (a fail drops a level, from +8 a small chance to break), protection
  charms; dinosaurs wear no gear.
- [Durability and repair: keep, change or drop](13-durability.md): softened:
  worn-out gear works at half strength; 1 durability per run or stage;
  repair costs meat (by rarity and upgrade); a successful upgrade restores
  durability; selling still scales with wear.
- [What the Market is for](14-market-role.md): keeps today's goods, adds
  torch refills and Kora's Blessing (few a week) and a daily deals shelf;
  no gear, XP boosts, eggs or boss materials for sale; endless runs earn
  the meat, the campaign pays what meat can't buy; boss materials sellable,
  eggs not.

## Not yet specified

- **The campaign screens**: the chapter map and stage picker, the stage's
  briefing (goals, recommended strength, cost, rewards) and the results
  screen (stars, rewards). Becomes a prototype once the stage settings and
  the way the campaign grows are decided.
- **Main menu**: the Endless Run and Campaign buttons replacing "tap to run",
  and what the title screen says.
- **How the campaign cycles with endless runs in practice**: does anything
  in endless runs change once the campaign exists (new hazards first met in
  stages, campaign-only rewards that help endless runs)?
- **Failing a stage**: what happens when Rok is caught or runs out of hearts
  (retry right away, cost refunded or not, a "you need to be stronger" hint
  pointing at endless runs).
- **Balance**: how hard the first stages are, how fast difficulty climbs,
  and checking it with a bot (like the endless-run autopilot).

- **What's in each milestone, skill tree, accessory and set**: the actual
  milestone rewards per species, each hero's skills, the accessory list and
  each boss set's bonus. Content to write once the Market is settled, so
  perks, skills and accessories don't overlap.
- **The level path and skill tree screens**: how they look at the Camp
  (joins the campaign screens prototype).

## Out of scope

- **Pets in the campaign**: the user wants pets to join stages later; that
  belongs to the pet system's own map. Stage settings shouldn't make it
  impossible, nothing more.
- **Ads**: they'll later refill the play cost; this map only leaves room for
  them.
- **Pet battles and PVP**: their own effort (see docs/GAME_DESIGN.md).
- **Real money** (a premium currency, purchases): later; the Market leaves
  room for it ([What the Market is for](14-market-role.md)).
