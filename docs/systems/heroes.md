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

## Skill trees

Hero levels pay out in **skill points** (campaign build ticket
[08](../wayfinder/campaign-build/08-rok-skill-tree.md)): one per level from 2
to 20, 19 in all. Heroes grow no attributes by level ([leveling](leveling.md)).

| | |
|---|---|
| Config | **`config/skills.cfg`**: `[general] costs` (1, 1, 2, 2, 3), `[tree.<hero>] branches`, `[branch.<id>]` name, colour and its five skills bottom to top, `[skill.<id>]` name, text and `value` (the number its code reads) |
| Code | `scripts/skills.gd` (`Skills`: `tree`, `place`, `cost`, `points`, `free_points`, `can_learn`, `learn`, `reset`, `has` for the hero being played, `value`), `main.learn_skill` / `main.reset_skills` (save + `Forms.clear_cache`), `scripts/skill_tree_view.gd` (the screen) |
| Saved | `progress/skills` (hero -> [skill ids], `SaveData.load/save_skills`) |

**Rules**: three branches of five skills costing 1, 1, 2, 2, 3 (9 a branch, 27
for all, so two branches fill but not three); each skill needs the one below
it; Reset is free. A skill works for the hero being played (`Skills.hero()`:
Rok, or Nira/Boro on his button). Movement and ATTACK skills work only in the
hero's own form; heart, hunter and once-a-run skills all run long.

**Rok** (built; Nira's and Boro's trees are ticket 09):

| Branch | Skill | In the game |
|---|---|---|
| Runner | Quick Feet | slide cooldown × 0.75 (`Player.press_slide`) |
| | Air Step | +1 air jump as the hero (`Dinos.form_data`; `Forms.get_data` builds Rok's data when he knows it) |
| | Slipstream | each clean dodge (`_combo_step`) adds 6 px of chase gap |
| | Light Feet | no sinking in quicksand as the hero (`_check_quicksand`) |
| | Second Wind | once a run, a pepper speed burst when the chase gap drops under 40 (`_skill_step`) |
| Brawler | Heavy Swing | `attack_power()` × 1.2 (breaks by Power; boss damage later) |
| | Quick Hands | ATTACK cooldown × 0.8 |
| | Rock Breaker | ATTACK breaks boulders whatever the Power. (The spec said "always breaks small hazards", but ATTACK already does that for everyone, so it breaks rocks instead.) |
| | Combo Strike | every third boss hit in a row does double: waits for bosses (ticket 22); no effect yet |
| | Ground Pound | ATTACK while sliding breaks every small hazard within 260 px (`_ground_pound`) |
| Survivor | Tough Hide | the first hit of each run is free (`_hurt`) |
| | Shake It Off | stumbles cost × 0.6 chase gap (`_stumble`) |
| | Iron Will | at 1 heart or less, hits cost half (rounded up) |
| | Patch Up | +¼ heart every 500 m without a hit (`_skill_step`, `_last_hit_m`) |
| | Last Stand | once a run, a hit that would end it leaves ¼ heart; pits, liquids and being caught still end it (they don't go through `_hurt`) |

**The screen** (`SkillTreeView`, variant A of the level-path prototype): the
Camp's hero detail has a **Skill Tree (n)** button under the XP bar (n = free
points). It opens full screen over the Camp: a parchment panel on the left
(the hero, level, XP, skill points, the tapped skill's name, text and
**Learn · n points**, or why it can't be learned yet, then Back and **Reset
(free)**), and the three branches on the right as columns of five cards
growing upward, the branch name at each foot. Cards use the user's frames
(`assets/ui/camp/skill_card_{learned,learnable,locked}.png`, from
`tools/prepare_camp_ui.py`): learned filled in the branch colour with a check,
learnable on parchment with a gold rim, locked on grey stone with a padlock.
Card size comes from the screen height (5 rows) and width (3 columns). A first
tap selects a card; a second tap on a learnable one learns it.

## Open items

- The pack's hurt, transform and victory clips aren't used yet.
