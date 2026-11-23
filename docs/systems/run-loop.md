# Run loop, states, summary and main menu

How a run starts, plays, ends and hands back to the main menu.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/main.gd` (states, input, run step), `scripts/summary.gd` (summary card), `scripts/save_data.gd` |
| Save file | `user://rok_runner.cfg` (`SaveData.path` can be redirected; tests and screenshots use their own) |
| Tests | `start_run(false)` skips the intro in every test |

## Game states

`main.state`: TITLE → INTRO → PLAYING → DYING → OVER → TITLE, plus PAUSED and INFO.

| State | What's on screen | A tap… |
|---|---|---|
| TITLE (main menu) | title panel ("Tap to run" / "Tap to run again"), Encyclopedia, Dinosaurs and Marketplace buttons, daily missions | starts a run (ignored for `MENU_GRACE` 0.35 s after the summary) |
| INTRO | the hunter charges in and roars | nothing (input ignored) |
| PLAYING | the run | jump, or the button it hits |
| PAUSED | pause menu | resumes |
| INFO | an info card about something new (see [progression](progression.md)) | dismisses it |
| DYING | the death animation; world frozen | nothing |
| OVER | the summary card only (side buttons and combo meter hidden) | opens the main menu |

Keyboard (desktop testing): Space = jump / go on, R = restart now, X = stop, C = Field Guide, M/K = Market.

## A run, step by step

