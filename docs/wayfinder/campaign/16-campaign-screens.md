---
title: The campaign screens
label: wayfinder:prototype
status: closed
assignee: claude
blocked_by: [08-recommended-strength]
---

# The campaign screens

## Question

How do the campaign screens look and flow? The main menu's Endless Run and Campaign buttons (and the locked Campaign button), the chapter map and stage picker (chapters, stages, Trails, stars, locks, the torch row and its timer), a stage's briefing (kind, goals, recommended strength, suggested dinosaurs, cost, rewards, time and weather), the in-run bits (star tracker, boss health bar, checkpoint), and the results screen (stars, XP bars, items, NEW tags). A rough clickable prototype to react to, sized for 1280x720 and 1560x720.

## Resolution

Decided with the user (2026-11-24): **variant A, the trail map.**

Prototype (throwaway, never merged): branch `prototype/campaign-screens`,
file `docs/wayfinder/campaign/prototype/campaign-screens.PROTOTYPE.html`
(three variants, `?variant=A|B|C`).

What A means for the build:
- **Main menu**: two big buttons, **Endless Run** and **Campaign** (the
  Campaign button shows the chapter, progress and torches; locked, it lists
  what's still needed).
- **Campaign screen**: each chapter is a **winding path of stage circles**
  on the zone's backdrop: number and stars on cleared ones, the next one
  glowing ("NEXT"), locked ones dim with a lock, puzzle and boss stages with
  their own icons (the boss circle stands out). **Trails branch off the
  path** as side signs (locked until the chapter boss is beaten). Chapter
  buttons along the bottom; the chapter's star total and star chests
  bottom-right; the torch row with its timer and your Strength in the top
  bar.
- **Tapping a stage** opens its **briefing** as a popup (kind, chapter and
  stage number, time and weather, the 3 goals with earned stars, suggested
  and needed dinosaurs, first-clear rewards, recommended vs your Strength in
  green/yellow/red, the torch cost note, Start).
- Shared parts kept as shown: the **stage loading screen** (name, goals,
  Strength, progress, tip, "Tap to start"), the **in-run** pieces (hearts and
  PRIMAL, distance to the finish, a star-goal tracker, the boss health bar,
  the puzzle checkpoint and gem counter), and the **results** popup (stars,
  XP bars, rewards with NEW tags; on failure the spent torch, kept stars,
  Retry and Endless Run).
- Art needed later (spec in docs/TODO.md when built): path and stage-circle
  pieces per zone, boss and puzzle stage icons, Trail signs, the torch icon.
