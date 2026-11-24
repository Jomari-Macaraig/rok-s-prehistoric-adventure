# 03: Automatic levels

**What to build:** Characters level up by themselves. The moment a hero or dinosaur has the XP it levels up mid-run with a LEVEL UP! burst, sound and glow, without stopping play, up to level 20. No meat and no Camp trip. XP comes from metres run as that character plus a small team share for the other equipped dinosaurs; the curve (level 2 at about 300 m, slowing gently) lives in config. The summary fills each character's XP bar.

**Blocked by:** None (can start immediately)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] Running enough metres levels a character mid-run, with the burst and sound, and play continues
- [x] Levels cap at 20; the XP curve and team share come from config
- [x] The per-attribute + buttons and the meat cost of levels are gone
- [x] Dinosaurs grow their attributes automatically, mostly their best ones
- [x] An old save keeps its levels, recalculates attributes and is refunded the meat spent on levels
- [x] The summary shows each character's XP bar filling
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Levels come from XP alone (`config/leveling.cfg`, `main.add_xp`); dinosaurs grow by a rank pattern (mostly their best attribute); heroes level with no attribute growth until ticket 08 gives skill points; the Camp shows the level and what the next level adds; old saves are refunded. See [docs/systems/leveling.md](../../systems/leveling.md).
