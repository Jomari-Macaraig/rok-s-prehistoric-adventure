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
campaign cycles with endless runs, and its screens. Decide everything first;
build afterwards.

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

## Out of scope

- **Pets in the campaign**: the user wants pets to join stages later; that
  belongs to the pet system's own map. Stage settings shouldn't make it
  impossible, nothing more.
- **Ads**: they'll later refill the play cost; this map only leaves room for
  them.
- **Pet battles and PVP**: their own effort (see docs/GAME_DESIGN.md).
