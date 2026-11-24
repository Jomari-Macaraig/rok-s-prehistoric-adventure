# 02: Lean launch and zone streaming

**What to build:** The game starts faster and long runs never hold every zone at once. Launch loads only the always-loaded core (the played hero, HUD and menus, pickups, effects, sounds, music) and the first zone; during an endless run the next zone is prepared in the background and the zone left behind is freed.

**Blocked by:** [01: Memory budget](01-memory-budget.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Launch loads the core and the first zone only (measured lower than ticket 1's number)
- [ ] Crossing into a zone never stutters: it was prepared ahead
- [ ] The zone behind is freed; memory stays under budget across a full 6000 m lap
- [ ] The loading screen and every existing test still pass
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
