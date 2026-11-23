# Audio

Sound effects, per-form and per-surface sounds, the hunter's voice and the
zone music. Every sound is synthesised by a script (except Rok's shout).

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/audio.gd` (`Audio`), `main.STEP_SOUND` / `JUMP_SOUND` / `SURFACE_SOUND` / `_trex_voice` |
| Sounds | `assets/sounds/*.wav`, made by `tools/make_sounds.py` (see [tools/CLAUDE.md](../../tools/CLAUDE.md)) |
| Rok's shout | `rok_alarm.wav`, a real recording the user supplies (`tools/prepare_voice.py`); silent until then |
| Mute | saved through SaveData; the sound button top-left |

## Playback

- `play(name, pitch_jitter, pitch, extra_db)` uses a round-robin pool of 14 players.
- `played` logs the last 32 names (even while muted), for tests.
- **Music**: one looping track per zone (`MUSIC`: forest, desert, volcanic), all playing at once and cross-faded by `set_music_weights(Zones.weights(m))` every frame.
- Death: the music cuts out (`duck_music`) for the death jingle, and comes back on a new run.

## Sound groups

**Per form**
- Footsteps fire from the run clip (`Player.stepped`, frames 0 and 4): Rok patters; the Raptor and Pteranodon click; the Triceratops and Spinosaurus thud (`step_heavy`, a little screen shake, plus `land_heavy` on every landing).
- Each form has its own jump sound (Rok, Raptor chirp, heavy grunt, Pteranodon wingbeat) and shift call (`form_<id>`).

**Per surface** (`SURFACE_SOUND`): grass (Forest), sand (Desert and quicksand), rock (Volcanic), layered quietly under each step and landing.

**The hunter** (`_trex_voice`)
- The intro roar, footsteps (louder as it closes in) and bite.
- Roars every `TREX_ROAR_EVERY` s, more often and louder the closer it is (with shake).
- Growls once whenever it gets within `CHASE_DANGER`.

**Gameplay**: jump and double jump, slide, wing flaps, hard landing, shift, smash, `break_wood` / `break_rock`, `weapon_break`, amber, pepper, shield, power-ups (`powerup_pickup` / `powerup_activate` / `powerup_expire`, see [power-ups](power-ups.md#sounds)), hit, pit fall, run start, unlock, intro.

**UI**: click, denied ("need amber"), Ugo's mumbles (`mumble_1..6`, see [marketplace](marketplace.md)).

## Settings

The top-left speaker became a **Settings** button (the user's request, 2026-11-23; a drawn cog until the user's art): it opens a panel (`Hud.open_settings`) with **Sound effects** and **Music** sliders, 0–100% in steps of 5 ("Off" at 0), and Done. Sound effects play on an `SFX` bus and the zone music on a `Music` bus (made by `Audio._ready`); each slider sets its bus's volume and mutes it at 0 (`Audio.set_sfx_volume` / `set_music_volume`), saved as `settings/sfx_volume` and `music_volume` (`SaveData.load/save_volume`). Opening it in a run pauses first; while it's open taps don't start a run. The old all-sound mute (`Audio.muted`) is cleared when Settings opens.
