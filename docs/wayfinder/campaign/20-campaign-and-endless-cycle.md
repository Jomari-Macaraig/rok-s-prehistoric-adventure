---
title: How the campaign and endless runs feed each other
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# How the campaign and endless runs feed each other

## Question

Once the campaign exists, does anything in endless runs change? Where is a
hazard first met (endless runs, stages, either), and does meeting it in one
mode count in the other? Which things stay campaign-only (bosses, puzzle
pieces) and which campaign rewards help endless runs (boss sets, accessories,
Trail cards and XP)? Do missions, badges, chests and the run summary point
the player from one mode to the other ("next stage needs Strength 40, you
have 38")? The goal from [GAME_DESIGN.md](../../GAME_DESIGN.md): endless runs
are where you grow, the campaign is where you prove it.

## Resolution

Decided with the user (2026-11-24). Endless runs grow you; the campaign
proves it and pays what meat can't buy.
- **Introductions in either mode**: a stage may introduce a hazard the
  player hasn't met, taught the same way (NEW banner, alone first).
  Meeting it counts in both modes (Field Guide entry, no repeat banner).
  The endless-run introduction order and distances stay exactly as they
  are.
- **Campaign-only**: Bosses, puzzle pieces (Switches, Gems, Doors,
  Checkpoints), Stars and Torches. **Shared**: hazards, wild dinosaurs,
  hunters, weather and pickups.
- **One team, same rules**: gear, Tricks, Traits, skills, accessories and
  set bonuses work identically in both modes (the Allosaurus set bonus
  works at 5,000 m in an endless run). The campaign helps endless runs
  only through what it gives the team (Boss Sets, accessories, Trail cards
  and XP, Kora's Blessing); endless runs get no new content from it.
- **Run summary**: once the campaign is open, the endless-run summary adds
  "Strength 38 (+2 this run). Next stage: Desert 4 needs 40"; tapping it
  opens that stage's briefing.
- **Missions and badges**: once the campaign is open, about 1 in 3
  daily/weekly missions is a campaign goal ("Clear 2 stages", "Earn 3
  stars", "Beat a boss"), never needing a stage the player can't reach.
  Badges gain tracks for stars earned, bosses beaten, Trails finished.
- **Chests**: once the campaign is open, rare and better milestone chests
  have a small chance of 1 torch (reward torches still cap at 10).
- **No farming**: endless runs never drop Boss Materials or eggs; the
  campaign stays the only source of Boss Sets. Endless runs stay the best
  source of meat, materials and XP.

Feeds: the spec (`docs/systems/campaign.md`), `progression.md` (shared
"met" list), `goals.md` (campaign missions, badge tracks), `run-loop.md`
(summary line), `pickups.cfg` (chest torch odds), `missions.cfg`; the
balance question (21) checks the Strength numbers the summary shows.
