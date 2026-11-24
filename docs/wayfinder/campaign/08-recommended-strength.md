---
title: How recommended strength is worked out
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: [11-levels-rethink, 12-gear-slots]
---

# How recommended strength is worked out

## Question

Each stage shows a recommended strength. Is it a single number (a power score from levels, attributes and gear), or a short list ("Raptor level 4, a Rare weapon")? How does the game compare it to the player's current strength and show it (green / yellow / red)?

## Resolution

Decided with the user (2026-11-24):
- **One number, called Strength** ("Power" is already an attribute).
- **What adds up**: the hero (level, skill points, gear by rarity and
  upgrade level, worn-out pieces counting half) plus the four equipped
  dinosaurs (level and evolution). Weights in config.
- **Briefing**: "Recommended: 40 · You: 32", the player's number coloured
  green (at or above), yellow (within about 15% below), red (well below).
  Any reached stage can still be tried.
- **Each stage's recommended Strength is set in its config**, and a test
  bot checks the stage is beatable at that Strength.
- **Shown elsewhere**: at the Camp and next to the Campaign button, ticking
  up with a small animation when it grows.

Feeds: the campaign screens (briefing, Camp, menu), failing a stage (the
nudge), balance (the bot check).
