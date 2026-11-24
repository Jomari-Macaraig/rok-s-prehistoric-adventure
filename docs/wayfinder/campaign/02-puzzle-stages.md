---
title: What a puzzle stage is
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# What a puzzle stage is

## Question

What does "puzzle-like" mean inside a runner? For example: picking the right dinosaur for a sequence of gates, timing switches that open the way, finding a hidden path, collecting keys in order. Which kinds of puzzle are in, and how does a puzzle stage end (finish line, solved puzzle)?

## Resolution

Decided with the user (2026-11-24):
- **Kinds of puzzle** (all three from the start):
  - **Right dinosaur, right moment**: chains of dino gates, water,
    crumbling bridges and quicksand, each needing a certain dinosaur, with
    limited PRIMAL energy.
  - **Switches and paths**: stone **switches** hit with ATTACK lower a
    bridge or open a gate; **forks** where the upper or lower path is
    chosen, one a dead end.
  - **Keys**: coloured **gems** open stone **doors** of the same colour
    later on; some gems sit off the main path (reached by a fork, a switch
    or a dinosaur).
- **Pace**: puzzle stages run **slower** and have **no hunter**.
- **Mistakes**: **checkpoints** (a totem) along the stage; a wrong choice (a
  pit, the wrong gate, a closed door) costs a heart and sends Rok back to
  the last checkpoint. Out of hearts fails the stage.
- **Switches stay on** until Rok is sent back to a checkpoint before them,
  which resets them. No timers.
- **End**: a finish line after the last puzzle.
- **Made from config**: a puzzle stage lists its **pieces in order** (for
  example: Raptor gate, switch bridge, water, checkpoint, fork, gem, door),
  plus its **starting energy** and hand-placed **amber**; the game builds
  the course from that list.
- **Needed dinosaurs**: a puzzle stage lists the dinosaurs it needs and is
  **locked until they're unlocked** in endless runs (the one exception to
  "recommended, not locked").
- **Hints**: after **3 returns** to the same checkpoint, a hint for the next
  piece appears (its text written per piece in the stage settings).
- **Art**: switches (off/on), coloured doors (closed/open), gems in a few
  colours and a checkpoint totem; stand-ins drawn in code until the user's
  art (spec in docs/TODO.md).

Feeds: "What settings define a stage" (piece list, energy, amber, needed
dinosaurs, hints), "The list of star goals" (puzzle-stage stars), and the
screens (a locked puzzle stage says which dinosaurs it needs).
