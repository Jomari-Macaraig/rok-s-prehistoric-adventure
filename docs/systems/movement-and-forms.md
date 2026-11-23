# Movement and forms

Running, jumping, sliding and flying, and the rules of the five shapeshift
forms (Rok and the four dinosaur buttons).

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/player.gd` (movement), `scripts/forms.gd` (form table), `main._request_form` / `_shift` |
| Numbers | `scripts/tuning.gd` (gravity, jump, slide, flight, energy) |
| Physics | hand-written; no physics engine. The player's origin is at the feet. |

## Movement

**Running and jumping**
- Gravity, ground snapping on downhill slopes (`GROUND_SNAP`; a bigger drop means he falls off a ledge).
- Coyote time, a jump buffer and air jumps.
- **Hold for higher**: letting go early multiplies the rising speed by `JUMP_CUT` (0.75). A release that comes before the buffered jump has started (a very quick tap) is remembered and cut `JUMP_TAP_TIME` (0.08 s) after takeoff (`_cut_after`). That used to give the *full* jump, so holding seemed to do nothing. Heights for Rok: a tap ~116–129 px, a 10-frame hold ~155, a full hold 184. A tap still clears a small rock pressed 40–100 px out.
- Jump has no cooldown (the user's call).
- In the air, jump frames follow vertical velocity (`_update_jump_frame`), not time.

**Sliding** (the `Low` state machine)
- `press_slide()` on the ground: ENTER (frames 0–1) → GLIDE (frames 2–4 repeat) → RECOVER (frames 5–7).
- **One press = one slide** of `SLIDE_MIN` (the user's rule). Holding SLIDE neither stretches it nor starts another when the cooldown ends. (The old hold-to-duck is gone; `SLIDE_MAX` and DUCK are unused.)
- The cooldown starts on the press (`SLIDE_COOLDOWN` 2.2 s, shortened by Speed; see [attributes](attributes.md)). A press within `SLIDE_BUFFER` (0.2 s) of it ending slides when ready; earlier presses are ignored.
- Rok won't stand up under a ledge (`headroom_clear`, supplied by main): he keeps gliding until there's room.
- While low, the hitbox is the form's `slide_box` (or `duck_box`) and a `body` node squashes vertically by `low_squash` (the drawn crouches are only a little shorter than standing).
- Slide in the air: fast-fall (`FAST_FALL_SPEED`) and slide on landing. Jumping cancels a slide.
- `reset_actions()` (every new run) clears any slide, cooldown and attack clip.

**Flying** (forms with `flies`: the Pteranodon and Flyer species)
- JUMP on the ground plays `takeoff` with an upward impulse.
- Hold JUMP to climb toward `FLY_RISE` (`fly` clip); release to sink at up to `GLIDE_FALL` (`glide` clip).
- The feet line is clamped at `FLY_CEILING` to stay clear of the HUD.
- Touchdown plays `land` at double speed before running.
- Changing form mid-flight (including running out of energy) gives at least one grace air jump.
- The `flapped` signal fires on the wing downstroke (fly frame 3) for the flap sound.

**Shapeshifting** (`shift_to()`)
- Swaps the SpriteFrames with a squash-and-flash pop.
- 0.35 s shift cooldown. Q/E (or Shift) cycle forms on desktop.

## Form rules

| Form | Key | Ability | Breaks | Energy/s | Speed (pips, gap change/s) |
|---|---|---|---|---|---|
| Rok | 1 | double jump | none | 0 | 4, 0 (hunter's pace) |
| Raptor | 2 | fastest (no uphill penalty), highest jump + double jump, ×2 score | none | 6 | 5, +40 |
| Triceratops | 3 | single jump | rock, wood (small: a Power roll) | 9 | 3, −8 |
| Spinosaurus | 4 | 1 shield per transformation; swims | fence, wood, thorns (small: a Power roll) | 10 | 1, −14 |
| Pteranodon | 5 | flies (hold JUMP to climb, release to glide), ×1.5 score | none | 13 | 5, +25 |

The heavy smashers trade the chase for their power. Each button's dinosaur can
be swapped for another of its category (see [dinosaurs](dinosaurs.md)).

**Form data** (`forms.gd`): frame size, pivot, scale, hitbox (optional `box_offset_x`), slide and duck boxes, `low_squash`, jump velocity, air jumps, `breaks`, energy drain, score multiplier, armor, `speed` (1–10), `speed_label`, `chase_rate`. The Pteranodon also has `flies`, a torso-only `fly_box` (`fly_box_bottom` above the origin, `fly_offset_x`), and `extra_anims` (fly, glide, takeoff, land).

## Ledges

- Clearance is 110 px. Standing Rok (140) and Spinosaurus (115) must slide.
- The Raptor (77), Triceratops (101) and grounded Pteranodon (100) fit standing.
- A flying Pteranodon that hits a ledge's side still dies.
- Every form's slide and duck boxes fit (tested).

## Energy

- Dinosaurs unlock by distance (see [progression](progression.md)). Entering a dino form needs `SHIFT_MIN_ENERGY` (15).
- At 0 energy Rok turns back into himself automatically.
- **Staying a dino gets tiring**: `main.dino_time` counts seconds as any dino (reset only by going back to Rok; paused by the Primal Berry). Drain = form rate × (1 + dino_time / `DRAIN_DOUBLE_TIME` (8 s)): ×2 after 8 s, ×3 after 16 s. The energy bar turns from orange to red (`Hud.set_drain_heat`).
- Amber gives `AMBER_ENERGY` (15) as Rok, only `AMBER_ENERGY_DINO` (7) as a dino: Rok is the form for recharging.
- With no amber a full bar lasts about 11 s as the Raptor, 7.5 s as the Triceratops, 6 s as the Pteranodon.
- How the player learns it (the user asked for a proper explanation, 2026-11-23):
  - the training run's PRIMAL note (`tutorial_run.gd`, after the amber step): it powers the dinosaurs, drains faster the longer you stay one, amber refills it, empty means Rok;
  - the first dino's unlock card: the orange bar, the `SHIFT_MIN_ENERGY` needed to change, the tiring drain (red bar), empty → Rok, rest as Rok and refill with amber (most as Rok);
  - the first time the drain reaches ×2 in a run, a banner "YOUR DINO IS TIRING!" (once ever, `seen` key `primal_tired`);
  - the Field Guide's Items tab: a **PRIMAL Energy** page with every number from `Tuning` (start, max, minimum, the ×2/×3 times, amber as Rok and as a dinosaur, Primal Amber, Primal Berry), revealed once amber has been met; the Amber page gives the real amounts (+15 as Rok, +7 as a dinosaur).

## Shapeshift burst

The user's generic transformation effect (`../Assets/Rok_Generic_Transformation_FX`, imported by `tools/prepare_transform_fx.py` into `assets/fx/transform_burst` + `.json`) plays on every gameplay shapeshift (`main._shift` → `Player.play_transform(from)`), in both directions, in place of the old particle puff (kept as the fallback without the art).

- Shapeshifting stays instant (bridges, pits and the tutorial depend on it), so the burst starts on `TRANSFORM_FX_START` (3, its first covering frame): the swap has already happened under the solid cream cloud, which then opens (frame 5) to show the new form and fades. 0 would show the whole build-up after the change.
- It's scaled so its solid cloud (`cover` in the JSON: the alpha > 200 box on the cover frames, ~130×128 at 1x) hides the bigger of the two forms (`TRANSFORM_FX_COVER` × its frame × scale), centred on it, and is a child of the player so it follows jumps and flight (not of the body, so a slide's squash doesn't bend it). It hides itself when it ends.

