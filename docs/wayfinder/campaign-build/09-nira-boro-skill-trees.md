# 09: Nira's and Boro's Skill Trees

**What to build:** Nira (Pathfinder, Acrobat, Tracker) and Boro (Bulwark, Crusher, Protector) get their own trees on the same screen, shared skills reusing Rok's effects.

**Blocked by:** [08: Rok's Skill Tree and its screen](08-rok-skill-tree.md)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] Each of the 30 skills works in a run (shared ones reuse one effect)
- [x] Switching hero shows that hero's tree and points
- [x] Nira's Scout's Hint and Boro's Fortress are wired where their systems exist, and listed as pending otherwise
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [heroes.md#skill-trees](../../systems/heroes.md#skill-trees). Seven skills wait for boss and puzzle stages (tickets 22 and 24): Scout's Hint, Shortcut Sense, Weak Spot, Mark, Fortress, Quake (and Rok's Combo Strike). Keen Eyes means dives start earlier (the only warning in today's game that fits). Brace triggers on pressing SLIDE.
