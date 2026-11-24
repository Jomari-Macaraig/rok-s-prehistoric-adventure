# 19: Results, rewards and failing

**What to build:** Clearing shows rewards one by one (stars, XP bars, items with NEW tags): first clears pay XP, zone materials, a little meat, a card chance and every 3rd stage a torch; replays about a fifth; each star's first earning a small bonus. Failing says what happened, how far, and the torch spent, keeps XP and pickups, and offers Retry, Back and Endless Run (Refill when out); after 3 failures in a row a tip from the weakest part of Strength.

**Blocked by:** [16: Trail map and briefing](16-trail-map-briefing.md), [17: Torches](17-torches.md), [18: Stars](18-stars.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Reward amounts per chapter come from config
- [ ] First clear and replay pay differently; torches every 3rd first clear
- [ ] The fail screen shows the cause, progress and torch spent
- [ ] XP and pickups are kept on a failure; no first-clear rewards or stars
- [ ] Three failures in a row show the tip
- [ ] Game-scene tests for a clear and a failure
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
