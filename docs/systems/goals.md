# Badges, daily missions and the best-distance flag

Long-term goals (tiered badges, which also unlock Market items), three daily
missions, and the flag marking your best distance.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/badges.gd` (`Badges`), `scripts/missions.gd` (`main.missions`), `scripts/best_flag.gd` (`BestFlag`), `main.badge_event` / `badge_best` / `_badge_run_step` / `_course_badges` / `_award_badges` |
| Config | `[market_badges]` (which items need which badge tier) |
| Art | medals `assets/badges/<id>_<0-3>.png` (`tools/prepare_badges.py`); flag `assets/best_flag/` (`tools/prepare_animation_pack.gd`) |
| Saved | `main.badge_stats`, `main.badge_tiers` (`SaveData.load/save_badges`), missions (`SaveData.load/save_missions`) |

## Badges

Each has Bronze, Silver and Gold tiers (`Badges.DATA`: id → name, goal text, stat, kind, three targets).

**Design rules**
- Every badge needs the course, never a button you can mash (no "slide N times" or "transform N times").
- Targets are long-term (raised after playtesting showed a couple of casual runs earning most Bronzes): Bronze = a few runs doing it on purpose, Silver = tens of runs, Gold = mastery.

**Kinds of stat**

| Kind | Examples |
|---|---|
| total (adds up over every run) | obstacles smashed, meat, amber, dino gates passed, low ledges slid under, metres flown, charges escaped, wild dinosaurs led to the hunter |
| best (one run) | distance, distance since the last stumble, metres as a dino, zones reached |
| current count | dinosaurs owned (Herd Keeper: 1 / 10 / 28) |

Examples: Marathon 2000 / 4000 / 7000 m, Untouchable 800 / 2000 / 4000 m, Explorer 3 / 5 / 9 zones, Amber Hoarder 250 / 1500 / 5000.

**Perk badges** (`Badges.PERKS`, the user's request): bonuses for good.

| Badge | Stat (B / S / G) | Perk (B / S / G) |
|---|---|---|
| Point Hunter (`scorer`) | total points, counted once per run in `_apply_rank`: 25k / 150k / 600k | +5 / 10 / 20% to every point (`points_mult`, stacks with the Golden Fossil) |
| Seasoned (`veteran`) | total dinosaur XP: 2k / 12k / 50k | +10 / 20 / 35% XP (`xp_mult`) |

**Category badges** (gate higher dinosaur tiers; see [dinosaurs](dinosaurs.md)): Swift Feet (`swift`, metres as a Runner), Iron Hide (`ironhide`, metres as a Tank); Rock Breaker and Sky Rider double as the Smasher and Flyer ones.

**How progress is counted**
- `badge_event(stat, amount)` for totals (hooked into `_smash`, pickups, charge escapes).
- `_course_badges`: a low ledge counts once it's behind Rok if he was sliding under it; a dino gate once its start is `GATE_CLEAR` (1300 px) behind him while he's still running.
- `badge_best(stat, value)` for bests; `_badge_run_step` tracks per-run stats a few times a second.
- Running totals are saved once per run (`_bank_meat`).

**Earning a tier** (`_award_badges`)
- `TIER_REWARD` meat (20 / 50 / 120, kept small so runs stay the main income) straight into the bank.
- A non-pausing banner mid-run, a "Badge: …" line in the summary news, and a red dot on the Field Guide button (`Codex.badges_new`).

**Badges unlock Market items** (`[market_badges]`, `"badge id:tier"`)
- Every Skilled / Expert / Legend dinosaur needs its category badge.
- Fossil Magnet: Amber Hoarder Bronze; Primal Berry: Primal Spirit Bronze; Golden Fossil: Untouchable Silver.
- `Market.on_sale` checks distance and badge (`Market.badge_ok`); earning the tier that completes one adds it to the run's Market news. `Badges.unlocks(id)` lists what a badge unlocks.

**Display**
- `Badges.icon(id, tier)`: the user's medals (0 = not earned, 1–3 = bronze/silver/gold); a placeholder medal for any still missing (none now: Point Hunter and Seasoned arrived with `Rok_Day_Night_Badges`).
- The Field Guide's **Badges** tab (`Codex._badge_card`): medal, next goal, what each tier unlocks, a progress bar, the three tiers with rewards; perk badges list their bonuses.

## Daily missions

- Three a day from `Missions.POOL`, picked by the date (seeded: the same all day) from what the player can already do (`eligible`: best distance, unlocked forms); targets are harder further along (`target_for`).
- "total" missions count across the day's runs, "best" ones within a run.
- Progress comes from `badge_event` (`mission_event`), `badge_best`, the combo tier, chests and frenzies.
- Each one done pays `MISSION_MEAT` into the bank, with a banner and a news line.
- All three pay `MISSION_ALL_MEAT` + `MISSION_STREAK_MEAT` per streak day (`complete_day`); a missed day restarts the streak.
- Listed on the main menu (`Hud.set_missions`, bottom centre; hidden in runs).

## Best-distance flag

- `start_run` plants one at `best_m` (if the record is 50 m or more), just behind Rok among the world's children; `main._best_flag_step` places it on the ground as it scrolls in.
- The user's art waves (`waving`) until Rok runs past, then switches to the green-and-gold `passed` loop; a "BEST N m" label floats above. Drawn in code without the art.
- Passing it the first time in a run: "NEW BEST!" banner, sparkles, the unlock sound, and `Player.celebrate_t` (`CELEBRATE_WINDOW`, 4 s): Rok's next jump is the celebration (see [heroes](heroes.md)).
