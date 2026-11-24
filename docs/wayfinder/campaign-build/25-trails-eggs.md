# 25: Trails and eggs

**What to build:** Every species has a Home Zone in config, where it runs wild. Once a chapter's boss is beaten, each species at home there gets a 3-stage Trail (meet it running wild, a stage built around its category, beat it as a boss). The last stage pays one random reward from the Trail's pool (its card, XP if owned, a Market discount if not, an egg), each won only once; an empty pool pays the normal replay reward. Eggs are stored for the pet system.

**Blocked by:** [22: First Boss stage (T-rex)](22-first-boss-trex.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Home zones come from config
- [ ] Trail signs open after the chapter boss
- [ ] Pool rewards are each won once; an empty pool gives the replay reward
- [ ] Eggs are saved in the player's items and can't be sold
- [ ] At least one Trail is written as the template for the rest
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
