---
title: Loading each stage
label: wayfinder:grilling
status: open
assignee: 
blocked_by: [10-campaign-growth]
---

# Loading each stage

## Question

How should a stage load, so the game stays memory-efficient as the campaign grows to many zones, bosses and species? Today the game preloads almost everything once at launch, behind the loading screen (`scripts/preloader.gd`: the equipped forms, plus whole folders of fx, hunters, traps, items, props, terrain and backgrounds; docs/systems/run-loop.md). For stages: what loads before a stage (only its zone, its hazards, its boss, its puzzle pieces, the brought dinosaurs?), what stays loaded all the time (Rok, the HUD), what gets freed after the stage or when leaving the campaign, and does the launch preload shrink to match? The stage loading screen should look like the main one (the user's loading-screen kit, progress bar, a tip), perhaps with the stage's name and goals. What's the memory budget to aim for on a phone, and how is it checked?

(Added by the user, 2026-11-24. Waits on "How the campaign grows with more species", which decides how many zones, bosses and species a stage can pull in.)
