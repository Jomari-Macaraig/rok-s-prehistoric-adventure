# Item art plan: weapons, armor and accessories without an animation matrix

How to add many weapons, armor pieces and accessories without drawing every hero holding every item in every animation. This document lists what exists today, what's missing, and the exact order to make it in.

Each step says who does it:
- **[Art]**: generated or drawn by the user or their artist.
- **[Code]**: done in the project by Claude.

## The idea in one paragraph

Today every weapon is drawn into the hero's frames, so 3 heroes × 7 weapons is already 42 attack sheets plus running packs, and every new weapon or hero multiplies that. Instead, heroes are drawn **once per attack style, empty-handed**, with a **guide sheet** that marks where the hand, head, chest and back are in every frame. The game then places any item's picture at those points:
- **Weapons:** about 5 attack styles cover every weapon.
- **Rigid armor** (helmets, shells, capes) sits on the head, chest or back points.
- **Body armor** (vests, wraps, mail) is painted into the hero's clothing area using an **outfit mask**, made once per hero animation.
- **Accessories** are a small picture on the chest point, or not drawn at all.

**A new item then needs only its own picture.**

---

## 1. What we have today

### Heroes (3: Rok, Nira, Boro)
| Animation | Rok | Nira | Boro |
|---|---|---|---|
| idle, walk, run, jump, duck, slide, die | ✓ | ✓ | ✓ |
| celebrate | ✓ | ✓ | ✓ |
| hit reactions: trip, dizzy, snag | ✓ | ✓ | ✓ |
| standing attack per weapon (weapon drawn in) | ✓ all 7 | ✓ all 7 | ✓ all 7 |
| running attack (weapon drawn in) | club only | none | none |
| bare-hands attack | none | none | none |

### Hand and back points
Measured automatically from the art by `tools/prepare_gear.py` into `assets/gear/sockets.json`. They exist for idle, walk, run, jump, duck, slide and celebrate, for all 3 heroes. There are no points for attacks, hit reactions or death, and no head or chest points.

### Weapons (7)
| Weapon | Icon | Grip data | Break animation | Attack clips (3 heroes) | Running attack |
|---|---|---|---|---|---|
| Wooden Club | ✓ | ✓ | ✓ | ✓ | Rok only |
| Stone Axe | ✓ | ✓ | ✓ | ✓ | no |
| Flint Spear | ✓ | ✓ | ✓ | ✓ | no |
| Bone Hammer | ✓ | ✓ | ✓ | ✓ | no |
| Sling | ✓ | ✓ (hangs) | ✓ | ✓ | no |
| Torch | ✓ + burning loop | ✓ (upright) | **no** | ✓ | no |
| Bow (+ arrow) | ✓ | ✓ (upright) | **no** | ✓ | no |

### Armor (4)
| Armor | Icon | Shown on the hero |
|---|---|---|
| Hide Vest | ✓ | **no** (needs body fitting) |
| Bone Guards | ✓ | **no** |
| Scale Mail | ✓ | **no** |
| Shell Plate | ✓ | ✓ (rigid, on the back point) |

### Accessories
None. There is no accessory slot yet.

### Unusable as they are
Nira's Wooden Club, Ivory Bone Hammer and Stone Sling sheets are upper body only. This plan replaces the need for them.

---

## 2. What we need to generate

### Attack styles (5)
Every weapon belongs to exactly one style, and the hero's motion comes from the style.

| Style | Motion | Current weapons | Future weapons (examples) |
|---|---|---|---|
| **Swing** | overhead or side swing with one or two hands | Club, Stone Axe, Bone Hammer, Torch | mace, obsidian blade, tail-club mace, meteor hammer, T-rex tooth blade |
| **Thrust** | forward stab | Flint Spear | horn lance, fire spear |
| **Throw** | wind-up and release | Sling | bola, boomerang, atlatl, throwing stones |
| **Shoot** | draw and release | Bow | (other bows) |
| **Fist** | quick punch or slash at close range | bare hands | claw gauntlets, bone dagger |

