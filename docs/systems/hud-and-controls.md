# HUD and touch controls

The on-screen layout during a run: thumb clusters of touch buttons, the status
panels, banners and cooldown display, plus the touch-first text rule.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/hud.gd` (`Hud`, `_layout`), `scripts/touch_button.gd` (`TouchButton`), `main._input` / `_touch_pressed` / `_glow_hint` |
| Sizes and angles | `tuning.gd` (`MAIN_FORM_SIZE`, `LEFT_ARC_R/DEG`, `RIGHT_ARC_R/DEG`, `ATTACK_R/DEG`, …) |
| Art | action buttons `assets/ui/button_<jump|slide|attack>.png` (`tools/prepare_action_buttons.py`); sandstone slot rings `assets/ui/slot_<hero|dino|powerup>.png` (`tools/prepare_slot_frames.py`) |
| Layout rules | the root `CLAUDE.md` UI rules; `run_tests.gd` checks "no control overlaps another" |

## Layout

**Thumb clusters** (MLBB-style)

| Cluster | Main button | Around it (arc) |
|---|---|---|
| Left (bottom-left) | Rok / the hero (`MAIN_FORM_SIZE`), hero ring | the four dinosaur buttons, dino rings (`LEFT_ARC_R` / `LEFT_ARC_DEG`) |
| Right (bottom-right) | JUMP | SLIDE, ATTACK (left of SLIDE), and the three booster slots with power-up rings (`RIGHT_ARC_R` / `RIGHT_ARC_DEG`) |

- Rok runs at `PLAYER_X` = 335, clear of the left cluster.
- Buttons above the ground line are slightly see-through.
- Locked form buttons show a padlock and their unlock distance; locked slots show the slot-2 distance or "Market".
- Rings stick out `TouchButton.FRAME_OUT` (1.12×) past the button; spacing is measured with what's drawn.

**Top-left**: pause, sound, and Stop (during a run). Then **Rok's status panel** (`status_panel`, one stack, the user's choice):
1. hearts (34 px) and shield count
2. PRIMAL energy bar (orange → red as dino drain climbs)
3. the hunter meter (see [chase-and-hunters](chase-and-hunters.md))

**Top-right**: score and distance ("123 m · Desert", led by a time-of-day icon: sun, moon, or the half-and-half face at dusk and dawn; `Hud.set_daylight`), the meat pill below it, then the combo meter (during a run only) and the event countdown.

**Middle**: slide-in banners (`show_banner()`, under the top bar; they queue), info cards (`show_info`), and centre messages on a dark rounded backdrop. All labels have a thick outline and a drop shadow.

**Pause screen**: the PAUSED panel and the Tips on/off button under it (see [tutorial](tutorial.md)).

**Main menu**: the title panel, side buttons (see [screens-and-navigation](screens-and-navigation.md)), daily missions at the bottom centre.

## Touch buttons

`touch_button.gd`:
- A round button drawn in `_draw()`. `art` makes it a picture button (the user's jump/slide/attack art, darkened while held, dimmed when disabled; no captions).
- `frame` + `frame_geo` lay a sandstone ring over it; the portrait sits in its hole; the tap area is unchanged.
- It ignores GUI input: main hit-tests it with `hit()` (`hud.action_at()`); `set_held()` plays a press/pop.
- Multi-touch: each finger is tracked, so JUMP can be held while another finger taps a form; a touch that misses every button counts as jump.

**Cooldown display**: `cooldown` (share) and `cooldown_left` (seconds), set by main every frame: a dark wedge unwinding clockwise from 12 o'clock with a timer ("0.6") in the middle. (A user-supplied cooldown animation is planned; see [attributes](attributes.md).)

**Button glow** (`main._glow_hint()` → `Hud.set_glow()` → `TouchButton.glow`)
- Strong pulse on the needed dino's button when a gate (or deep quicksand) is within 1300 px.
- Soft pulse when a big hazard (wall, tall fence) is coming that an unlocked Triceratops or Spinosaurus handles and there's energy for it.

## Touch-first text

This is a tap game. Buttons show no keyboard labels, and nothing the player
reads (cards, banners, title, Field Guide) mentions keys.

Keyboard bindings remain for desktop testing (`main._setup_input`):

| Key | Action |
|---|---|
| Space / ↑ / W | jump |
| ↓ / S | slide |
| F | attack |
| 1–5 | forms; Q / E cycle |
| B / N / comma | booster slots |
| P / Esc | pause |
| X | stop |
| C | Field Guide |
| M / K | Market |
| H | Camp |
| U | Tutorial (main menu) |
| R | restart |
| T | Tips on/off (paused) |
