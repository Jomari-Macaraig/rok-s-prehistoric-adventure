# 27: Balance Bot

**What to build:** The autopilot plays like a person: a skill setting (perfect stays for today's tests; average presses about 0.2 s late now and then and gets about 1 press in 20 wrong), ATTACK use, boss-attack answers after their warning, and puzzle play from the piece list. A team builder turns any Strength into the Journey's typical team with the stage's suggested dinosaurs. It can play endless runs from a fresh save to check the Journey table.

**Blocked by:** [14: Strength](14-strength.md), [22: First Boss stage (T-rex)](22-first-boss-trex.md), [24: Puzzle stages](24-puzzle-stages.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Perfect mode keeps every existing test passing
- [ ] Average mode misses and lags at the configured rates
- [ ] The bot beats the T-rex boss and a puzzle stage
- [ ] The team builder makes the Journey's typical team for any Strength
- [ ] The Journey table lives in config
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