The Fist style also gives the bare-hands attack that's missing today.

### The full list of new art

| # | What | How many | Who |
|---|---|---|---|
| A | Empty-handed **standing attack** per style per hero | 5 × 3 = **15 sheets** | [Art] |
| B | Empty-handed **running attack** per style per hero | 5 × 3 = **15 packs** | [Art] |
| C | **Guide sheet** for every hero animation (hand stick, head, chest and back dots) | 3 heroes × 21 animations = **63 sheets** | [Art] (same pass as A and B) |
| D | **Outfit mask** for every hero animation (where the clothing is) | 3 × 21 = **63 sheets**; I try to make these automatically first | [Code] first, then [Art] fixes |
| E | **Break animations by material** (wood, stone, bone, obsidian, metal, fibre/cord) instead of one per weapon | **6 sheets** total | [Art] |
| F | Icons for every **new** weapon | 1 per weapon | [Art] |
| G | **Body-armor patterns** (a tileable texture per armor) | 1 per body armor | [Art] |
| H | **Rigid armor pieces** (helmets, capes, plates) | 1 picture per piece | [Art] |
| I | **Accessory icons** | 1 per accessory | [Art] |
| J | Pictures **in the hand** for weapons whose icon doesn't work when held (e.g. a sling drawn mid-swing) | only where needed | [Art] |

**The 21 animations:** idle, walk, run, jump, duck, slide, die, celebrate, trip, dizzy, snag, the 5 style attacks and the 5 style running attacks.

**After this, a new weapon is F (+ J if needed), a new body armor is G, a new rigid armor is H, and a new accessory is I.** A new hero is 10 attack sheets plus guides and masks for its 21 animations.

---

## 3. Steps, in order

### Step 0: Lock the decisions [Code + you]
1. Confirm the 5 styles above, and which style each new weapon will use.
2. Confirm the slots: weapon, armor and a **new accessory slot**. Decide whether armor splits into **body** (vest, wraps, mail) and **rigid** (helmet, shell, cape). Recommended: one armor slot, where each armor is either body or rigid.
3. **[Code]** Give every weapon a `style` (Swing, Thrust, Throw, Shoot or Fist), and every armor a `kind` (body or rigid) and, for rigid armor, an anchor (head, chest or back), in config. The current items get theirs.
4. **[Code]** Add the accessory slot: an empty slot at the Dinosaur Camp, an Items tab and the save data.

### Step 1: Pilot: Rok's Swing, to prove it works before ordering everything
1. **[Art]** Rok, Swing, standing attack, empty-handed (format in section 4.1).
2. **[Art]** Rok, Swing, guide sheet for that attack (section 4.3).
3. **[Code]** Write the guide reader. It finds the green grip dot and the magenta stick's direction on every frame and writes the hand point and angle per frame.
4. **[Code]** Draw the weapon on top of the empty-handed clip at those points, for the Club, Axe, Hammer and Torch.
5. **[Code]** Screenshots: Rok swinging all four at 1280×720 and 1560×720, compared with today's drawn clips.
6. **You:** approve the look, or adjust the guide format. **Don't order the rest until this passes.**

### Step 2: Rok's other styles
1. **[Art]** Rok's Thrust, Throw, Shoot and Fist standing attacks, empty-handed, with a guide sheet each.
2. **[Art]** Rok's 5 running attacks per style, empty-handed (format in section 4.2), with guides.
3. **[Code]** Import them, switch the Spear, Sling and Bow to their styles, and give bare hands the Fist style.
4. **[Code]** The Throw and Shoot styles hide the weapon or its projectile after the release frame. The existing arrow and stone effects fly from the hand point.
5. **[Code]** Tests and screenshots for each style, standing and running.

