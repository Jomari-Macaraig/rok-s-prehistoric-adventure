# 18: Stars

**What to build:** Each stage has three Stars: clear it, plus two goals from the set list with numbers in its config. A small tracker shows progress in the run and a star pops with a sound when met; stars count only on a clear, add up across tries and stay earned; the briefing lists the goals; chapter star totals open bonus chests.

**Blocked by:** [15: Campaign opens and a first stage plays](15-campaign-opens-first-stage.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Every goal kind on the list (normal, boss-only and puzzle-only once those exist) is tracked from run events
- [ ] Stars are saved only on a clear and kept across tries
- [ ] The tracker shows progress and pops on a met goal
- [ ] Star chests open at the configured totals
- [ ] Game-scene test: a goal met on a failed try gives no star; met on a clear does
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
