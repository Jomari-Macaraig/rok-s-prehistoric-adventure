---
title: Loading each stage
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: [10-campaign-growth]
---

# Loading each stage

## Question

How should a stage load, so the game stays memory-efficient as the campaign grows to many zones, bosses and species? Today the game preloads almost everything once at launch, behind the loading screen (`scripts/preloader.gd`: the equipped forms, plus whole folders of fx, hunters, traps, items, props, terrain and backgrounds; docs/systems/run-loop.md). For stages: what loads before a stage (only its zone, its hazards, its boss, its puzzle pieces, the brought dinosaurs?), what stays loaded all the time (Rok, the HUD), what gets freed after the stage or when leaving the campaign, and does the launch preload shrink to match? The stage loading screen should look like the main one (the user's loading-screen kit, progress bar, a tip), perhaps with the stage's name and goals. What's the memory budget to aim for on a phone, and how is it checked?

(Added by the user, 2026-11-24. Waits on "How the campaign grows with more species", which decides how many zones, bosses and species a stage can pull in.)

## Resolution

Decided with the user (2026-11-24):
- **Always loaded (the core)**: the played hero, the HUD and menus,
  pickups, effects, sounds and music.
- **Per stage**: only its zone (background, ground, that zone's obstacles
  and traps), its boss, its puzzle pieces, its wild species, and the four
  equipped dinosaurs. Nothing from other zones.
- **Endless runs stream zones**: the current zone plus the next one,
  prepared in the background while running; the zone left behind is freed.
  **Launch loads only the core and the first zone** (faster too), instead of
  whole folders.
- **Retrying** a stage reloads nothing; going back to the chapter map frees
  the stage's extras; leaving the campaign frees everything campaign-only.
- **Stage loading screen**: the main loading screen's look (the user's kit,
  progress bar, a tip) plus the stage's name, its 3 star goals and
  recommended vs your Strength, ending on "Tap to start".
- **Memory budget in config** (a first guess of about 400 MB of images in
  memory on a phone); a test loads each stage and endless zone, measures,
  and fails over budget. Building starts by measuring today's launch.

Feeds: the campaign screens (the stage loading screen), building (the
preloader rework, `scripts/preloader.gd`), and endless runs (zone
streaming).
