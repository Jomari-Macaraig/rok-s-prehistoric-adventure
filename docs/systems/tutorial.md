# Tutorial: the training run and coach hints

Two parts (the user's brief: teach step by step, but never be annoying):
1. **The training run** plays once, at the very beginning: a short scripted
   run that teaches the controls.
2. **Coach hints** afterwards: a pulsing ring on a button and a few words, only
   for things the training run didn't cover, at the moment they're useful.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/tutorial_run.gd` (`TutorialRun`: the training run), `scripts/menu_tour.gd` (`MenuTour`: the menu tour after it), `Hud.coach_control` / `hud_part` / `coach_part`, `main.start_tutorial` / `end_tutorial` / `_tutorial_allows` / `_release_jump`; `scripts/tutorial.gd` (`Tutorial`: lessons and rules), `scripts/coach_marker.gd` (`CoachMarker`: the ring and bubble), `Hud.coach` / `hide_coach`, `main._coach_step` / `_coach_target` / `_coach_done` |
| Numbers | `COACH_*` in `tuning.gd`; `GAP`, `SHOW_TIME`, `MAX_SHOWS`, `START_QUIET` in `tutorial.gd` |
| Saved | training run done `SaveData.load/save_tutorial_run_done` (an existing save with any best distance counts as done); lesson progress `SaveData.load/save_tutorial` (saved at each run's end and when the Market or Camp opens); on/off `SaveData.load/save_tips` |
| Tests | rules and in-run hints in `run_tests.gd` (search "coach") |

## The training run

**When**: the first tap on a fresh save's main menu (`main._start_from_menu`)
starts it instead of a normal run. It plays **only once** (the user's rule):
finished or skipped, it never comes back by itself. Stop (two taps, "SKIP THE
TUTORIAL?") skips it.

**Replay**: the main menu's **Tutorial** button (key U) plays it again any
time (`main.replay_tutorial` → `start_tutorial`). A replay works the same way
and ends on the main menu. What it marks learned or taught is already known,
and the Raptor is only lent if it isn't unlocked yet.

**Look** (after the user's mockups, polished on 2026-11-23): at each moment
to act the world freezes and a big **card** shows at the top: a bold title
and one line with the button's name highlighted (`[JUMP]` in the text is
drawn in the accent colour), e.g. "JUMP THE ROCK / Tap JUMP to clear the
obstacle." The button glows (a soft halo, the pulsing ring and three little
rays), the user's tapping hand bobs on it once `assets/ui/tap_hand.png`
exists (`CoachMarker.HAND_PATH`; the fingertip is the image's top left), and
a dashed, crawling path shows the move: an arc over the rock or log (`arc`
"jump"/"high", and from Rok in mid-air for the double jump's second hop), a
low line under the branch ("slide") (`TutorialRun._arc`, `Hud.coach_card`,
`CoachMarker` card mode). A **"Tutorial" plaque and a "Skip »" pill** sit in
the gap at the top between Rok's status panel and the score panel
(`Hud.set_tutorial_bar`; Skip is action `stop`: a tap asks, a second skips;
the Stop button is hidden meanwhile). Only steps with something to explain or
grab first (`intro`: your screen, meat, power-ups, amber) open with a note;
the button steps go straight to their card.

**The user's tutorial UI kit** (`../Assets/Rok_Tutorial_UI_Kit`, imported by
`tools/prepare_tutorial_ui.py` into `assets/ui/tutorial/` and `assets/fonts/`)
dresses all of this: the ivory card (`SpriteLib.tutorial_box("card")`,
stretched only in its straight middle), the focus ring, the attention marks
(over the button and off the card's corner), the tap pointer (mirrored when
the button is in the screen's corner), the wood-and-bone plaque, the brown
pill for Skip (with the chevrons) and the notes' Back / Next, and the fonts
(`SpriteLib.ui_font`: Baloo 2 weight 800 for card titles, Nunito Sans weight
600 for text; the weight is set with the OpenType tag as a number). Without
the kit everything falls back to the code-drawn look. The kit's HUD pieces
(hearts, pause, counter, PRIMAL bar), slot frames and action buttons aren't
used (the game keeps its own HUD).

**How each step works** (`TutorialRun.STEPS`)
1. An `intro` step first shows a note with its title and hint (frozen, until
   a tap; the user wanted nothing to move on by itself; a retry skips it).
   Then one thing spawns ahead of Rok.
2. At the step's trigger distance (`at`, px from Rok's hitbox) the world
   **freezes**: main skips `_play_step`, Rok's and the hunter's animations
   hold, and a coach ring sits on the button with a few words.
3. Only that button (or pause / stop) works while frozen (`_tutorial_allows`).
   Pressing it un-freezes the world at exactly the moment it works.
4. If Rok gets hit anyway, the step repeats ("TRY AGAIN!"), even when the
   crash broke the obstacle (that used to count as passed). A fall restarts
   the run at that step (`start_tutorial(step)`).
5. **Bug-proofing** (the user's report: attacking the jump lesson's rock left
   Rok running forever). While the world runs, a move isn't usable before
   the step that teaches it (`TutorialRun.TAUGHT_BY`: SLIDE, ATTACK;
   `allows()`, checked by `_tutorial_allows` and the keyboard path). And if a
   lesson's obstacle is gone or already behind Rok before its hint froze the
   world (a crash broke it, an early jump), the step sets up again with a
   fresh one instead of waiting forever.

**The steps**

| # | Step | Spawn | Freeze and button |
|---|---|---|---|
| 0 | Your screen | – | HUD notes: hearts, hunter meter, points, distance |
| 1 | Jump | a fixed rock (`Stones_02`) | 70 px away: JUMP "Tap to jump!" |
| 2 | Hold to jump higher | the short log (`Logs_01`, 114 px hitbox) | 60 px: JUMP "Hold to jump higher!" (a held jump stays above it ~0.6 s; at 150 px, or on a ~162 px log, Rok came down on it) |
| 3 | Double jump | a 2-high rock wall | 140 px: JUMP, then at the jump's peak JUMP again "Tap again in mid-air!" |
| 4 | Slide | a low ledge | 110 px: SLIDE |
| 5 | Attack | a rock | 60 px: ATTACK "Tap to smash it!" |
| 5b | Meat | 3 meat | once every piece is grabbed or passed: HUD note on the meat counter (freezing on the first piece looked broken) |
| 6 | Amber | an arc of 5 amber | once collected or passed: HUD note on the PRIMAL bar |
| 7 | Power-up | a Blaze Pepper | once it's in slot 1: the slot "Use your power-up!" |
| 8 | Shapeshift | the Raptor's crumbling bridge (`force_gate`) | 520 px before the gap: Raptor button; once the whole bridge is behind, Rok's button "Back to Rok to save energy" |
| 9 | Finish | – | an info card: YOU'RE READY! (the Marketplace, the Camp, the Encyclopedia) |

**Notes** (`note_list`: [HUD part or "", title, text]; the user's request):
the world freezes and the coach marker shows the note. A step's intro is a
free-standing bubble with a heading near the top. HUD notes (a step's
`notes`) box one part of the HUD (`Hud.hud_part`: hearts, chase, score,
distance, meat, primal). Every note has a **Next ›** chip, plus **‹ Back**
from the second note of a group on (`CoachMarker.chips`, hit-tested first by
`Hud.action_at` as `note_next` / `note_back`; keys: any key for Next, Left
or Backspace for Back). Any tap is Next, after `NOTE_MIN` (0.45 s) so a stray
tap can't skip one (`TutorialRun.note_tap` / `note_back`, routed by
`main._tutorial_allows`). Only taps and real key presses count: mouse motion,
drags and key releases are ignored while the run is frozen (they used to
skip notes on desktop). Back stays within the group (e.g. from the hunter
meter back to the hearts, or to the step's intro). Wide targets get a rounded
box instead of a ring (`CoachMarker._draw`).

**Forgiving by design**: no starter chest, wild-dinosaur preview or
first-sight cards during it (they came mid-lesson); a quick second tap right
after closing a note isn't a jump (`tap_grace`, 0.35 s); hearts refill every frame, the hunter's gap is
pinned, speed stays at `START_SPEED`, random hazards are held
(`course.holding`), the ground stays flat (`terrain.calm`), the starter pepper
and hazard info cards are off, and the Raptor is **lent** for step 8 (energy
kept topped up). Every jump counts as held for at least `MIN_HOLD` (0.2 s): a
0.07 s first-time tap is too small a hop to clear even the small rock.

**At the end** (`end_tutorial`): the lessons it taught are marked learned
(the coach won't repeat them); on a finish, rocks, logs, walls, ledges and the
pepper count as taught (no info cards for them later); the lent Raptor goes back;
straight to the main menu (no summary, no best distance recorded). A
finished run (not a skipped one) then starts the menu tour.

## The menu tour

`MenuTour` (`main.menu_tour`, stepped every frame instead of the coach hints).
The user asked for the tutorial to walk the player through the screens.

1. On the main menu, a ring on the **Marketplace** button with a line about
   it. Only that button works. Inside, a note on the screen's **Back**
   button (the coach marker is on its own `CanvasLayer` 30, above the
   Market, Camp and Field Guide). Back moves on.
2. The same for the **Camp**, then the **Encyclopedia**.
3. "YOU'RE ALL SET!", and the title panel comes back once that banner has gone (it used to sit on top of it).

During the tour the title panel and the Tutorial button are hidden (the
bubbles sit there). A tap anywhere else shows "TAP THE GLOWING BUTTON", and a
second within `SKIP_TIME` (3 s) skips the tour. Starting a run also ends it.

## How the coach hints stay out of the way

| Rule | Value |
|---|---|
| Never pauses the game | hints draw over the HUD while you keep playing |
| One hint at a time | |
| Quiet gap after a hint | `GAP` 6 s |
| Quiet start of each run | `START_QUIET` 1.5 s |
| A hint lasts while its moment lasts | at most `SHOW_TIME` 4.5 s |
| Once per run per lesson | |
| Learned = done `need` times (counted whether a hint was up or not) | then never shown again |
| Ignored lessons stop | after `MAX_SHOWS` (3) shows in all |
| Returning players | a save with a best run ≥ `COACH_SKIP_BASICS_M` (1500 m) and no tutorial progress skips the basic move lessons |
| Not during | info cards, pause, death, summary, or while the Market, Camp or Field Guide is open |
| Can be switched off | the **Tips** button on the pause screen (below) |

Hazard info cards (see [progression](progression.md)) still explain *what* a
new hazard is; the coach shows *which button* to press.

## Lessons

Checked in this order each frame (`Tutorial.LESSONS`); the first whose moment
has come shows.

| Lesson | Moment (`_coach_target`) | Points at | Hint | Learned when (×need) |
|---|---|---|---|---|
| jump | an obstacle `COACH_NEAR`–`COACH_FAR` (40–420 px) ahead, on the ground | JUMP | "Tap to jump!" | cleared an obstacle in the air (×2) |
| high_jump | jump learned; a log, boulder, fence or thorns ≥ `COACH_TALL` (60 px) ahead | JUMP | "Hold to jump higher" | held JUMP ≥ `COACH_HOLD_JUMP` (0.25 s) after a ground jump (×2) |
| double_jump | jump learned; an obstacle ≥ `COACH_WALL` (110 px) ahead | JUMP | "Tap again in mid-air!" | an air jump (×2) |
| slide | a ledge or swooper ahead, and the form is too tall to pass standing | SLIDE | "Slide under!" | slid under a ledge (×2) |
| attack | a target in reach that ATTACK would break, cooldown ready; for rocks only once jump is learned (wild dinosaurs any time) | ATTACK | "Smash it!" | an attack that breaks something (×2) |
| booster | a ready power-up has sat in a slot `COACH_SLOT_WAIT` (3 s) | that slot | "Use your power-up" | used a slot (×1) |
| shift | a dino button glows (a gate ahead, or a big hazard it handles) and there's energy | that dino's button | "Change into this dinosaur" | shifted into a dinosaur (×2) |
| energy | as a dinosaur with energy < `COACH_LOW_ENERGY` (22) | Rok's button | "Low energy: back to Rok" | turned back into Rok while low (×1) |
| market | main menu after a run; something in the Market is new or affordable | Marketplace | "Spend your meat here" | opened the Market (×1) |
| camp | main menu after a run; something can level up | Dinosaurs (Camp) | "Level up at the Camp" | opened the Camp (×1) |

The one-off ATTACK banner 2.5 s into the first run was replaced by the attack
lesson.

## The hint on screen

`CoachMarker` (one per HUD, made on first use, kept on top):
- a golden ring around the button, with a pulsing outer ring;
- a cream bubble with the hint and an arrow to the ring;
- in a run the bubble sits above the button; on the main menu it sits below
  (side buttons, two short lines) so it stays off the title panel;
- fades in and out (0.15 s); ignores input.

## The Tips switch

- A round button under the PAUSED panel, above the grass (`Hud.tips_button`, `TIPS_BUTTON_SIZE` 112; solid, not see-through like other mid-screen buttons). Shown only while paused.
- Lit bulb and "TIPS ON", or a grey bulb and "TIPS OFF" (`Hud.set_tips`).
- A tap (`main._toggle_tips`) flips `Tutorial.enabled`, saves it (`SaveData.save_tips`) and hides any hint; it doesn't resume the run. Key T on desktop.

## Adding a lesson

1. An entry in `Tutorial.LESSONS` (text, target action, `need`; `"menu": true` for the main menu).
2. Its moment in `main._coach_target` (return the button's action, or "").
3. `_coach_done("<id>")` where the player does the thing.

## Open items

- Possible lessons: the chase meter when the hunter gets close, hearts, cooldowns, equipping gear at the Camp.

## Crafting tour

The user's request (2026-11-23): back on the main menu after the run that opened the Crafting Bench (`main.bench_just_opened`, set in `_bank_meat` when `bench_open` is first seen), the coach gives a short tour, once ever (`seen` key `craft_tour`). It's the menu tour (`MenuTour`) with `CRAFT_STEPS`: a ring on the main menu's **Crafting** button, then on the bench a note on CRAFT (`target` "Craft": pick a recipe, tap CRAFT twice, every craft rolls a rarity, Items holds materials and cards); Back, then a ring on the Camp button and inside it a note on its EQUIPMENT section (`target` "EquipmentHead", scrolled into view by `MenuTour._scroll_to`): Change equips a weapon or armor, weapons wear with each hit landed and armor with each hit taken, Repair is here, a weapon's Card slot takes a dinosaur card, and the Encyclopedia's Items tab explains it all; closing the Camp ends it. Stray taps on the menu ask, a second skips it, as in the menu tour.