### Step 3: Guides for Rok's other animations
1. **[Art]** Guide sheets for Rok's idle, walk, run, jump, duck, slide, die, celebrate, trip, dizzy and snag. These are drawn over the existing frames, so no new animation is needed.
2. **[Code]** These replace the auto-measured hand and back points. Weapons now also show during hit reactions and death, with no gaps.

### Step 4: Nira and Boro
1. **[Art]** Repeat steps 1–3 for Nira, then Boro: 5 standing and 5 running style attacks, and guides for all 21 animations.
2. **[Code]** Import them. Every weapon now works for all 3 heroes. Nira gets running attacks for the first time.

### Step 5: Break animations by material
1. **[Art]** 6 break sheets: wood, stone, bone, obsidian, metal, fibre/cord (section 4.5).
2. **[Code]** Give each weapon a break material in config (Club → wood, Axe → stone, Torch → wood, Bow → wood…). The 5 existing per-weapon breaks stay as overrides.

### Step 6: Retire the drawn-in weapon clips
1. **[Code]** Once every hero has all 5 styles, switch the 7 current weapons to styles, remove the per-weapon attack sheets from the build, and update the docs.
2. **You:** compare before and after in screenshots and confirm.

### Step 7: Body armor (outfit masks)
1. **[Code]** Generate a first-pass outfit mask for every hero animation automatically, from each outfit's colours (Rok's tunic, Nira's dress, Boro's wrap). Send you a contact sheet of the results.
2. **[Art]** Hand-make or fix the masks that came out wrong (section 4.4).
3. **[Code]** Add the outfit shader: it paints an armor's pattern into the masked area and keeps the hero's own shading. Hide Vest, Bone Guards and Scale Mail become visible on all 3 heroes.
4. **[Art]** One pattern texture per body armor (section 4.6). Hide Vest, Bone Guards and Scale Mail first.
5. **[Code]** Screenshots: each armor on each hero in run, jump, slide and attack.

### Step 8: Rigid armor and accessories on their anchors
1. **[Code]** Read head, chest and back points from the guides (steps 3–4). Draw rigid armor and accessories there; the Shell Plate moves onto this system.
2. **[Art]** Rigid pieces and accessory pictures (sections 4.7 and 4.8).
3. **[Code]** Accessories show as an icon on the HUD in a run and on the hero's tile in the Dinosaur Camp. The ones with a picture are also drawn on the chest point.

### Step 9: New items (repeatable, no hero animation)
For each new weapon, armor or accessory:
1. **[Art]** Its icon: F, G, H or I (plus J if a weapon needs a separate picture when held).
2. **[Code]** Its config entry: stats, style or kind, recipe in `config/crafting.cfg`, break material, when the recipe is learned.
3. **[Code]** Tests, screenshots, and an update to [NEW_CONTENT.md](NEW_CONTENT.md).

---

## 4. Art formats

