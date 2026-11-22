# Rendering, sprites and effects

How character art is loaded (1x/@2x), how animations are built from sprite
sheets, and the particles, shake and floating text.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Code | `scripts/sprite_lib.gd` (`SpriteLib`), `scripts/fx.gd` (`Fx`) |
| Asset pipeline | [tools/CLAUDE.md](../../tools/CLAUDE.md) |

## Loading art: `SpriteLib.tex(path)`

- Uses a `<name>@2x.png` twin when one exists, with its size overridden to the 1x size, so all frame and pivot numbers stay in 1x units while phones sample the sharper pixels.
- Used for character and portrait art, attack clips, the Market UI pack and gear icons.
- The 1x files stay as the fallback and for code that reads pixels.

## Animations

`SpriteLib` builds and caches SpriteFrames from 4×2 sheets:

| Function | Clips |
|---|---|
| `character(form)` | idle, walk, run, jump, duck, slide (+ fly, glide, takeoff, land, swim, celebrate where present) |
| `death(form)` / `death_pivot` | "die" (frames 0–1), "hop" (2–7) |
| `reactions(id)` / `reaction_pivot` | trip, dizzy, snag (own canvas and pivot) |
| `attacks(id)` / `attack_meta` | attack clips (own canvas and pivot) |
| `trex()`, `trap(name)`, `wind(name)` | the T-rex, traps and break animations, wind-animated plants |

- Animation speed is 1000 fps and each frame's duration is its milliseconds, so frame times match the art's metadata exactly.
- Clips with their own canvas (reactions, attacks) play on a second sprite in the player and hide the main one.

## Effects

`fx.gd`:
- CPUParticles2D bursts with a soft radial dot texture: dust, transform puff, smash debris, sparkle, splash.
- Screen shake (`add_shake`).
- Floating popup labels: bright fill, an outline in the darkened accent colour, a drop shadow, a pop-in scale animation, `z_index` 100 so they draw above the fern foreground.
