---
title: What settings define a stage
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: [01-boss-stages, 02-puzzle-stages, 05-star-goals]
---

# What settings define a stage

## Question

Stages are made from config settings. What is the full list of settings for one stage (zone, length, hazards and how often, difficulty, required or suggested dinosaurs, boss, puzzle pieces, star goals, rewards, recommended strength, cost)? Which file holds them, and how does a new species' stages get added?

## Resolution

Decided with the user (2026-11-24):
- **Same course every try**: each stage builds the exact same course each
  time (a fixed seed per stage), so it can be learned.
- **Files**: general campaign settings (torches, unlock, bosses) in
  `config/campaign.cfg`; stages in **one file per chapter**,
  `config/campaign/<chapter>.cfg`, one section per stage.
- **Every stage**: name; kind (run, boss, puzzle); zone; length; difficulty
  (speed and how close hazards come); which hazards can appear; whether wild
  dinosaurs and the hunter appear (and the hunter's charges); suggested
  dinosaurs; its two star goals with their numbers; its rewards (first clear
  and replay, sized by "What stages pay"); its recommended strength (once
  "How recommended strength is worked out" is decided).
- **Bosses** are described once in `config/campaign.cfg` (health, speed,
  attacks, how often, what changes on enrage); a boss stage names its boss
  plus its approach length and escape distance, and may override a boss's
  numbers (a tougher T-rex later).
- **Puzzle stages** add their pieces in order, starting energy, amber spots,
  the dinosaurs they need, and a hint per piece.

Feeds: building (the config format), "How the campaign grows with more
species" (adding a chapter file), and balance (checking stages with a bot).
