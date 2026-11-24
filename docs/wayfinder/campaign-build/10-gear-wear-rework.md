# 10: Gear wear rework

**What to build:** Gear never stops working. Each run or stage uses 1 durability per piece worn (shown as "12 runs left"); at 0 a piece is Worn Out and gives half its bonus until repaired; repairs cost meat by rarity and upgrade level, at the Camp and Kora's Items screen; selling scales with wear.

**Blocked by:** None (can start immediately)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] A run uses exactly 1 durability per worn piece; no more per-hit wear
- [x] A Worn Out piece gives half its bonus
- [x] Repair costs meat from config and restores full durability
- [x] Old saves' broken gear loads as Worn Out
- [x] Selling value scales with durability left
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [weapons-and-armor.md#durability-and-repair](../../systems/weapons-and-armor.md#durability-and-repair). Durability is now 12-20 runs per piece (config). Starting a new run while one is going counts as that run ending (it wears gear).
