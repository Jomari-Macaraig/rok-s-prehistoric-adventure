---
title: The level path and skill tree screens
label: wayfinder:prototype
status: closed
assignee: claude
blocked_by: []
---

# The level path and skill tree screens

## Question

How do the Camp's new screens look: a character's level path from 1 to 20 (milestones and evolutions as icons, unlocked lit, next highlighted) and a hero's skill tree (branches, skill points to spend, free reset)? A rough prototype to react to, at 1280x720 and 1560x720.

## Resolution

Decided with the user (2026-11-24): **variant A, the road and the growing
tree.**

Prototype (throwaway, never merged): branch `prototype/level-path-screens`,
file `docs/wayfinder/campaign/prototype/level-path-screens.PROTOTYPE.html`
(three variants, `?variant=A|B|C`; the Raptor and Rok tabs).

What A means for the build:
- **A dinosaur's level path** (the Camp, a dinosaur picked): levels 1-20 as
  a **winding road across the screen** under the dinosaur's portrait and XP
  bar. Plain levels are small dots; **milestones** are bigger gold circles
  with their icon (trick, perk, look) and name below; **evolutions** (10 and
  20) are the biggest, purple; reached ones are lit, the **next level
  glows**; a "Next: Lv 8 · Hunter's Eye" chip. Tapping a milestone shows a
  card with its reward and whether it's unlocked.
- **A hero's skill tree** (the Camp, a hero picked): the hero standing at
  the bottom-left, a panel with level, XP bar, **skill points** and **Reset
  (free)**; the **three branches grow upward** as columns of skill cards
  from the branch's name at the bottom. Learned skills are filled in the
  branch's colour, learnable ones have a gold rim, the rest are locked
  (each needs the one below it). Bigger skills cost more points. Tapping a
  learnable skill learns it.
- Fits 1280x720 and 1560x720 (checked in the prototype).
- Art needed later: path dots and milestone/evolution circles, milestone
  icons, branch banners, skill card frames (spec in docs/TODO.md when
  built).
