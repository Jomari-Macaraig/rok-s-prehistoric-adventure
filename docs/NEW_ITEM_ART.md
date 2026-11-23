# New weapon, armor or accessory: what art to generate

The checklist for one new item: the art to make, and what the game already handles so you don't make it. It follows the attack-style plan in [ITEM_ART_PLAN.md](ITEM_ART_PLAN.md), which has the exact sheet formats (its section 4). For config, stats and recipes, see [NEW_CONTENT.md](NEW_CONTENT.md).

**The rule:** a new item needs only **pictures of the item itself**. Heroes are never redrawn for one item. Hero animations are made **once per hero per attack style** (see the last section), and every item of that style reuses them.

---

## Weapon

### Always
| Art | Format | Used for |
|---|---|---|
| **Icon** | transparent PNG, at least 512 px tall, drawn **upright**: head or blade at the top, handle at the bottom, no hand, no background, no shadow | the Market, Camp, Items and Crafting Bench, **and** the weapon drawn in the hero's hand (idle, run, jump and every style attack) |
| **Its style** (not art: pick one) | Swing, Thrust, Throw, Shoot or Fist | which hero motion it uses. Goes in `config/crafting.cfg` `[weapon_styles]` |

### Only if
| Art | When | Format |
|---|---|---|
| **Break animation** | until the six break-by-material sheets exist (plan step 5); after that, only for a weapon that should break in its own way | 4×2 one-shot, frame 0 the intact weapon, frame 2 the crack, then pieces fall and fade (like `Rok_Weapons_Animation_Pack/spritesheets/<weapon>_break.png`) |
| **Held picture** | the icon doesn't read right in the hand, e.g. a sling (it should hang or whirl) | transparent, same size rules as the icon, drawn as held |
| **Projectile** | Throw and Shoot weapons (bow, sling, bola…) | small transparent PNG, pointing right (like the arrow) |
| **Animated loop** | it moves on its own, like the Torch's flame | 4×2 loop on the icon's canvas, so it lines up with the icon |

### Never (the game does it)
- An attack clip per hero for this weapon (the style clip and its guide place the weapon).
- A running-attack pack per hero for this weapon.
- Any hero frame with the weapon drawn in.

### Does every hero have the weapon's style yet?
If a hero doesn't have the style's clip yet, a new weapon falls back to the code-drawn lunge and slash for that hero. The old weapons fall back to their drawn-in clips instead. So before giving a style its first new weapon, check this table, and order the missing style sheets (one-time, below).

| Style | Rok | Nira | Boro |
|---|---|---|---|
| Swing | ✓ (pilot, waiting for approval) | – | – |
| Thrust | – | – | – |
| Throw | – | – | – |
| Shoot | – | – | – |
| Fist (also bare hands) | – | – | – |

---

## Armor

First decide which kind it is:
- **Body armor** bends with the body: a vest, wraps, mail, robes.
- **Rigid armor** is stiff and sits on one point: a helmet, a shell, a cape, a chest plate, shoulder pads.

### Body armor
| Art | Format | Used for |
|---|---|---|
| **Icon** | transparent, at least 512 px, the armor laid flat or on an invisible body | menus |
| **Pattern** | a **seamless, tileable** 256×256 texture in the armor's material (hide with stitching, bone segments, scales…), flat, with no lighting | painted into each hero's clothing area by the outfit shader (plan step 7, not built yet) |

Until the outfit shader exists, body armor shows in menus and works in play but **isn't drawn on the hero**. No per-hero overlay sheets are needed: the outfit masks are one-time per hero animation (below).

### Rigid armor
| Art | Format | Used for |
|---|---|---|
| **Icon** | as above | menus |
| **The piece** | transparent PNG, side view facing right, about the size it should be on Rok (Rok is 168 px tall at 1x; send 2× or more), with its **mount point** given (e.g. the middle of a helmet's rim, the centre of a shell's straps), say as pixel coordinates or a 1-pixel magenta dot on a separate copy | drawn on its anchor point every frame |
| **Its anchor** (not art: pick one) | head, chest or back | which guide dot it follows |

Today only the **back** anchor works (Rok's, Nira's and Boro's back points are measured from the art; the Shell Plate uses them). **Head** and **chest** anchors need the guide sheets for each hero's animations (plan step 3, one-time per hero).

---

## Accessory

The accessory slot isn't built yet (plan step 0.4). When it is:

| Art | Format | Used for |
|---|---|---|
| **Icon** | transparent, at least 256 px (512 is better), centred | menus, and a small icon on the HUD in a run |
| **Worn picture** (optional) | like a rigid armor piece: transparent, side view facing right, mount point given, anchor **chest** (necklace, amulet) or **head** (feather, band) | drawn on the hero; without it the accessory only shows as an icon |

Most accessories need only the icon.

---

## One-time hero art (not per item)

Made once for each hero (Rok, Nira, Boro, and any new hero). After that, items need only the art above.

| What | How many per hero | Format |
|---|---|---|
| **Style attack, empty-handed** | 5 (Swing, Thrust, Throw, Shoot, Fist) | 4×2, the hero's canvas (Rok 384×512 cells, floor at y 488), strike on frame 4, closed empty hand. Rok's Swing (`../Assets/Rok_Swing_Attack`) is the model to copy |
| **Its guide sheet** | 1 per style attack | same grid, pixel-aligned: magenta `#FF00FF` 6 px stick (the weapon's direction from the grip; leave it out where no weapon should show), 10 px dots green `#00FF00` grip, cyan `#00FFFF` head top, yellow `#FFFF00` chest, orange `#FF8000` upper back. No anti-aliasing. A landmarks JSON like the Swing pack's is welcome (the importer checks against it) |
| **Running style attack, empty-handed** | 5 | like `Rok_Running_Club`: 8 phase sheets plus `validation.json`, legs matching the hero's run, no weapon drawn |
| **Guides for the other animations** | 11: idle, walk, run, jump, duck, slide, die, celebrate, trip, dizzy, snag | guide sheets over the existing frames (no new animation) |
| **Outfit masks** | 1 per animation | white where body armor covers, transparent elsewhere. Claude makes these automatically first and flags any that need fixing by hand |

Drop each pack in `../Assets` (e.g. `Rok_Thrust_Attack/` with `rok_thrust_attack.png`, `rok_thrust_attack_guide.png`, `rok_thrust_attack_landmarks.json`), then ask Claude to import it (`tools/prepare_styles.py` takes a new `STYLES` entry).
