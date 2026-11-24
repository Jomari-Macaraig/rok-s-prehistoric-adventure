# 01: Memory budget

**What to build:** Know how much image memory the game uses today and stop it growing past a budget. Measure what launch loads now, put a memory budget (first guess about 400 MB of images) in campaign config, and add a test that loads each endless zone and fails if it goes over.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Today's launch memory is measured and written in the run-loop doc
- [ ] The budget is a config value, not a code constant
- [ ] A test loads each endless zone on its own, measures image memory and fails over budget
- [ ] The test reports each zone's number so later tickets can see the effect
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
