# 07: Dinosaur level path screen

**What to build:** At the Camp, a picked dinosaur shows its road from level 1 to 20 (variant A of the level-path prototype): small dots, gold Milestone circles, purple Evolution circles, reached ones lit, the next glowing, a "Next: Lv 8 ..." chip; tapping a Milestone shows its reward card.

**Blocked by:** [04: Milestones, Evolution and the Raptor's six](04-milestones-evolution-raptor.md)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] The road shows all 20 levels with the right kinds and states
- [x] Tapping a Milestone opens its card, saying whether it's unlocked
- [x] Fits 1280x720 and 1560x720 with nothing overlapping (screenshots)
- [x] Stand-in drawing until the user's art arrives
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [camp.md#level-path-dinosaur-tabs](../../systems/camp.md#level-path-dinosaur-tabs), with the user's path art. Milestone icons (section 4) aren't in yet: milestone circles show the level number and the name under them.
