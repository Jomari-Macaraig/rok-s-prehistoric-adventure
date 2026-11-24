# 11: Upgrades +1 to +10 and Kora's Blessing

**What to build:** Gear can be upgraded at Kora's bench for materials: +1 to +6 always succeed, +7 to +10 can fail (odds in config) dropping a level, and from +8 a small chance breaks the piece. A successful upgrade restores durability. Kora's Blessing (sold in the Market, a few a week, and later from chests and bosses) protects one upgrade.

**Blocked by:** [10: Gear wear rework](10-gear-wear-rework.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Upgrade odds, costs and break chance come from config
- [ ] A failure costs the materials and drops a level; from +8 it can break
- [ ] A success restores full durability
- [ ] Using a Blessing stops the drop and break
- [ ] The Market sells a limited number of Blessings a week
- [ ] The upgrade level raises a piece's strength and value
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
