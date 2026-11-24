---
title: What a boss stage is
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# What a boss stage is

## Question

In a boss stage, what is the boss dinosaur, what does it do during the run, and how does the player beat it (outrun it to the finish, hit it with ATTACK a number of times, survive its attacks for a while, something else)? How is it different from the zone hunters that already chase Rok?

## Resolution

Decided with the user (2026-11-24):
- **Where the boss is**: it runs **ahead** of Rok and throws attacks back at
  him; Rok wears down its **health bar** (top of the screen) with ATTACK.
  (A boss that chases from behind, or stages mixing both, may come later as
  variants.)
- **Who is a boss**: any species, big or small. The first chapter bosses
  reuse the hunters (T-rex Forest, Carnotaurus Desert, Allosaurus Volcanic,
  one to pick for the Canyon); smaller dinosaurs can be bosses too; new boss
  species come later with their art.
- **How it plays**: a normal approach run (about 600-800 m), then the boss
  jumps in ahead and the fight starts. **Beating it clears the stage** (no
  finish line in a boss stage).
- **Its attacks**: warned a moment before (a flash, a roar) and answered
  with moves the player knows: a kicked-back rock (jump), a tail sweep
  (slide), a roar shockwave on the ground (jump), a backward charge (dodge
  or shapeshift). A hit costs hearts like an obstacle.
- **Damage**: only ATTACK hurts it (Rok's weapon or Fist, or a dinosaur
  form's attack), more with higher Power and better weapons. Smashing
  obstacles or a Primal Frenzy doesn't.
- **Two phases**: at half health it **enrages**: it attacks more often and
  gains one extra move.
- **Losing**: out of hearts, or the boss **escapes** if it isn't beaten
  within a set fighting distance (for example 800 m). **No hunter** chases
  during the fight.
- **Each boss is set in config**: health, speed, its attack list and how
  often it attacks (small bosses fast and fragile, big ones slow and tough).
- **Art**: until the user supplies boss clips (running ahead, a wind-up per
  attack, hurt, defeated), the game uses existing clips plus a flash and
  shake on hits; the art spec is in docs/TODO.md.

Feeds: "What settings define a stage" (boss settings), "What stages pay"
(what a boss pays), and the screens (the boss health bar).
