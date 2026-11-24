# 10: Gear wear rework

**What to build:** Gear never stops working. Each run or stage uses 1 durability per piece worn (shown as "12 runs left"); at 0 a piece is Worn Out and gives half its bonus until repaired; repairs cost meat by rarity and upgrade level, at the Camp and Kora's Items screen; selling scales with wear.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] A run uses exactly 1 durability per worn piece; no more per-hit wear
- [ ] A Worn Out piece gives half its bonus
- [ ] Repair costs meat from config and restores full durability
- [ ] Old saves' broken gear loads as Worn Out
- [ ] Selling value scales with durability left
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