**1. Intro** (`start_run(intro := true)`, `_intro_step`, `INTRO_TIME` 1.7 s)
- Rok stands at `INTRO_PLAYER_X` (680) so the whole hunter fits on screen.
- The hunter charges in to `INTRO_ROAR_GAP` and roars (shake, `trex_roar`).
- Rok startles ("!" and his shout `rok_alarm`, the user's recording; silent until supplied) and sprints.
- Speed ramps up while Rok eases back to `PLAYER_X` and the gap opens to `CHASE_GAP_START`.
- `start_run()` also clears any slide, cooldown and attack clip (`Player.reset_actions`).

**2. Playing** (`main._play_step`)
- World speed ramp, energy drain, scoring, collisions (`_collide`) and the support surface (`_support_y`: terrain height under Rok, or a platform above it).
- Airborne and already below the terrain (fell into a pit and its far wall arrived): he keeps falling; below the screen → `_fell_in_pit()`.
- `_check_unlocks()`: the first time a run reaches a dinosaur's distance it unlocks (banner, button pulse, `unlock` sound, energy topped to 60).
- `_request_form()` refuses locked forms with a "Reach N m" popup.
- Auto-pause when the app loses focus (`NOTIFICATION_APPLICATION_FOCUS_OUT`).

**3. Ending a run**
- **Death** (`Player.die`): a Mario-style hop. Rok freezes on the hit for `DEATH_FREEZE` (0.5 s), kicks up (`DEATH_HOP`) and falls off the bottom, drawn in front of everything. Frames: 0–1 "die", 2–7 "hop" (`SpriteLib.death()`).
- **Everyone else stops** (`_freeze_world`): every child of `world` except the player and fx is disabled, so scrolling, the hunter (frozen mid-bite if it caught him), obstacles, liquids, plants, pickups and particles hold still.
- The music cuts out (`Audio.duck_music`) and the death jingle plays. The summary waits `DEATH_FREEZE` + 1.7 s so the jingle finishes.
- Pit, lava, water and quicksand deaths hide Rok with a splash instead.
- **Stop** (`Hud.stop_button`, top left, during a run and while paused): the first tap arms it, a second within `STOP_CONFIRM_TIME` ends the run (`main.stop_run`: no death animation, meat banked, cause "stopped", the summary says RUN OVER).
- `death_cause` records what ended the run (for the summary and tests).

**4. Summary card** (`summary.gd`, `RunSummary`, layer 15)
- Shown by `_finish_game_over` → `show_run(dict)`; hidden by `start_run` / `_to_title`.
- EXTINCT! / CAUGHT! / RUN OVER with the cause in plain words (`cause_text`), NEW BEST! ribbon.
- **Run rank**: big letter, its bonus, what the next rank needs.
- Tiles: distance (and zones), score, meat (with the rank bonus), best run.
- **Table** of Rok and the dinosaurs played (Rok first, then up to 4 by metres; `main.run_dino_m`): idle-animated icon, name with tier and level, metres, XP gained, an `XPBar` (before-the-run blue, this run's gain filling in), and READY FOR LV N! / "N to Lv N" / MAX LEVEL.
- The run's news (`new_this_run`, Market items, badges).
- It ignores the mouse; a tap goes to the main menu (`_to_title`), never straight into a run.
- `hud.show_game_over` still fills its labels (tests read them) but stays hidden.

**5. Main menu** (`_to_title`): the title screen again, now saying "Tap to run again" (`played_once`).

## Run ranks

`Tuning.RUN_RANKS` (the user wanted them very steep):

| Rank | Score | Meat and XP × |
|---|---|---|
| C | 0 | 1 |
| B | 3000 | 1.25 |
| A | 8000 | 1.5 |
| S | 20000 | 2 |
| SS | 50000 | 3 |

`main._apply_rank()` runs once per run from `_bank_meat`: it sets `run_rank`, adds `run_bonus_meat` (meat × (multiplier − 1)) and the same extra share of XP to Rok and every dinosaur played.

## Input

- Touch (`_input`): each finger is hit-tested with `hud.action_at()` and remembered until release, so JUMP can be held while another finger taps a form. A touch that misses every button counts as jump.
- Keyboard (`_unhandled_input`), set up in `_setup_input`. See [hud-and-controls](hud-and-controls.md).

## Save data

`save_data.gd` stores best score and distance, unlocked forms, owned power-ups, open booster slots, banked meat, banners seen, Field Guide entries viewed, the mute setting, and every system's own state (gear, levels, badges, missions…).

## Coordinates

- Viewport 1280×720 (wider on phones). Feet line `GROUND_Y` = 560 (raised from 604 so the buttons fit on the dirt); raised levels at 513 and 466. Grass tips sit `FEET_BELOW_GRASS` (8 px) above the feet line.
- Rok stays at x = 335 (`PLAYER_X`). The world scrolls left at `speed`: 380 px/s, +3 px/s every second, capped at 900.
- Character sheets are pre-scaled by 7/16: Rok 168×224 (pivot 84, 213.5), dinosaurs 224×168 (pivot 112, 157.5).

## Loading screen (`scripts/preloader.gd`)

The user's request: no hitches in the game itself. On a normal launch, main adds a `Preloader` over everything (CanvasLayer 100). It uses the boot splash's green, the app icon, a progress bar ("Loading... N%") and a random tip, and taps wait until it's done.
1. **Load:** the forms on the buttons (Rok or the played hero, and the four equipped dinosaurs: body, attack and hit-reaction sheets) and whole folders (`WHOLE`: fx, hunters, the T-rex, traps, items, power-ups, flag, gear, wind, props, terrain, backgrounds). This runs on background threads, and everything is held in `Preloader.keep`.
2. **Decode:** `SpriteLib.tex` for every character, attack and reaction sheet. It decodes the `@2x` twins on the main thread, `BUDGET_MS` per frame.
3. **Build:** the run's SpriteFrames (`frame_jobs`): each form's body and death, attacks, reactions, the T-rex and zone hunters, the shapeshift burst, the power-up effects, Elder Numa, the milestone chest and meat loop (`Pickup.warm`; the chest stuttered on first sight) and every power-up's loop. Props, traps, items and gear also have their `@2x` twins decoded (`SHARP_WHOLE`).

**Hints** (the user's request) come from **`config/hints.cfg`**: about 35 hints, each `[text, needs]`. Only hints the player is ready for are shown (`hint_ready`), so nothing is spoiled. "needs" can be:
- a best distance,
- `dino:<id>` (that dinosaur is unlocked),
- `intro:<key>` (that thing has been introduced),
- `bench`, `slot2` or `charge`.

The shown hint changes every `[settings] seconds`.

**The look** is the user's loading screen kit (`../Assets/Rok_Loading_Screen_Kit`, imported by `tools/prepare_loading.py` into `assets/loading/`, positions in `loading.json` on a 1920×1080 design canvas). The kit is laid out on that canvas, scaled to fit and centred (`_kit_layout`), over the jungle background, which covers the whole screen:
- the ROK logo,
- the game's own Rok, Raptor and Triceratops run animations in the kit's boxes, with contact shadows, puffing dust and pulsing gold ribbons,
- a few drifting leaves,
- the LOADING label,
- the wooden track, with the gold fill clipped to the progress (`_kit_progress`; the fill keeps its rounded caps),
- the footprint marker riding the fill's edge (hidden at 0 and 100%),
- the live tip ("TIP: …").

Without the kit it falls back to the plain splash-green screen with the app icon.

Then it fades out and frees itself. It takes about 1.4 s on a Mac, and afterwards the first shapeshift and attack in a run take 0.4 ms instead of about 43 ms. `start_run` calls `Preloader.warm_forms()`, so a dinosaur equipped later is built during the intro. Test and screenshot scripts don't get it: main only adds it when it is the tree's `current_scene`.

