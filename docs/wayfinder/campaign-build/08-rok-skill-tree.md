# 08: Rok's Skill Tree and its screen

**What to build:** Heroes grow by choice. Each hero level from 2 to 20 gives a skill point; Rok's three branches (Runner, Brawler, Survivor) of five skills costing 1,1,2,2,3, each needing the one below, work in runs. The Camp shows the growing-tree screen (variant A) with level, XP, skill points and a free Reset.

**Blocked by:** [03: Automatic levels](03-automatic-levels.md)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] Levelling Rok grants skill points (19 by level 20)
- [x] Learning a skill spends points, needs the one below and is saved
- [x] Each of Rok's 15 skills works in a run as the spec describes
- [x] Reset refunds every point for free
- [x] Fits 1280x720 and 1560x720 (screenshots)
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [heroes.md#skill-trees](../../systems/heroes.md#skill-trees). Two notes: **Combo Strike** has no effect until bosses exist (ticket 22 wires it); **Rock Breaker** breaks boulders, because ATTACK already breaks small hazards for everyone. Branch banners and skill icons are still art to come; the cards show names.
