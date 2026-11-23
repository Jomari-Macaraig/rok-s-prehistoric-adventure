# scripts/: gameplay

## Scene tree (built by main.gd)
```
Main (main.gd)
├─ world (Node2D, shaken by Fx)
│  ├─ Background: sky gradient, parallax layers, wind-animated decor
│  ├─ Terrain: scrolling ground (slopes, levels, cliffs, pits) + grass tufts
│  ├─ Course: obstacles, floating platforms, pickups
│  ├─ Trex: the pursuer (behind Rok)
│  ├─ Player: Rok (AnimatedSprite2D + shadow)
│  ├─ Fx: particles, floating text
│  └─ Background.foreground: bg-3 fern layer drawn in front of the player
├─ Audio: sound-effect player pool + looping music
├─ lighting (CanvasModulate): zone + day/night tint of the world
├─ Hud (CanvasLayer): TouchButtons, energy bar, score, centre messages
├─ Codex (CanvasLayer 20): the Field Guide overlay
├─ Market (CanvasLayer 21): the shop overlay
└─ Herd (CanvasLayer 22): choose and compare the dinosaur on each button
```


## Systems
Each system is documented on its own in [docs/systems/](../docs/systems/README.md). Update that system's doc when you change it.

## Files → system docs
| Script | Documented in |
|---|---|
| `attack_marker.gd` | [combat](../docs/systems/combat.md) |
| `audio.gd` | [audio](../docs/systems/audio.md) |
| `background.gd` | [zones-and-environment](../docs/systems/zones-and-environment.md) |
| `badges.gd` | [goals](../docs/systems/goals.md) |
| `best_flag.gd` | [goals](../docs/systems/goals.md) |
| `bonus_portal.gd` | [long-run-events](../docs/systems/long-run-events.md) |
| `boosters.gd` | [power-ups](../docs/systems/power-ups.md) |
| `chase_meter.gd` | [chase-and-hunters](../docs/systems/chase-and-hunters.md) |
| `chest.gd` | [long-run-events](../docs/systems/long-run-events.md) |
| `codex.gd` | [field-guide](../docs/systems/field-guide.md) |
| `combo.gd` | [combo-and-frenzy](../docs/systems/combo-and-frenzy.md) |
| `combo_meter.gd` | [combo-and-frenzy](../docs/systems/combo-and-frenzy.md) |
| `course.gd` | [obstacles-and-gates](../docs/systems/obstacles-and-gates.md), [pickups-and-loot](../docs/systems/pickups-and-loot.md), [wild-dinosaurs](../docs/systems/wild-dinosaurs.md) |
| `critters.gd` | [wild-dinosaurs](../docs/systems/wild-dinosaurs.md) |
| `dino_facts.gd` | [field-guide](../docs/systems/field-guide.md) |
| `dinos.gd` | [attributes](../docs/systems/attributes.md), [leveling](../docs/systems/leveling.md), [dinosaurs](../docs/systems/dinosaurs.md) |
| `forms.gd` | [movement-and-forms](../docs/systems/movement-and-forms.md), [attributes](../docs/systems/attributes.md) |
| `fx.gd` | [rendering-and-fx](../docs/systems/rendering-and-fx.md) |
| `gear.gd` | [weapons-and-armor](../docs/systems/weapons-and-armor.md) |
| `gear_layer.gd` | [weapons-and-armor](../docs/systems/weapons-and-armor.md), [combat](../docs/systems/combat.md) (hidden during a carry run) |
| `hearts.gd` | [health-and-damage](../docs/systems/health-and-damage.md) |
| `herd.gd` | [camp](../docs/systems/camp.md) |
| `hazard_icons.gd` | [field-guide](../docs/systems/field-guide.md#hazard-pictures), [progression](../docs/systems/progression.md) |
| `heroes.gd` | [heroes](../docs/systems/heroes.md) |
| `hud.gd` | [screens-and-navigation](../docs/systems/screens-and-navigation.md), [hud-and-controls](../docs/systems/hud-and-controls.md) |
| `hunters.gd` | [chase-and-hunters](../docs/systems/chase-and-hunters.md) |
| `loot.gd` | [pickups-and-loot](../docs/systems/pickups-and-loot.md) |
| `main.gd` | [run-loop](../docs/systems/run-loop.md) |
| `market.gd` | [marketplace](../docs/systems/marketplace.md) |
| `market_scene.gd` | [marketplace](../docs/systems/marketplace.md), [screens-and-navigation](../docs/systems/screens-and-navigation.md) |
| `menu_tour.gd` | [tutorial](../docs/systems/tutorial.md) |
| `missions.gd` | [goals](../docs/systems/goals.md) |
| `obstacle.gd` | [obstacles-and-gates](../docs/systems/obstacles-and-gates.md) |
| `pickup.gd` | [pickups-and-loot](../docs/systems/pickups-and-loot.md) |
| `platform.gd` | [obstacles-and-gates](../docs/systems/obstacles-and-gates.md) |
| `player.gd` | [health-and-damage](../docs/systems/health-and-damage.md), [movement-and-forms](../docs/systems/movement-and-forms.md), [combat](../docs/systems/combat.md) |
| `progression.gd` | [progression](../docs/systems/progression.md) |
| `requires.gd` | [requirements](../docs/systems/requirements.md) |
| `run_events.gd` | [long-run-events](../docs/systems/long-run-events.md) |
| `save_data.gd` | [run-loop](../docs/systems/run-loop.md) |
| `scene_kit.gd` | [field-guide](../docs/systems/field-guide.md#the-scene-kit-look), [camp](../docs/systems/camp.md) |
| `sprite_lib.gd` | [rendering-and-fx](../docs/systems/rendering-and-fx.md) |
| `summary.gd` | [run-loop](../docs/systems/run-loop.md) |
| `terrain.gd` | [terrain](../docs/systems/terrain.md) |
| `touch_button.gd` | [hud-and-controls](../docs/systems/hud-and-controls.md) |
| `tutorial_run.gd` | [tutorial](../docs/systems/tutorial.md) |
| `tutorial.gd` | [tutorial](../docs/systems/tutorial.md) |
| `coach_marker.gd` | [tutorial](../docs/systems/tutorial.md) |
| `trex.gd` | [chase-and-hunters](../docs/systems/chase-and-hunters.md) |
| `tuning.gd` | every system's gameplay numbers (each system doc names the constants it uses) |
| `weather.gd` | [zones-and-environment](../docs/systems/zones-and-environment.md) |
| `zones.gd` | [zones-and-environment](../docs/systems/zones-and-environment.md) |