Every sheet is a **4×2 grid, 8 frames**, read left to right then top to bottom. Transparent PNG with no background. Each hero's sheets use **that hero's existing canvas** (Rok's are 384×512 per frame, the same as `Rok_Running_Club`), with the feet on the same baseline as the hero's idle. One-shot attacks put the hit on **frame 4**.

### 4.1 Standing style attack (A)
- File: `<hero>_<style>_attack.png`, e.g. `rok_swing_attack.png`.
- The hero performs the style's motion with an **empty, closed hand** in the gripping pose. No weapon is drawn at all.
- For two-handed Swing and Thrust, both hands close around where the handle would be.

### 4.2 Running style attack (B)
- Same layout as `Rok_Running_Club`: `phases/run_attack_phase_0..7.png` (the attack started from each of the 8 run frames) and `validation.json`.
- The legs must match the hero's existing run frame for frame, so the run never stutters.
- Empty-handed, like 4.1. There's no `run.png` carrying a weapon: the carried weapon is placed on the normal run by its hand point.

### 4.3 Guide sheet (C)
A separate sheet, exactly the same grid, canvas and frames as the animation it belongs to. Only these flat, unshaded marks, with no anti-aliasing:

| Mark | Colour | Meaning |
|---|---|---|
| Stick | magenta `#FF00FF`, 6 px wide | the weapon's handle, from the grip outwards in the direction the weapon points. Leave it out on frames where no weapon should show (e.g. after a throw) |
| Dot | green `#00FF00`, 10 px | the grip, the centre of the closed hand. For two-handed holds, the front hand |
| Dot | cyan `#00FFFF`, 10 px | the top-centre of the head (helmets) |
| Dot | yellow `#FFFF00`, 10 px | the centre of the chest (necklaces, chest plates) |
| Dot | orange `#FF8000`, 10 px | the centre of the upper back (shells, capes, quivers) |

- File: the animation's name plus `_guide`, e.g. `rok_swing_attack_guide.png`, `rok_run_guide.png`.
- The stick's direction gives the weapon's angle on that frame, so draw it as the weapon should sit.
- Hidden parts (e.g. the back during a front-facing frame) still get their dot, so attached items stay put.

### 4.4 Outfit mask (D)
- Same grid and canvas as the animation. **White** where the clothing body armor should cover (the tunic or dress area, over the torso), **transparent** everywhere else.
- Leave out the skin, hair, the hero's belt or sash, and anything in the hands.
- File: animation name plus `_outfit`, e.g. `rok_run_outfit.png`.
- I make these automatically first. Only the ones I flag need making by hand.

### 4.5 Break animation by material (E)
- 4×2 one-shot, like the existing `break_<weapon>.png`. Frame 0 is the intact piece, frame 2 the crack, then pieces fall and fade.
- Drawn as a generic piece of that material (a wood shaft, a stone head…), centred, about 512 px frames.
- File: `break_wood.png`, `break_stone.png`, `break_bone.png`, `break_obsidian.png`, `break_metal.png`, `break_cord.png`.

### 4.6 Body-armor pattern (G)
- A **seamless tileable** texture, 256×256, in the armor's material and colours: hide with stitching, bone segments, scales.
- Drawn flat with no lighting; the hero's own shading is kept on top.
- Optional: a 1-pixel accent colour for the trim, if it should differ.
- File: `<armor id>_pattern.png`.

### 4.7 Rigid armor piece (H)
- One picture, transparent, at least 512 px. Its attach point is marked with a green dot on a separate copy: the bottom-centre of a helmet, the top-centre of a shell or cape.
- File: `<armor id>.png` plus `<armor id>_anchor.png`.

### 4.8 Accessory (I)
- An icon, square, transparent, about 256 px.
- If it's worn visibly (necklace, pendant), also a small worn picture with a green dot at its hanging point.

### 4.9 Weapon icon (F) and picture in the hand (J)
- Like the existing gear icons: transparent, at least 512 px, the weapon pointing up and to the right, the handle at the bottom left.
- Mark the grip with a green dot on a separate copy (`<id>_grip.png`). That replaces measuring the grip by eye.
- J is only needed if the weapon looks different when held (e.g. a sling drawn mid-swing).

---

## 5. Totals

| Stage | Sheets to generate |
|---|---|
| Step 1 pilot | 2 (Rok Swing attack + guide) |
| Steps 2–3 (Rok complete) | 8 attacks + 5 running packs + 18 guides |
| Step 4 (Nira and Boro) | 2 × (5 attacks + 5 running packs + 21 guides) = 62 |
| Step 5 (breaks) | 6 |
| Step 7 (body armor) | some mask fixes + 3 patterns |
| Step 8 | 1 picture per rigid piece and accessory |
| **Then per new item** | **1 icon (+ grip copy)** |

Compare: keeping today's approach for 18 weapons would mean 3 × 18 standing sheets + 3 × 18 running packs = 108, plus armor fitted to every animation for every hero.
