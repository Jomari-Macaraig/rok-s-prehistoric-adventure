# 04: Milestones, Evolution and the Raptor's six

**What to build:** Levels change how a form plays. Milestones at 3, 5, 8, 13, 15 and 18 give a Trick or a Trait (set per species in config); Evolution at 10 (+1 every attribute) and 20 (+1 again, best attribute may pass its cap) with a glow until evolved art exists. The Raptor gets all six: Quick Start, Double Dash, Light Step, Pounce, Pack Instinct, Triple Jump.

**Blocked by:** [03: Automatic levels](03-automatic-levels.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] A Milestone is unlocked when its level is reached and saved
- [ ] Each of the Raptor's six works in a run as the spec describes
- [ ] Evolution at 10 and 20 changes attributes and shows a glow
- [ ] The summary shows a card for a new Milestone ("NEW: Raptor learned Double Dash!")
- [ ] Milestones are listed per species in config
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
