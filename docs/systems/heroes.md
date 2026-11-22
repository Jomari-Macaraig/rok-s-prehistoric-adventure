# Heroes

Rok, Nira and Boro: the human form on the ROK button. Buying and playing a
hero, and the new-best celebration jump.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/heroes.gd` (`Heroes`), `main.equip` / `unequip("hero")` / `equipped_in("hero")` / `owns_form` |
| Data and art | `assets/heroes/heroes.json`, `assets/characters/<id>/` (`tools/prepare_heroes.gd`); celebration `assets/characters/<id>/celebrate.png` + `celebrate.json` |
| Prices | `[market]` nira 1200, boro 1800 meat; `[market_unlocks]` 2500 / 4500 m |

## The heroes

| Hero | Role | Speed / Jump / Stamina / Power / Armor |
|---|---|---|
| Rok | all-rounder (free) | 4 / 5 / 4 / 2 / 2 |
| Nira | quick scout: fast and springy, but fragile | 5 / 6 / 4 / 1 / 1 |
| Boro | sturdy guardian | 3 / 3 / 4 / 4 / 3 |

- Stats in `Dinos.HERO_STATS`, on the originals' 17-point budget.
- All heroes count as "Rok" to the attribute code: category "rok", tier 0 ("Hero · <role>"), level cap 10 in everything (see [attributes](attributes.md)).
- Each levels and earns XP on its own (see [leveling](leveling.md)).
- Every hero keeps Rok's abilities: double jump, no energy drain, turns into the dinosaurs.
- Every hero has a swing per weapon (see [combat](combat.md)) and wears gear (see [weapons-and-armor](weapons-and-armor.md)).

## Buying and playing

- Nira and Boro are bought in the Market's Heroes tab and stored in `main.dinos_owned` (the Herd Keeper badge counts only dinosaurs).
- `main.owns_form(id)`: Rok and the originals always; bought heroes and dinosaurs once bought.
- Choose a hero in the Camp's Heroes tab ("Play as …"): `main.equip("nira")` sets `Forms.equipped[ROK]`, saved as `equipped["hero"]`. `main.equip("rok")` puts Rok back.
- Equipping refreshes the running sprite (`Player.refresh_form`), the button portrait and the chase meter's runner icon (`Hud.refresh_form_icons`).
- Art goes through `Dinos.form_data`'s species branch (`_play_of` reads `Heroes.play(id)`).
- The summary heading names the hero.

## Celebration jump

The user's art for each hero (`SpriteLib.celebrate_meta`, added as `celebrate` by `_add_celebrate`).

- The first ground jump within `celebrate_t` (4 s) after passing the best-distance flag plays it instead of the normal jump (`Player._do_jump`).
- The art has no root motion, so jump physics are unchanged. In the air, frames launch..land−1 follow vertical velocity (`_update_celebrate_frame`); landing plays the land and recover frames once, then back to `run`.
- Shifting form, an air jump or a new run (`reset_celebration`) cancels it.

## Open items

- The pack's hurt, transform and victory clips aren't used yet.
