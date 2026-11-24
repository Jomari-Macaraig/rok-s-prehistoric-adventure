# 26: Endless runs point at the campaign

**What to build:** Once the campaign is open, the endless-run summary shows "Strength 38 (+2 this run). Next stage: Desert 4 needs 40" and tapping it opens that briefing; about 1 in 3 daily and weekly missions is a campaign goal (only reachable stages); badges gain tracks for stars, bosses and Trails; rare and better milestone chests have a small chance of 1 torch.

**Blocked by:** [14: Strength](14-strength.md), [17: Torches](17-torches.md), [18: Stars](18-stars.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] The summary line appears only once the campaign is open and opens the briefing
- [ ] Campaign missions never need an unreachable stage
- [ ] New badge tracks count stars, bosses and Trails
- [ ] Chest torch odds come from config and respect the cap of 10
- [ ] Endless runs never drop Boss Materials or eggs
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
