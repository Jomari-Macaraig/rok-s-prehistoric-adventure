# 11: Upgrades +1 to +10 and Kora's Blessing

**What to build:** Gear can be upgraded at Kora's bench for materials: +1 to +6 always succeed, +7 to +10 can fail (odds in config) dropping a level, and from +8 a small chance breaks the piece. A successful upgrade restores durability. Kora's Blessing (sold in the Market, a few a week, and later from chests and bosses) protects one upgrade.

**Blocked by:** [10: Gear wear rework](10-gear-wear-rework.md)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] Upgrade odds, costs and break chance come from config
- [x] A failure costs the materials and drops a level; from +8 it can break
- [x] A success restores full durability
- [x] Using a Blessing stops the drop and break
- [x] The Market sells a limited number of Blessings a week
- [x] The upgrade level raises a piece's strength and value
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [weapons-and-armor.md#upgrades-1-to-10-and-koras-blessing](../../systems/weapons-and-armor.md#upgrades-1-to-10-and-koras-blessing). Blessings from chests and bosses come with those tickets.
